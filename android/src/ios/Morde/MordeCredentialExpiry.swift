import Foundation
import CryptoKit

enum MordePersonalJSONValue: Codable, Equatable, Sendable {
    case object([String: MordePersonalJSONValue])
    case array([MordePersonalJSONValue])
    case string(String)
    case integer(Int64)
    case number(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null; return }
        if let value = try? container.decode([String: MordePersonalJSONValue].self) { self = .object(value); return }
        if let value = try? container.decode([MordePersonalJSONValue].self) { self = .array(value); return }
        if let value = try? container.decode(String.self) { self = .string(value); return }
        if let value = try? container.decode(Bool.self) { self = .bool(value); return }
        if let value = try? container.decode(Int64.self) { self = .integer(value); return }
        if let value = try? container.decode(Double.self), value.isFinite { self = .number(value); return }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported personal-data JSON value")
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .integer(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        try JSONDecoder().decode(type, from: JSONEncoder().encode(self))
    }
}

struct MordePersonalRevisionConflict: LocalizedError, Equatable, Sendable {
    let baseRevision: Int64
    let currentRevision: Int64
    let deleted: Bool
    let message: String

    var errorDescription: String? { message }

    static func decode(_ data: Data) -> MordePersonalRevisionConflict? {
        guard let envelope = try? JSONDecoder().decode(MordePersonalErrorEnvelope.self, from: data),
              envelope.error.code == "conflict",
              let details = envelope.error.details else { return nil }
        let recognizedReason = details["reason"] == .string("personal_object_revision_changed") ||
            (details["reason"] == nil && details.count == 3)
        guard recognizedReason,
              case .integer(let baseRevision)? = details["base_revision"],
              case .integer(let currentRevision)? = details["current_revision"],
              case .bool(let deleted)? = details["deleted"],
              baseRevision >= 0, currentRevision >= 0 else { return nil }
        // Older local API builds omit `reason` but retain this exact revision-conflict shape.
        return MordePersonalRevisionConflict(baseRevision: baseRevision, currentRevision: currentRevision,
                                             deleted: deleted, message: envelope.error.message)
    }
}

private struct MordePersonalErrorEnvelope: Decodable {
    struct ErrorBody: Decodable {
        let code: String
        let message: String
        let details: [String: MordePersonalJSONValue]?
    }

    let error: ErrorBody
}

enum MordeFirstRunPolicy {
    static func isNeeded(
        signedIn: Bool,
        hasProviders: Bool,
        hasSessions: Bool,
        done: Bool,
        mordeSignedIn: Bool
    ) -> Bool {
        !mordeSignedIn && ((!signedIn && !hasProviders) || (!hasSessions && !done))
    }
}

enum MordeLocalExecutionPolicy {
    static let isEnabled = false
    static var disabledMessage: String {
        String(localized: "Local Agent execution and direct model calls are disabled. Open Morde cloud tasks to continue.")
    }

    static func requireEnabled() throws {
        guard isEnabled else { throw MordeLocalExecutionDisabledError() }
    }
}

/// CloudKit sync is an independent product path from local Agent execution.
/// Keep it fail-closed until the old iCloud data flow is explicitly reviewed.
enum MordeCloudKitSyncPolicy {
    static let isEnabled = false
    static var disabledMessage: String {
        String(localized: "Legacy iCloud business sync is paused.")
    }

    static func shouldRemoveLegacyCache(userSyncEnabled: Bool) -> Bool {
        isEnabled && userSyncEnabled
    }
}

struct MordeCloudKitSyncDisabledError: LocalizedError {
    var errorDescription: String? { MordeCloudKitSyncPolicy.disabledMessage }
}

/// Keep preserved nanoMuse Cloud and Relay code from making requests in the Morde app.
enum MordeLegacyServicePolicy {
    static let isEnabled = false
    static var disabledMessage: String {
        String(localized: "Legacy morde services are disabled in morde.")
    }
}

struct MordeLegacyServiceDisabledError: LocalizedError {
    var errorDescription: String? { MordeLegacyServicePolicy.disabledMessage }
}

struct MordeLocalExecutionDisabledError: LocalizedError {
    var errorDescription: String? { MordeLocalExecutionPolicy.disabledMessage }
}

struct MordeAPIKeyDeletionOutcome: Equatable {
    static let successStatus: Int32 = 0
    static let itemNotFoundStatus: Int32 = -25_300

    let legacyStatus: Int32
    let synchronizableStatus: Int32

    var isComplete: Bool {
        Self.isSuccessful(legacyStatus) && Self.isSuccessful(synchronizableStatus)
    }

    var failedStatuses: [Int32] {
        [legacyStatus, synchronizableStatus].filter { !Self.isSuccessful($0) }
    }

    private static func isSuccessful(_ status: Int32) -> Bool {
        status == successStatus || status == itemNotFoundStatus
    }
}

struct MordeProviderKeyCleanupDescriptor: Equatable {
    let instanceID: String
    let providerType: String
    let credentialType: String
}

struct MordeProviderKeyCleanupLedger: Codable, Equatable {
    enum Status: String, Codable {
        case pending
        case complete
    }

    let version: Int
    var status: Status
    var pendingInstanceIDs: [String]
    var pendingLegacyServices: [String]
    var reviewRequiredInstanceIDs: [String]
}

enum MordeProviderKeyCleanupPlan {
    static let version = 1
    static let defaultsKey = "morde.provider-own-api-key-cleanup.v1"
    static let noticePendingDefaultsKey = "morde.provider-own-api-key-cleanup-notice-pending.v1"
    static let legacyKeychainServices = [
        "io.github.nanomuse.app.anthropic-api-key",
        "io.github.nanomuse.app.gemini-api-key",
        "io.github.nanomuse.app.openai-api-key",
    ]

    static func shouldShowNotice(storedValue: Bool?, cleanupComplete: Bool) -> Bool {
        storedValue ?? cleanupComplete
    }

    /// Delete both Keychain variants with an explicit synchronization scope. The injected
    /// closure lets the host-side test use synthetic entries instead of the real Keychain.
    static func deleteVariants(
        baseQuery: [String: Any],
        synchronizableAttribute: String,
        deleteItem: ([String: Any]) -> Int32
    ) -> MordeAPIKeyDeletionOutcome {
        var legacyQuery = baseQuery
        legacyQuery[synchronizableAttribute] = false
        var synchronizableQuery = baseQuery
        synchronizableQuery[synchronizableAttribute] = true
        return MordeAPIKeyDeletionOutcome(
            legacyStatus: deleteItem(legacyQuery),
            synchronizableStatus: deleteItem(synchronizableQuery)
        )
    }

    private static let knownKeyProviderTypes: Set<String> = [
        "openAI", "anthropic", "gemini", "antigravity", "openRouter",
        "openAIResponses", "xAI", "kimiCode",
    ]

    static func candidateInstanceIDs(from descriptors: [MordeProviderKeyCleanupDescriptor]) -> [String] {
        Array(Set(descriptors.compactMap { descriptor in
            guard descriptor.credentialType == "apiKey",
                  knownKeyProviderTypes.contains(descriptor.providerType),
                  !descriptor.instanceID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }
            return descriptor.instanceID
        })).sorted()
    }

    static func reviewRequiredInstanceIDs(from descriptors: [MordeProviderKeyCleanupDescriptor]) -> [String] {
        Array(Set(descriptors.compactMap { descriptor in
            guard descriptor.credentialType == "apiKey",
                  !knownKeyProviderTypes.contains(descriptor.providerType),
                  !descriptor.instanceID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }
            return descriptor.instanceID
        })).sorted()
    }

    static func begin(
        previous: MordeProviderKeyCleanupLedger?,
        candidateInstanceIDs: [String],
        reviewRequiredInstanceIDs: [String],
        preservedInstanceIDs: Set<String> = []
    ) -> MordeProviderKeyCleanupLedger {
        if let previous, previous.version == version, previous.status == .complete {
            var completed = previous
            completed.pendingInstanceIDs.removeAll { preservedInstanceIDs.contains($0) }
            completed.reviewRequiredInstanceIDs.removeAll { preservedInstanceIDs.contains($0) }
            return completed
        }
        return MordeProviderKeyCleanupLedger(
            version: version,
            status: .pending,
            // nanoMuse: A pending cleanup retry must not delete the relay key after its provider row was reclassified.
            pendingInstanceIDs: Array(Set((previous?.pendingInstanceIDs ?? []) + candidateInstanceIDs)
                .filter { !preservedInstanceIDs.contains($0) }).sorted(),
            pendingLegacyServices: Array(Set((previous?.pendingLegacyServices ?? []) + legacyKeychainServices)).sorted(),
            reviewRequiredInstanceIDs: Array(Set((previous?.reviewRequiredInstanceIDs ?? []) + reviewRequiredInstanceIDs)
                .filter { !preservedInstanceIDs.contains($0) }).sorted()
        )
    }

    static func finish(
        _ ledger: MordeProviderKeyCleanupLedger,
        failedInstanceIDs: [String],
        failedLegacyServices: [String]
    ) -> MordeProviderKeyCleanupLedger {
        let failedInstances = Array(Set(failedInstanceIDs)).sorted()
        let failedServices = Array(Set(failedLegacyServices)).sorted()
        return MordeProviderKeyCleanupLedger(
            version: version,
            status: failedInstances.isEmpty && failedServices.isEmpty ? .complete : .pending,
            pendingInstanceIDs: failedInstances,
            pendingLegacyServices: failedServices,
            reviewRequiredInstanceIDs: ledger.reviewRequiredInstanceIDs
        )
    }
}

enum MordeBackupAPIKeyRestorePolicy {
    enum Disposition: Equatable {
        case absent
        case removedByMigration
    }

    static func disposition(hasAPIKey: Bool) -> Disposition {
        hasAPIKey ? .removedByMigration : .absent
    }

    static func unknownFieldCount(in data: Data) -> Int {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return 0 }
        var count = unknownKeys(in: root, allowed: ["v", "providers", "envVars", "mcpOAuth"])
        for provider in root["providers"] as? [[String: Any]] ?? [] {
            count += unknownKeys(in: provider, allowed: [
                "instanceId", "label", "providerType", "apiKey", "manualOAuthToken",
                "oauthToken", "oauthEmail", "oauthGcpProject",
            ])
        }
        for envVar in root["envVars"] as? [[String: Any]] ?? [] {
            count += unknownKeys(in: envVar, allowed: ["name", "value"])
        }
        for server in root["mcpOAuth"] as? [[String: Any]] ?? [] {
            count += unknownKeys(in: server, allowed: ["serverId", "token", "clientSecret"])
        }
        return count
    }

    private static func unknownKeys(in object: [String: Any], allowed: Set<String>) -> Int {
        object.keys.reduce(into: 0) { count, key in
            if !allowed.contains(key) { count += 1 }
        }
    }
}

struct MordeLoginIntent: Equatable {
    let id: UUID
    let origin: String
    let accountName: String
    fileprivate let scopeKey: String
}

enum MordeLoginContract {
    private static let requiredFeatures: Set<String> = [
        "password_login", "client_installations", "ordered_client_login"
    ]

    static func supportsOrderedClientLogin(_ features: [String]) -> Bool {
        requiredFeatures.isSubset(of: Set(features))
    }

    static func mayRenewInstallation(installationOrigin: String?, installationServiceInstanceID: String?,
                                     selectedServer: String, selectedServiceInstanceID: String,
                                     legacyServer: String?, installationAccount: String,
                                     accountName: String) -> Bool {
        guard installationAccount == accountName,
              let selectedOrigin = MordeLoginStateStore.serviceOrigin(selectedServer),
              let storedOrigin = MordeLoginStateStore.serviceOrigin(installationOrigin ?? legacyServer ?? "") else {
            return false
        }
        guard storedOrigin == selectedOrigin else { return false }
        guard let installationServiceInstanceID else { return true }
        guard let storedInstanceID = UUID(uuidString: installationServiceInstanceID),
              let selectedInstanceID = UUID(uuidString: selectedServiceInstanceID) else { return false }
        return storedInstanceID == selectedInstanceID
    }
}

enum MordeAccountLoginFailure: Equatable {
    case pending, rejected, disabled

    static func fromAPIErrorCode(_ code: String?) -> Self? {
        switch code {
        case "account_pending": .pending
        case "account_rejected": .rejected
        case "account_disabled": .disabled
        default: nil
        }
    }
}

// nanoMuse: Registration is a pending username/password request, never a login credential.
struct MordeRegistrationPayload: Equatable {
    let name: String
    let password: String

    static func make(name: String, password: String) -> Self? {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !password.isEmpty else { return nil }
        return Self(name: name, password: password)
    }

    var jsonObject: [String: String] { ["name": name, "password": password] }
}

enum MordeTaskSpeechInputPolicy {
    static func onDeviceRequirement(forced: Bool, supported: Bool) -> Bool? {
        guard !forced || supported else { return nil }
        return forced || supported
    }
}

enum MordeCapabilitiesFailure: Equatable {
    case network
    case http(statusCode: Int)
    case invalidResponse
    case incompatible
    case minimumVersion

    static func classify(domain: String, code: Int) -> MordeCapabilitiesFailure {
        if domain == NSURLErrorDomain { return .network }
        if domain == "Morde", (400..<600).contains(code) { return .http(statusCode: code) }
        return .invalidResponse
    }

    func message(underlying: String? = nil) -> String {
        let summary: String
        switch self {
        case .network:
            summary = "无法连接 Morde 服务，未发送账号信息。"
        case .http(let statusCode) where statusCode == 401 || statusCode == 403:
            summary = "无权读取 Morde 服务能力（HTTP \(statusCode)），未发送账号信息。"
        case .http(statusCode: 404):
            summary = "Morde 服务未提供能力接口（HTTP 404），未发送账号信息。"
        case .http(let statusCode):
            summary = "Morde 服务返回 HTTP \(statusCode)，无法读取服务能力，未发送账号信息。"
        case .invalidResponse:
            summary = "Morde 服务能力响应无效，未发送账号信息。"
        case .incompatible:
            summary = "Morde 服务版本不兼容或未开放有序客户端登录，未发送账号信息。"
        case .minimumVersion:
            summary = "当前 Morde 客户端版本过低，请更新后再登录，未发送账号信息。"
        }
        guard let underlying, !underlying.isEmpty else { return summary }
        return "\(summary)\n\(underlying)"
    }
}

enum MordeTaskCapability {
    static func cloudWorkerIsAvailable(_ features: [String]) -> Bool {
        features.contains("cloud_tasks")
    }

    // nanoMuse: Treat legacy cloud_tasks as Task API support during capability migration.
    static func taskAPIIsAvailable(_ features: [String]) -> Bool {
        features.contains("task_api") || cloudWorkerIsAvailable(features)
    }

    static func mediaGenerationIsAvailable(_ features: [String]) -> Bool {
        features.contains("task_media_generation")
    }
}

enum MordeWorkspaceSyncCapability {
    static func isAvailable(_ features: [String]?) -> Bool {
        features?.contains("workspace_sync") == true
    }
}

enum MordeConversationSelectionPolicy {
    static func shouldFollowMain(currentlySelected: String?, wasFollowingMain: Bool) -> Bool {
        wasFollowingMain || currentlySelected == nil
    }
}

enum MordeScopedRequestPolicy {
    static func isCurrent(scope: String?, generation: UUID, activeScope: String?, activeGeneration: UUID) -> Bool {
        guard let scope else { return false }
        return scope == activeScope && generation == activeGeneration
    }
}

enum MordePersonalSnapshotCursorPolicy {
    static func repeats(_ cursor: String?, seen: inout Set<String>) -> Bool {
        guard let cursor, !cursor.isEmpty else { return false }
        return !seen.insert(cursor).inserted
    }
}

enum MordeHostControlPolicy {
    static func canTakeOver(state: String, actorID: String?, leaseActive: Bool?, transitioning: Bool) -> Bool {
        state == "ai" && actorID == "" && leaseActive == false && !transitioning
    }

    static func canRelease(state: String, actorID: String?, currentUserID: String?,
                           leaseActive: Bool?, transitioning: Bool) -> Bool {
        state == "user" && !currentUserID.isNilOrEmpty && actorID == currentUserID &&
            leaseActive == true && !transitioning
    }

    static func canRenew(state: String, actorID: String?, currentUserID: String?,
                         leaseActive: Bool?, transitioning: Bool) -> Bool {
        canRelease(state: state, actorID: actorID, currentUserID: currentUserID,
                   leaseActive: leaseActive, transitioning: transitioning)
    }
}

enum MordeProjectPolicy {
    static func hasValidID(_ id: String) -> Bool {
        id.range(of: #"^j[a-z0-9]{7}$"#, options: .regularExpression) != nil
    }

    static func hasValidInvitationID(_ id: String) -> Bool {
        id.range(of: #"^r[a-z0-9]{7}$"#, options: .regularExpression) != nil
    }

    static func hasValidConversationID(_ id: String) -> Bool {
        id.range(of: #"^c[a-z0-9]{7}$"#, options: .regularExpression) != nil
    }

    static func hasValidUserID(_ id: String) -> Bool {
        id.range(of: #"^u[a-z0-9]{7}$"#, options: .regularExpression) != nil
    }

    static func hasValidTaskID(_ id: String) -> Bool {
        id.range(of: #"^q[a-z0-9]{7}$"#, options: .regularExpression) != nil
    }

    static func restorableTaskID(ownerID: String, currentUserID: String?,
                                 messages: [(actorID: String, taskID: String?)]) -> String? {
        guard isOwner(ownerID: ownerID, currentUserID: currentUserID),
              let userID = currentUserID else { return nil }
        return messages.reversed().compactMap { message in
            message.actorID == userID ? message.taskID : nil
        }.first(where: hasValidTaskID)
    }

    static func isOwner(ownerID: String, currentUserID: String?) -> Bool {
        hasValidUserID(ownerID) && ownerID == currentUserID
    }

    static func canAcceptInvitation(state: String, inviteeID: String, currentUserID: String?) -> Bool {
        state == "pending" && hasValidUserID(inviteeID) && inviteeID == currentUserID
    }

    static func canTransferOwnership(ownerID: String, currentUserID: String?, targetUserID: String,
                                     targetRole: String) -> Bool {
        isOwner(ownerID: ownerID, currentUserID: currentUserID) && hasValidUserID(targetUserID) &&
            targetUserID != currentUserID && ["member", "viewer"].contains(targetRole)
    }

    static func canContinuePendingMutation(_ pendingFingerprint: String?, requestedFingerprint: String) -> Bool {
        pendingFingerprint == nil || pendingFingerprint == requestedFingerprint
    }

    static func canManageWorkItems(role: String?) -> Bool {
        role == "owner" || role == "member"
    }

    static func canLinkTask(role: String?, state: String, taskID: String, taskIDs: [String]) -> Bool {
        canManageWorkItems(role: role) && state != "delivered" && taskIDs.count < 100 &&
            hasValidTaskID(taskID) && !taskIDs.contains(taskID)
    }

    static func canRecordDelivery(role: String?, state: String, taskID: String, taskIDs: [String],
                                  workspaceID: String, revision: Int64) -> Bool {
        canManageWorkItems(role: role) && state == "open" && taskIDs.contains(taskID) &&
            hasValidTaskID(taskID) && hasValidResourceID(kind: "workspace", id: workspaceID) && revision > 0
    }

    static func canSetBudget(role: String?, currency: String, limitMicros: Int64) -> Bool {
        role == "owner" && currency.range(of: "^[A-Z]{3}$", options: .regularExpression) != nil &&
            limitMicros > 0 && limitMicros < Int64.max
    }

    static func hasValidResourceID(kind: String, id: String) -> Bool {
        switch kind {
        case "host": return id.range(of: #"^h[a-z0-9]{7}$"#, options: .regularExpression) != nil
        case "workspace": return id.range(of: #"^w[a-z0-9]{7}$"#, options: .regularExpression) != nil
        default: return false
        }
    }
}

enum MordeProjectExecutionCapability {
    static func isAvailable(_ features: [String]?) -> Bool {
        features?.contains("project_budget_execution") == true
    }

    static func canContinueTask(status: String) -> Bool {
        ["queued", "running", "waiting_user"].contains(status)
    }
}

private extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool { self?.isEmpty != false }
}

enum MordeNotificationPresentationPolicy {
    static func summary(_ summary: String?, redacted: Bool?) -> String {
        guard redacted == false, let summary else { return "不可查看" }
        return summary
    }

    static func canOpenTask(kind: String, redacted: Bool?, actionable: Bool?) -> Bool {
        redacted == false && (kind != "waiting_user" || actionable == true)
    }

    static func canAppendPage(currentIDs: [String], pageIDs: [String]) -> Bool {
        let ids = currentIDs + pageIDs
        return Set(ids).count == ids.count
    }
}

enum MordeTaskResponsePolicy {
    static func hasValidTaskID(_ id: String) -> Bool {
        id.range(of: #"^q[a-z0-9]{7}$"#, options: .regularExpression) != nil
    }

    static func hasValidRequestID(_ id: String) -> Bool {
        id.range(of: #"^r[a-z0-9]{7}$"#, options: .regularExpression) != nil
    }

    static func hasValidOperationID(_ id: String) -> Bool {
        id.range(of: #"^o[a-z0-9]{7}$"#, options: .regularExpression) != nil
    }

    static func hasValidAnswer(_ answer: String) -> Bool {
        !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && answer.utf8.count <= 16384 && !answer.contains("\0")
    }

    static func actionPath(taskID: String) -> String? {
        hasValidTaskID(taskID) ? "/api/tasks/\(taskID)/actions" : nil
    }

    static func approvalPath(taskID: String, approvalID: String) -> String? {
        guard hasValidTaskID(taskID), hasValidRequestID(approvalID) else { return nil }
        return "/api/tasks/\(taskID)/approvals/\(approvalID)/responses"
    }

    static func mediaPreviewPath(taskID: String, operationID: String) -> String? {
        guard hasValidTaskID(taskID), hasValidOperationID(operationID) else { return nil }
        return "/api/tasks/\(taskID)/media/\(operationID)/preview"
    }

    static func inputPath(taskID: String) -> String? {
        hasValidTaskID(taskID) ? "/api/tasks/\(taskID)/inputs" : nil
    }
}

struct MordeMainConversation: Decodable, Equatable {
    let status: String
    let conversation_id: String
    let version: Int64

    var isValid: Bool {
        ["ready", "selection_required", "uninitialized"].contains(status) &&
            (status == "ready"
                ? (conversation_id.range(of: "^c[a-z0-9]{7}$", options: .regularExpression) != nil && version > 0)
                : (conversation_id.isEmpty && version == 0))
    }
}

enum MordeMessageDeliveryPresentation {
    static func label(_ status: String?) -> String {
        switch status {
        case "pending": return "已受理，等待进入 Agent"
        case "applied": return "已进入 Agent；任务仍可能运行"
        case "unknown": return "投递状态未知；请刷新确认，不要重复提交"
        default: return "服务端未提供投递状态"
        }
    }
}

enum MordeClientInstallationPolicy {
    static func isValidID(_ id: String) -> Bool {
        id.range(of: "^i[a-z0-9]{7}$", options: .regularExpression) != nil
    }

    static func canRevoke(_ targetID: String, currentInstallationID: String?) -> Bool {
        guard isValidID(targetID), let currentInstallationID, isValidID(currentInstallationID) else {
            return false
        }
        return targetID != currentInstallationID
    }

    static func revokePath(for targetID: String, currentInstallationID: String?) -> String? {
        guard canRevoke(targetID, currentInstallationID: currentInstallationID) else { return nil }
        return "/api/clients/\(targetID)"
    }
}

enum MordeResource: String, CaseIterable, Hashable {
    case hosts
    case sharedHosts
    case workspaces
    case models
    case conversations
    case tasks
    case notifications
    case messages
    case taskDetail

    var label: String {
        switch self {
        case .hosts: return "电脑列表"
        case .sharedHosts: return "共享电脑列表"
        case .workspaces: return "Workspace 列表"
        case .models: return "模型列表"
        case .conversations: return "对话列表"
        case .tasks: return "Task 列表"
        case .notifications: return "通知列表"
        case .messages: return "消息"
        case .taskDetail: return "Task 状态"
        }
    }
}

enum MordeResourceLoadState: Equatable {
    case loading
    case loaded
    case failed(String)

    var isLoaded: Bool {
        if case .loaded = self { return true }
        return false
    }

    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }

    var failureMessage: String? {
        if case .failed(let message) = self { return message }
        return nil
    }
}

enum MordeResourcePresentation {
    static func emptyListMessage(resource: MordeResource, state: MordeResourceLoadState,
                                 itemCount: Int, emptyMessage: String) -> String? {
        guard itemCount == 0 else { return nil }
        switch state {
        case .loading:
            return "\(resource.label)正在读取。"
        case .loaded:
            return emptyMessage
        case .failed(let message):
            let detail = message.isEmpty ? "暂时不可用" : message
            return "\(resource.label)未成功读取：\(detail)"
        }
    }
}

enum MordeTaskModelSelection {
    static func canSubmit(modelID: String, resourceState: MordeResourceLoadState,
                          allowedModelIDs: Set<String>) -> Bool {
        resourceState.isLoaded && !modelID.isEmpty && allowedModelIDs.contains(modelID)
    }
}

enum MordeConversationTaskState {
    static func belongs(taskConversationID: String?, toSelectedConversationID: String?) -> Bool {
        guard let taskConversationID, let toSelectedConversationID else { return false }
        return taskConversationID == toSelectedConversationID
    }
}

struct MordeClientDataScope: Codable, Equatable, Hashable {
    let serviceOrigin: String
    let serviceInstanceID: String
    let accountID: String
    let installationID: String

    init?(serviceOrigin: String, serviceInstanceID: String, accountID: String, installationID: String) {
        guard let origin = MordeLoginStateStore.serviceOrigin(serviceOrigin),
              let instanceID = UUID(uuidString: serviceInstanceID),
              !accountID.isEmpty, !installationID.isEmpty else { return nil }
        self.serviceOrigin = origin
        self.serviceInstanceID = instanceID.uuidString.lowercased()
        self.accountID = accountID
        self.installationID = installationID
    }

    var storageKey: String { Self.digest([serviceOrigin, serviceInstanceID, accountID, installationID]) }

    static func installationLookupKey(origin: String, serviceInstanceID: String, accountName: String) -> String? {
        guard let canonicalOrigin = MordeLoginStateStore.serviceOrigin(origin),
              let instanceID = UUID(uuidString: serviceInstanceID), !accountName.isEmpty else { return nil }
        return digest([canonicalOrigin, instanceID.uuidString.lowercased(), accountName])
    }

    private static func digest(_ parts: [String]) -> String {
        SHA256.hash(data: Data(parts.joined(separator: "\u{0}").utf8))
            .map { String(format: "%02x", $0) }.joined()
    }
}

enum MordeUnauthorizedResponsePolicy {
    static func shouldClearAuthorization(requestCredential: String, currentCredential: String?,
                                         requestScope: MordeClientDataScope,
                                         currentScope: MordeClientDataScope?,
                                         hasPendingLoginIntent: Bool, isCancelled: Bool) -> Bool {
        !isCancelled && !hasPendingLoginIntent && requestCredential == currentCredential &&
            requestScope == currentScope
    }
}

struct MordeScopedRecentConversation: Codable, Equatable {
    let scope: MordeClientDataScope
    let conversationID: String?

    func matches(scope: MordeClientDataScope) -> Bool { self.scope == scope }
}

struct MordeLoginAttemptTicket: Equatable {
    let intentID: UUID
    let origin: String
    let serviceInstanceID: String
    let accountName: String
    let clientInstanceID: UUID
    let attemptGeneration: Int64
    let idempotencyKey: String
    fileprivate let intentScopeKey: String
    fileprivate let identityScopeKey: String
}

private struct MordeLoginClientIdentity: Codable {
    let origin: String
    let serviceInstanceID: String
    let accountName: String
    var clientInstanceID: UUID
    var attemptGeneration: Int64
    var retiredInstanceIDs: [UUID]
}

private struct MordeActiveLoginAttempt: Codable, Equatable {
    let intentID: UUID
    let intentScopeKey: String
    let identityScopeKey: String
    let serviceInstanceID: String
    let clientInstanceID: UUID
    let attemptGeneration: Int64
}

private struct MordeLoginStateSnapshot: Codable {
    var identities: [String: MordeLoginClientIdentity] = [:]
    var latestIntents: [String: MordeLoginIntentRecord] = [:]
    var activeAttempts: [String: MordeActiveLoginAttempt] = [:]
    var retiredInstanceIDs: [UUID] = []
}

private struct MordeLegacyLoginClientIdentity: Codable {
    let clientInstanceID: UUID
    let retiredInstanceIDs: [UUID]?
}

private struct MordeLegacyLoginStateSnapshot: Codable {
    let identities: [String: MordeLegacyLoginClientIdentity]
}

private struct MordeLoginIntentRecord: Codable {
    let id: UUID
    let origin: String
    let accountName: String
}

enum MordeLoginStateStoreError: Error {
    case invalidOrigin
    case invalidServiceInstance
    case emptyAccount
}

final class MordeLoginStateStore {
    static let defaultsKey = "morde.clientLoginState.v2"
    private static let legacyDefaultsKey = "morde.clientLoginState.v1"
    private static let lock = NSLock()
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    static func serviceOrigin(_ server: String) -> String? {
        guard var components = URLComponents(string: server),
              let scheme = components.scheme?.lowercased(),
              let host = components.host?.lowercased(), !host.isEmpty,
              components.user == nil, components.password == nil else { return nil }
        let secure = scheme == "https"
#if DEBUG
        let localHTTP = scheme == "http" && ["localhost", "127.0.0.1", "[::1]"].contains(host)
#else
        let localHTTP = false
#endif
        guard secure || localHTTP else { return nil }
        components.scheme = scheme
        components.host = host
        if (scheme == "https" && components.port == 443) || (scheme == "http" && components.port == 80) {
            components.port = nil
        }
        components.path = ""
        components.query = nil
        components.fragment = nil
        return components.string
    }

    func registerIntent(origin rawOrigin: String, accountName: String) throws -> MordeLoginIntent {
        guard let origin = Self.serviceOrigin(rawOrigin) else { throw MordeLoginStateStoreError.invalidOrigin }
        let accountName = accountName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !accountName.isEmpty else { throw MordeLoginStateStoreError.emptyAccount }
        let intentScopeKey = Self.intentScopeKey(origin: origin, accountName: accountName)
        Self.lock.lock()
        defer { Self.lock.unlock() }
        var snapshot = loadSnapshot()
        let intent = MordeLoginIntent(id: UUID(), origin: origin, accountName: accountName, scopeKey: intentScopeKey)
        snapshot.latestIntents[intentScopeKey] = MordeLoginIntentRecord(id: intent.id, origin: origin, accountName: accountName)
        snapshot.activeAttempts.removeValue(forKey: intentScopeKey)
        try saveSnapshot(snapshot)
        return intent
    }

    func beginAttempt(for intent: MordeLoginIntent, serviceInstanceID rawServiceInstanceID: String) throws -> MordeLoginAttemptTicket? {
        guard let serviceInstanceID = UUID(uuidString: rawServiceInstanceID)?.uuidString.lowercased() else {
            throw MordeLoginStateStoreError.invalidServiceInstance
        }
        Self.lock.lock()
        defer { Self.lock.unlock() }
        var snapshot = loadSnapshot()
        guard snapshot.latestIntents[intent.scopeKey]?.id == intent.id else { return nil }

        let identityScopeKey = Self.identityScopeKey(origin: intent.origin, serviceInstanceID: serviceInstanceID,
                                                     accountName: intent.accountName)
        var identity = snapshot.identities[identityScopeKey]
        if identity?.origin != intent.origin || identity?.serviceInstanceID != serviceInstanceID ||
            identity?.accountName != intent.accountName { identity = nil }
        var nextGeneration: Int64 = 1
        var instanceID: UUID
        if var current = identity {
            if current.attemptGeneration == Int64.max {
                retire(current.clientInstanceID, from: &current)
                retire(current.clientInstanceID, in: &snapshot)
                current.clientInstanceID = newInstanceID(in: snapshot)
                nextGeneration = 1
            } else {
                nextGeneration = current.attemptGeneration + 1
            }
            instanceID = current.clientInstanceID
            current.attemptGeneration = nextGeneration
            identity = current
        } else {
            instanceID = newInstanceID(in: snapshot)
            identity = MordeLoginClientIdentity(origin: intent.origin, serviceInstanceID: serviceInstanceID,
                                                accountName: intent.accountName,
                                                clientInstanceID: instanceID, attemptGeneration: nextGeneration,
                                                retiredInstanceIDs: [])
        }

        guard let identity else { return nil }
        snapshot.identities[identityScopeKey] = identity
        let active = MordeActiveLoginAttempt(intentID: intent.id, intentScopeKey: intent.scopeKey,
                                             identityScopeKey: identityScopeKey, serviceInstanceID: serviceInstanceID,
                                             clientInstanceID: instanceID, attemptGeneration: nextGeneration)
        snapshot.activeAttempts[intent.scopeKey] = active
        try saveSnapshot(snapshot)
        return MordeLoginAttemptTicket(intentID: intent.id, origin: intent.origin,
                                       serviceInstanceID: serviceInstanceID, accountName: intent.accountName,
                                       clientInstanceID: instanceID,
                                       attemptGeneration: nextGeneration, idempotencyKey: UUID().uuidString,
                                       intentScopeKey: intent.scopeKey, identityScopeKey: identityScopeKey)
    }

    func isLatest(_ intent: MordeLoginIntent) -> Bool {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        return loadSnapshot().latestIntents[intent.scopeKey]?.id == intent.id
    }

    func finish(_ intent: MordeLoginIntent) throws -> Bool {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        var snapshot = loadSnapshot()
        guard snapshot.latestIntents[intent.scopeKey]?.id == intent.id else { return false }
        snapshot.latestIntents.removeValue(forKey: intent.scopeKey)
        snapshot.activeAttempts.removeValue(forKey: intent.scopeKey)
        try saveSnapshot(snapshot)
        return true
    }

    func hasPendingIntent(origin rawOrigin: String, accountName: String) -> Bool {
        guard let origin = Self.serviceOrigin(rawOrigin) else { return false }
        let accountName = accountName.trimmingCharacters(in: .whitespacesAndNewlines)
        Self.lock.lock()
        defer { Self.lock.unlock() }
        return loadSnapshot().latestIntents[Self.intentScopeKey(origin: origin, accountName: accountName)] != nil
    }

    func isCurrent(_ ticket: MordeLoginAttemptTicket) -> Bool {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        return isCurrent(ticket, in: loadSnapshot())
    }

    func commitIfCurrent(_ ticket: MordeLoginAttemptTicket, persist: () throws -> Void) throws -> Bool {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        var snapshot = loadSnapshot()
        guard isCurrent(ticket, in: snapshot) else { return false }
        try persist()
        snapshot.latestIntents.removeValue(forKey: ticket.intentScopeKey)
        snapshot.activeAttempts.removeValue(forKey: ticket.intentScopeKey)
        try saveSnapshot(snapshot)
        return true
    }

    func rotateClientInstanceID(origin rawOrigin: String, serviceInstanceID rawServiceInstanceID: String,
                                accountName: String) throws {
        guard let origin = Self.serviceOrigin(rawOrigin) else { throw MordeLoginStateStoreError.invalidOrigin }
        guard let serviceInstanceID = UUID(uuidString: rawServiceInstanceID)?.uuidString.lowercased() else {
            throw MordeLoginStateStoreError.invalidServiceInstance
        }
        let accountName = accountName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !accountName.isEmpty else { throw MordeLoginStateStoreError.emptyAccount }
        let intentScopeKey = Self.intentScopeKey(origin: origin, accountName: accountName)
        let identityScopeKey = Self.identityScopeKey(origin: origin, serviceInstanceID: serviceInstanceID,
                                                     accountName: accountName)
        Self.lock.lock()
        defer { Self.lock.unlock() }
        var snapshot = loadSnapshot()
        var identity = snapshot.identities[identityScopeKey] ?? MordeLoginClientIdentity(
            origin: origin, serviceInstanceID: serviceInstanceID, accountName: accountName,
            clientInstanceID: newInstanceID(in: snapshot),
            attemptGeneration: 0, retiredInstanceIDs: [])
        if identity.origin != origin || identity.serviceInstanceID != serviceInstanceID || identity.accountName != accountName {
            identity = MordeLoginClientIdentity(origin: origin, serviceInstanceID: serviceInstanceID, accountName: accountName,
                                                clientInstanceID: newInstanceID(in: snapshot),
                                                attemptGeneration: 0, retiredInstanceIDs: [])
        }
        retire(identity.clientInstanceID, from: &identity)
        retire(identity.clientInstanceID, in: &snapshot)
        identity.clientInstanceID = newInstanceID(in: snapshot)
        identity.attemptGeneration = 0
        snapshot.identities[identityScopeKey] = identity
        snapshot.latestIntents.removeValue(forKey: intentScopeKey)
        snapshot.activeAttempts.removeValue(forKey: intentScopeKey)
        try saveSnapshot(snapshot)
    }

    func invalidatePendingAttempts(origin rawOrigin: String? = nil, accountName: String? = nil) throws {
        let origin = rawOrigin.flatMap(Self.serviceOrigin)
        Self.lock.lock()
        defer { Self.lock.unlock() }
        var snapshot = loadSnapshot()
        let keys = snapshot.latestIntents.compactMap { key, intent -> String? in
            if rawOrigin != nil && (origin == nil || intent.origin != origin) { return nil }
            if let accountName, intent.accountName != accountName { return nil }
            return key
        }
        for key in keys {
            snapshot.latestIntents.removeValue(forKey: key)
            snapshot.activeAttempts.removeValue(forKey: key)
        }
        try saveSnapshot(snapshot)
    }

    private func isCurrent(_ ticket: MordeLoginAttemptTicket, in snapshot: MordeLoginStateSnapshot) -> Bool {
        let active = MordeActiveLoginAttempt(intentID: ticket.intentID, intentScopeKey: ticket.intentScopeKey,
                                             identityScopeKey: ticket.identityScopeKey,
                                             serviceInstanceID: ticket.serviceInstanceID,
                                             clientInstanceID: ticket.clientInstanceID,
                                             attemptGeneration: ticket.attemptGeneration)
        guard snapshot.latestIntents[ticket.intentScopeKey]?.id == ticket.intentID,
              snapshot.activeAttempts[ticket.intentScopeKey] == active,
              let identity = snapshot.identities[ticket.identityScopeKey] else { return false }
        return identity.origin == ticket.origin && identity.serviceInstanceID == ticket.serviceInstanceID &&
            identity.accountName == ticket.accountName &&
            identity.clientInstanceID == ticket.clientInstanceID && identity.attemptGeneration == ticket.attemptGeneration
    }

    private func loadSnapshot() -> MordeLoginStateSnapshot {
        if let data = defaults.data(forKey: Self.defaultsKey),
           let snapshot = try? JSONDecoder().decode(MordeLoginStateSnapshot.self, from: data) {
            return snapshot
        }
        guard let legacyData = defaults.data(forKey: Self.legacyDefaultsKey),
              let legacy = try? JSONDecoder().decode(MordeLegacyLoginStateSnapshot.self, from: legacyData) else {
            return MordeLoginStateSnapshot()
        }
        let retiredIDs = legacy.identities.values.flatMap { ($0.retiredInstanceIDs ?? []) + [$0.clientInstanceID] }
        return MordeLoginStateSnapshot(retiredInstanceIDs: Array(Set(retiredIDs)))
    }

    private func saveSnapshot(_ snapshot: MordeLoginStateSnapshot) throws {
        defaults.set(try JSONEncoder().encode(snapshot), forKey: Self.defaultsKey)
    }

    private static func intentScopeKey(origin: String, accountName: String) -> String {
        digest([origin, accountName])
    }

    private static func identityScopeKey(origin: String, serviceInstanceID: String, accountName: String) -> String {
        digest([origin, serviceInstanceID, accountName])
    }

    private static func digest(_ parts: [String]) -> String {
        let data = Data(parts.joined(separator: "\u{0}").utf8)
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private func newInstanceID(in snapshot: MordeLoginStateSnapshot) -> UUID {
        let usedIDs = Set(snapshot.retiredInstanceIDs + snapshot.identities.values.flatMap {
            $0.retiredInstanceIDs + [$0.clientInstanceID]
        })
        var candidate = UUID()
        while usedIDs.contains(candidate) { candidate = UUID() }
        return candidate
    }

    private func retire(_ instanceID: UUID, from identity: inout MordeLoginClientIdentity) {
        if !identity.retiredInstanceIDs.contains(instanceID) { identity.retiredInstanceIDs.append(instanceID) }
    }

    private func retire(_ instanceID: UUID, in snapshot: inout MordeLoginStateSnapshot) {
        if !snapshot.retiredInstanceIDs.contains(instanceID) { snapshot.retiredInstanceIDs.append(instanceID) }
    }
}

enum MordeTaskAttempt {
    static func fingerprint(conversationID: String?, hostID: String, workspaceID: String? = nil,
                            modelID: String, objective: String, attachmentIDs: [String] = [],
                            expectedTaskID: String? = nil) -> String {
        var fields = [conversationID ?? "", hostID, workspaceID ?? "", modelID, objective] + attachmentIDs
        if let expectedTaskID { fields.append("queue:\(expectedTaskID)") }
        let input = Data(fields.joined(separator: "\u{0}").utf8)
        return SHA256.hash(data: input).map { String(format: "%02x", $0) }.joined()
    }

    static func canContinuePendingAttempt(_ pendingFingerprint: String?, requestedFingerprint: String) -> Bool {
        pendingFingerprint == nil || pendingFingerprint == requestedFingerprint
    }
}

enum MordeTaskTargetPolicy {
    static func hostIsReady(state: String, controlState: String?) -> Bool {
        state == "running" && controlState == "ai"
    }

    static func canRestoreHost(state: String, isOwner: Bool, workspaceBindingCount: Int,
                               workspaceReady: Bool) -> Bool {
        state == "stopped" && isOwner && workspaceBindingCount == 1 && workspaceReady
    }

    static func workspaceIsReady(bindingState: String, workspaceState: String, syncState: String,
                                 appliedRevision: Int64, desiredRevision: Int64,
                                 workspaceRevision: Int64) -> Bool {
        bindingState == "active" && workspaceState == "ready" && syncState == "healthy" &&
            appliedRevision == desiredRevision && appliedRevision == workspaceRevision
    }

    static func targetIsUnavailable(hostID: String, workspaceID: String, workspaceBindingCount: Int,
                                    hostExists: Bool,
                                    hostReady: Bool, workspaceExists: Bool,
                                    workspaceReady: Bool) -> Bool {
        if !hostID.isEmpty && (workspaceID.isEmpty || workspaceBindingCount != 1 || !hostExists || !hostReady) {
            return true
        }
        if !workspaceID.isEmpty && (hostID.isEmpty || !workspaceExists || !workspaceReady) { return true }
        return false
    }
}

enum MordeTaskTargetPresentation {
    static func hostState(_ state: String) -> String {
        switch state {
        case "creating": return "创建中"
        case "running": return "运行中"
        case "stopping": return "停止中"
        case "stopped": return "已停止"
        case "failed": return "失败"
        case "deleting": return "删除中"
        case "deleted": return "已删除"
        default: return "状态未知"
        }
    }

    static func hostControlState(_ state: String?) -> String {
        switch state {
        case "ai": return "AI 控制"
        case "taking_over": return "正在接管"
        case "user": return "人工控制"
        case "returning": return "正在交还 AI"
        default: return "控制状态待核验"
        }
    }

    static func fixedTarget(executionLocation: String?, hostID: String?, hostName: String?,
                            hostState: String?, workspaceID: String?, workspaceName: String?,
                            inputRevision: Int64?) -> String {
        let runtime: String
        switch executionLocation {
        case "server": runtime = "云端 Agent Runtime"
        case "legacy": runtime = "旧客户端 Runtime"
        default: runtime = "执行位置待核验"
        }
        let computer: String
        if let hostID, !hostID.isEmpty {
            if let hostName {
                computer = "\(hostName)（\(hostState.map(hostStateLabel) ?? "状态未知")）"
            } else {
                computer = "Host \(hostID)（当前不可访问）"
            }
        } else {
            computer = "无电脑目标"
        }
        let workspace: String
        if let workspaceID, !workspaceID.isEmpty {
            let name = workspaceName ?? workspaceID
            workspace = inputRevision.map { "\(name) v\($0)" } ?? name
        } else {
            workspace = "无 Workspace"
        }
        return "\(runtime) · \(computer) · \(workspace)"
    }

    private static func hostStateLabel(_ state: String) -> String { hostState(state) }
}

// nanoMuse: hash action payloads so retries reuse a key without retaining clarification text.
struct MordeActionRetryAttempt: Equatable {
    let fingerprint: String
    let idempotencyKey: String

    init(fingerprint: String, idempotencyKey: String = UUID().uuidString) {
        self.fingerprint = fingerprint
        self.idempotencyKey = idempotencyKey
    }

    func matches(fingerprint: String) -> Bool { self.fingerprint == fingerprint }

    static func reusing(_ current: MordeActionRetryAttempt?, for fingerprint: String) -> MordeActionRetryAttempt {
        guard let current, current.matches(fingerprint: fingerprint) else {
            return MordeActionRetryAttempt(fingerprint: fingerprint)
        }
        return current
    }

    static func fingerprint(taskID: String, endpoint: String, body: [String: Any]) -> String? {
        guard JSONSerialization.isValidJSONObject(body),
              let encodedBody = try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys]) else {
            return nil
        }
        var input = Data(taskID.utf8)
        input.append(0)
        input.append(contentsOf: endpoint.utf8)
        input.append(0)
        input.append(encodedBody)
        return SHA256.hash(data: input).map { String(format: "%02x", $0) }.joined()
    }
}

enum MordeClientVersion {
    private struct Parsed: Equatable {
        let major: Int
        let minor: Int
        let patch: Int
        let prerelease: [String]
    }

    static func meetsMinimum(current: String?, minimum: String?) -> Bool {
        guard let current, let actual = parse(current), let minimum, let required = parse(minimum) else { return false }
        if actual.major != required.major { return actual.major > required.major }
        if actual.minor != required.minor { return actual.minor > required.minor }
        if actual.patch != required.patch { return actual.patch > required.patch }
        if actual.prerelease.isEmpty || required.prerelease.isEmpty { return actual.prerelease.isEmpty }
        for index in 0..<max(actual.prerelease.count, required.prerelease.count) {
            guard index < actual.prerelease.count else { return false }
            guard index < required.prerelease.count else { return true }
            let left = actual.prerelease[index]
            let right = required.prerelease[index]
            if left == right { continue }
            let leftIsNumber = left.utf8.allSatisfy { (48...57).contains($0) }
            let rightIsNumber = right.utf8.allSatisfy { (48...57).contains($0) }
            if leftIsNumber && rightIsNumber {
                if left.count != right.count { return left.count > right.count }
                return left > right
            }
            if leftIsNumber { return false }
            if rightIsNumber { return true }
            return left < right
        }
        return true
    }

    private static func parse(_ raw: String) -> Parsed? {
        let buildParts = raw.split(separator: "+", maxSplits: 1, omittingEmptySubsequences: false)
        guard let version = buildParts.first, buildParts.count <= 2, !version.isEmpty else { return nil }
        if buildParts.count == 2 {
            let buildIdentifiers = buildParts[1].split(separator: ".", omittingEmptySubsequences: false)
            guard !buildIdentifiers.isEmpty, buildIdentifiers.allSatisfy(validIdentifier) else { return nil }
        }
        let versionAndPrerelease = version.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
        guard versionAndPrerelease.count <= 2 else { return nil }
        let core = versionAndPrerelease[0].split(separator: ".", omittingEmptySubsequences: false)
        guard core.count == 3,
              core.allSatisfy({ $0 == "0" || ($0.first != "0" && $0.allSatisfy(\.isNumber)) }),
              let major = Int(core[0]), let minor = Int(core[1]), let patch = Int(core[2]) else { return nil }
        let prerelease: [String]
        if versionAndPrerelease.count == 2 {
            let parts = versionAndPrerelease[1].split(separator: ".", omittingEmptySubsequences: false)
            guard !parts.isEmpty, parts.allSatisfy(validIdentifier),
                  parts.allSatisfy({ !($0.count > 1 && $0.allSatisfy(\.isNumber) && $0.first == "0") }) else { return nil }
            prerelease = parts.map(String.init)
        } else {
            prerelease = []
        }
        return Parsed(major: major, minor: minor, patch: patch, prerelease: prerelease)
    }

    private static func validIdentifier(_ value: Substring) -> Bool {
        !value.isEmpty && value.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") }
    }
}

enum MordeTaskSnapshotCursor {
    /// A snapshot may advance beyond the event that triggered it; resume after the snapshot's
    /// sequence so older events cannot replay stale state over the newer snapshot.
    static func resumeCursor(eventID: String, snapshotSequence: Int64) -> String? {
        guard let observed = Int64(eventID), observed >= 0, snapshotSequence >= observed else { return nil }
        return String(snapshotSequence)
    }
}

struct MordeClientMessage: Decodable, Equatable, Identifiable {
    let id: String
    let conversation_id: String?
    let task_id: String?
    let role: String
    let content: String
    let attachment_ids: [String]?
    let status: String?
    let delivery_status: String?
    let created_at: String?

    init(id: String, conversation_id: String? = nil, task_id: String? = nil,
         role: String, content: String, attachment_ids: [String]? = nil, status: String? = nil, delivery_status: String? = nil,
         created_at: String? = nil) {
        self.id = id
        self.conversation_id = conversation_id
        self.task_id = task_id
        self.role = role
        self.content = content
        self.attachment_ids = attachment_ids
        self.status = status
        self.delivery_status = delivery_status
        self.created_at = created_at
    }
}

enum MordeTaskSnapshotMessageMerge {
    static let statuses: Set<String> = ["streaming", "completed", "interrupted"]

    static func merge(_ messages: [MordeClientMessage], snapshot: MordeClientMessage?,
                      taskID: String, conversationID: String) -> [MordeClientMessage] {
        guard let snapshot,
              snapshot.role == "assistant",
              snapshot.task_id == taskID,
              snapshot.conversation_id == conversationID,
              let status = snapshot.status,
              statuses.contains(status) else { return messages }

        var merged = messages
        if let index = merged.firstIndex(where: { $0.id == snapshot.id }) {
            let existing = merged[index]
            // The conversation endpoint only returns committed messages. If it already has this
            // ID, prefer its content over an older in-flight snapshot read.
            if status == "streaming", existing.status == nil {
                merged[index] = MordeClientMessage(
                    id: existing.id, conversation_id: existing.conversation_id,
                    task_id: existing.task_id, role: existing.role, content: existing.content,
                    attachment_ids: existing.attachment_ids,
                    status: "completed", delivery_status: existing.delivery_status,
                    created_at: existing.created_at)
            } else {
                merged[index] = MordeClientMessage(
                    id: snapshot.id, conversation_id: snapshot.conversation_id ?? existing.conversation_id,
                    task_id: snapshot.task_id ?? existing.task_id, role: snapshot.role, content: snapshot.content,
                    attachment_ids: snapshot.attachment_ids ?? existing.attachment_ids,
                    status: snapshot.status, delivery_status: snapshot.delivery_status ?? existing.delivery_status,
                    created_at: snapshot.created_at ?? existing.created_at)
            }
        } else {
            merged.append(snapshot)
        }
        return merged
    }
}

enum MordeTaskStatusPresentation {
    // nanoMuse: Keep the localized string lookup keys beside the wire status mapping.
    static func localizationKey(status: String, waitingReason: String? = nil,
                                stopRequestStatus: String? = nil) -> String {
        switch label(status: status, waitingReason: waitingReason, stopRequestStatus: stopRequestStatus) {
        case "排队中": return "Queued"
        case "运行中": return "Running"
        case "等待你审批": return "Waiting for approval"
        case "等待你补充信息": return "Waiting for your input"
        case "等待电脑同步": return "Waiting for computer sync"
        case "工作区已变化，等待确认": return "Workspace changed; awaiting confirmation"
        case "电脑焦点已变化，等待确认": return "Computer focus changed; awaiting confirmation"
        case "操作结果待核对": return "Operation result needs review"
        case "当前操作不受支持，等待处理": return "Operation not supported; action needed"
        case "连接器已撤销，等待处理": return "Connector revoked; action needed"
        case "电脑状态已变化，等待处理": return "Computer state changed; action needed"
        case "等待任务额度处理": return "Waiting for task quota"
        case "等待你处理": return "Waiting for you"
        case "正在暂停": return "Pausing"
        case "已暂停": return "Paused"
        case "正在停止，等待服务端确认": return "Stopping; awaiting server confirmation"
        case "停止请求已处理，等待任务状态更新": return "Stop request processed; task update pending"
        case "停止状态待确认": return "Stop status needs confirmation"
        case "已完成": return "Completed"
        case "失败": return "Task failed"
        case "已取消": return "Cancelled"
        default: return "Status unknown"
        }
    }

    static func notificationLocalizationKey(kind: String) -> String {
        switch kind {
        case "completed": return "Task completed"
        case "failed": return "Task failed"
        case "waiting_user": return "Action needed"
        default: return "Task notification"
        }
    }

    static func label(status: String, waitingReason: String? = nil, stopRequestStatus: String? = nil) -> String {
        switch status {
        case "queued": return "排队中"
        case "running": return "运行中"
        case "waiting_user":
            if waitingReason == "approval_required" { return "等待你审批" }
            if waitingReason == "clarification_required" { return "等待你补充信息" }
            switch waitingReason {
            case "workspace_host_sync": return "等待电脑同步"
            case "workspace_input_changed": return "工作区已变化，等待确认"
            case "desktop_focus_changed": return "电脑焦点已变化，等待确认"
            case "mcp_result_unknown", "dsh_recovery_unresolved": return "操作结果待核对"
            case "mcp_result_unsupported": return "当前操作不受支持，等待处理"
            case "mcp_connector_revoked": return "连接器已撤销，等待处理"
            case "host_fence_changed": return "电脑状态已变化，等待处理"
            case "tool_call_budget": return "等待任务额度处理"
            default: break
            }
            if waitingReason?.localizedCaseInsensitiveContains("unknown") == true { return "操作结果待核对" }
            return "等待你处理"
        case "pausing": return "正在暂停"
        case "paused": return "已暂停"
        case "cancelling":
            if stopRequestStatus == "pending" { return "正在停止，等待服务端确认" }
            if stopRequestStatus == "completed" { return "停止请求已处理，等待任务状态更新" }
            return "停止状态待确认"
        case "completed": return "已完成"
        case "failed": return "失败"
        case "cancelled": return "已取消"
        default: return "状态未知"
        }
    }

    static func notificationLabel(kind: String) -> String {
        switch kind {
        case "completed": return "任务完成"
        case "failed": return "任务失败"
        case "waiting_user": return "需要你处理"
        default: return "任务通知"
        }
    }
}

struct MordeRetryAttempt: Codable, Equatable {
    let scope: MordeClientDataScope
    let fingerprint: String
    let key: String
    let inputRevision: Int64?
    let expectedTaskID: String?

    init(scope: MordeClientDataScope, fingerprint: String, key: String, inputRevision: Int64? = nil,
         expectedTaskID: String? = nil) {
        self.scope = scope
        self.fingerprint = fingerprint
        self.key = key
        self.inputRevision = inputRevision
        self.expectedTaskID = expectedTaskID
    }

    func matches(scope: MordeClientDataScope, fingerprint: String) -> Bool {
        self.scope == scope && self.fingerprint == fingerprint
    }

    static func decodePersisted(from defaults: UserDefaults, scope: MordeClientDataScope) -> MordeRetryAttempt? {
        guard let data = defaults.data(forKey: "morde.pendingSendAttempt.\(scope.storageKey)"),
              let attempt = try? JSONDecoder().decode(MordeRetryAttempt.self, from: data),
              attempt.scope == scope else { return nil }
        return attempt
    }
}

struct MordeRevocationRecord: Codable, Equatable {
    let scope: MordeClientDataScope
    let clientInstanceID: UUID?
    let confirmed: Bool
}

private struct MordeRevocationSnapshot: Codable {
    var records: [String: MordeRevocationRecord] = [:]
}

final class MordeRevocationStore {
    static let defaultsKey = "morde.pendingRevocations.v1"
    private static let lock = NSLock()
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func record(_ revocation: MordeRevocationRecord) throws {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        var snapshot = loadSnapshot()
        snapshot.records[revocation.scope.storageKey] = revocation
        defaults.set(try JSONEncoder().encode(snapshot), forKey: Self.defaultsKey)
    }

    func pending() -> [MordeRevocationRecord] {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        return loadSnapshot().records.values.filter { !$0.confirmed }
    }

    private func loadSnapshot() -> MordeRevocationSnapshot {
        guard let data = defaults.data(forKey: Self.defaultsKey),
              let snapshot = try? JSONDecoder().decode(MordeRevocationSnapshot.self, from: data) else {
            return MordeRevocationSnapshot()
        }
        return snapshot
    }
}

enum MordeCredentialExpiryStatus: Equatable {
    case expired
    case expiringSoon
    case valid
}

enum MordeCredentialExpiry {
    static func parse(_ raw: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: raw) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: raw)
    }

    static func status(expiresAt raw: String, now: Date = Date()) -> MordeCredentialExpiryStatus? {
        guard let expiry = parse(raw) else { return nil }
        if expiry <= now { return .expired }
        if expiry <= now.addingTimeInterval(7 * 24 * 60 * 60) { return .expiringSoon }
        return .valid
    }

    static func validCredential(_ credential: String?, expiresAt: String?, now: Date = Date()) -> String? {
        guard let credential, !credential.isEmpty, let expiresAt,
              let status = status(expiresAt: expiresAt, now: now), status != .expired else { return nil }
        return credential
    }

    static func secondsUntilExpiry(expiresAt raw: String?, now: Date = Date()) -> TimeInterval? {
        guard let raw, let expiry = parse(raw) else { return nil }
        return max(0, expiry.timeIntervalSince(now))
    }
}
