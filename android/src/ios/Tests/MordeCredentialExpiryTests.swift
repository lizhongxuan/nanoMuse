import Foundation

private func fixtureObject(_ value: Any?, label: String) -> [String: Any] {
    guard let object = value as? [String: Any] else { fatalError("Missing fixture object: \(label)") }
    return object
}

private func fixtureString(_ value: Any?, label: String) -> String {
    guard let string = value as? String else { fatalError("Missing fixture string: \(label)") }
    return string
}

private func fixtureInt(_ value: Any?, label: String) -> Int {
    guard let integer = value as? Int else { fatalError("Missing fixture integer: \(label)") }
    return integer
}

private func parseSSEFixture(_ raw: String) -> (id: String, event: String, data: [String: Any]) {
    var id: String?
    var event: String?
    var payload: [String: Any]?
    for line in raw.components(separatedBy: .newlines) where !line.isEmpty {
        if line.hasPrefix("id:") {
            id = line.dropFirst(3).trimmingCharacters(in: .whitespaces)
        } else if line.hasPrefix("event:") {
            event = line.dropFirst(6).trimmingCharacters(in: .whitespaces)
        } else if line.hasPrefix("data:") {
            let json = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
            guard let data = json.data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                fatalError("Invalid SSE fixture data")
            }
            payload = object
        }
    }
    guard let id, let event, let payload else { fatalError("Incomplete SSE fixture frame") }
    return (id, event, payload)
}

@main
enum MordeCredentialExpiryTests {
    static func main() {
        let registration = MordeRegistrationPayload.make(name: "  alice  ", password: "password123")
        precondition(registration?.jsonObject == ["name": "alice", "password": "password123"])
        precondition(MordeRegistrationPayload.make(name: "  ", password: "password123") == nil)
        precondition(MordeRegistrationPayload.make(name: "alice", password: "") == nil)
        precondition(MordeLoginStateStore.serviceOrigin("https://MORDE.example:443") == "https://morde.example")
#if DEBUG
        precondition(MordeLoginStateStore.serviceOrigin("http://localhost:7080") == "http://localhost:7080")
        precondition(MordeLoginStateStore.serviceOrigin("http://127.0.0.1:7080") == "http://127.0.0.1:7080")
        precondition(MordeLoginStateStore.serviceOrigin("http://[::1]:7080") == "http://[::1]:7080")
        precondition(MordeLoginStateStore.serviceOrigin("http://localhost.example:7080") == nil)
#else
        precondition(MordeLoginStateStore.serviceOrigin("http://localhost:7080") == nil)
#endif
        precondition(!MordeFirstRunPolicy.isNeeded(
            signedIn: false, hasProviders: false, hasSessions: false, done: false, mordeSignedIn: true))
        precondition(MordeFirstRunPolicy.isNeeded(
            signedIn: false, hasProviders: false, hasSessions: false, done: false, mordeSignedIn: false))
        precondition(MordeFirstRunPolicy.isNeeded(
            signedIn: true, hasProviders: false, hasSessions: false, done: false, mordeSignedIn: false))
        precondition(!MordeFirstRunPolicy.isNeeded(
            signedIn: true, hasProviders: false, hasSessions: true, done: false, mordeSignedIn: false))
        precondition(!MordeFirstRunPolicy.isNeeded(
            signedIn: true, hasProviders: false, hasSessions: false, done: true, mordeSignedIn: false))
        precondition(!MordeFirstRunPolicy.isNeeded(
            signedIn: false, hasProviders: true, hasSessions: true, done: false, mordeSignedIn: false))
        precondition(!MordeLocalExecutionPolicy.isEnabled)
        precondition(!MordeLocalExecutionPolicy.disabledMessage.isEmpty)
        precondition(MordeLocalExecutionDisabledError().errorDescription == MordeLocalExecutionPolicy.disabledMessage)
        do {
            try MordeLocalExecutionPolicy.requireEnabled()
            preconditionFailure("local execution must stay disabled")
        } catch is MordeLocalExecutionDisabledError {
        } catch {
            preconditionFailure("unexpected local execution error: \(error)")
        }
        precondition(!MordeCloudKitSyncPolicy.isEnabled)
        precondition(!MordeCloudKitSyncPolicy.disabledMessage.isEmpty)
        precondition(MordeCloudKitSyncDisabledError().errorDescription == MordeCloudKitSyncPolicy.disabledMessage)
        precondition(!MordeCloudKitSyncPolicy.shouldRemoveLegacyCache(userSyncEnabled: true))
        precondition(!MordeCloudKitSyncPolicy.shouldRemoveLegacyCache(userSyncEnabled: false))
        precondition(!MordeLegacyServicePolicy.isEnabled)
        precondition(MordeLegacyServiceDisabledError().errorDescription == MordeLegacyServicePolicy.disabledMessage)
        precondition(MordeAPIKeyDeletionOutcome(legacyStatus: 0, synchronizableStatus: 0).isComplete)
        precondition(MordeAPIKeyDeletionOutcome(legacyStatus: -25_300, synchronizableStatus: -25_300).isComplete)
        precondition(MordeAPIKeyDeletionOutcome(legacyStatus: 0, synchronizableStatus: -25_300).isComplete)
        let partialAPIKeyDeletion = MordeAPIKeyDeletionOutcome(legacyStatus: 0, synchronizableStatus: -50)
        precondition(!partialAPIKeyDeletion.isComplete)
        precondition(partialAPIKeyDeletion.failedStatuses == [-50])

        let providerCleanupRows = [
            MordeProviderKeyCleanupDescriptor(instanceID: "openai-1", providerType: "openAI", credentialType: "apiKey"),
            MordeProviderKeyCleanupDescriptor(instanceID: "cloud-relay-1", providerType: "openAI", credentialType: "apiKey"),
            MordeProviderKeyCleanupDescriptor(instanceID: "oauth-1", providerType: "anthropic", credentialType: "oauth"),
            MordeProviderKeyCleanupDescriptor(instanceID: "unknown-1", providerType: "futureProvider", credentialType: "apiKey"),
            MordeProviderKeyCleanupDescriptor(instanceID: " ", providerType: "gemini", credentialType: "apiKey"),
        ]
        precondition(MordeProviderKeyCleanupPlan.candidateInstanceIDs(from: providerCleanupRows) == ["cloud-relay-1", "openai-1"])
        precondition(MordeProviderKeyCleanupPlan.reviewRequiredInstanceIDs(from: providerCleanupRows) == ["unknown-1"])
        precondition(MordeProviderKeyCleanupPlan.shouldShowNotice(storedValue: nil, cleanupComplete: true))
        precondition(MordeProviderKeyCleanupPlan.shouldShowNotice(storedValue: true, cleanupComplete: false))
        precondition(!MordeProviderKeyCleanupPlan.shouldShowNotice(storedValue: false, cleanupComplete: true))
        precondition(!MordeProviderKeyCleanupPlan.shouldShowNotice(storedValue: nil, cleanupComplete: false))
        let syntheticService = "io.github.nanomuse.app.provider.synthetic"
        var syntheticKeychain: [[String: Any]] = [
            ["class": "generic-password", "service": syntheticService, "account": "api-key", "synchronizable": false, "value": "synthetic-legacy-key"],
            ["class": "generic-password", "service": syntheticService, "account": "api-key", "synchronizable": true, "value": "synthetic-synced-key"],
            ["class": "generic-password", "service": syntheticService, "account": "oauth-token", "synchronizable": false, "value": "synthetic-oauth-token"],
            ["class": "generic-password", "service": "another.provider", "account": "api-key", "synchronizable": true, "value": "synthetic-other-key"],
        ]
        var deletionQueries: [[String: Any]] = []
        func syntheticMatch(_ item: [String: Any], query: [String: Any]) -> Bool {
            query.allSatisfy { key, expected in
                if let bool = expected as? Bool { return item[key] as? Bool == bool }
                if let string = expected as? String { return item[key] as? String == string }
                return false
            }
        }
        let syntheticOutcome = MordeProviderKeyCleanupPlan.deleteVariants(
            baseQuery: ["class": "generic-password", "service": syntheticService, "account": "api-key"],
            synchronizableAttribute: "synchronizable"
        ) { query in
            deletionQueries.append(query)
            let found = syntheticKeychain.contains { syntheticMatch($0, query: query) }
            syntheticKeychain.removeAll { syntheticMatch($0, query: query) }
            return found ? MordeAPIKeyDeletionOutcome.successStatus : MordeAPIKeyDeletionOutcome.itemNotFoundStatus
        }
        precondition(syntheticOutcome.isComplete)
        precondition(deletionQueries.count == 2)
        precondition(deletionQueries[0]["synchronizable"] as? Bool == false)
        precondition(deletionQueries[1]["synchronizable"] as? Bool == true)
        precondition(syntheticKeychain.count == 2)
        precondition(syntheticKeychain.contains { $0["account"] as? String == "oauth-token" })
        precondition(syntheticKeychain.contains { $0["service"] as? String == "another.provider" })
        var partialDeleteStatuses: [Int32] = [MordeAPIKeyDeletionOutcome.successStatus, -50]
        let partialDelete = MordeProviderKeyCleanupPlan.deleteVariants(
            baseQuery: [:],
            synchronizableAttribute: "synchronizable"
        ) { _ in partialDeleteStatuses.removeFirst() }
        precondition(!partialDelete.isComplete && partialDelete.failedStatuses == [-50])
        let priorCleanup = MordeProviderKeyCleanupLedger(
            version: MordeProviderKeyCleanupPlan.version,
            status: .pending,
            pendingInstanceIDs: ["cloud-relay-1", "retry-1"],
            pendingLegacyServices: [MordeProviderKeyCleanupPlan.legacyKeychainServices[0]],
            reviewRequiredInstanceIDs: []
        )
        let pendingCleanup = MordeProviderKeyCleanupPlan.begin(
            previous: priorCleanup,
            candidateInstanceIDs: MordeProviderKeyCleanupPlan.candidateInstanceIDs(from: providerCleanupRows),
            reviewRequiredInstanceIDs: MordeProviderKeyCleanupPlan.reviewRequiredInstanceIDs(from: providerCleanupRows),
            preservedInstanceIDs: ["cloud-relay-1"]
        )
        precondition(pendingCleanup.status == .pending)
        precondition(pendingCleanup.pendingInstanceIDs == ["openai-1", "retry-1"])
        precondition(!pendingCleanup.pendingInstanceIDs.contains("cloud-relay-1"), "a Cloud relay key in a pending ledger must not be deleted")
        precondition(pendingCleanup.pendingInstanceIDs.contains("openai-1"), "ordinary OpenAI API keys remain in the cleanup plan")
        precondition(pendingCleanup.pendingLegacyServices == MordeProviderKeyCleanupPlan.legacyKeychainServices)
        precondition(pendingCleanup.reviewRequiredInstanceIDs == ["unknown-1"])
        let failedCleanup = MordeProviderKeyCleanupPlan.finish(
            pendingCleanup,
            failedInstanceIDs: ["retry-1"],
            failedLegacyServices: [MordeProviderKeyCleanupPlan.legacyKeychainServices[0]]
        )
        precondition(failedCleanup.status == .pending)
        precondition(failedCleanup.pendingInstanceIDs == ["retry-1"])
        precondition(failedCleanup.pendingLegacyServices == [MordeProviderKeyCleanupPlan.legacyKeychainServices[0]])
        let completedCleanup = MordeProviderKeyCleanupPlan.finish(failedCleanup, failedInstanceIDs: [], failedLegacyServices: [])
        precondition(completedCleanup.status == .complete)
        precondition(completedCleanup.pendingInstanceIDs.isEmpty && completedCleanup.pendingLegacyServices.isEmpty)
        precondition(completedCleanup.reviewRequiredInstanceIDs == ["unknown-1"])
        let cleanupLedgerData = try! JSONEncoder().encode(completedCleanup)
        precondition(try! JSONDecoder().decode(MordeProviderKeyCleanupLedger.self, from: cleanupLedgerData) == completedCleanup)
        precondition(MordeBackupAPIKeyRestorePolicy.disposition(hasAPIKey: true) == .removedByMigration)
        precondition(MordeBackupAPIKeyRestorePolicy.disposition(hasAPIKey: false) == .absent)
        let syntheticBackupSecrets = Data(#"{"futureTopLevel":"ignored","providers":[{"instanceId":"synthetic","apiKey":"synthetic-key","futureCredential":"ignored"}],"envVars":[{"name":"SYNTHETIC","value":"eA==","futureEnv":"ignored"}]}"#.utf8)
        precondition(MordeBackupAPIKeyRestorePolicy.unknownFieldCount(in: syntheticBackupSecrets) == 3)

        let now = Date(timeIntervalSince1970: 1_793_548_800)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let nowString = formatter.string(from: now)
        let soonString = formatter.string(from: now.addingTimeInterval(7 * 24 * 60 * 60))
        let futureString = formatter.string(from: now.addingTimeInterval(7 * 24 * 60 * 60 + 1))

        precondition(MordeCredentialExpiry.status(expiresAt: nowString, now: now) == .expired)
        precondition(MordeCredentialExpiry.status(expiresAt: soonString, now: now) == .expiringSoon)
        precondition(MordeCredentialExpiry.status(expiresAt: futureString, now: now) == .valid)
        precondition(MordeCredentialExpiry.secondsUntilExpiry(expiresAt: nowString, now: now) == 0)
        precondition(MordeCredentialExpiry.secondsUntilExpiry(expiresAt: futureString, now: now) == 7 * 24 * 60 * 60 + 1)
        precondition(MordeCredentialExpiry.secondsUntilExpiry(expiresAt: nil, now: now) == nil)
        precondition(MordeCredentialExpiry.validCredential("secret", expiresAt: nowString, now: now) == nil)
        precondition(MordeCredentialExpiry.validCredential("secret", expiresAt: nil, now: now) == nil)
        precondition(MordeCredentialExpiry.validCredential(nil, expiresAt: futureString, now: now) == nil)
        precondition(MordeCredentialExpiry.validCredential("secret", expiresAt: futureString, now: now) == "secret")
        precondition(MordeCredentialExpiry.status(expiresAt: "invalid", now: now) == nil)
        precondition(MordeTaskStatusPresentation.label(status: "queued") == "排队中")
        precondition(MordeTaskStatusPresentation.label(status: "running") == "运行中")
        precondition(MordeTaskStatusPresentation.label(status: "waiting_user", waitingReason: "approval_required") == "等待你审批")
        precondition(MordeTaskStatusPresentation.label(status: "waiting_user", waitingReason: "clarification_required") == "等待你补充信息")
        precondition(MordeTaskStatusPresentation.label(status: "waiting_user", waitingReason: "mcp_result_unknown") == "操作结果待核对")
        precondition(MordeTaskStatusPresentation.label(status: "waiting_user", waitingReason: "workspace_host_sync") == "等待电脑同步")
        precondition(MordeTaskStatusPresentation.label(status: "waiting_user", waitingReason: "workspace_input_changed") == "工作区已变化，等待确认")
        precondition(MordeTaskStatusPresentation.label(status: "waiting_user", waitingReason: "desktop_focus_changed") == "电脑焦点已变化，等待确认")
        precondition(MordeTaskStatusPresentation.label(status: "waiting_user", waitingReason: "mcp_result_unsupported") == "当前操作不受支持，等待处理")
        precondition(MordeTaskStatusPresentation.label(status: "waiting_user", waitingReason: "mcp_connector_revoked") == "连接器已撤销，等待处理")
        precondition(MordeTaskStatusPresentation.label(status: "waiting_user", waitingReason: "host_fence_changed") == "电脑状态已变化，等待处理")
        precondition(MordeTaskStatusPresentation.label(status: "waiting_user", waitingReason: "tool_call_budget") == "等待任务额度处理")
        precondition(MordeTaskStatusPresentation.label(status: "waiting_user", waitingReason: "future_reason") == "等待你处理")
        precondition(MordeTaskStatusPresentation.label(status: "pausing") == "正在暂停")
        precondition(MordeTaskStatusPresentation.label(status: "paused") == "已暂停")
        precondition(MordeTaskStatusPresentation.label(status: "cancelling", stopRequestStatus: "pending") == "正在停止，等待服务端确认")
        precondition(MordeTaskStatusPresentation.label(status: "cancelling", stopRequestStatus: "completed") == "停止请求已处理，等待任务状态更新")
        precondition(MordeTaskStatusPresentation.label(status: "cancelling") == "停止状态待确认")
        precondition(MordeTaskStatusPresentation.label(status: "completed") == "已完成")
        precondition(MordeTaskStatusPresentation.label(status: "failed") == "失败")
        precondition(MordeTaskStatusPresentation.label(status: "cancelled") == "已取消")
        precondition(MordeTaskStatusPresentation.label(status: "future_status") == "状态未知")
        let statusLocalizationCases: [(String, String?, String?, String)] = [
            ("queued", nil, nil, "Queued"),
            ("running", nil, nil, "Running"),
            ("waiting_user", "approval_required", nil, "Waiting for approval"),
            ("waiting_user", "clarification_required", nil, "Waiting for your input"),
            ("waiting_user", "workspace_host_sync", nil, "Waiting for computer sync"),
            ("waiting_user", "workspace_input_changed", nil, "Workspace changed; awaiting confirmation"),
            ("waiting_user", "desktop_focus_changed", nil, "Computer focus changed; awaiting confirmation"),
            ("waiting_user", "mcp_result_unknown", nil, "Operation result needs review"),
            ("waiting_user", "mcp_result_unsupported", nil, "Operation not supported; action needed"),
            ("waiting_user", "mcp_connector_revoked", nil, "Connector revoked; action needed"),
            ("waiting_user", "host_fence_changed", nil, "Computer state changed; action needed"),
            ("waiting_user", "tool_call_budget", nil, "Waiting for task quota"),
            ("waiting_user", "future_reason", nil, "Waiting for you"),
            ("pausing", nil, nil, "Pausing"),
            ("paused", nil, nil, "Paused"),
            ("cancelling", nil, "pending", "Stopping; awaiting server confirmation"),
            ("cancelling", nil, "completed", "Stop request processed; task update pending"),
            ("cancelling", nil, nil, "Stop status needs confirmation"),
            ("completed", nil, nil, "Completed"),
            ("failed", nil, nil, "Task failed"),
            ("cancelled", nil, nil, "Cancelled"),
            ("future_status", nil, nil, "Status unknown"),
        ]
        for (status, reason, stop, key) in statusLocalizationCases {
            precondition(MordeTaskStatusPresentation.localizationKey(
                status: status, waitingReason: reason, stopRequestStatus: stop) == key)
        }
        precondition(MordeTaskStatusPresentation.notificationLabel(kind: "completed") == "任务完成")
        precondition(MordeTaskStatusPresentation.notificationLabel(kind: "failed") == "任务失败")
        precondition(MordeTaskStatusPresentation.notificationLabel(kind: "waiting_user") == "需要你处理")
        precondition(MordeTaskStatusPresentation.notificationLabel(kind: "future_kind") == "任务通知")
        precondition(MordeTaskStatusPresentation.notificationLocalizationKey(kind: "completed") == "Task completed")
        precondition(MordeTaskStatusPresentation.notificationLocalizationKey(kind: "waiting_user") == "Action needed")
        precondition(MordeTaskStatusPresentation.notificationLocalizationKey(kind: "future_kind") == "Task notification")
        precondition(!MordeLoginContract.supportsOrderedClientLogin(["password_login", "client_installations"]))
        precondition(MordeLoginContract.supportsOrderedClientLogin(["password_login", "client_installations", "ordered_client_login"]))
        precondition(MordeAccountLoginFailure.fromAPIErrorCode("account_pending") == .pending)
        precondition(MordeAccountLoginFailure.fromAPIErrorCode("account_rejected") == .rejected)
        precondition(MordeAccountLoginFailure.fromAPIErrorCode("account_disabled") == .disabled)
        precondition(MordeAccountLoginFailure.fromAPIErrorCode("unauthenticated") == nil)
        precondition(MordeClientInstallationPolicy.isValidID("i1234567"))
        precondition(!MordeClientInstallationPolicy.isValidID("../api/me"))
        precondition(MordeClientInstallationPolicy.canRevoke("i7654321", currentInstallationID: "i1234567"))
        precondition(!MordeClientInstallationPolicy.canRevoke("i1234567", currentInstallationID: "i1234567"))
        precondition(!MordeClientInstallationPolicy.canRevoke("i7654321", currentInstallationID: nil))
        precondition(MordeClientInstallationPolicy.revokePath(
            for: "i7654321", currentInstallationID: "i1234567") == "/api/clients/i7654321")
        precondition(MordeClientInstallationPolicy.revokePath(
            for: "../api/me", currentInstallationID: "i1234567") == nil)
        let networkCapabilityFailure = MordeCapabilitiesFailure.classify(domain: NSURLErrorDomain,
                                                                           code: URLError.notConnectedToInternet.rawValue)
        precondition(networkCapabilityFailure == .network)
        precondition(networkCapabilityFailure.message(underlying: "offline").contains("无法连接 Morde 服务"))
        precondition(!networkCapabilityFailure.message().contains("版本不兼容"))
        let forbiddenCapabilityFailure = MordeCapabilitiesFailure.classify(domain: "Morde", code: 403)
        precondition(forbiddenCapabilityFailure == .http(statusCode: 403))
        precondition(forbiddenCapabilityFailure.message(underlying: "forbidden").contains("HTTP 403"))
        precondition(!forbiddenCapabilityFailure.message().contains("版本不兼容"))
        let missingCapabilitiesFailure = MordeCapabilitiesFailure.classify(domain: "Morde", code: 404)
        precondition(missingCapabilitiesFailure == .http(statusCode: 404))
        precondition(missingCapabilitiesFailure.message().contains("未提供能力接口"))
        precondition(MordeCapabilitiesFailure.classify(domain: NSCocoaErrorDomain, code: 3840) == .invalidResponse)
        precondition(MordeCapabilitiesFailure.incompatible.message().contains("版本不兼容"))
        precondition(MordeCapabilitiesFailure.minimumVersion.message().contains("版本过低"))
        precondition(MordeTaskCapability.cloudWorkerIsAvailable(["cloud_tasks"]))
        precondition(MordeTaskCapability.taskAPIIsAvailable(["cloud_tasks"]))
        precondition(!MordeTaskCapability.cloudWorkerIsAvailable(["task_api"]))
        precondition(MordeTaskCapability.taskAPIIsAvailable(["task_api"]))
        precondition(!MordeTaskCapability.taskAPIIsAvailable([]))
        precondition(MordeTaskCapability.mediaGenerationIsAvailable(["task_media_generation"]))
        precondition(!MordeTaskCapability.mediaGenerationIsAvailable(["task_api"]))
        precondition(MordeResourcePresentation.emptyListMessage(
            resource: .models, state: .loaded, itemCount: 0, emptyMessage: "没有模型。") == "没有模型。")
        let loadingModelsMessage = MordeResourcePresentation.emptyListMessage(
            resource: .models, state: .loading, itemCount: 0, emptyMessage: "没有模型。")
        precondition(loadingModelsMessage?.contains("正在读取") == true)
        precondition(loadingModelsMessage?.contains("没有模型") == false)
        let failedModelsMessage = MordeResourcePresentation.emptyListMessage(
            resource: .models, state: .failed("HTTP 403"), itemCount: 0, emptyMessage: "没有模型。")
        precondition(failedModelsMessage?.contains("未成功读取") == true)
        precondition(failedModelsMessage?.contains("HTTP 403") == true)
        precondition(MordeResourcePresentation.emptyListMessage(
            resource: .models, state: .failed("HTTP 403"), itemCount: 2, emptyMessage: "没有模型。") == nil)
        let approvedModelIDs: Set<String> = ["text-with-tools"]
        precondition(MordeTaskModelSelection.canSubmit(modelID: "text-with-tools", resourceState: .loaded,
                                                       allowedModelIDs: approvedModelIDs))
        precondition(!MordeTaskModelSelection.canSubmit(modelID: "text-with-tools", resourceState: .loading,
                                                        allowedModelIDs: approvedModelIDs))
        precondition(!MordeTaskModelSelection.canSubmit(modelID: "text-with-tools", resourceState: .failed("offline"),
                                                        allowedModelIDs: approvedModelIDs))
        precondition(!MordeTaskModelSelection.canSubmit(modelID: "removed-model", resourceState: .loaded,
                                                        allowedModelIDs: approvedModelIDs))
        precondition(!MordeTaskModelSelection.canSubmit(modelID: "", resourceState: .loaded,
                                                        allowedModelIDs: approvedModelIDs))
        precondition(MordeConversationTaskState.belongs(taskConversationID: "conversation-2",
                                                        toSelectedConversationID: "conversation-2"))
        precondition(!MordeConversationTaskState.belongs(taskConversationID: "conversation-1",
                                                         toSelectedConversationID: "conversation-2"))
        precondition(!MordeConversationTaskState.belongs(taskConversationID: "conversation-1",
                                                        toSelectedConversationID: nil))

        guard let fixturePath = ProcessInfo.processInfo.environment["MORDE_CLIENT_CONTRACT_FIXTURE"] else {
            fatalError("MORDE_CLIENT_CONTRACT_FIXTURE must point to the shared API contract fixture")
        }
        let fixtureData = try! Data(contentsOf: URL(fileURLWithPath: fixturePath))
        let contract = fixtureObject(try! JSONSerialization.jsonObject(with: fixtureData), label: "root")
        let capabilities = fixtureObject(contract["capabilities"], label: "capabilities")
        let queuedTaskAPI = fixtureObject(capabilities["queued_task_api"], label: "queued_task_api")
        let cloudExecution = fixtureObject(capabilities["cloud_execution"], label: "cloud_execution")
        let unsupported = fixtureObject(capabilities["unsupported"], label: "unsupported")
        let unsupportedVersion = fixtureObject(capabilities["unsupported_version"], label: "unsupported_version")
        func supportedFeatures(_ value: [String: Any], label: String) -> [String] {
            guard let features = value["supported_features"] as? [String] else {
                fatalError("Missing fixture feature list: \(label)")
            }
            return features
        }

        let queuedFeatures = supportedFeatures(queuedTaskAPI, label: "queued_task_api")
        precondition(fixtureString(queuedTaskAPI["api_version"], label: "queued_task_api.api_version") == "1")
        precondition(MordeLoginContract.supportsOrderedClientLogin(queuedFeatures))
        precondition(MordeTaskCapability.taskAPIIsAvailable(queuedFeatures))
        precondition(!MordeTaskCapability.cloudWorkerIsAvailable(queuedFeatures))

        let cloudFeatures = supportedFeatures(cloudExecution, label: "cloud_execution")
        precondition(MordeLoginContract.supportsOrderedClientLogin(cloudFeatures))
        precondition(MordeTaskCapability.taskAPIIsAvailable(cloudFeatures))
        precondition(MordeTaskCapability.cloudWorkerIsAvailable(cloudFeatures))

        let unsupportedFeatures = supportedFeatures(unsupported, label: "unsupported")
        precondition(MordeLoginContract.supportsOrderedClientLogin(unsupportedFeatures))
        precondition(!MordeTaskCapability.taskAPIIsAvailable(unsupportedFeatures))
        let unsupportedVersionFeatures = supportedFeatures(unsupportedVersion, label: "unsupported_version")
        precondition(fixtureString(unsupportedVersion["api_version"], label: "unsupported_version.api_version") != "1")
        precondition(MordeLoginContract.supportsOrderedClientLogin(unsupportedVersionFeatures))
        precondition(MordeTaskCapability.taskAPIIsAvailable(unsupportedVersionFeatures))
        let fixtureMinimumVersion = fixtureString(unsupportedVersion["minimum_client_version"],
                                                  label: "unsupported_version.minimum_client_version")
        precondition(!MordeClientVersion.meetsMinimum(current: "1.0.0", minimum: fixtureMinimumVersion))

        guard let errors = contract["errors"] as? [[String: Any]] else { fatalError("Missing fixture errors") }
        let expectedErrorStatuses = [
            "unauthenticated": 401, "forbidden": 403, "not_found": 404,
            "event_cursor_expired": 409, "unsupported": 422,
            "host_not_ready": 503, "upstream_timeout": 504,
        ]
        precondition(errors.count == expectedErrorStatuses.count)
        for error in errors {
            let name = fixtureString(error["name"], label: "error.name")
            let status = fixtureInt(error["status"], label: "error.status")
            precondition(expectedErrorStatuses[name] == status)
            let body = fixtureObject(error["body"], label: "error.body")
            let envelope = fixtureObject(body["error"], label: "error.body.error")
            precondition(fixtureString(envelope["code"], label: "error.body.error.code") == name)
            precondition(!fixtureString(envelope["message"], label: "error.body.error.message").isEmpty)
            precondition(envelope["details"] is [String: Any])
            precondition(MordeCapabilitiesFailure.classify(domain: "Morde", code: status) == .http(statusCode: status))
        }
        let hostNotReady = errors.first { $0["name"] as? String == "host_not_ready" }!
        precondition(fixtureString(hostNotReady["retry_after"], label: "host_not_ready.retry_after") == "5")
        let nonJSONError = fixtureObject(contract["non_json_error"], label: "non_json_error")
        precondition(fixtureInt(nonJSONError["status"], label: "non_json_error.status") == 502)
        precondition(fixtureString(nonJSONError["content_type"], label: "non_json_error.content_type") == "text/html")
        precondition(fixtureString(nonJSONError["body"], label: "non_json_error.body").hasPrefix("<!doctype"))
        precondition(MordeCapabilitiesFailure.classify(domain: "Morde", code: 502) == .http(statusCode: 502))
        let networkError = fixtureObject(contract["network_error"], label: "network_error")
        precondition(fixtureString(networkError["name"], label: "network_error.name") == "TypeError")
        precondition(MordeCapabilitiesFailure.classify(domain: NSURLErrorDomain,
                                                       code: URLError.notConnectedToInternet.rawValue) == .network)

        let taskSnapshot = fixtureObject(contract["task_snapshot"], label: "task_snapshot")
        let snapshotSequence = Int64(fixtureInt(taskSnapshot["event_sequence"], label: "task_snapshot.event_sequence"))
        let frames = fixtureObject(contract["task_event_frames"], label: "task_event_frames")
        let assistantDelta = parseSSEFixture(fixtureString(frames["assistant_delta"], label: "assistant_delta"))
        precondition(assistantDelta.id == "7" && assistantDelta.event == "task.message")
        precondition(fixtureInt(assistantDelta.data["sequence"], label: "assistant_delta.data.sequence") == 7)
        precondition(MordeTaskSnapshotCursor.resumeCursor(eventID: assistantDelta.id,
                                                          snapshotSequence: snapshotSequence) == "8")
        let snapshotRequired = parseSSEFixture(fixtureString(frames["snapshot_required"], label: "snapshot_required"))
        precondition(snapshotRequired.id == "8" && snapshotRequired.event == "task.snapshot_required")
        precondition(fixtureInt(snapshotRequired.data["sequence"], label: "snapshot_required.data.sequence") == 8)
        precondition(snapshotSequence >= Int64(snapshotRequired.id)!)
        precondition(MordeTaskSnapshotCursor.resumeCursor(eventID: snapshotRequired.id,
                                                          snapshotSequence: snapshotSequence) == "8")

        let serviceA = "11111111-1111-4111-8111-111111111111"
        let serviceB = "22222222-2222-4222-8222-222222222222"
        precondition(MordeLoginContract.mayRenewInstallation(
            installationOrigin: "https://morde.example", installationServiceInstanceID: serviceA,
            selectedServer: "https://morde.example:443", selectedServiceInstanceID: serviceA.uppercased(),
            legacyServer: nil, installationAccount: "alice", accountName: "alice"))
        precondition(MordeLoginContract.mayRenewInstallation(
            installationOrigin: nil, installationServiceInstanceID: nil,
            selectedServer: "https://morde.example", selectedServiceInstanceID: serviceA,
            legacyServer: "https://morde.example", installationAccount: "alice", accountName: "alice"))
        precondition(!MordeLoginContract.mayRenewInstallation(
            installationOrigin: "https://other.example", installationServiceInstanceID: serviceA,
            selectedServer: "https://morde.example", selectedServiceInstanceID: serviceA,
            legacyServer: "https://morde.example", installationAccount: "alice", accountName: "alice"))
        precondition(!MordeLoginContract.mayRenewInstallation(
            installationOrigin: "https://morde.example", installationServiceInstanceID: serviceA,
            selectedServer: "https://morde.example", selectedServiceInstanceID: serviceA,
            legacyServer: nil, installationAccount: "alice", accountName: "bob"))
        precondition(!MordeLoginContract.mayRenewInstallation(
            installationOrigin: "https://morde.example", installationServiceInstanceID: serviceB,
            selectedServer: "https://morde.example", selectedServiceInstanceID: serviceA,
            legacyServer: nil, installationAccount: "alice", accountName: "alice"))
        let suiteName = "MordeLoginStateStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let firstStore = MordeLoginStateStore(defaults: defaults)
        let restartedStore = MordeLoginStateStore(defaults: defaults)
        let firstIntent = try! firstStore.registerIntent(origin: "https://MORDE.example:443/", accountName: " alice ")
        let firstAttempt = try! firstStore.beginAttempt(for: firstIntent, serviceInstanceID: serviceA)!
        precondition(firstAttempt.origin == "https://morde.example")
        precondition(firstAttempt.attemptGeneration == 1)

        let secondIntent = try! restartedStore.registerIntent(origin: "https://morde.example", accountName: "alice")
        let secondAttempt = try! restartedStore.beginAttempt(for: secondIntent, serviceInstanceID: serviceA)!
        precondition(secondAttempt.attemptGeneration == 2)
        precondition(secondAttempt.clientInstanceID == firstAttempt.clientInstanceID)
        precondition(secondAttempt.idempotencyKey != firstAttempt.idempotencyKey)

        let persistedState = String(decoding: defaults.data(forKey: MordeLoginStateStore.defaultsKey)!, as: UTF8.self)
        precondition(!persistedState.contains("password"))
        precondition(!persistedState.contains(secondAttempt.idempotencyKey))
        var staleCredentialWasWritten = false
        precondition(try! !firstStore.commitIfCurrent(firstAttempt) { staleCredentialWasWritten = true })
        precondition(!staleCredentialWasWritten)
        var currentCredentialWasWritten = false
        precondition(try! restartedStore.commitIfCurrent(secondAttempt) { currentCredentialWasWritten = true })
        precondition(currentCredentialWasWritten)

        let thirdIntent = try! firstStore.registerIntent(origin: "https://morde.example", accountName: "alice")
        let thirdAttempt = try! firstStore.beginAttempt(for: thirdIntent, serviceInstanceID: serviceA)!
        precondition(thirdAttempt.attemptGeneration == 3)
        precondition(thirdAttempt.clientInstanceID == firstAttempt.clientInstanceID)
        precondition(try! firstStore.commitIfCurrent(thirdAttempt) {})

        let rebuiltInstanceIntent = try! restartedStore.registerIntent(origin: "https://morde.example", accountName: "alice")
        let rebuiltInstanceAttempt = try! restartedStore.beginAttempt(for: rebuiltInstanceIntent,
                                                                       serviceInstanceID: serviceB)!
        precondition(rebuiltInstanceAttempt.attemptGeneration == 1)
        precondition(rebuiltInstanceAttempt.clientInstanceID != thirdAttempt.clientInstanceID)
        precondition(try! restartedStore.commitIfCurrent(rebuiltInstanceAttempt) {})

        let otherServiceIntent = try! restartedStore.registerIntent(origin: "https://other.example", accountName: "alice")
        let otherServiceAttempt = try! restartedStore.beginAttempt(for: otherServiceIntent, serviceInstanceID: serviceA)!
        precondition(otherServiceAttempt.attemptGeneration == 1)
        precondition(otherServiceAttempt.clientInstanceID != thirdAttempt.clientInstanceID)
        precondition(try! restartedStore.commitIfCurrent(otherServiceAttempt) {})

        let otherAccountIntent = try! restartedStore.registerIntent(origin: "https://morde.example", accountName: "bob")
        let otherAccountAttempt = try! restartedStore.beginAttempt(for: otherAccountIntent, serviceInstanceID: serviceA)!
        precondition(otherAccountAttempt.attemptGeneration == 1)
        precondition(otherAccountAttempt.clientInstanceID != thirdAttempt.clientInstanceID)
        precondition(try! restartedStore.commitIfCurrent(otherAccountAttempt) {})

        let supersededIntent = try! firstStore.registerIntent(origin: "https://morde.example", accountName: "alice")
        let latestIntent = try! restartedStore.registerIntent(origin: "https://morde.example", accountName: "alice")
        precondition(try! firstStore.beginAttempt(for: supersededIntent, serviceInstanceID: serviceA) == nil)
        let pendingAtLogout = try! restartedStore.beginAttempt(for: latestIntent, serviceInstanceID: serviceA)!
        try! firstStore.rotateClientInstanceID(origin: "https://morde.example", serviceInstanceID: serviceA, accountName: "alice")
        precondition(!restartedStore.isCurrent(pendingAtLogout))
        let afterLogoutIntent = try! restartedStore.registerIntent(origin: "https://morde.example", accountName: "alice")
        let afterLogoutAttempt = try! restartedStore.beginAttempt(for: afterLogoutIntent, serviceInstanceID: serviceA)!
        precondition(afterLogoutAttempt.attemptGeneration == 1)
        precondition(afterLogoutAttempt.clientInstanceID != firstAttempt.clientInstanceID)
        precondition(afterLogoutAttempt.clientInstanceID != otherAccountAttempt.clientInstanceID)
        try! firstStore.rotateClientInstanceID(origin: "https://morde.example", serviceInstanceID: serviceA, accountName: "alice")
        let secondLogoutIntent = try! restartedStore.registerIntent(origin: "https://morde.example", accountName: "alice")
        let afterSecondLogoutAttempt = try! restartedStore.beginAttempt(for: secondLogoutIntent, serviceInstanceID: serviceA)!
        precondition(afterSecondLogoutAttempt.attemptGeneration == 1)
        precondition(afterSecondLogoutAttempt.clientInstanceID != firstAttempt.clientInstanceID)
        precondition(afterSecondLogoutAttempt.clientInstanceID != afterLogoutAttempt.clientInstanceID)

        let parallelSuite = "MordeLoginStateStoreParallelTests-\(UUID().uuidString)"
        let parallelDefaults = UserDefaults(suiteName: parallelSuite)!
        parallelDefaults.removePersistentDomain(forName: parallelSuite)
        defer { parallelDefaults.removePersistentDomain(forName: parallelSuite) }
        let resultLock = NSLock()
        var parallelGenerations: [Int64] = []
        DispatchQueue.concurrentPerform(iterations: 16) { _ in
            let store = MordeLoginStateStore(defaults: parallelDefaults)
            let intent = try! store.registerIntent(origin: "https://parallel.example", accountName: "alice")
            if let ticket = try! store.beginAttempt(for: intent, serviceInstanceID: serviceA) {
                resultLock.lock()
                parallelGenerations.append(ticket.attemptGeneration)
                resultLock.unlock()
            }
        }
        precondition(!parallelGenerations.isEmpty)
        precondition(Set(parallelGenerations).count == parallelGenerations.count)
        let taskAttempt = MordeTaskAttempt.fingerprint(conversationID: nil, hostID: "host-1", modelID: "model-1", objective: "private prompt")
        precondition(taskAttempt.count == 64)
        precondition(MordeTaskAttempt.canContinuePendingAttempt(nil, requestedFingerprint: taskAttempt))
        precondition(MordeTaskAttempt.canContinuePendingAttempt(taskAttempt, requestedFingerprint: taskAttempt))
        precondition(!MordeTaskAttempt.canContinuePendingAttempt("different", requestedFingerprint: taskAttempt))
        precondition(taskAttempt == MordeTaskAttempt.fingerprint(conversationID: nil, hostID: "host-1", modelID: "model-1", objective: "private prompt"))
        precondition(taskAttempt != MordeTaskAttempt.fingerprint(conversationID: nil, hostID: "host-1", modelID: "model-1", objective: "changed prompt"))
        precondition(taskAttempt != MordeTaskAttempt.fingerprint(conversationID: nil, hostID: "host-1", workspaceID: "workspace-1", modelID: "model-1", objective: "private prompt"))
        precondition(taskAttempt != MordeTaskAttempt.fingerprint(conversationID: nil, hostID: "host-1", modelID: "model-1",
                                                                  objective: "private prompt", expectedTaskID: "q1234567"))
        precondition(MordeTaskTargetPolicy.hostIsReady(state: "running", controlState: "ai"))
        precondition(!MordeTaskTargetPolicy.hostIsReady(state: "running", controlState: "user"))
        precondition(!MordeTaskTargetPolicy.hostIsReady(state: "stopped", controlState: "ai"))
        precondition(!MordeTaskTargetPolicy.hostIsReady(state: "running", controlState: nil))
        precondition(MordeTaskTargetPolicy.workspaceIsReady(bindingState: "active", workspaceState: "ready",
                                                            syncState: "healthy", appliedRevision: 4,
                                                            desiredRevision: 4, workspaceRevision: 4))
        precondition(!MordeTaskTargetPolicy.workspaceIsReady(bindingState: "preparing", workspaceState: "ready",
                                                             syncState: "healthy", appliedRevision: 4,
                                                             desiredRevision: 4, workspaceRevision: 4))
        precondition(!MordeTaskTargetPolicy.workspaceIsReady(bindingState: "active", workspaceState: "archived",
                                                             syncState: "healthy", appliedRevision: 4,
                                                             desiredRevision: 4, workspaceRevision: 4))
        precondition(!MordeTaskTargetPolicy.workspaceIsReady(bindingState: "active", workspaceState: "ready",
                                                             syncState: "conflict", appliedRevision: 4,
                                                             desiredRevision: 4, workspaceRevision: 4))
        precondition(!MordeTaskTargetPolicy.workspaceIsReady(bindingState: "active", workspaceState: "ready",
                                                             syncState: "healthy", appliedRevision: 3,
                                                             desiredRevision: 4, workspaceRevision: 4))
        precondition(!MordeTaskTargetPolicy.workspaceIsReady(bindingState: "active", workspaceState: "ready",
                                                             syncState: "healthy", appliedRevision: 4,
                                                             desiredRevision: 4, workspaceRevision: 5))
        precondition(MordeTaskTargetPolicy.targetIsUnavailable(hostID: "host-1", workspaceID: "", workspaceBindingCount: 0,
                                                              hostExists: false, hostReady: false,
                                                              workspaceExists: false, workspaceReady: false))
        precondition(!MordeTaskTargetPolicy.targetIsUnavailable(hostID: "", workspaceID: "", workspaceBindingCount: 0,
                                                               hostExists: false, hostReady: false,
                                                               workspaceExists: false, workspaceReady: false))
        precondition(MordeTaskTargetPolicy.targetIsUnavailable(hostID: "host-1", workspaceID: "", workspaceBindingCount: 0,
                                                              hostExists: true, hostReady: false,
                                                              workspaceExists: false, workspaceReady: false))
        precondition(MordeTaskTargetPolicy.targetIsUnavailable(hostID: "host-1", workspaceID: "workspace-1", workspaceBindingCount: 1,
                                                              hostExists: true, hostReady: true,
                                                              workspaceExists: false, workspaceReady: false))
        precondition(MordeTaskTargetPolicy.targetIsUnavailable(hostID: "", workspaceID: "workspace-1", workspaceBindingCount: 0,
                                                              hostExists: false, hostReady: false,
                                                              workspaceExists: true, workspaceReady: true))
        precondition(!MordeTaskTargetPolicy.targetIsUnavailable(hostID: "host-1", workspaceID: "workspace-1", workspaceBindingCount: 1,
                                                               hostExists: true, hostReady: true,
                                                               workspaceExists: true, workspaceReady: true))
        precondition(MordeTaskTargetPolicy.targetIsUnavailable(hostID: "host-1", workspaceID: "workspace-1", workspaceBindingCount: 2,
                                                              hostExists: true, hostReady: true,
                                                              workspaceExists: true, workspaceReady: true))
        precondition(MordeTaskTargetPolicy.canRestoreHost(state: "stopped", isOwner: true,
                                                          workspaceBindingCount: 1, workspaceReady: true))
        precondition(!MordeTaskTargetPolicy.canRestoreHost(state: "stopped", isOwner: false,
                                                           workspaceBindingCount: 1, workspaceReady: true))
        precondition(!MordeTaskTargetPolicy.canRestoreHost(state: "stopped", isOwner: true,
                                                           workspaceBindingCount: 2, workspaceReady: true))
        precondition(!MordeTaskTargetPolicy.canRestoreHost(state: "running", isOwner: true,
                                                           workspaceBindingCount: 1, workspaceReady: true))
        precondition(MordeWorkspaceSyncCapability.isAvailable(["workspace_sync"]))
        precondition(!MordeWorkspaceSyncCapability.isAvailable(["hub", "task_api"]))
        precondition(!MordeWorkspaceSyncCapability.isAvailable(["task_api"]))
        precondition(!MordeWorkspaceSyncCapability.isAvailable(nil))
        precondition(MordeConversationSelectionPolicy.shouldFollowMain(currentlySelected: nil,
                                                                       wasFollowingMain: false))
        precondition(MordeConversationSelectionPolicy.shouldFollowMain(currentlySelected: "c1234567",
                                                                       wasFollowingMain: true))
        precondition(!MordeConversationSelectionPolicy.shouldFollowMain(currentlySelected: "c1234567",
                                                                        wasFollowingMain: false))
        let scopeGeneration = UUID()
        precondition(MordeScopedRequestPolicy.isCurrent(scope: "account-a", generation: scopeGeneration,
                                                         activeScope: "account-a", activeGeneration: scopeGeneration))
        precondition(!MordeScopedRequestPolicy.isCurrent(scope: "account-a", generation: scopeGeneration,
                                                          activeScope: "account-b", activeGeneration: scopeGeneration))
        precondition(!MordeScopedRequestPolicy.isCurrent(scope: "account-a", generation: scopeGeneration,
                                                          activeScope: "account-a", activeGeneration: UUID()))
        precondition(MordeHostControlPolicy.canTakeOver(state: "ai", actorID: "", leaseActive: false, transitioning: false))
        precondition(!MordeHostControlPolicy.canTakeOver(state: "ai", actorID: nil, leaseActive: false, transitioning: false))
        precondition(!MordeHostControlPolicy.canTakeOver(state: "ai", actorID: "u1234567", leaseActive: false, transitioning: false))
        precondition(MordeHostControlPolicy.canRelease(state: "user", actorID: "u1234567", currentUserID: "u1234567",
                                                        leaseActive: true, transitioning: false))
        precondition(!MordeHostControlPolicy.canRelease(state: "user", actorID: "u7654321", currentUserID: "u1234567",
                                                         leaseActive: true, transitioning: false))
        precondition(!MordeHostControlPolicy.canRenew(state: "user", actorID: "u1234567", currentUserID: "u1234567",
                                                       leaseActive: false, transitioning: false))
        precondition(MordeProjectPolicy.hasValidID("j1234567"))
        precondition(!MordeProjectPolicy.hasValidID("../project"))
        precondition(MordeProjectPolicy.hasValidInvitationID("r1234567"))
        precondition(MordeProjectPolicy.hasValidConversationID("c1234567"))
        precondition(!MordeProjectPolicy.hasValidConversationID("../tasks"))
        precondition(MordeProjectPolicy.hasValidUserID("u1234567"))
        precondition(MordeProjectPolicy.hasValidTaskID("q1234567"))
        precondition(!MordeProjectPolicy.hasValidTaskID("../tasks"))
        precondition(MordeProjectPolicy.restorableTaskID(
            ownerID: "u1234567", currentUserID: "u1234567",
            messages: [(actorID: "u1234567", taskID: "q1234567"),
                       (actorID: "u7654321", taskID: "q7654321"),
                       (actorID: "u1234567", taskID: "q7654321")]) == "q7654321")
        precondition(MordeProjectPolicy.restorableTaskID(
            ownerID: "u7654321", currentUserID: "u1234567",
            messages: [(actorID: "u1234567", taskID: "q1234567")]) == nil)
        precondition(MordeProjectPolicy.restorableTaskID(
            ownerID: "u1234567", currentUserID: "u1234567",
            messages: [(actorID: "u1234567", taskID: "q1234567"),
                       (actorID: "u1234567", taskID: "../tasks")]) == "q1234567")
        precondition(MordeProjectPolicy.hasValidResourceID(kind: "workspace", id: "w1234567"))
        precondition(!MordeProjectPolicy.hasValidResourceID(kind: "workspace", id: "h1234567"))
        precondition(MordeProjectPolicy.isOwner(ownerID: "u1234567", currentUserID: "u1234567"))
        precondition(!MordeProjectPolicy.isOwner(ownerID: "u1234567", currentUserID: "u7654321"))
        precondition(MordeProjectPolicy.canAcceptInvitation(
            state: "pending", inviteeID: "u1234567", currentUserID: "u1234567"))
        precondition(!MordeProjectPolicy.canAcceptInvitation(
            state: "pending", inviteeID: "u1234567", currentUserID: "u7654321"))
        precondition(MordeProjectPolicy.canTransferOwnership(
            ownerID: "u1234567", currentUserID: "u1234567", targetUserID: "u7654321", targetRole: "member"))
        precondition(!MordeProjectPolicy.canTransferOwnership(
            ownerID: "u1234567", currentUserID: "u1234567", targetUserID: "u7654321", targetRole: "owner"))
        precondition(MordeProjectPolicy.canContinuePendingMutation(nil, requestedFingerprint: "create"))
        precondition(MordeProjectPolicy.canContinuePendingMutation("create", requestedFingerprint: "create"))
        precondition(!MordeProjectPolicy.canContinuePendingMutation("create", requestedFingerprint: "delete"))
        precondition(MordeProjectPolicy.canManageWorkItems(role: "owner"))
        precondition(MordeProjectPolicy.canManageWorkItems(role: "member"))
        precondition(!MordeProjectPolicy.canManageWorkItems(role: "viewer"))
        precondition(MordeProjectPolicy.canLinkTask(role: "member", state: "open", taskID: "q1234567", taskIDs: []))
        precondition(!MordeProjectPolicy.canLinkTask(role: "viewer", state: "open", taskID: "q1234567", taskIDs: []))
        precondition(!MordeProjectPolicy.canLinkTask(role: "member", state: "delivered", taskID: "q1234567", taskIDs: []))
        precondition(!MordeProjectPolicy.canLinkTask(role: "member", state: "open", taskID: "q1234567", taskIDs: ["q1234567"]))
        precondition(MordeProjectPolicy.canRecordDelivery(role: "owner", state: "open", taskID: "q1234567",
                                                           taskIDs: ["q1234567"], workspaceID: "w1234567", revision: 2))
        precondition(!MordeProjectPolicy.canRecordDelivery(role: "viewer", state: "open", taskID: "q1234567",
                                                            taskIDs: ["q1234567"], workspaceID: "w1234567", revision: 2))
        precondition(!MordeProjectPolicy.canRecordDelivery(role: "member", state: "open", taskID: "q1234567",
                                                            taskIDs: [], workspaceID: "w1234567", revision: 2))
        precondition(!MordeProjectPolicy.canRecordDelivery(role: "member", state: "open", taskID: "q1234567",
                                                            taskIDs: ["q1234567"], workspaceID: "w1234567", revision: 0))
        precondition(MordeProjectPolicy.canSetBudget(role: "owner", currency: "USD", limitMicros: 1_000_000))
        precondition(!MordeProjectPolicy.canSetBudget(role: "member", currency: "USD", limitMicros: 1_000_000))
        precondition(!MordeProjectPolicy.canSetBudget(role: "owner", currency: "usd", limitMicros: 1_000_000))
        precondition(!MordeProjectPolicy.canSetBudget(role: "owner", currency: "USD", limitMicros: 0))
        precondition(MordeProjectExecutionCapability.isAvailable(["project_budget_execution"]))
        precondition(!MordeProjectExecutionCapability.isAvailable(["task_api"]))
        precondition(!MordeProjectExecutionCapability.isAvailable(nil))
        precondition(MordeProjectExecutionCapability.canContinueTask(status: "running"))
        precondition(MordeProjectExecutionCapability.canContinueTask(status: "waiting_user"))
        precondition(!MordeProjectExecutionCapability.canContinueTask(status: "completed"))
        var seenPersonalSnapshotCursors = Set<String>()
        precondition(!MordePersonalSnapshotCursorPolicy.repeats("page-1", seen: &seenPersonalSnapshotCursors))
        precondition(!MordePersonalSnapshotCursorPolicy.repeats("page-2", seen: &seenPersonalSnapshotCursors))
        precondition(MordePersonalSnapshotCursorPolicy.repeats("page-1", seen: &seenPersonalSnapshotCursors))
        precondition(!MordePersonalSnapshotCursorPolicy.repeats(nil, seen: &seenPersonalSnapshotCursors))
        precondition(MordeNotificationPresentationPolicy.summary("任务完成", redacted: false) == "任务完成")
        precondition(MordeNotificationPresentationPolicy.summary("敏感摘要", redacted: true) == "不可查看")
        precondition(MordeNotificationPresentationPolicy.summary("旧服务端摘要", redacted: nil) == "不可查看")
        precondition(MordeNotificationPresentationPolicy.summary(nil, redacted: false) == "不可查看")
        precondition(MordeNotificationPresentationPolicy.canOpenTask(kind: "completed", redacted: false, actionable: false))
        precondition(MordeNotificationPresentationPolicy.canOpenTask(kind: "waiting_user", redacted: false, actionable: true))
        precondition(!MordeNotificationPresentationPolicy.canOpenTask(kind: "waiting_user", redacted: false, actionable: false))
        precondition(!MordeNotificationPresentationPolicy.canOpenTask(kind: "completed", redacted: nil, actionable: true))
        precondition(MordeNotificationPresentationPolicy.canAppendPage(currentIDs: ["n1"], pageIDs: ["n2"]))
        precondition(!MordeNotificationPresentationPolicy.canAppendPage(currentIDs: ["n1"], pageIDs: ["n1"]))
        let mainConversation = try! JSONDecoder().decode(MordeMainConversation.self,
            from: Data(#"{"status":"ready","conversation_id":"c1234567","version":1}"#.utf8))
        precondition(mainConversation.isValid)
        precondition(!(try! JSONDecoder().decode(MordeMainConversation.self,
            from: Data(#"{"status":"ready","conversation_id":"","version":0}"#.utf8))).isValid)
        precondition((try! JSONDecoder().decode(MordeMainConversation.self,
            from: Data(#"{"status":"selection_required","conversation_id":"","version":0}"#.utf8))).isValid)
        precondition(MordeMessageDeliveryPresentation.label("pending") == "已受理，等待进入 Agent")
        precondition(MordeMessageDeliveryPresentation.label("applied").contains("任务仍可能运行"))
        precondition(MordeMessageDeliveryPresentation.label("unknown").contains("不要重复提交"))
        precondition(MordeMessageDeliveryPresentation.label(nil).contains("未提供"))
        let deliveryMessageData = Data(#"{"id":"m1234567","conversation_id":"c1234567","task_id":"t1234567","role":"user","content":"hello","delivery_status":"pending"}"#.utf8)
        let deliveryMessage = try! JSONDecoder().decode(MordeClientMessage.self, from: deliveryMessageData)
        precondition(deliveryMessage.delivery_status == "pending")
        let conflictData = Data(#"{"error":{"code":"conflict","message":"conflict","details":{"reason":"personal_object_revision_changed","base_revision":2,"current_revision":3,"deleted":false}}}"#.utf8)
        precondition(MordePersonalRevisionConflict.decode(conflictData)?.currentRevision == 3)
        let fixedTarget = MordeTaskTargetPresentation.fixedTarget(
            executionLocation: "server", hostID: "host-1", hostName: "Mac mini", hostState: "running",
            workspaceID: "workspace-1", workspaceName: "Project", inputRevision: 8)
        precondition(fixedTarget == "云端 Agent Runtime · Mac mini（运行中） · Project v8")
        let inaccessibleTarget = MordeTaskTargetPresentation.fixedTarget(
            executionLocation: "server", hostID: "host-1", hostName: nil, hostState: nil,
            workspaceID: "workspace-1", workspaceName: nil, inputRevision: nil)
        precondition(inaccessibleTarget.contains("Host host-1（当前不可访问）"))
        precondition(inaccessibleTarget.contains("workspace-1"))
        let serverTaskWithoutHost = MordeTaskTargetPresentation.fixedTarget(
            executionLocation: "server", hostID: nil, hostName: nil, hostState: nil,
            workspaceID: nil, workspaceName: nil, inputRevision: nil)
        precondition(serverTaskWithoutHost == "云端 Agent Runtime · 无电脑目标 · 无 Workspace")
        precondition(MordeTaskTargetPresentation.fixedTarget(
            executionLocation: nil, hostID: nil, hostName: nil, hostState: nil,
            workspaceID: nil, workspaceName: nil, inputRevision: nil).hasPrefix("执行位置待核验"))

        precondition(MordeTaskResponsePolicy.hasValidTaskID("q1234567"))
        precondition(!MordeTaskResponsePolicy.hasValidTaskID("qbad"))
        precondition(MordeTaskResponsePolicy.hasValidRequestID("r1234567"))
        precondition(!MordeTaskResponsePolicy.hasValidRequestID("pending-1"))
        precondition(MordeTaskResponsePolicy.actionPath(taskID: "q1234567") == "/api/tasks/q1234567/actions")
        precondition(MordeTaskResponsePolicy.approvalPath(taskID: "q1234567", approvalID: "r1234567") ==
                     "/api/tasks/q1234567/approvals/r1234567/responses")
        precondition(MordeTaskResponsePolicy.approvalPath(taskID: "q1234567", approvalID: "../actions") == nil)
        precondition(MordeTaskResponsePolicy.inputPath(taskID: "q1234567") == "/api/tasks/q1234567/inputs")
        precondition(MordeTaskResponsePolicy.hasValidOperationID("o1234567"))
        precondition(!MordeTaskResponsePolicy.hasValidOperationID("../tasks"))
        precondition(MordeTaskResponsePolicy.mediaPreviewPath(taskID: "q1234567", operationID: "o1234567") ==
                     "/api/tasks/q1234567/media/o1234567/preview")
        precondition(MordeTaskResponsePolicy.mediaPreviewPath(taskID: "q1234567", operationID: "../tasks") == nil)
        precondition(MordeTaskResponsePolicy.hasValidAnswer("Use staging"))
        precondition(!MordeTaskResponsePolicy.hasValidAnswer("  \n"))
        precondition(!MordeTaskResponsePolicy.hasValidAnswer("a\0b"))
        precondition(!MordeTaskResponsePolicy.hasValidAnswer(String(repeating: "a", count: 16_385)))

        let approvalEndpoint = "approvals/r1234567/responses"
        let approveAction: [String: Any] = ["version": 3, "decision": "approve"]
        let approveFingerprint = MordeActionRetryAttempt.fingerprint(
            taskID: "q1234567", endpoint: approvalEndpoint, body: approveAction)!
        precondition(approveFingerprint.count == 64)
        precondition(approveFingerprint == MordeActionRetryAttempt.fingerprint(
            taskID: "q1234567", endpoint: approvalEndpoint, body: approveAction))
        precondition(approveFingerprint != MordeActionRetryAttempt.fingerprint(
            taskID: "q1234568", endpoint: approvalEndpoint, body: approveAction))
        precondition(approveFingerprint != MordeActionRetryAttempt.fingerprint(
            taskID: "q1234567", endpoint: "inputs", body: approveAction))
        let firstActionAttempt = MordeActionRetryAttempt(fingerprint: approveFingerprint, idempotencyKey: "action-retry-key")
        let repeatedActionAttempt = MordeActionRetryAttempt.reusing(firstActionAttempt, for: approveFingerprint)
        precondition(repeatedActionAttempt.idempotencyKey == "action-retry-key")
        let changedApproval = ["version": 3, "decision": "reject"] as [String: Any]
        let changedFingerprint = MordeActionRetryAttempt.fingerprint(
            taskID: "q1234567", endpoint: approvalEndpoint, body: changedApproval)!
        precondition(changedFingerprint != approveFingerprint)
        precondition(MordeTaskAttempt.canContinuePendingAttempt(
            firstActionAttempt.fingerprint, requestedFingerprint: approveFingerprint))
        precondition(!MordeTaskAttempt.canContinuePendingAttempt(
            firstActionAttempt.fingerprint, requestedFingerprint: changedFingerprint))
        precondition(MordeActionRetryAttempt.reusing(firstActionAttempt, for: changedFingerprint).idempotencyKey != "action-retry-key")

        precondition(MordeClientVersion.meetsMinimum(current: "1.2.0", minimum: "1.1.9"))
        precondition(MordeClientVersion.meetsMinimum(current: "1.2.0", minimum: "1.2.0"))
        precondition(!MordeClientVersion.meetsMinimum(current: "1.1.9", minimum: "1.2.0"))
        precondition(!MordeClientVersion.meetsMinimum(current: "1.2.0-beta.1", minimum: "1.2.0"))
        precondition(MordeClientVersion.meetsMinimum(current: "1.2.0", minimum: "1.2.0-beta.9"))
        precondition(MordeClientVersion.meetsMinimum(current: "1.2.0-beta.12", minimum: "1.2.0-beta.9"))
        precondition(MordeClientVersion.meetsMinimum(current: "1.2.3+build.8", minimum: "1.2.3"))
        precondition(!MordeClientVersion.meetsMinimum(current: "invalid", minimum: "1.2.0"))
        precondition(!MordeClientVersion.meetsMinimum(current: "", minimum: "1.2.0"))

        precondition(MordeTaskSnapshotCursor.resumeCursor(eventID: "7", snapshotSequence: 9) == "9")
        precondition(MordeTaskSnapshotCursor.resumeCursor(eventID: "9", snapshotSequence: 7) == nil)
        precondition(MordeTaskSnapshotCursor.resumeCursor(eventID: "-1", snapshotSequence: 0) == nil)
        let assistantStatusValues = Set((contract["assistant_message_statuses"] as? [String]) ?? [])
        precondition(assistantStatusValues == MordeTaskSnapshotMessageMerge.statuses)
        let assistantSnapshotFixture = fixtureObject(taskSnapshot["assistant_message"], label: "task_snapshot.assistant_message")
        let assistantSnapshotData = try! JSONSerialization.data(withJSONObject: assistantSnapshotFixture)
        let streamingAssistant = try! JSONDecoder().decode(MordeClientMessage.self, from: assistantSnapshotData)
        precondition(streamingAssistant.status == "streaming")
        let streamingMessages = MordeTaskSnapshotMessageMerge.merge(
            [], snapshot: streamingAssistant, taskID: "q1234567", conversationID: "c1234567")
        precondition(streamingMessages == [streamingAssistant])
        let nextDelta = MordeClientMessage(
            id: streamingAssistant.id, conversation_id: "c1234567", task_id: "q1234567",
            role: "assistant", content: "Hello world", status: "streaming", created_at: streamingAssistant.created_at)
        let accumulatedMessages = MordeTaskSnapshotMessageMerge.merge(
            streamingMessages, snapshot: nextDelta, taskID: "q1234567", conversationID: "c1234567")
        precondition(accumulatedMessages.count == 1 && accumulatedMessages[0].content == "Hello world")
        let completedAssistant = MordeClientMessage(
            id: streamingAssistant.id, conversation_id: "c1234567", task_id: "q1234567",
            role: "assistant", content: "Hello world!", status: "completed", created_at: streamingAssistant.created_at)
        let completedMessages = MordeTaskSnapshotMessageMerge.merge(
            accumulatedMessages, snapshot: completedAssistant, taskID: "q1234567", conversationID: "c1234567")
        precondition(completedMessages.count == 1 && completedMessages[0].id == streamingAssistant.id)
        precondition(completedMessages[0].content == "Hello world!" && completedMessages[0].status == "completed")
        let deliveredCanonical = MordeClientMessage(
            id: streamingAssistant.id, conversation_id: "c1234567", task_id: "q1234567",
            role: "assistant", content: "Canonical final text", delivery_status: "applied",
            created_at: streamingAssistant.created_at)
        let completedSnapshotMerge = MordeTaskSnapshotMessageMerge.merge(
            [deliveredCanonical], snapshot: completedAssistant, taskID: "q1234567", conversationID: "c1234567")
        precondition(completedSnapshotMerge[0].content == "Hello world!" &&
                     completedSnapshotMerge[0].status == "completed" &&
                     completedSnapshotMerge[0].delivery_status == "applied")
        let canonicalMessage = MordeClientMessage(
            id: streamingAssistant.id, conversation_id: "c1234567", task_id: "q1234567",
            role: "assistant", content: "Canonical final text", created_at: streamingAssistant.created_at)
        let staleSnapshotMerge = MordeTaskSnapshotMessageMerge.merge(
            [canonicalMessage], snapshot: streamingAssistant, taskID: "q1234567", conversationID: "c1234567")
        precondition(staleSnapshotMerge.count == 1 && staleSnapshotMerge[0].content == "Canonical final text")
        precondition(staleSnapshotMerge[0].status == "completed")
        let interruptedAssistant = MordeClientMessage(
            id: "m7654321", conversation_id: "c1234567", task_id: "q1234567",
            role: "assistant", content: "Partial reply", status: "interrupted", created_at: streamingAssistant.created_at)
        let interruptedMessages = MordeTaskSnapshotMessageMerge.merge(
            [], snapshot: interruptedAssistant, taskID: "q1234567", conversationID: "c1234567")
        precondition(interruptedMessages.count == 1 && interruptedMessages[0].status == "interrupted")
        let wrongTaskMerge = MordeTaskSnapshotMessageMerge.merge(
            [], snapshot: streamingAssistant, taskID: "q7654321", conversationID: "c1234567")
        precondition(wrongTaskMerge.isEmpty)

        let scope = MordeClientDataScope(serviceOrigin: "https://morde.example", serviceInstanceID: serviceA,
                                         accountID: "user-1", installationID: "install-1")!
        let pendingSend = MordeRetryAttempt(scope: scope, fingerprint: taskAttempt, key: "retry-key",
                                            inputRevision: 17, expectedTaskID: "q1234567")
        let restoredSend = try! JSONDecoder().decode(MordeRetryAttempt.self, from: JSONEncoder().encode(pendingSend))
        precondition(restoredSend == pendingSend)
        precondition(restoredSend.inputRevision == 17)
        precondition(restoredSend.expectedTaskID == "q1234567")
        let legacyRetryData = try! JSONSerialization.data(withJSONObject: [
            "scope": ["serviceOrigin": scope.serviceOrigin, "serviceInstanceID": scope.serviceInstanceID,
                      "accountID": scope.accountID, "installationID": scope.installationID],
            "fingerprint": taskAttempt, "key": "legacy-retry-key",
        ])
        let legacyRetry = try! JSONDecoder().decode(MordeRetryAttempt.self, from: legacyRetryData)
        precondition(legacyRetry.inputRevision == nil, "legacy retries without an input revision must remain readable")
        precondition(legacyRetry.expectedTaskID == nil, "legacy retries without a queued task must remain readable")
        let outboxSuite = "MordeTaskOutboxTests-\(UUID().uuidString)"
        let outboxDefaults = UserDefaults(suiteName: outboxSuite)!
        outboxDefaults.removePersistentDomain(forName: outboxSuite)
        defer { outboxDefaults.removePersistentDomain(forName: outboxSuite) }
        outboxDefaults.set(try! JSONEncoder().encode(pendingSend), forKey: "morde.pendingSendAttempt.\(scope.storageKey)")
        let restartedOutbox = MordeRetryAttempt.decodePersisted(from: outboxDefaults, scope: scope)
        precondition(restartedOutbox == pendingSend)
        precondition(restoredSend.matches(scope: scope, fingerprint: taskAttempt))
        let otherAccountScope = MordeClientDataScope(serviceOrigin: "https://morde.example", serviceInstanceID: serviceA,
                                                      accountID: "user-2", installationID: "install-1")!
        let rebuiltServiceScope = MordeClientDataScope(serviceOrigin: "https://morde.example", serviceInstanceID: serviceB,
                                                       accountID: "user-1", installationID: "install-1")!
        let otherInstallationScope = MordeClientDataScope(serviceOrigin: "https://morde.example", serviceInstanceID: serviceA,
                                                          accountID: "user-1", installationID: "install-2")!
        precondition(!restoredSend.matches(scope: otherAccountScope, fingerprint: taskAttempt))
        precondition(!restoredSend.matches(scope: rebuiltServiceScope, fingerprint: taskAttempt))
        precondition(!restoredSend.matches(scope: otherInstallationScope, fingerprint: taskAttempt))
        precondition(MordeUnauthorizedResponsePolicy.shouldClearAuthorization(
            requestCredential: "old-token", currentCredential: "old-token", requestScope: scope,
            currentScope: scope, hasPendingLoginIntent: false, isCancelled: false))
        precondition(!MordeUnauthorizedResponsePolicy.shouldClearAuthorization(
            requestCredential: "old-token", currentCredential: "new-token", requestScope: scope,
            currentScope: scope, hasPendingLoginIntent: false, isCancelled: false))
        precondition(!MordeUnauthorizedResponsePolicy.shouldClearAuthorization(
            requestCredential: "old-token", currentCredential: "old-token", requestScope: scope,
            currentScope: otherAccountScope, hasPendingLoginIntent: false, isCancelled: false))
        precondition(!MordeUnauthorizedResponsePolicy.shouldClearAuthorization(
            requestCredential: "old-token", currentCredential: "old-token", requestScope: scope,
            currentScope: rebuiltServiceScope, hasPendingLoginIntent: false, isCancelled: false))
        precondition(!MordeUnauthorizedResponsePolicy.shouldClearAuthorization(
            requestCredential: "old-token", currentCredential: "old-token", requestScope: scope,
            currentScope: otherInstallationScope, hasPendingLoginIntent: false, isCancelled: false))
        precondition(!MordeUnauthorizedResponsePolicy.shouldClearAuthorization(
            requestCredential: "old-token", currentCredential: "old-token", requestScope: scope,
            currentScope: nil, hasPendingLoginIntent: false, isCancelled: false))
        precondition(!MordeUnauthorizedResponsePolicy.shouldClearAuthorization(
            requestCredential: "old-token", currentCredential: "old-token", requestScope: scope,
            currentScope: scope, hasPendingLoginIntent: true, isCancelled: false))
        precondition(!MordeUnauthorizedResponsePolicy.shouldClearAuthorization(
            requestCredential: "old-token", currentCredential: "old-token", requestScope: scope,
            currentScope: scope, hasPendingLoginIntent: false, isCancelled: true))
        precondition(Set([scope.storageKey, otherAccountScope.storageKey, rebuiltServiceScope.storageKey,
                          otherInstallationScope.storageKey]).count == 4)

        let recent = MordeScopedRecentConversation(scope: scope, conversationID: "conversation-1")
        outboxDefaults.set(try! JSONEncoder().encode(recent), forKey: "morde.recentConversation.\(scope.storageKey)")
        let restartedRecent = try! JSONDecoder().decode(
            MordeScopedRecentConversation.self,
            from: outboxDefaults.data(forKey: "morde.recentConversation.\(scope.storageKey)")!)
        precondition(restartedRecent.matches(scope: scope))
        precondition(!restartedRecent.matches(scope: otherAccountScope))
        precondition(!restartedRecent.matches(scope: rebuiltServiceScope))
        precondition(!restartedRecent.matches(scope: otherInstallationScope))

        let revocationSuite = "MordeRevocationStoreTests-\(UUID().uuidString)"
        let revocationDefaults = UserDefaults(suiteName: revocationSuite)!
        revocationDefaults.removePersistentDomain(forName: revocationSuite)
        defer { revocationDefaults.removePersistentDomain(forName: revocationSuite) }
        let revocation = MordeRevocationRecord(scope: scope, clientInstanceID: firstAttempt.clientInstanceID,
                                               confirmed: false)
        try! MordeRevocationStore(defaults: revocationDefaults).record(revocation)
        let restartedRevocations = MordeRevocationStore(defaults: revocationDefaults).pending()
        precondition(restartedRevocations == [revocation])
        let revocationJSON = String(decoding: revocationDefaults.data(forKey: MordeRevocationStore.defaultsKey)!, as: UTF8.self)
        precondition(revocationJSON.contains("install-1"))
        precondition(revocationJSON.contains(firstAttempt.clientInstanceID.uuidString))
        precondition(!revocationJSON.contains("credential"))
        precondition(!revocationJSON.contains("password"))
        try! MordeRevocationStore(defaults: revocationDefaults).record(
            MordeRevocationRecord(scope: scope, clientInstanceID: firstAttempt.clientInstanceID, confirmed: true))
        precondition(MordeRevocationStore(defaults: revocationDefaults).pending().isEmpty)

        print("Morde login fence, scoped task recovery, target readiness and pinning, revocation persistence, credential, version, cursor, task status, and notification checks passed")
    }
}
