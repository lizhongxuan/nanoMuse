import Foundation
import Security
import SwiftUI
import UIKit
import WebKit

// BEGIN Morde host navigation helpers
import Foundation

func isAllowedMordeHostNavigation(_ candidate: URL?, relativeTo origin: URL) -> Bool {
    guard let candidate,
          let candidateComponents = URLComponents(url: candidate, resolvingAgainstBaseURL: false),
          let originComponents = URLComponents(url: origin, resolvingAgainstBaseURL: false),
          candidateComponents.scheme?.lowercased() == "https",
          originComponents.scheme?.lowercased() == "https",
          let candidateHost = candidateComponents.host, !candidateHost.isEmpty,
          let originHost = originComponents.host, !originHost.isEmpty,
          candidateHost.caseInsensitiveCompare(originHost) == .orderedSame,
          (candidateComponents.port ?? 443) == (originComponents.port ?? 443),
          candidateComponents.user == nil, candidateComponents.password == nil,
          originComponents.user == nil, originComponents.password == nil else { return false }
    return true
}

func canStartMordeAction(busy: Bool) -> Bool { !busy }
func canRetryMordeBatchItem(taskStatus: String, itemStatus: String) -> Bool { taskStatus == "failed" && itemStatus == "failed" }
// END Morde host navigation helpers

func isValidMordeHostTicketURL(_ ticket: URL, for origin: URL) -> Bool {
    guard let host = URLComponents(url: origin, resolvingAgainstBaseURL: false),
          let url = URLComponents(url: ticket, resolvingAgainstBaseURL: false),
          host.scheme?.lowercased() == "https", let hostName = host.host, !hostName.isEmpty,
          host.user == nil, host.password == nil, host.query == nil, host.fragment == nil,
          host.percentEncodedPath.isEmpty || host.percentEncodedPath == "/",
          url.scheme?.lowercased() == "https", url.host?.caseInsensitiveCompare(hostName) == .orderedSame,
          (url.port ?? 443) == (host.port ?? 443), url.percentEncodedPath == "/__ch/auth",
          url.user == nil, url.password == nil, url.fragment == nil else { return false }
    let tickets = (url.queryItems ?? []).filter { $0.name == "t" }
    guard tickets.count == 1, let value = tickets.first?.value else { return false }
    return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}

private struct MordeKeychain {
    private let service = "io.morde.client"
    func get(_ account: String) -> String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service, kSecAttrAccount as String: account,
                                    kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var item: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    func set(_ value: String, key account: String) throws {
        remove(account)
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service, kSecAttrAccount as String: account,
                                    kSecValueData as String: Data(value.utf8),
                                    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly]
        guard SecItemAdd(query as CFDictionary, nil) == errSecSuccess else { throw URLError(.cannotWriteToFile) }
    }
    func remove(_ account: String) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service, kSecAttrAccount as String: account]
        SecItemDelete(query as CFDictionary)
    }
}

private struct MordeLoginResult: Decodable {
    let installation_id: String
    let client_credential: String
    let client_expires_at: String
}
private struct MordeInstallation: Codable { let id: String; let accountName: String }
private struct MordeAuthorization: Codable { let credential: String; let expiresAt: String }
private struct MordePage<Item: Decodable>: Decodable { let items: [Item] }
private struct MordeHost: Decodable, Identifiable { let id: String; let name: String; let state: String; let url: URL }
private struct MordeSharedHost: Decodable, Identifiable { let id: String; let name: String; let state: String; let url: URL }
private struct MordeWorkspace: Decodable, Identifiable { let id: String; let name: String; let revision: Int }
private struct MordeModel: Decodable, Identifiable {
    struct Capabilities: Decodable { let text: Bool; let tools: Bool }
    let id: String; let name: String; let capabilities: Capabilities
}
private struct MordeConversation: Decodable, Identifiable { let id: String; let host_id: String; let title: String }
private struct MordeMessage: Decodable, Identifiable { let id: String; let role: String; let content: String }
private struct MordeBatchItem: Decodable, Identifiable { let id: String; let key: String; let status: String }
private struct MordeTask: Decodable, Identifiable {
    struct Pending: Decodable { let id: String; let version: Int; let title: String; let content: String; let impact: String }
    struct Clarification: Decodable { let id: String; let version: Int; let question: String }
    let id: String; let conversation_id: String; let host_id: String; let objective: String; let status: String
    let result: String?; let current_step: String?; let pending_request: Pending?
    let clarification_request: Clarification?; let batch_items: [MordeBatchItem]?; let updated_at: String
}
private struct MordeNotification: Decodable, Identifiable {
    let id: String; let summary: String?; let kind: String; let task_id: String?; let read_at: String?
}
private struct MordeTicket: Decodable { let url: URL }
private struct MordeEmpty: Decodable {}
private struct MordeMe: Decodable { let id: String; let name: String }
private struct MordeError: Decodable { struct Detail: Decodable { let message: String }; let error: Detail }

@MainActor private final class MordeClient: ObservableObject {
    @Published var server = UserDefaults.standard.string(forKey: "morde.server") ?? ""
    @Published var user: MordeMe?
    @Published var hosts: [MordeHost] = []
    @Published var sharedHosts: [MordeSharedHost] = []
    @Published var workspaces: [MordeWorkspace] = []
    @Published var models: [MordeModel] = []
    @Published var conversations: [MordeConversation] = []
    @Published var messages: [MordeMessage] = []
    @Published var tasks: [MordeTask] = []
    @Published var notifications: [MordeNotification] = []
    @Published var currentConversation: String?
    @Published var currentTask: MordeTask?
    @Published var hostURL: URL?
    @Published var error: String?
    @Published var busy = false

    private let keychain = MordeKeychain()
    private var loginAttempt: (fingerprint: String, key: String)?
    private var authorization: MordeAuthorization? {
        guard let raw = keychain.get("authorization"), let data = raw.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(MordeAuthorization.self, from: data)
    }
    private var installation: MordeInstallation? {
        guard let data = UserDefaults.standard.data(forKey: "morde.installation") else { return nil }
        return try? JSONDecoder().decode(MordeInstallation.self, from: data)
    }
    private var token: String? {
        guard let authorization else { return nil }
        return MordeCredentialExpiry.validCredential(authorization.credential, expiresAt: authorization.expiresAt)
    }
    var signedIn: Bool { token != nil }

    func expiryNotice(at now: Date) -> String? {
        guard let raw = authorization?.expiresAt else { return nil }
        switch MordeCredentialExpiry.status(expiresAt: raw, now: now) {
        case .expired: return "登录已到期，请重新登录"
        case .expiringSoon: return "登录将在 7 天内到期，请重新登录以续期"
        case .valid, nil: return nil
        }
    }

    private func clearAuthorization() {
        keychain.remove("authorization")
        keychain.remove("credential")
    }

    func refreshExpiredAuthorization(now: Date = Date()) {
        guard let authorization,
              MordeCredentialExpiry.status(expiresAt: authorization.expiresAt, now: now) == .expired else { return }
        clearAuthorization()
        reset()
        error = "登录已到期，请重新登录"
    }

    func authorizationExpiryDelay(at now: Date = Date()) -> TimeInterval? {
        MordeCredentialExpiry.secondsUntilExpiry(expiresAt: authorization?.expiresAt, now: now)
    }

    func setServer(_ value: String) throws {
        guard let url = URL(string: value), url.scheme == "https", url.host != nil, (url.path.isEmpty || url.path == "/"),
              url.user == nil, url.password == nil, url.query == nil, url.fragment == nil else {
            throw NSError(domain: "Morde", code: 1, userInfo: [NSLocalizedDescriptionKey: "请输入 HTTPS 服务地址"])
        }
        let normalized = url.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if normalized != UserDefaults.standard.string(forKey: "morde.server") {
            clearAuthorization()
            UserDefaults.standard.removeObject(forKey: "morde.installation")
            reset()
        }
        server = normalized
        UserDefaults.standard.set(normalized, forKey: "morde.server")
    }

    private func reset() {
        user = nil; hosts = []; sharedHosts = []; workspaces = []; models = []
        conversations = []; messages = []; tasks = []; notifications = []
        currentConversation = nil; currentTask = nil; hostURL = nil
        retrySend = nil; retryAction = nil
    }

    private func call<T: Decodable>(_ path: String, method: String = "GET", body: [String: Any]? = nil,
                                    key: String? = nil, authorized: Bool = true) async throws -> T {
        let credential: String?
        if authorized {
            refreshExpiredAuthorization()
            guard let validCredential = token else {
                throw NSError(domain: "Morde", code: 401,
                              userInfo: [NSLocalizedDescriptionKey: "登录已到期，请重新登录"])
            }
            credential = validCredential
        } else { credential = nil }
        guard let base = URL(string: server), let url = URL(string: path, relativeTo: base)?.absoluteURL,
              url.host == base.host, url.port == base.port, url.scheme == "https" else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Request-Id")
        if let credential { request.setValue("Bearer \(credential)", forHTTPHeaderField: "Authorization") }
        if let key { request.setValue(key, forHTTPHeaderField: "Idempotency-Key") }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode == 401 {
            clearAuthorization()
            reset()
        }
        guard (200..<300).contains(http.statusCode) else {
            let reason = try? JSONDecoder().decode(MordeError.self, from: data)
            throw NSError(domain: "Morde", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: reason?.error.message ?? "请求失败 (\(http.statusCode))"])
        }
        return try JSONDecoder().decode(T.self, from: data.isEmpty ? Data("{}".utf8) : data)
    }

    func login(name: String, password: String) async {
        guard !busy else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !password.isEmpty else { return }
        busy = true; defer { busy = false }
        do {
            try setServer(server)
            let fingerprint = MordeLoginAttempt.fingerprint(server: server, name: trimmedName, password: password)
            if loginAttempt?.fingerprint != fingerprint {
                loginAttempt = (fingerprint, UUID().uuidString)
            }
            var body: [String: Any] = ["name": trimmedName, "password": password,
                                       "platform": "ios", "display_name": UIDevice.current.name]
            if let installation, installation.accountName == trimmedName {
                body["renewal_installation_id"] = installation.id
            }
            let result: MordeLoginResult = try await call("/api/auth/client-login", method: "POST",
                body: body, key: loginAttempt?.key, authorized: false)
            guard !result.installation_id.isEmpty, !result.client_credential.isEmpty,
                  MordeCredentialExpiry.validCredential(result.client_credential, expiresAt: result.client_expires_at) != nil else {
                throw URLError(.cannotParseResponse)
            }
            let stored = MordeAuthorization(credential: result.client_credential, expiresAt: result.client_expires_at)
            let installationData = try JSONEncoder().encode(MordeInstallation(id: result.installation_id, accountName: trimmedName))
            try keychain.set(String(decoding: JSONEncoder().encode(stored), as: UTF8.self), key: "authorization")
            UserDefaults.standard.set(installationData, forKey: "morde.installation")
            loginAttempt = nil
            error = nil
            await load()
        } catch {
            let status = (error as NSError).code
            if (400...499).contains(status) { loginAttempt = nil }
            self.error = error.localizedDescription
        }
    }

    func signOut() async {
        guard !busy else { return }
        busy = true; defer { busy = false }
        var remoteFailed = false
        if signedIn {
            do {
                let _: MordeEmpty = try await call("/api/auth/client-logout", method: "POST")
            } catch { remoteFailed = true }
        }
        clearAuthorization()
        UserDefaults.standard.removeObject(forKey: "morde.installation")
        reset()
        if remoteFailed {
            error = "已在本机退出。联网后请在 Morde 用户端撤销此安装。"
        }
    }

    func load() async {
        refreshExpiredAuthorization()
        guard signedIn else { return }
        do {
            let me: MordeMe = try await call("/api/me")
            if user?.id != nil && user?.id != me.id { reset() }
            user = me
            let hosts: MordePage<MordeHost> = try await call("/api/hosts")
            let shared: MordePage<MordeSharedHost> = try await call("/api/shared-hosts")
            let workspaces: MordePage<MordeWorkspace> = try await call("/api/workspaces")
            let models: MordePage<MordeModel> = try await call("/api/available-models")
            let conversations: MordePage<MordeConversation> = try await call("/api/conversations?limit=100")
            let tasks: MordePage<MordeTask> = try await call("/api/tasks?limit=100")
            let notifications: MordePage<MordeNotification> = try await call("/api/notifications?limit=100")
            self.hosts = hosts.items; self.sharedHosts = shared.items
            self.workspaces = workspaces.items; self.models = models.items
            self.conversations = conversations.items; self.tasks = tasks.items; self.notifications = notifications.items
            if let id = currentConversation { await chooseConversation(id) }
            error = nil
        } catch { self.error = error.localizedDescription }
    }

    func chooseConversation(_ id: String) async {
        currentConversation = id
        do {
            let page: MordePage<MordeMessage> = try await call("/api/conversations/\(id)/messages?limit=100")
            messages = page.items
            if let latest = tasks.filter({ $0.conversation_id == id }).max(by: { $0.updated_at < $1.updated_at }) {
                currentTask = try await call("/api/tasks/\(latest.id)")
            } else { currentTask = nil }
        } catch { self.error = error.localizedDescription }
    }

    private var retrySend: (fingerprint: String, key: String)?
    func send(_ objective: String, host: String, model: String) async -> Bool {
        guard !objective.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        let fingerprint = "\(currentConversation ?? "")|\(host)|\(model)|\(objective)"
        if retrySend?.fingerprint != fingerprint { retrySend = (fingerprint, UUID().uuidString) }
        busy = true; defer { busy = false }
        do {
            let task: MordeTask
            if let conversation = currentConversation {
                struct Appended: Decodable { let task: MordeTask }
                let appended: Appended = try await call("/api/conversations/\(conversation)/messages", method: "POST",
                                                         body: ["host_id": host, "model_id": model, "content": objective],
                                                         key: retrySend?.key)
                task = appended.task
            } else {
                task = try await call("/api/tasks", method: "POST",
                                      body: ["host_id": host, "model_id": model, "objective": objective],
                                      key: retrySend?.key)
            }
            retrySend = nil; currentConversation = task.conversation_id; currentTask = task
            await load(); return true
        } catch { self.error = error.localizedDescription; return false }
    }

    private var retryAction: (fingerprint: String, key: String)?
    func act(_ body: [String: Any]) async {
        guard canStartMordeAction(busy: busy), let task = currentTask else { return }
        let fingerprint = "\(task.id)|\(body.sorted { $0.key < $1.key })"
        if retryAction?.fingerprint != fingerprint { retryAction = (fingerprint, UUID().uuidString) }
        busy = true; defer { busy = false }
        do {
            struct Response: Decodable { let task_id: String }
            let _: Response = try await call("/api/tasks/\(task.id)/actions", method: "POST", body: body,
                                             key: retryAction?.key)
            retryAction = nil
            currentTask = try await call("/api/tasks/\(task.id)")
            error = nil
        } catch {
            self.error = error.localizedDescription
            if (error as NSError).code == 409 {
                retryAction = nil
                currentTask = try? await call("/api/tasks/\(task.id)")
            }
        }
    }

    func watchCurrentTask() async {
        guard let id = currentTask?.id else { return }
        var cursor = ""
        while !Task.isCancelled, currentTask?.id == id, let token {
            do {
                guard var components = URLComponents(string: "\(server)/api/tasks/\(id)/events") else { return }
                if !cursor.isEmpty { components.queryItems = [URLQueryItem(name: "after", value: cursor)] }
                guard let url = components.url else { return }
                var request = URLRequest(url: url)
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.cachePolicy = .reloadIgnoringLocalCacheData
                let (bytes, response) = try await URLSession.shared.bytes(for: request)
                guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
                if http.statusCode == 401 { signOutLocally(); return }
                if http.statusCode == 204 { return }
                guard http.statusCode == 200 else { throw URLError(.badServerResponse) }
                var event = ""
                var eventID = ""
                for try await line in bytes.lines {
                    if Task.isCancelled { return }
                    if line.hasPrefix("id:") { eventID = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces) }
                    else if line.hasPrefix("event:") { event = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces) }
                    else if line.isEmpty && !event.isEmpty {
                        guard !eventID.isEmpty, Int64(eventID) != nil else { throw URLError(.cannotParseResponse) }
                        let task: MordeTask = try await call("/api/tasks/\(id)")
                        let page: MordePage<MordeMessage> = try await call("/api/conversations/\(task.conversation_id)/messages?limit=100")
                        guard !Task.isCancelled, currentTask?.id == id else { return }
                        currentTask = task; currentConversation = task.conversation_id; messages = page.items
                        cursor = eventID
                        if ["completed", "failed", "cancelled"].contains(task.status) { return }
                        if event == "task.snapshot_required" { break }
                        event = ""; eventID = ""
                    }
                }
            } catch {
                if !Task.isCancelled { self.error = error.localizedDescription }
            }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
    }

    func openHost(_ id: String, shared: Bool = false) async {
        do {
            guard let origin = (shared ? sharedHosts.first(where: { $0.id == id })?.url : hosts.first(where: { $0.id == id })?.url),
                  origin.scheme == "https", origin.host != nil else { throw URLError(.badURL) }
            let suffix = shared ? "observation-ticket" : "enter"
            let ticket: MordeTicket = try await call("/api/hosts/\(id)/\(suffix)", method: "POST")
            guard isValidMordeHostTicketURL(ticket.url, for: origin) else { throw URLError(.badURL) }
            hostURL = ticket.url
        } catch { self.error = error.localizedDescription }
    }

    func openNotification(_ notice: MordeNotification) async {
        do {
            let _: MordeEmpty = try await call("/api/notifications/\(notice.id)/read", method: "POST")
            if let id = notice.task_id {
                currentTask = try await call("/api/tasks/\(id)")
                if let conversation = currentTask?.conversation_id { await chooseConversation(conversation) }
            }
            let page: MordePage<MordeNotification> = try await call("/api/notifications?limit=100")
            notifications = page.items
        } catch { self.error = error.localizedDescription }
    }

    private func signOutLocally() {
        clearAuthorization()
        reset()
    }
}

@main struct MordeApp: App {
    @StateObject private var client = MordeClient()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            MordeRoot(client: client)
                .task {
                    client.refreshExpiredAuthorization()
                    await client.load()
                }
                .task {
                    while !Task.isCancelled {
                        let seconds = min(max(client.authorizationExpiryDelay() ?? 30, 0.05), 30)
                        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                        if Task.isCancelled { break }
                        client.refreshExpiredAuthorization()
                    }
                }
                .task(id: client.currentTask?.id) { await client.watchCurrentTask() }
                .onChange(of: scenePhase) { phase in
                    if phase == .active {
                        Task {
                            client.refreshExpiredAuthorization()
                            await client.load()
                        }
                    }
                }
        }
    }
}

private struct MordeRoot: View {
    @ObservedObject var client: MordeClient
    @State private var loginName = ""
    @State private var loginPassword = ""
    @State private var selectedTab = 0
    @State private var host = ""
    @State private var model = ""
    @State private var draft = ""
    @State private var answer = ""
    private func clearComposer() {
        host = ""; model = ""; draft = ""; answer = ""; selectedTab = 0
    }
    var body: some View {
        Group {
            if !client.signedIn {
                Form {
                    Section("Morde 服务") {
                        TextField("https://morde.example", text: $client.server)
                            .textInputAutocapitalization(.never).keyboardType(.URL)
                            .disabled(client.busy)
                    }
                    Section("登录") {
                        TextField("账号", text: $loginName)
                            .textInputAutocapitalization(.never)
                        SecureField("密码", text: $loginPassword)
                        Button(client.busy ? "登录中…" : "登录") {
                            let password = loginPassword
                            loginPassword = ""
                            Task { await client.login(name: loginName, password: password) }
                        }
                        .disabled(client.busy || client.server.isEmpty ||
                                  loginName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || loginPassword.isEmpty)
                    }
                }
            } else {
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        List {
                            Section("最近对话") {
                                Button("新任务") { client.currentConversation = nil; client.currentTask = nil; client.messages = [] }
                                ForEach(client.conversations) { item in
                                    Button(item.title.isEmpty ? "新对话" : item.title) { Task { await client.chooseConversation(item.id) } }
                                }
                            }
                            ForEach(client.messages) { message in
                                Text(message.content).frame(maxWidth: .infinity, alignment: message.role == "user" ? .trailing : .leading)
                            }
                            if let task = client.currentTask {
                                Section("任务 · \(task.status)") {
                                    Text(task.current_step ?? task.result ?? task.objective)
                                    if let pending = task.pending_request {
                                        Text(pending.title).font(.headline)
                                        Text(pending.content)
                                        Text(pending.impact).font(.footnote)
                                        HStack {
                                            Button("批准") { Task { await client.act(["action": "respond", "pending_id": pending.id, "pending_version": pending.version, "decision": "approve"]) } }.disabled(!canStartMordeAction(busy: client.busy))
                                            Button("拒绝") { Task { await client.act(["action": "respond", "pending_id": pending.id, "pending_version": pending.version, "decision": "reject"]) } }.disabled(!canStartMordeAction(busy: client.busy))
                                        }
                                    }
                                    if let clarification = task.clarification_request {
                                        Text(clarification.question)
                                        TextField("回复问题", text: $answer, axis: .vertical)
                                        Button("回复") {
                                            let text = answer.trimmingCharacters(in: .whitespacesAndNewlines)
                                            Task { await client.act(["action": "answer_clarification", "clarification_id": clarification.id,
                                                                     "clarification_version": clarification.version, "answer": text]); answer = "" }
                                        }.disabled(!canStartMordeAction(busy: client.busy) || answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                    }
                                    ForEach((task.batch_items ?? []).filter { canRetryMordeBatchItem(taskStatus: task.status, itemStatus: $0.status) }) { item in
                                        Button("重试批次项：\(item.key)") { Task { await client.act(["action": "retry_batch_item", "batch_item_id": item.id]) } }
                                            .disabled(!canStartMordeAction(busy: client.busy))
                                    }
                                    if task.status == "running" || task.status == "queued" {
                                        Button("暂停") { Task { await client.act(["action": "pause", "expected_status": task.status]) } }.disabled(!canStartMordeAction(busy: client.busy))
                                    }
                                    if task.status == "paused" {
                                        Button("继续") { Task { await client.act(["action": "resume", "expected_status": "paused"]) } }.disabled(!canStartMordeAction(busy: client.busy))
                                    }
                                    if ["running", "queued", "paused", "waiting_user"].contains(task.status) {
                                        Button("取消") { Task { await client.act(["action": "cancel", "expected_status": task.status]) } }.disabled(!canStartMordeAction(busy: client.busy))
                                    }
                                }
                            }
                            Section("发送任务") {
                                Picker("电脑", selection: $host) {
                                    Text("选择电脑").tag("")
                                    ForEach(client.hosts.filter { $0.state == "running" }) { item in Text(item.name).tag(item.id) }
                                }
                                Picker("模型", selection: $model) {
                                    Text("选择模型").tag("")
                                    ForEach(client.models.filter { $0.capabilities.text && $0.capabilities.tools }) { item in Text(item.name).tag(item.id) }
                                }
                                TextField("描述任务", text: $draft, axis: .vertical)
                                Button("发送") {
                                    Task { if await client.send(draft, host: client.conversations.first(where: { $0.id == client.currentConversation })?.host_id ?? host, model: model) { draft = "" } }
                                }.disabled(client.busy || draft.trimmingCharacters(in: .whitespaces).isEmpty || (client.currentConversation == nil && host.isEmpty) || model.isEmpty)
                            }
                        }.navigationTitle("Morde")
                    }.tabItem { Label("对话", systemImage: "bubble.left.and.bubble.right") }.tag(0)
                    NavigationStack {
                        List {
                            ForEach(client.hosts) { item in
                                Button { Task { await client.openHost(item.id) } } label: {
                                    VStack(alignment: .leading) { Text(item.name); Text(item.state).font(.caption) }
                                }.disabled(item.state != "running")
                            }
                            ForEach(client.sharedHosts) { item in
                                Button { Task { await client.openHost(item.id, shared: true) } } label: {
                                    VStack(alignment: .leading) { Text(item.name); Text("共享 · \(item.state)").font(.caption) }
                                }.disabled(item.state != "running")
                            }
                        }.navigationTitle("电脑")
                    }.tabItem { Label("电脑", systemImage: "desktopcomputer") }.tag(1)
                    NavigationStack {
                        List(client.workspaces) { item in
                            VStack(alignment: .leading) { Text(item.name); Text("版本 \(item.revision)").font(.caption) }
                        }.navigationTitle("项目")
                    }.tabItem { Label("项目", systemImage: "folder") }.tag(2)
                    NavigationStack {
                        List(client.notifications) { item in
                            Button { Task { await client.openNotification(item); if item.task_id != nil { selectedTab = 0 } } } label: {
                                VStack(alignment: .leading) { Text(item.kind); Text(item.summary ?? "不可查看").font(.caption) }
                            }
                        }.navigationTitle("通知")
                        Button("退出登录") { Task { await client.signOut() } }
                    }.tabItem { Label("通知", systemImage: "bell") }.tag(3)
                }.safeAreaInset(edge: .top) {
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        if let notice = client.expiryNotice(at: context.date) {
                            Text(notice).font(.headline).frame(maxWidth: .infinity)
                                .padding().background(Color.orange.opacity(0.25))
                        }
                    }
                }
            }
        }
        .onChange(of: client.signedIn) { if !$0 { clearComposer() } }
        .onChange(of: client.user?.id) { _ in clearComposer() }
        .alert("请求失败", isPresented: Binding(get: { client.error != nil }, set: { if !$0 { client.error = nil } })) {
            Button("确定") { client.error = nil }
        } message: { Text(client.error ?? "") }
        .sheet(item: Binding(get: { client.hostURL.map(MordeHostURL.init) }, set: { if $0 == nil { client.hostURL = nil } })) { item in
            MordeHostView(url: item.url)
        }
    }
}

private struct MordeHostURL: Identifiable { let url: URL; var id: String { url.absoluteString } }
private struct MordeHostView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        let web = WKWebView(frame: .zero)
        web.navigationDelegate = context.coordinator
        web.load(URLRequest(url: url))
        return web
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.stopLoading()
        uiView.navigationDelegate = nil
    }
    func makeCoordinator() -> Coordinator { Coordinator(origin: url) }
    final class Coordinator: NSObject, WKNavigationDelegate {
        let origin: URL
        init(origin: URL) { self.origin = origin }
        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(isAllowedMordeHostNavigation(action.request.url, relativeTo: origin) ? .allow : .cancel)
        }
    }
}
