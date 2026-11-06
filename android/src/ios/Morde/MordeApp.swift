import CryptoKit
import Combine
import Foundation
import ImageIO
import PDFKit
import QuickLook
import Security
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import WebKit

enum MordePersonalStorage {
    static let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Morde", isDirectory: true)
}

#if DEBUG
// nanoMuse: Keep account login acceptance local so synthetic test credentials never reach a service.
private final class MordeAuthURLProtocol: URLProtocol {
    static let launchArgument = "-morde.localRegistrationStub"
    static let approvedLaunchArgument = "-morde.localRegistrationApproved"
    static let hubFixtureLaunchArgument = "-morde.localHubFixture"
    static let taskSSEFixtureLaunchArgument = "-morde.localTaskSSEFixture"
    static let taskSnapshotRequiredFixtureLaunchArgument = "-morde.localTaskSnapshotRequiredFixture"
    static let taskDisconnectRecoveryFixtureLaunchArgument = "-morde.localTaskDisconnectRecoveryFixture"
    static let taskRelaunchFixtureLaunchArgument = "-morde.localTaskRelaunchFixture"
    static let taskApprovalConflictFixtureLaunchArgument = "-morde.localTaskApprovalConflictFixture"
    static let taskSequentialSendFixtureLaunchArgument = "-morde.localTaskSequentialSendFixture"
    static let taskQueueFixtureLaunchArgument = "-morde.localTaskQueueFixture"
    static let localHistoryFixtureLaunchArgument = "-morde.localLegacyHistoryFixture"
    static let historyImportFixtureLaunchArgument = "-morde.localHistoryImportFixture"
    static let unknownTaskStatusFixtureLaunchArgument = "-morde.localUnknownTaskStatusFixture"
    static let accountIsolationFixtureLaunchArgument = "-morde.localAccountIsolationFixture"
    static let delayedAccountResponseFixtureLaunchArgument = "-morde.localDelayedAccountResponseFixture"
    static let delayedAccountChatResponseFixtureLaunchArgument = "-morde.localDelayedAccountChatResponseFixture"
    static let taskMediaFixtureLaunchArgument = "-morde.localTaskMediaFixture"
    static let taskMediaCapabilityDisabledFixtureLaunchArgument = "-morde.localTaskMediaCapabilityDisabled"
    static let taskPagesFixtureLaunchArgument = "-morde.localTaskPagesFixture"
    static let taskPagesEmptyFixtureLaunchArgument = "-morde.localTaskPagesEmptyFixture"
    static let taskPagesEmptyIntermediateFixtureLaunchArgument = "-morde.localTaskPagesEmptyIntermediateFixture"
    static let taskPagesRetryFixtureLaunchArgument = "-morde.localTaskPagesRetryFixture"
    static let taskPagesApprovalPaginationFixtureLaunchArgument = "-morde.localTaskPagesApprovalPaginationFixture"
    static let taskPagesApprovalPartialFixtureLaunchArgument = "-morde.localTaskPagesApprovalPartialFixture"
    static let taskPagesTaskDetailRequestsFixtureLaunchArgument = "-morde.localTaskPagesTaskDetailRequestsFixture"
    static let conversationFailureFixtureLaunchArgument = "-morde.localConversationFailureFixture"
    static let conversationDrawerRetryFixtureLaunchArgument = "-morde.localConversationDrawerRetryFixture"
    static let taskPagesApprovalUnknownRetryFixtureLaunchArgument = "-morde.localTaskPagesApprovalUnknownRetryFixture"
    static let taskPagesApprovalRetryWithoutCommitFixtureLaunchArgument = "-morde.localTaskPagesApprovalRetryWithoutCommitFixture"
    static let taskPagesApprovalDelayFixtureLaunchArgument = "-morde.localTaskPagesApprovalDelayFixture"
    static let taskPagesApprovalRefreshPendingFixtureLaunchArgument = "-morde.localTaskPagesApprovalRefreshPendingFixture"
    static let taskPagesTimelineRecoveryFixtureLaunchArgument = "-morde.localTaskPagesTimelineRecoveryFixture"
    static let taskPagesTimelinePermissionFixtureLaunchArgument = "-morde.localTaskPagesTimelinePermissionFixture"
    static let taskPagesEventChainTimelineFixtureLaunchArgument = "-morde.localTaskPagesEventChainTimelineFixture"
    static let chatAttachmentFixtureLaunchArgument = "-morde.localChatAttachmentFixture"
    static let chatAttachmentUploadFailureFixtureLaunchArgument = "-morde.localChatAttachmentUploadFailureFixture"
    static let chatAttachmentSendRetryFixtureLaunchArgument = "-morde.localChatAttachmentSendRetryFixture"
    static let chatAttachmentOverflowFixtureLaunchArgument = "-morde.localChatAttachmentOverflowFixture"
    static let chatAttachmentDownloadFailureFixtureLaunchArgument = "-morde.localChatAttachmentDownloadFailureFixture"
    static let chatAttachmentDownloadBadLengthFixtureLaunchArgument = "-morde.localChatAttachmentDownloadBadLengthFixture"
    static let chatAttachmentDownloadBadETagFixtureLaunchArgument = "-morde.localChatAttachmentDownloadBadETagFixture"
    static let taskPagesTaskActionDelayFixtureLaunchArgument = "-morde.localTaskPagesTaskActionDelayFixture"
    static let taskPagesTaskActionUnknownRetryFixtureLaunchArgument = "-morde.localTaskPagesTaskActionUnknownRetryFixture"
    static let taskPagesTaskActionServiceInstanceFixtureLaunchArgument = "-morde.localTaskPagesTaskActionServiceInstanceFixture"
    static let taskTabLifecycleFixtureLaunchArgument = "-morde.localTaskTabLifecycleFixture"
    static let taskArtifactPreviewFixtureLaunchArgument = "-morde.localTaskArtifactPreviewFixture"
    static let resourceAcceptanceFixtureLaunchArgument = "-morde.localResourceAcceptanceFixture"
    static let resourceConfirmedEmptyFixtureLaunchArgument = "-morde.localResourceConfirmedEmptyFixture"
    static let resourceDefaultHostPreferenceFailureFixtureLaunchArgument = "-morde.localResourceDefaultHostPreferenceFailureFixture"
    static let mainChatFixtureLaunchArgument = "-morde.localMainChatFixture"
    static let noAdminModelFixtureLaunchArgument = "-morde.localNoAdminModelFixture"
    static let conversationHistoryPaginationFixtureLaunchArgument = "-morde.localConversationHistoryPaginationFixture"
    static let workItemFixtureLaunchArgument = "-morde.localWorkItemFixture"
    static let workItemCreateFailureFixtureLaunchArgument = "-morde.localWorkItemCreateFailureFixture"
    private static let executionConflictFixtureLaunchArgument = "-morde.localExecutionConflictFixture"
    private static let executionUnknownFixtureLaunchArgument = "-morde.localExecutionUnknownFixture"
    private static let executionDelayStopFixtureLaunchArgument = "-morde.localExecutionDelayStopFixture"
    private static let taskFixtureLock = NSLock()
    private static let registrationFixtureLock = NSLock()
    private static let workItemFixtureLock = NSLock()
    private static let workItemFixtureInitializationLock = NSLock()
    private static let executionFixtureLock = NSLock()
    private static let chatAttachmentFixtureLock = NSLock()
    private let delayedResponseLock = NSLock()
    private var delayedResponseWorkItem: DispatchWorkItem?
    private static var taskFixtureEventCount = 0
    private static var taskApprovalConflictActionCount = 0
    private static var taskSequentialSendContents: [String] = []
    private static var registrationFixtureRequestCount = 0
    private static var taskMediaFixtureDecision: String?
    private static var workItemFixtureRows: [[String: Any]] = []
    private static var workItemFixtureInitialized = false
    private static var workItemFixtureBlockConflictPending = true
    private static var taskPagesApprovalDecision: String?
    private static var taskPagesClarificationAnswered = false
    private static var taskPagesApprovalRetryIdempotencyKey: String?
    private static var taskPagesTaskActionStatus = "running"
    private static var taskPagesTaskActionIdempotencyKey: String?
    private static var taskPagesTaskActionRequestCount = 0
    private static var taskPagesTaskActionServiceInstanceChanged = false
    private static var taskPagesTaskActionSecondInstanceAccepted = false
    private static var taskPagesRetryListRequestCount = 0
    private static var taskTabLifecycleTaskAccepted = false
    private static var taskTabLifecycleCompleted = false
    private static var conversationDrawerListRequestCount = 0
    private static var taskPagesCreatedConversation = false
    private static var mainChatFixtureEnsured = false
    private static var conversationHistoryFixtureInitialRequestCount = 0
    private static var executionFixtureState = "enabled"
    private static var executionFixtureEpoch: Int64 = 7
    private static var executionFixtureStopKey: String?
    private static var executionFixtureStopEpoch: Int64?
    private static var executionFixtureEnableKey: String?
    private static var executionFixtureEnableEpoch: Int64?
    private static var executionFixtureStopPolls = 0
    private static var executionFixtureUnknownPending = false
    private static var executionFixtureConflictPending = false
    private static var executionFixtureStopResponsePending = false
    private struct ChatAttachmentFixtureUpload {
        let objectID: String
        let sizeBytes: Int64
        let sha256: String
        let mediaType: String
        let chunkCount: Int32
        var chunks: [Int32: Data] = [:]
        var attachmentID: String?
    }
    private struct ChatAttachmentFixtureLibraryItem {
        let revision: Int64
        let body: Data
    }
    private static var chatAttachmentFixtureSequence: Int64 = 0
    private static var chatAttachmentFixtureLibraryItems: [String: ChatAttachmentFixtureLibraryItem] = [:]
    private static var chatAttachmentFixtureUploads: [String: ChatAttachmentFixtureUpload] = [:]
    private static var chatAttachmentFixtureUploadKeys: [String: String] = [:]
    private static var chatAttachmentFixtureCommittedIDs = Set<String>()
    private static var chatAttachmentFixtureAcceptedMessageKey: String?

    private static let taskMediaFixturePNG = Data([
        0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,
        0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x04, 0x00, 0x00, 0x00, 0xb5, 0x1c, 0x0c,
        0x02, 0x00, 0x00, 0x00, 0x0b, 0x49, 0x44, 0x41,
        0x54, 0x78, 0xda, 0x63, 0xfc, 0xff, 0x1f, 0x00,
        0x03, 0x03, 0x02, 0x00, 0xef, 0xbf, 0x6a, 0xf7,
        0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44,
        0xae, 0x42, 0x60, 0x82,
    ])
    private static let taskMediaWaitingTask = Data(#"{"id":"q1234567","conversation_id":"c1234567","host_id":null,"execution_location":"server","workspace_id":null,"input_revision":null,"objective":"local media fixture","status":"waiting_user","event_sequence":1,"result":null,"current_step":"Generated media is ready for review","waiting_reason":"approval_required","stop_request":null,"pending_request":{"id":"r1234567","version":1,"kind":"approval","title":"Save generated image?","object":"image","content":"Review this generated image before saving it to the task Workspace.","impact":"Saving publishes the generated image to the authorized Workspace.","media_preview_operation_id":"o1234567"},"clarification_request":null,"batch_items":null,"updated_at":"2026-11-04T00:00:00Z"}"#.utf8)

    static var usesLocalFixture: Bool {
        ProcessInfo.processInfo.arguments.contains { $0.hasPrefix("-morde.local") }
    }

    private static func setTaskMediaFixtureDecision(_ decision: String?) {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        taskMediaFixtureDecision = decision
    }

    private static func setTaskPagesApprovalDecision(_ decision: String?) {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        taskPagesApprovalDecision = decision
    }

    private static func nextTaskPagesRetryListRequest() -> Int {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        taskPagesRetryListRequestCount += 1
        return taskPagesRetryListRequestCount
    }

    // nanoMuse: Keep task-page clarification acceptance inside the process-local UI fixture.
    private static func setTaskPagesClarificationAnswered() {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        taskPagesClarificationAnswered = true
    }

    private static func setTaskPagesCreatedConversation() {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        taskPagesCreatedConversation = true
    }

    private static func resetMainChatFixture() {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        mainChatFixtureEnsured = false
    }

    private static var mainChatFixtureIsEnsured: Bool {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        return mainChatFixtureEnsured
    }

    private static func ensureMainChatFixture() {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        mainChatFixtureEnsured = true
    }

    private static func nextConversationHistoryFixtureInitialRequest() -> Int {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        conversationHistoryFixtureInitialRequestCount += 1
        return conversationHistoryFixtureInitialRequestCount
    }

    private static func conversationHistoryFixtureMessages(from first: Int, through last: Int) -> [[String: Any]] {
        (first...last).map { index in
            [
                "id": "mh\(index)", "conversation_id": "c1234567", "task_id": NSNull(),
                "role": index.isMultiple(of: 2) ? "assistant" : "user",
                "content": String(format: "History message %03d", index), "status": "completed",
                "delivery_status": NSNull(),
                "created_at": String(format: "2026-11-05T00:%02d:%02dZ", index / 60, index % 60),
            ]
        }
    }

    private static var taskPagesCreatedConversationSnapshot: Bool {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        return taskPagesCreatedConversation
    }

    private static func taskPagesApprovalUnknownRetryResponse(
        key: String?, payload: [String: Any]?, commitOnFirstAttempt: Bool = true
    ) -> (status: Int, body: Data, shouldLoseResponse: Bool) {
        guard let key, !key.isEmpty else {
            return (400, Data(#"{"error":{"code":"bad_request","message":"Approval fixture expected Idempotency-Key"}}"#.utf8), false)
        }
        guard let version = payload?["version"] as? Int, version == 1,
              let decision = payload?["decision"] as? String,
              ["approve", "reject"].contains(decision) else {
            return (409, Data(#"{"error":{"code":"conflict","message":"Invalid local approval version or decision"}}"#.utf8), false)
        }

        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        if let originalKey = taskPagesApprovalRetryIdempotencyKey {
            guard key == originalKey else {
                return (409, Data(#"{"error":{"code":"conflict","message":"Approval retry must reuse the original local idempotency key"}}"#.utf8), false)
            }
            taskPagesApprovalDecision = decision
            return (202, Data(#"{"task_id":"q0000101","action":"approval_response","status":"completed","unsettled_operation_ids":[]}"#.utf8), false)
        }

        taskPagesApprovalRetryIdempotencyKey = key
        if commitOnFirstAttempt { taskPagesApprovalDecision = decision }
        return (202, Data(#"{"task_id":"q0000101","action":"approval_response","status":"completed","unsettled_operation_ids":[]}"#.utf8), true)
    }

    private static func taskPagesTaskActionResponse(
        key: String?, payload: [String: Any]?, unknownRetry: Bool, serviceInstanceChange: Bool = false
    ) -> (status: Int, body: Data, shouldLoseResponse: Bool, shouldDelayResponse: Bool) {
        guard let key, !key.isEmpty else {
            return (400, Data(#"{"error":{"code":"bad_request","message":"Task action fixture expected Idempotency-Key"}}"#.utf8), false, false)
        }
        guard payload?["action"] as? String == "pause",
              payload?["expected_status"] as? String == "running" else {
            return (409, Data(#"{"error":{"code":"conflict","message":"Expected pause from running"}}"#.utf8), false, false)
        }

        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        taskPagesTaskActionRequestCount += 1
        let success = Data(#"{"task_id":"q0000001","action":"pause","status":"paused","unsettled_operation_ids":[]}"#.utf8)

        if serviceInstanceChange {
            if !taskPagesTaskActionServiceInstanceChanged {
                taskPagesTaskActionIdempotencyKey = key
                taskPagesTaskActionServiceInstanceChanged = true
                return (202, success, true, false)
            }
            guard key != taskPagesTaskActionIdempotencyKey else {
                return (409, Data(#"{"error":{"code":"conflict","message":"A new service instance must not reuse the old Task action key"}}"#.utf8), false, false)
            }
            taskPagesTaskActionSecondInstanceAccepted = true
            taskPagesTaskActionStatus = "paused"
            return (202, success, false, false)
        }

        if unknownRetry, let originalKey = taskPagesTaskActionIdempotencyKey {
            guard key == originalKey else {
                return (409, Data(#"{"error":{"code":"conflict","message":"Task action retry must reuse its original idempotency key"}}"#.utf8), false, false)
            }
            taskPagesTaskActionStatus = "paused"
            return (202, success, false, false)
        }
        guard taskPagesTaskActionStatus == "running" else {
            return (409, Data(#"{"error":{"code":"conflict","message":"Task action was already accepted"}}"#.utf8), false, false)
        }

        if unknownRetry {
            taskPagesTaskActionIdempotencyKey = key
            return (202, success, true, false)
        }
        taskPagesTaskActionStatus = "paused"
        return (202, success, false, true)
    }

    private static var taskPagesTaskActionSnapshot: (status: String, requestCount: Int) {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        if ProcessInfo.processInfo.arguments.contains(taskPagesTaskActionServiceInstanceFixtureLaunchArgument),
           taskPagesTaskActionServiceInstanceChanged, !taskPagesTaskActionSecondInstanceAccepted {
            return ("running", taskPagesTaskActionRequestCount)
        }
        return (taskPagesTaskActionStatus, taskPagesTaskActionRequestCount)
    }

    private static var taskPagesTaskActionServiceInstanceChangedSnapshot: Bool {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        return taskPagesTaskActionServiceInstanceChanged
    }

    private static func nextConversationDrawerListRequest() -> Int {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        conversationDrawerListRequestCount += 1
        return conversationDrawerListRequestCount
    }

    private static func markTaskTabLifecycleAccepted() {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        taskTabLifecycleTaskAccepted = true
    }

    private static func beginTaskTabLifecycleEvent() -> Bool {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        guard taskTabLifecycleTaskAccepted, !taskTabLifecycleCompleted else { return false }
        return true
    }

    private static func finishTaskTabLifecycleEvent() {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        taskTabLifecycleCompleted = true
    }

    private static var taskTabLifecycleTaskAcceptedSnapshot: Bool {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        return taskTabLifecycleTaskAccepted
    }

    private static var taskTabLifecycleCompletedSnapshot: Bool {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        return taskTabLifecycleCompleted
    }

    private static func taskTabLifecycleTask() -> [String: Any] {
        let completed = taskTabLifecycleCompletedSnapshot
        return ["id": "q1234567", "conversation_id": "c1234567", "host_id": NSNull(),
                "execution_location": "server", "workspace_id": NSNull(), "input_revision": NSNull(),
                "objective": "Task accepted before switching tabs", "status": completed ? "completed" : "running",
                "event_sequence": completed ? 2 : 1,
                "result": completed ? "Local Task completed after tab switch" as Any : NSNull(),
                "current_step": NSNull(), "waiting_reason": NSNull(), "stop_request": NSNull(),
                "pending_request": NSNull(), "clarification_request": NSNull(), "batch_items": NSNull(),
                "updated_at": "2026-11-05T00:00:00Z"]
    }

    private static var taskPagesApprovalDecisionSnapshot: String? {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        return taskPagesApprovalDecision
    }

    private static var taskPagesClarificationAnsweredSnapshot: Bool {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        return taskPagesClarificationAnswered
    }

    private static var taskMediaFixtureDecisionSnapshot: String? {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        return taskMediaFixtureDecision
    }

    private static func nextRegistrationFixtureRequest() -> Int {
        registrationFixtureLock.lock(); defer { registrationFixtureLock.unlock() }
        registrationFixtureRequestCount += 1
        return registrationFixtureRequestCount
    }

    private static func isAccountA(_ request: URLRequest) -> Bool {
        request.value(forHTTPHeaderField: "Authorization") == "Bearer local-account-a-credential"
    }

    private static func requestBodyData(_ request: URLRequest, maxBytes: Int) -> Data? {
        var body = request.httpBody
        if body == nil, let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var streamed = Data()
            var buffer = [UInt8](repeating: 0, count: 4096)
            while true {
                let count = buffer.withUnsafeMutableBufferPointer { bytes in
                    guard let address = bytes.baseAddress else { return -1 }
                    return stream.read(address, maxLength: bytes.count)
                }
                guard count >= 0, count <= maxBytes, streamed.count <= maxBytes - count else { return nil }
                if count == 0 { break }
                streamed.append(contentsOf: buffer.prefix(count))
            }
            body = streamed
        }
        guard let body, !body.isEmpty, body.count <= maxBytes else { return nil }
        return body
    }

    private static func jsonPayload(_ request: URLRequest) -> [String: Any]? {
        guard let body = requestBodyData(request, maxBytes: 1_000_000) else { return nil }
        return (try? JSONSerialization.jsonObject(with: body)) as? [String: Any]
    }

    private static func resetTaskFixture() {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        taskFixtureEventCount = 0
        taskApprovalConflictActionCount = 0
        taskSequentialSendContents = []
        taskPagesApprovalDecision = nil
        taskPagesClarificationAnswered = false
        taskPagesApprovalRetryIdempotencyKey = nil
        taskPagesTaskActionStatus = "running"
        taskPagesTaskActionIdempotencyKey = nil
        taskPagesTaskActionRequestCount = 0
        taskPagesTaskActionServiceInstanceChanged = false
        taskPagesTaskActionSecondInstanceAccepted = false
        taskTabLifecycleTaskAccepted = false
        taskTabLifecycleCompleted = false
        conversationDrawerListRequestCount = 0
        taskPagesCreatedConversation = false
    }

    private static func resetChatAttachmentFixture() {
        chatAttachmentFixtureLock.lock(); defer { chatAttachmentFixtureLock.unlock() }
        chatAttachmentFixtureSequence = 0
        chatAttachmentFixtureLibraryItems = [:]
        chatAttachmentFixtureUploads = [:]
        chatAttachmentFixtureUploadKeys = [:]
        chatAttachmentFixtureCommittedIDs = []
        chatAttachmentFixtureAcceptedMessageKey = nil
    }

    private static func chatAttachmentFixtureSnapshot() -> Data {
        chatAttachmentFixtureLock.lock(); defer { chatAttachmentFixtureLock.unlock() }
        let items: [[String: Any]] = chatAttachmentFixtureLibraryItems.keys.sorted().compactMap { id in
            guard let item = chatAttachmentFixtureLibraryItems[id],
                  let body = try? JSONSerialization.jsonObject(with: item.body) as? [String: Any] else { return nil }
            return ["object_type": "library_item", "object_id": id, "revision": item.revision, "body": body]
        }
        return (try? JSONSerialization.data(withJSONObject: [
            "watermark": chatAttachmentFixtureSequence, "items": items, "next_cursor": NSNull(),
        ])) ?? Data()
    }

    private static func personalAttachmentDownloadFixtureResponse(for request: URLRequest)
        -> (status: Int, body: Data, headers: [String: String])? {
        guard ProcessInfo.processInfo.arguments.contains(chatAttachmentFixtureLaunchArgument),
              request.url?.host == "portal.120.25.178.93.sslip.io",
              request.httpMethod == "GET",
              let path = request.url?.path,
              path.hasPrefix("/api/personal-data/attachments/") else { return nil }
        let attachmentID = String(path.dropFirst("/api/personal-data/attachments/".count))
        guard MordePersonalDataContract.isValidAttachmentID(attachmentID) else {
            return (400, Data(#"{"error":{"code":"bad_request","message":"Invalid fixture attachment ID"}}"#.utf8),
                    ["Content-Type": "application/json"])
        }
        if ProcessInfo.processInfo.arguments.contains(chatAttachmentDownloadFailureFixtureLaunchArgument) {
            return (503, Data(#"{"error":{"code":"unavailable","message":"Synthetic attachment download failed"}}"#.utf8),
                    ["Content-Type": "application/json"])
        }

        chatAttachmentFixtureLock.lock(); defer { chatAttachmentFixtureLock.unlock() }
        guard chatAttachmentFixtureCommittedIDs.contains(attachmentID),
              let upload = chatAttachmentFixtureUploads.values.first(where: { $0.attachmentID == attachmentID }) else {
            return (404, Data(#"{"error":{"code":"not_found","message":"Synthetic attachment not found"}}"#.utf8),
                    ["Content-Type": "application/json"])
        }
        let bytes = (0..<upload.chunkCount).reduce(into: Data()) { data, index in
            data.append(upload.chunks[index] ?? Data())
        }
        guard Int64(bytes.count) == upload.sizeBytes,
              MordePersonalAttachmentHash.sha256(bytes) == upload.sha256 else {
            return (409, Data(#"{"error":{"code":"conflict","message":"Synthetic attachment bytes changed"}}"#.utf8),
                    ["Content-Type": "application/json"])
        }
        var headers = ["Content-Type": upload.mediaType,
                       "Content-Length": String(bytes.count),
                       "ETag": "\"\(upload.sha256)\"",
                       "Cache-Control": "private, no-store",
                       "X-Content-Type-Options": "nosniff"]
        if ProcessInfo.processInfo.arguments.contains(chatAttachmentDownloadBadLengthFixtureLaunchArgument) {
            headers["Content-Length"] = String(bytes.count + 1)
        }
        if ProcessInfo.processInfo.arguments.contains(chatAttachmentDownloadBadETagFixtureLaunchArgument) {
            headers["ETag"] = "\"\(String(repeating: "0", count: 64))\""
        }
        return (200, bytes, headers)
    }

    private static func chatAttachmentFixtureResponse(for request: URLRequest) -> (status: Int, body: Data)? {
        guard ProcessInfo.processInfo.arguments.contains(chatAttachmentFixtureLaunchArgument),
              request.url?.host == "portal.120.25.178.93.sslip.io",
              let path = request.url?.path else { return nil }
        func response(_ status: Int, _ value: [String: Any]) -> (status: Int, body: Data) {
            (status, (try? JSONSerialization.data(withJSONObject: value)) ?? Data())
        }
        if path == "/api/sync/snapshot", request.httpMethod == "GET" {
            return (200, chatAttachmentFixtureSnapshot())
        }
        if path == "/api/personal-data/quota", request.httpMethod == "GET" {
            let ownerID = ProcessInfo.processInfo.arguments.contains(accountIsolationFixtureLaunchArgument)
                ? (isAccountA(request) ? "u_accounta1" : "u_accountb1") : "u_localtest1"
            return response(200, ["owner_id": ownerID, "used_bytes": 0, "reserved_bytes": 0,
                "quota_bytes": 100_000_000, "max_attachment_bytes": 10_000_000,
                "remaining_bytes": 100_000_000, "version": 1])
        }
        if path.hasPrefix("/api/personal-data/library_item/"), request.httpMethod == "PUT" {
            let objectID = String(path.dropFirst("/api/personal-data/library_item/".count))
            guard MordePersonalDataContract.isValidObjectIdentifier(type: "library_item", id: objectID),
                  let payload = jsonPayload(request), let baseRevision = payload["base_revision"] as? Int64,
                  let value = payload["body"] as? [String: Any],
                  let body = try? JSONSerialization.data(withJSONObject: value) else {
                return response(400, ["error": ["code": "bad_request", "message": "Invalid synthetic library item"]])
            }
            chatAttachmentFixtureLock.lock(); defer { chatAttachmentFixtureLock.unlock() }
            let current = chatAttachmentFixtureLibraryItems[objectID]
            guard baseRevision == (current?.revision ?? 0) else {
                return response(409, ["error": ["code": "conflict", "message": "Synthetic library revision changed"]])
            }
            let revision = (current?.revision ?? 0) + 1
            chatAttachmentFixtureSequence += 1
            chatAttachmentFixtureLibraryItems[objectID] = ChatAttachmentFixtureLibraryItem(revision: revision, body: body)
            return response(200, ["object_type": "library_item", "object_id": objectID,
                "result_revision": revision, "account_change_sequence": chatAttachmentFixtureSequence, "replay": false])
        }
        if path == "/api/personal-data/uploads", request.httpMethod == "POST" {
            guard let key = request.value(forHTTPHeaderField: "Idempotency-Key"),
                  MordePersonalDataContract.isValidIdempotencyKey(key),
                  let payload = jsonPayload(request), let objectID = payload["object_id"] as? String,
                  MordePersonalDataContract.isValidObjectIdentifier(type: "library_item", id: objectID),
                  let sizeBytes = payload["size_bytes"] as? Int64, sizeBytes > 0,
                  let sha256 = payload["sha256"] as? String,
                  sha256.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil,
                  let mediaType = payload["media_type"] as? String,
                  MordePersonalDataContract.isValidAttachmentMediaType(mediaType),
                  let chunkCount = MordePersonalAttachmentHash.chunkCount(sizeBytes: sizeBytes), chunkCount > 0 else {
                return response(400, ["error": ["code": "bad_request", "message": "Invalid synthetic upload request"]])
            }
            chatAttachmentFixtureLock.lock(); defer { chatAttachmentFixtureLock.unlock() }
            let uploadID: String
            if let existingID = chatAttachmentFixtureUploadKeys[key] {
                uploadID = existingID
            } else {
                chatAttachmentFixtureSequence += 1
                uploadID = "pu_" + String(format: "%032llx", chatAttachmentFixtureSequence)
                chatAttachmentFixtureUploads[uploadID] = ChatAttachmentFixtureUpload(
                    objectID: objectID, sizeBytes: sizeBytes, sha256: sha256,
                    mediaType: mediaType, chunkCount: chunkCount)
                chatAttachmentFixtureUploadKeys[key] = uploadID
            }
            guard let upload = chatAttachmentFixtureUploads[uploadID], upload.objectID == objectID,
                  upload.sizeBytes == sizeBytes, upload.sha256 == sha256, upload.mediaType == mediaType else {
                return response(409, ["error": ["code": "conflict", "message": "Synthetic upload key was reused"]])
            }
            return response(200, ["upload_id": uploadID, "state": upload.attachmentID == nil ? "active" : "committed",
                "chunk_count": upload.chunkCount, "replay": upload.attachmentID != nil])
        }
        let pathParts = path.split(separator: "/").map(String.init)
        if pathParts.count == 6, pathParts[0...2] == ["api", "personal-data", "uploads"],
           pathParts[4] == "chunks", request.httpMethod == "PUT",
           let sequence = Int32(pathParts[5]), sequence >= 0 {
            if ProcessInfo.processInfo.arguments.contains(chatAttachmentUploadFailureFixtureLaunchArgument) {
                return response(503, ["error": ["code": "unavailable", "message": "Synthetic attachment upload failed"]])
            }
            let uploadID = pathParts[3]
            guard let chunk = requestBodyData(request, maxBytes: Int(MordePersonalAttachmentHash.chunkBytes)) else {
                return response(400, ["error": ["code": "bad_request", "message": "Synthetic upload chunk is missing or oversized"]])
            }
            let digest = MordePersonalAttachmentHash.sha256(chunk)
            guard request.value(forHTTPHeaderField: "X-Chunk-SHA256") == digest else {
                return response(400, ["error": ["code": "bad_request", "message": "Synthetic chunk digest mismatch"]])
            }
            chatAttachmentFixtureLock.lock(); defer { chatAttachmentFixtureLock.unlock() }
            guard var upload = chatAttachmentFixtureUploads[uploadID], sequence < upload.chunkCount,
                  let expectedSize = MordePersonalAttachmentHash.chunkSize(sizeBytes: upload.sizeBytes, sequence: sequence),
                  chunk.count == expectedSize else {
                return response(404, ["error": ["code": "not_found", "message": "Synthetic upload chunk not found"]])
            }
            let replay = upload.chunks[sequence] != nil
            guard upload.chunks[sequence].map({ $0 == chunk }) ?? true else {
                return response(409, ["error": ["code": "conflict", "message": "Synthetic chunk changed"]])
            }
            upload.chunks[sequence] = chunk
            chatAttachmentFixtureUploads[uploadID] = upload
            return response(200, ["upload_id": uploadID, "sequence": sequence, "replay": replay])
        }
        if pathParts.count == 5, pathParts[0...2] == ["api", "personal-data", "uploads"],
           pathParts[4] == "commit", request.httpMethod == "POST" {
            let uploadID = pathParts[3]
            chatAttachmentFixtureLock.lock(); defer { chatAttachmentFixtureLock.unlock() }
            guard var upload = chatAttachmentFixtureUploads[uploadID],
                  let item = chatAttachmentFixtureLibraryItems[upload.objectID] else {
                return response(404, ["error": ["code": "not_found", "message": "Synthetic upload not found"]])
            }
            if let attachmentID = upload.attachmentID {
                return response(200, ["attachment_id": attachmentID, "object_type": "library_item",
                    "object_id": upload.objectID, "result_revision": item.revision,
                    "account_change_sequence": chatAttachmentFixtureSequence, "replay": true])
            }
            guard upload.chunks.count == Int(upload.chunkCount) else {
                return response(409, ["error": ["code": "conflict", "message": "Synthetic upload is incomplete"]])
            }
            let bytes = (0..<upload.chunkCount).reduce(into: Data()) { data, index in
                data.append(upload.chunks[index] ?? Data())
            }
            guard Int64(bytes.count) == upload.sizeBytes, MordePersonalAttachmentHash.sha256(bytes) == upload.sha256,
                  var libraryBody = (try? JSONSerialization.jsonObject(with: item.body)) as? [String: Any] else {
                return response(400, ["error": ["code": "bad_request", "message": "Synthetic upload verification failed"]])
            }
            chatAttachmentFixtureSequence += 1
            let attachmentID = "pa_" + String(format: "%032llx", chatAttachmentFixtureSequence)
            libraryBody["attachment_id"] = attachmentID
            guard let encodedBody = try? JSONSerialization.data(withJSONObject: libraryBody) else {
                return response(500, ["error": ["code": "internal", "message": "Synthetic library item encoding failed"]])
            }
            let revision = item.revision + 1
            chatAttachmentFixtureLibraryItems[upload.objectID] = ChatAttachmentFixtureLibraryItem(revision: revision, body: encodedBody)
            upload.attachmentID = attachmentID
            chatAttachmentFixtureUploads[uploadID] = upload
            chatAttachmentFixtureCommittedIDs.insert(attachmentID)
            return response(200, ["attachment_id": attachmentID, "object_type": "library_item",
                "object_id": upload.objectID, "result_revision": revision,
                "account_change_sequence": chatAttachmentFixtureSequence, "replay": false])
        }
        if path == "/api/conversations/c1234567/messages", request.httpMethod == "POST" {
            guard let payload = jsonPayload(request),
                  let content = payload["content"] as? String, !content.isEmpty,
                  let modelID = payload["model_id"] as? String, !modelID.isEmpty,
                  let idempotencyKey = request.value(forHTTPHeaderField: "Idempotency-Key"),
                  MordePersonalDataContract.isValidIdempotencyKey(idempotencyKey),
                  let attachmentIDs = payload["attachment_ids"] as? [String], attachmentIDs.count == 4,
                  Set(attachmentIDs).count == 4,
                  attachmentIDs.allSatisfy(MordePersonalDataContract.isValidAttachmentID) else {
                return response(400, ["error": ["code": "bad_request", "message": "Expected two synthetic files and four attachment objects"]])
            }
            chatAttachmentFixtureLock.lock(); defer { chatAttachmentFixtureLock.unlock() }
            guard Set(attachmentIDs) == chatAttachmentFixtureCommittedIDs else {
                return response(409, ["error": ["code": "conflict", "message": "Synthetic message references uncommitted attachments"]])
            }
            if ProcessInfo.processInfo.arguments.contains(chatAttachmentSendRetryFixtureLaunchArgument) {
                if let acceptedKey = chatAttachmentFixtureAcceptedMessageKey {
                    guard idempotencyKey == acceptedKey else {
                        return response(409, ["error": ["code": "conflict", "message": "Retry changed the message idempotency key"]])
                    }
                } else {
                    chatAttachmentFixtureAcceptedMessageKey = idempotencyKey
                    return response(503, ["error": ["code": "unavailable", "message": "Synthetic response lost after accepting the message"]])
                }
            }
            let message: [String: Any] = ["id": "m9999999", "conversation_id": "c1234567", "task_id": "q9999999",
                "role": "user", "content": content, "status": "completed", "delivery_status": NSNull(),
                "attachment_ids": attachmentIDs, "created_at": "2026-11-05T00:00:00Z"]
            let task: [String: Any] = ["id": "q9999999", "conversation_id": "c1234567", "host_id": NSNull(),
                "execution_location": "server", "workspace_id": NSNull(), "input_revision": NSNull(),
                "objective": content, "status": "completed", "event_sequence": 1, "result": "Synthetic attachment request accepted.",
                "current_step": NSNull(), "waiting_reason": NSNull(), "stop_request": NSNull(),
                "pending_request": NSNull(), "clarification_request": NSNull(), "batch_items": NSNull(),
                "updated_at": "2026-11-05T00:00:00Z"]
            return response(200, ["message": message, "task": task])
        }
        if path == "/api/tasks/q9999999/events", request.httpMethod == "GET" {
            return (204, Data())
        }
        return nil
    }

    private static func resetExecutionFixture() {
        executionFixtureLock.lock(); defer { executionFixtureLock.unlock() }
        executionFixtureState = "enabled"
        executionFixtureEpoch = 7
        executionFixtureStopKey = nil
        executionFixtureStopEpoch = nil
        executionFixtureEnableKey = nil
        executionFixtureEnableEpoch = nil
        executionFixtureStopPolls = 0
        executionFixtureUnknownPending = false
        executionFixtureConflictPending = ProcessInfo.processInfo.arguments.contains(executionConflictFixtureLaunchArgument)
        executionFixtureStopResponsePending = false
    }

    private static func finishExecutionFixtureStopResponse() {
        executionFixtureLock.lock(); defer { executionFixtureLock.unlock() }
        executionFixtureStopResponsePending = false
    }

    private static func executionFixtureBodyLocked() -> Data {
        let runtimeState = executionFixtureState == "enabled" ? "running"
            : (executionFixtureState == "stopping" ? "stopping" : "stopped")
        let activeCount = executionFixtureState == "disabled" ? 0 : 1
        let pendingCount = executionFixtureState == "disabled" ? 0 : 2
        let body: [String: Any] = [
            "owner_id": "u_localtest1", "state": executionFixtureState,
            "epoch": executionFixtureEpoch, "pending_task_count": pendingCount,
            "runtime": ["state": runtimeState, "runtime_generation": 1,
                        "max_concurrent_tasks": 2, "active_task_count": activeCount],
            "updated_at": "2026-11-05T00:00:00Z",
        ]
        return (try? JSONSerialization.data(withJSONObject: body)) ?? Data()
    }

    private static func executionFixtureResponse(for request: URLRequest) -> (status: Int, body: Data)? {
        guard ProcessInfo.processInfo.arguments.contains("-morde.localExecutionFixture") else { return nil }
        let path = request.url?.path ?? ""
        let method = request.httpMethod ?? "GET"
        guard path == "/api/execution" || path == "/api/execution/stop-all" || path == "/api/execution/enable" else {
            return nil
        }
        if path == "/api/execution", method == "GET" {
            executionFixtureLock.lock(); defer { executionFixtureLock.unlock() }
            if executionFixtureState == "stopping" {
                if executionFixtureStopPolls == 0 { executionFixtureStopPolls += 1 }
                else { executionFixtureState = "disabled" }
            }
            return (200, executionFixtureBodyLocked())
        }
        guard method == "POST" else {
            return (400, Data(#"{"error":{"code":"bad_request","message":"Local execution fixture expected POST"}}"#.utf8))
        }
        guard let body = Self.jsonPayload(request) else {
            return (400, Data(#"{"error":{"code":"bad_request","message":"Local execution fixture expected a JSON body"}}"#.utf8))
        }
        guard let expected = (body["expected_epoch"] as? NSNumber)?.int64Value else {
            return (400, Data(#"{"error":{"code":"bad_request","message":"Local execution fixture expected expected_epoch"}}"#.utf8))
        }
        guard let key = request.value(forHTTPHeaderField: "Idempotency-Key"), !key.isEmpty else {
            return (400, Data(#"{"error":{"code":"bad_request","message":"Local execution fixture expected Idempotency-Key"}}"#.utf8))
        }
        executionFixtureLock.lock(); defer { executionFixtureLock.unlock() }
        if path == "/api/execution/stop-all" {
            if executionFixtureStopResponsePending {
                return (409, Data(#"{"error":{"code":"conflict","message":"Local stop request is still pending"}}"#.utf8))
            }
            if ProcessInfo.processInfo.arguments.contains(executionUnknownFixtureLaunchArgument), executionFixtureUnknownPending {
                guard key == executionFixtureStopKey, expected == executionFixtureStopEpoch else {
                    return (409, Data(#"{"error":{"code":"conflict","message":"Local retry must reuse its idempotency key and epoch"}}"#.utf8))
                }
                executionFixtureUnknownPending = false
                executionFixtureState = "stopping"
                executionFixtureEpoch += 1
                executionFixtureStopPolls = 0
                return (202, executionFixtureBodyLocked())
            }
            if executionFixtureConflictPending {
                executionFixtureConflictPending = false
                executionFixtureState = "disabled"
                executionFixtureEpoch += 1
                return (409, Data(#"{"error":{"code":"conflict","message":"Local execution epoch changed"}}"#.utf8))
            }
            if key == executionFixtureStopKey, expected == executionFixtureStopEpoch {
                return (202, executionFixtureBodyLocked())
            }
            guard executionFixtureState == "enabled", expected == executionFixtureEpoch else {
                return (409, Data(#"{"error":{"code":"conflict","message":"Local execution epoch changed"}}"#.utf8))
            }
            executionFixtureStopKey = key
            executionFixtureStopEpoch = expected
            executionFixtureState = "stopping"
            executionFixtureEpoch += 1
            executionFixtureStopPolls = 0
            executionFixtureStopResponsePending = ProcessInfo.processInfo.arguments.contains(executionDelayStopFixtureLaunchArgument)
            if ProcessInfo.processInfo.arguments.contains(executionUnknownFixtureLaunchArgument) {
                executionFixtureState = "enabled"
                executionFixtureEpoch = expected
                executionFixtureUnknownPending = true
                return (-1, Data())
            }
            return (202, executionFixtureBodyLocked())
        }
        if key == executionFixtureEnableKey, expected == executionFixtureEnableEpoch {
            return (200, executionFixtureBodyLocked())
        }
        guard executionFixtureState == "disabled", expected == executionFixtureEpoch else {
            return (409, Data(#"{"error":{"code":"conflict","message":"Local execution epoch changed"}}"#.utf8))
        }
        executionFixtureEnableKey = key
        executionFixtureEnableEpoch = expected
        executionFixtureState = "enabled"
        executionFixtureEpoch += 1
        return (200, executionFixtureBodyLocked())
    }

    private static func taskPagesSummary(id: String, status: String, objective: String) -> [String: Any] {
        ["id": id, "conversation_id": "c1234567", "host_id": NSNull(),
         "execution_location": "server", "workspace_id": NSNull(), "input_revision": NSNull(),
         "objective": objective, "status": status, "current_step": NSNull(),
         "created_at": "2026-11-04T00:00:00Z", "updated_at": "2026-11-04T00:00:00Z"]
    }

    private static func taskPagesDetail(id: String) -> [String: Any]? {
        if id == "q0000001" {
            let hasTaskActionFixture = ProcessInfo.processInfo.arguments.contains(Self.taskPagesTaskActionDelayFixtureLaunchArgument) ||
                ProcessInfo.processInfo.arguments.contains(Self.taskPagesTaskActionUnknownRetryFixtureLaunchArgument) ||
                ProcessInfo.processInfo.arguments.contains(Self.taskPagesTaskActionServiceInstanceFixtureLaunchArgument)
            let actionSnapshot: (status: String, requestCount: Int)? = hasTaskActionFixture
                ? taskPagesTaskActionSnapshot : nil
            var task = taskPagesSummary(id: id, status: actionSnapshot?.status ?? "running",
                                       objective: "Local task detail fixture")
            task["event_sequence"] = ProcessInfo.processInfo.arguments.contains(Self.taskPagesTimelineRecoveryFixtureLaunchArgument)
                ? 8 : (actionSnapshot?.status == "paused" ? 3 : 2)
            task["result"] = NSNull()
            task["current_step"] = actionSnapshot.map { "Local action requests: \($0.requestCount)" }
                ?? "Review local task data"
            task["waiting_reason"] = NSNull()
            task["stop_request"] = NSNull()
            task["pending_request"] = NSNull()
            task["clarification_request"] = NSNull()
            task["batch_items"] = []
            task["steps"] = [
                ["id": "s0000001", "sequence": 1, "kind": "agent", "status": "succeeded",
                 "title": "Read task snapshot", "summary": "A verified local fixture step.",
                 "created_at": "2026-11-04T00:00:01Z"],
                ["id": "s0000002", "sequence": 2, "kind": "budget", "status": "succeeded",
                 "title": "Private budget field", "summary": "This must never be shown.",
                 "created_at": "2026-11-04T00:00:02Z"],
            ]
            if ProcessInfo.processInfo.arguments.contains(Self.taskArtifactPreviewFixtureLaunchArgument),
               let file = Self.taskArtifactPreviewFile() {
                task["artifacts"] = [
                    ["id": "a7654321", "label": "Verified local output", "media_type": "text/plain",
                     "verified": true, "workspace_id": "wabc1234", "workspace_revision": 3,
                     "path": file.path, "size_bytes": file.sizeBytes, "sha256": file.sha256,
                     "created_at": "2026-11-05T00:00:00Z"],
                    ["id": "a7654322", "label": "Legacy metadata only", "media_type": "text/plain",
                     "verified": true, "created_at": "2026-11-05T00:00:00Z"],
                ]
            } else {
                task["artifacts"] = []
            }
            return task
        }
        if id == "q0000101" {
            let decision = taskPagesApprovalDecisionSnapshot
            let isEventChainTimelineFixture = ProcessInfo.processInfo.arguments.contains(Self.taskPagesEventChainTimelineFixtureLaunchArgument)
            let isTimelineFixture = ProcessInfo.processInfo.arguments.contains(Self.taskPagesTimelineRecoveryFixtureLaunchArgument) ||
                ProcessInfo.processInfo.arguments.contains(Self.taskPagesTimelinePermissionFixtureLaunchArgument)
            if isTimelineFixture || isEventChainTimelineFixture {
                var task = taskPagesSummary(id: id, status: isEventChainTimelineFixture ? "waiting_user" : "running",
                                            objective: "Local task timeline fixture")
                task["conversation_id"] = "c7654321"
                task["event_sequence"] = ProcessInfo.processInfo.arguments.contains(Self.taskPagesTimelineRecoveryFixtureLaunchArgument) || isEventChainTimelineFixture
                    ? 8 : 1
                task["result"] = NSNull()
                task["current_step"] = "Waiting for local task events"
                task["waiting_reason"] = isEventChainTimelineFixture ? "approval_required" : NSNull()
                task["stop_request"] = NSNull()
                task["pending_request"] = isEventChainTimelineFixture
                    ? ["id": "r0000001", "version": 1, "kind": "approval", "title": "Review local change",
                       "object": "Local task output", "content": "Accept the local fixture action?",
                       "impact": "The fixture changes only its synthetic task response."]
                    : NSNull()
                task["clarification_request"] = NSNull()
                task["batch_items"] = []
                task["steps"] = []
                task["artifacts"] = []
                return task
            }
            var task = taskPagesSummary(id: id, status: decision == nil ? "waiting_user" : "completed",
                                        objective: "Local approval fixture")
            task["event_sequence"] = decision == nil ? 1 : 2
            task["result"] = decision == nil ? NSNull() : "Local decision refreshed"
            task["waiting_reason"] = decision == nil ? "approval_required" : NSNull()
            task["current_step"] = decision == nil ? "Waiting for approval" : NSNull()
            task["stop_request"] = NSNull()
            task["pending_request"] = decision == nil
                ? ["id": "r0000001", "version": 1, "kind": "approval", "title": "Review local change",
                   "object": "Local task output", "content": "Accept the local fixture action?",
                   "impact": "The fixture changes only its synthetic task response."]
                : NSNull()
            task["clarification_request"] = NSNull()
            task["batch_items"] = []
            task["steps"] = []
            task["artifacts"] = []
            return task
        }
        if id == "q0000102" {
            let answered = taskPagesClarificationAnsweredSnapshot
            var task = taskPagesSummary(id: id, status: answered ? "completed" : "waiting_user",
                                        objective: "Local clarification fixture")
            task["event_sequence"] = answered ? 2 : 1
            task["result"] = answered ? "Local clarification response received" : NSNull()
            task["waiting_reason"] = answered ? NSNull() : "clarification_required"
            task["current_step"] = answered ? NSNull() : "Waiting for clarification"
            task["stop_request"] = NSNull()
            task["pending_request"] = NSNull()
            task["clarification_request"] = answered ? NSNull() : ["id": "r0000002", "version": 1,
                                                                    "question": "A synthetic clarification, not an approval."]
            task["batch_items"] = []
            task["steps"] = []
            task["artifacts"] = []
            return task
        }
        return nil
    }

    private static func taskArtifactPreviewFile() -> MordeWorkspaceFile? {
        let path = "task-artifacts/verified.txt"
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documents.appendingPathComponent("Morde Workspace Files", isDirectory: true)
            .appendingPathComponent("wabc1234", isDirectory: true).appendingPathComponent(path)
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try Data("Local verified Task artifact preview".utf8).write(to: fileURL, options: .atomic)
            return try MordeWorkspaceTransferSupport.scan(url: fileURL, path: path)
        } catch {
            return nil
        }
    }

    private static func taskArtifactPreviewManifest() -> Data? {
        guard let file = taskArtifactPreviewFile(),
              let encodedFile = try? JSONEncoder().encode(file),
              let fileObject = (try? JSONSerialization.jsonObject(with: encodedFile)) as? [String: Any] else {
            return nil
        }
        return try? JSONSerialization.data(withJSONObject: [
            "workspace_id": "wabc1234", "revision": 3, "files": [fileObject],
            "directories": [["path": "."], ["path": "task-artifacts"]],
            "next_cursor": NSNull(),
        ])
    }

    private static func markTaskFixtureEvent() -> Int {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        taskFixtureEventCount += 1
        return taskFixtureEventCount
    }

    private static var didTaskFixtureSeeEvent: Bool {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        return taskFixtureEventCount > 0
    }

    private static var taskFixtureEventCountSnapshot: Int {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        return taskFixtureEventCount
    }

    private static func markTaskApprovalConflictAction() {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        taskApprovalConflictActionCount += 1
    }

    private static var didTaskApprovalConflictAction: Bool {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        return taskApprovalConflictActionCount > 0
    }

    private static func recordTaskSequentialSend(_ content: String) -> Int {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        taskSequentialSendContents.append(content)
        return taskSequentialSendContents.count
    }

    private static var taskSequentialSendContentsSnapshot: [String] {
        taskFixtureLock.lock(); defer { taskFixtureLock.unlock() }
        return taskSequentialSendContents
    }

    private static func taskSequentialID(_ index: Int) -> String { index == 1 ? "q1234567" : "q2345678" }
    private static func taskSequentialPrompt(_ index: Int) -> String {
        index == 1 ? "Sequential prompt one" : "Sequential prompt two"
    }

    private static func taskSequentialMessage(_ index: Int, content: String, role: String) -> [String: Any] {
        let sequence = (index - 1) * 2 + (role == "user" ? 1 : 2)
        return ["id": String(format: "m%07d", sequence), "conversation_id": "c1234567",
                "task_id": taskSequentialID(index), "role": role, "content": content,
                "status": "completed", "delivery_status": NSNull(),
                "created_at": String(format: "2026-11-04T00:00:%02dZ", sequence)]
    }

    private static func taskSequentialTask(_ index: Int, content: String) -> [String: Any] {
        let reply = "Local sequential reply \(index)"
        let assistant = taskSequentialMessage(index, content: reply, role: "assistant")
        return ["id": taskSequentialID(index), "conversation_id": "c1234567", "host_id": NSNull(),
                "execution_location": "server", "workspace_id": NSNull(), "input_revision": NSNull(),
                "objective": content, "status": "completed", "event_sequence": 1, "result": reply,
                "current_step": NSNull(), "waiting_reason": NSNull(), "stop_request": NSNull(),
                "pending_request": NSNull(), "clarification_request": NSNull(), "batch_items": NSNull(),
                "updated_at": String(format: "2026-11-04T00:00:%02dZ", index), "assistant_message": assistant]
    }

    private static func taskQueueFixtureTask() -> [String: Any] {
        ["id": "q1234567", "conversation_id": "c1234567", "host_id": NSNull(),
         "execution_location": "server", "workspace_id": NSNull(), "input_revision": NSNull(),
         "model_id": "p1234567", "objective": "Local active queue fixture", "status": "running",
         "event_sequence": 1, "result": NSNull(), "current_step": NSNull(), "waiting_reason": NSNull(),
         "stop_request": NSNull(), "pending_request": NSNull(), "clarification_request": NSNull(),
         "batch_items": NSNull(), "updated_at": "2026-11-04T00:00:00Z"]
    }

    private static func workItemFixtureRow(id: String, projectID: String, title: String,
                                           description: String, assigneeID: String?, category: String = "unclassified",
                                           state: String = "open", blockedReason: String = "",
                                           taskIDs: [String] = [], delivery: [String: Any]? = nil,
                                           version: Int = 1) -> [String: Any] {
        // nanoMuse: Keep the fixture wire shape aligned with nullable V2 assignees and legacy categories.
        ["id": id, "project_id": projectID, "title": title, "description": description,
         "acceptance_criteria": [String](), "category": category,
         "assignee_id": assigneeID.map { $0 as Any } ?? NSNull(), "state": state,
         "blocked_reason": blockedReason, "task_ids": taskIDs,
         "delivery": delivery.map { $0 as Any } ?? NSNull(), "version": version]
    }

    private static func resetWorkItemFixture() {
        workItemFixtureLock.lock(); defer { workItemFixtureLock.unlock() }
        workItemFixtureRows = [
            workItemFixtureRow(id: "j1000001", projectID: "j0000001", title: "本地缺陷",
                               description: "本机替身中的工作项。", assigneeID: "u0000001", category: "bug"),
            workItemFixtureRow(id: "j1000002", projectID: "j0000001", title: "本地需求",
                               description: "第二页用于检查完整分页。", assigneeID: "u0000001", category: "request"),
            workItemFixtureRow(id: "j1000004", projectID: "j0000001", title: "本地待认领",
                               description: "未认领状态与 open 状态相互独立。", assigneeID: nil,
                               category: "unclassified", state: "blocked", blockedReason: "等待处理"),
            workItemFixtureRow(id: "j2000001", projectID: "j0000002", title: "只读项目工作项",
                               description: "viewer 只能浏览。", assigneeID: "u0000002", category: "unclassified"),
        ]
        workItemFixtureBlockConflictPending = true
    }

    private static func initializeWorkItemFixtureIfNeeded() {
        guard ProcessInfo.processInfo.arguments.contains(workItemFixtureLaunchArgument) else { return }
        workItemFixtureInitializationLock.lock(); defer { workItemFixtureInitializationLock.unlock() }
        guard !workItemFixtureInitialized else { return }
        resetWorkItemFixture()
        workItemFixtureInitialized = true
    }

    private static func workItemFixturePage(projectID: String, cursor: String?, includeUnassigned: Bool) -> [String: Any] {
        workItemFixtureLock.lock(); defer { workItemFixtureLock.unlock() }
        let rows = workItemFixtureRows.filter {
            $0["project_id"] as? String == projectID &&
                (includeUnassigned || !($0["assignee_id"] is NSNull))
        }
        if cursor == nil {
            return ["items": Array(rows.prefix(1)), "next_cursor": rows.count > 1 ? "local-work-items-2" as Any : NSNull()]
        }
        guard cursor == "local-work-items-2" else { return ["items": [[String: Any]](), "next_cursor": NSNull()] }
        return ["items": Array(rows.dropFirst()), "next_cursor": NSNull()]
    }

    private static func workItemFixtureItem(id: String) -> [String: Any]? {
        workItemFixtureLock.lock(); defer { workItemFixtureLock.unlock() }
        return workItemFixtureRows.first { $0["id"] as? String == id }
    }

    private static func mutateWorkItemFixtureItem(id: String, expectedVersion: Int,
                                                  matching canMutate: ([String: Any]) -> Bool = { _ in true },
                                                  update: ([String: Any]) -> [String: Any]) -> [String: Any]? {
        workItemFixtureLock.lock(); defer { workItemFixtureLock.unlock() }
        guard let index = workItemFixtureRows.firstIndex(where: { $0["id"] as? String == id }),
              let version = workItemFixtureRows[index]["version"] as? Int, version == expectedVersion,
              canMutate(workItemFixtureRows[index]) else { return nil }
        var updated = update(workItemFixtureRows[index])
        updated["version"] = version + 1
        workItemFixtureRows[index] = updated
        return updated
    }

    private static func shouldConflictWorkItemBlock() -> Bool {
        workItemFixtureLock.lock(); defer { workItemFixtureLock.unlock() }
        guard workItemFixtureBlockConflictPending else { return false }
        workItemFixtureBlockConflictPending = false
        return true
    }

    private static func resourceFixtureResponse(for request: URLRequest) -> (status: Int, body: Data)? {
        let usesResourceAcceptanceFixture = ProcessInfo.processInfo.arguments.contains(resourceAcceptanceFixtureLaunchArgument)
        let usesConfirmedEmptyFixture = ProcessInfo.processInfo.arguments.contains(resourceConfirmedEmptyFixtureLaunchArgument)
        guard usesResourceAcceptanceFixture || usesConfirmedEmptyFixture,
              request.url?.host == "portal.120.25.178.93.sslip.io" else { return nil }
        let path = request.url?.path ?? ""
        let method = request.httpMethod ?? "GET"
        func json(_ value: Any) -> Data { (try? JSONSerialization.data(withJSONObject: value)) ?? Data() }
        func page(_ items: [[String: Any]]) -> [String: Any] { ["items": items, "next_cursor": NSNull()] }
        func binding(_ workspaceID: String, name: String, syncState: String = "healthy") -> [String: Any] {
            ["workspace": ["id": workspaceID, "name": name, "revision": 7, "state": "ready"],
             "state": "active", "desired_revision": 7, "applied_revision": 7, "sync_state": syncState]
        }
        func host(_ id: String, name: String, state: String, bindings: [[String: Any]]) -> [String: Any] {
            ["id": id, "name": name, "owner_id": "u0000001", "state": state,
             "url": "https://resource-fixture.invalid", "control_state": "ai", "workspaces": bindings]
        }
        let readyBinding = binding("w0000001", name: "Ready Workspace")
        let hosts = [
            host("h0000001", name: "Running host", state: "running", bindings: [readyBinding]),
            host("h0000002", name: "Offline host", state: "offline", bindings: []),
            host("h0000003", name: "Unready binding host", state: "running",
                 bindings: [binding("w0000002", name: "Syncing Workspace", syncState: "syncing")]),
            host("h0000004", name: "Unknown control host", state: "running", bindings: [readyBinding]),
            host("h0000005", name: "Expired lease host", state: "running", bindings: [readyBinding]),
            host("h0000006", name: "Takeover failure host", state: "running", bindings: [readyBinding]),
            host("h0000007", name: "Return failure host", state: "running", bindings: [readyBinding]),
        ]
        if usesConfirmedEmptyFixture {
            if ["/api/hosts", "/api/shared-hosts", "/api/workspaces"].contains(path), method == "GET" {
                return (200, json(page([])))
            }
            return nil
        }
        if path == "/api/hosts", method == "GET" { return (200, json(page(hosts))) }
        if path == "/api/hosts/h0000001/enter", method == "POST" {
            return (200, json(["url": "https://resource-fixture.invalid/__ch/auth?t=local-only"]))
        }
        if path == "/api/hosts/h0000008/observation-ticket", method == "POST" {
            return (200, json(["url": "https://resource-fixture.invalid/__ch/auth?t=shared-local-only"]))
        }
        if path == "/api/hosts/h0000008/enter", method == "POST" {
            return (409, Data(#"{"error":{"code":"conflict","message":"Shared Hosts require an observation ticket"}}"#.utf8))
        }
        if path == "/api/shared-hosts", method == "GET" {
            return (200, json(page([[
                "id": "h0000008", "name": "Shared read-only host", "state": "running",
                "url": "https://resource-fixture.invalid", "permissions": ["desktop:view"],
            ], [
                "id": "h0000009", "name": "Running host without view permission", "state": "running",
                "url": "https://resource-fixture.invalid", "permissions": [String](),
            ], [
                "id": "h0000010", "name": "Offline host without view permission", "state": "offline",
                "url": "https://resource-fixture.invalid", "permissions": [String](),
            ]])))
        }
        if path == "/api/workspaces", method == "GET" {
            return (200, json(page([
                ["id": "w0000001", "name": "Ready Workspace", "revision": 7, "state": "ready"],
                ["id": "w0000002", "name": "Syncing Workspace", "revision": 7, "state": "ready"],
                ["id": "w0000003", "name": "Unbound Workspace", "revision": 1, "state": "syncing"],
            ])))
        }
        if path == "/api/workspaces/w0000001/manifest", method == "GET" {
            let query = request.url.flatMap {
                URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems
            } ?? []
            guard query.first(where: { $0.name == "revision" })?.value == "7" else {
                return (409, Data(#"{"error":{"code":"conflict","message":"Workspace revision changed"}}"#.utf8))
            }
            func file(_ path: String, content: String) -> [String: Any] {
                let data = Data(content.utf8)
                let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
                return ["path": path, "size_bytes": data.count, "sha256": digest, "mode": 420,
                        "chunks": data.isEmpty ? [] : [["sha256": digest, "size_bytes": data.count]]]
            }
            let prefix = query.first(where: { $0.name == "prefix" })?.value
            let directories: [[String: Any]]
            let files: [[String: Any]]
            switch prefix {
            case nil:
                directories = [["path": "."], ["path": "docs"]]
                files = [file("README.md", content: "README\n")]
            case "docs":
                directories = [["path": "docs"]]
                files = [file("docs/guide.md", content: "guide\n")]
            default:
                return (404, Data(#"{"error":{"code":"not_found","message":"Directory not found"}}"#.utf8))
            }
            return (200, json(["workspace_id": "w0000001", "revision": 7, "files": files,
                               "directories": directories, "next_cursor": NSNull()]))
        }
        let parts = path.split(separator: "/").map(String.init)
        if parts.count == 4, parts[0] == "api", parts[1] == "hosts", parts[3] == "control", method == "GET" {
            let hostID = parts[2]
            var state = "ai", actor = "", leaseActive = false
            var expires: Any = NSNull()
            switch hostID {
            case "h0000004": state = "future_control_state"
            case "h0000005": state = "user"; actor = "u0000001"
            case "h0000007": state = "user"; actor = "u0000001"; leaseActive = true
                expires = "2100-01-01T00:00:00Z"
            default: break
            }
            return (200, json(["host_id": hostID, "control_state": state, "control_version": 1,
                               "control_actor_user_id": actor, "control_lease_expires_at": expires,
                               "control_lease_active": leaseActive, "active_transition": NSNull(),
                               "pending_operation_ids": [String]()]))
        }
        if parts.count == 5, parts[0] == "api", parts[1] == "hosts", parts[3] == "control",
           parts[4] == "actions", method == "POST" {
            guard let body = jsonPayload(request),
                  ["take_over", "release"].contains(body["action"] as? String ?? ""),
                  body["expected_control_version"] as? Int == 1,
                  body["request_id"] as? String != nil else {
                return (400, Data(#"{"error":{"code":"invalid_argument","message":"Invalid local control action"}}"#.utf8))
            }
            return (409, Data(#"{"error":{"code":"conflict","message":"Local control action conflict"}}"#.utf8))
        }
        return nil
    }

    private static func workItemFixtureResponse(for request: URLRequest) -> (status: Int, body: Data)? {
        guard ProcessInfo.processInfo.arguments.contains(workItemFixtureLaunchArgument),
              request.url?.host == "portal.120.25.178.93.sslip.io" else { return nil }
        let path = request.url?.path ?? ""
        let method = request.httpMethod ?? "GET"
        func json(_ value: Any) -> Data { (try? JSONSerialization.data(withJSONObject: value)) ?? Data() }
        func page(_ values: [[String: Any]]) -> [String: Any] { ["items": values, "next_cursor": NSNull()] }
        if path == "/api/capabilities", method == "GET" {
            return (200, Data(#"{"service_instance_id":"00000000-0000-0000-0000-000000000001","api_version":"1","supported_features":["password_login","client_installations","ordered_client_login","task_api","cloud_tasks","project_budget_execution","project_work_items_v2"]}"#.utf8))
        }
        if path == "/api/me", method == "GET" {
            return (200, Data(#"{"id":"u0000001","name":"Local fixture user"}"#.utf8))
        }
        if path == "/api/projects", method == "GET" {
            return (200, json(page([
                ["id": "j0000001", "owner_id": "u0000001", "name": "可编辑项目", "description": "", "version": 1],
                ["id": "j0000002", "owner_id": "u0000002", "name": "只读项目", "description": "", "version": 1],
            ])))
        }
        if path == "/api/me/project-invitations", method == "GET" {
            return (200, json(page([])))
        }
        if path == "/api/hosts", method == "GET" {
            let host: [String: Any] = [
                "id": "h0000001", "name": "本地测试主机", "owner_id": "u0000001", "state": "running",
                "url": "https://example.invalid", "control_state": "ai",
                "workspaces": [["workspace": ["id": "w0000001", "name": "本地工作区", "revision": 7, "state": "ready"],
                                "state": "active", "desired_revision": 7, "applied_revision": 7,
                                "sync_state": "healthy"]],
            ]
            return (200, json(page([host])))
        }
        if path == "/api/workspaces", method == "GET" {
            return (200, json(page([["id": "w0000001", "name": "本地工作区", "revision": 7, "state": "ready"]])))
        }
        if path == "/api/tasks/q0000001", method == "GET" {
            return (200, Data(#"{"id":"q0000001","conversation_id":"c0000001","host_id":null,"execution_location":"server","workspace_id":null,"input_revision":null,"objective":"本机工作项关联 Task","status":"completed","event_sequence":1,"result":"本机替身 Task","current_step":null,"waiting_reason":null,"stop_request":null,"pending_request":null,"clarification_request":null,"batch_items":null,"updated_at":"2026-11-04T00:00:00Z"}"#.utf8))
        }

        let parts = path.split(separator: "/").map(String.init)
        guard parts.count >= 3, parts[0] == "api", parts[1] == "projects" else { return nil }
        let projectID = parts[2]
        if parts.count == 4, parts[3] == "members", method == "GET" {
            let ownerID = projectID == "j0000001" ? "u0000001" : "u0000002"
            var members: [[String: Any]] = [["project_id": projectID, "user_id": ownerID, "role": "owner", "version": 1]]
            if projectID == "j0000002" {
                members.append(["project_id": projectID, "user_id": "u0000001", "role": "viewer", "version": 1])
            }
            return (200, json(page(members)))
        }
        if parts.count == 4, parts[3] == "resources", method == "GET" { return (200, json(page([]))) }
        if parts.count == 4, parts[3] == "conversations", method == "GET" {
            let values: [[String: Any]] = projectID == "j0000001"
                ? [["id": "c0000001", "project_id": projectID, "owner_id": "u0000001",
                    "title": "本地项目会话", "model_id": NSNull(), "created_at": "2026-11-04T00:00:00Z",
                    "updated_at": "2026-11-04T00:00:00Z"]]
                : []
            return (200, json(page(values)))
        }
        if parts.count == 6, parts[3] == "conversations", parts[5] == "messages", method == "GET" {
            let message: [String: Any] = ["id": "m0000001", "conversation_id": "c0000001", "role": "assistant",
                "content": "本地 Task 消息", "task_id": "q0000001", "delivery_status": "applied",
                "created_at": "2026-11-04T00:00:00Z", "owner_id": "u0000001", "actor_id": "u0000001"]
            return (200, json(page([message])))
        }
        if parts.count == 4, parts[3] == "work-items", method == "GET" {
            let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
            let cursor = query.first(where: { $0.name == "cursor" })?.value
            let includeUnassigned = query.contains { $0.name == "include_unassigned" && $0.value == "true" }
            return (200, json(workItemFixturePage(projectID: projectID, cursor: cursor,
                                                  includeUnassigned: includeUnassigned)))
        }
        if parts.count == 4, parts[3] == "work-items", method == "POST" {
            guard let key = request.value(forHTTPHeaderField: "Idempotency-Key"), !key.isEmpty,
                  let body = Self.jsonPayload(request), let title = body["title"] as? String else {
                return (400, Data(#"{"error":{"code":"invalid_argument","message":"Invalid local work-item create request"}}"#.utf8))
            }
            if ProcessInfo.processInfo.arguments.contains(workItemCreateFailureFixtureLaunchArgument) {
                return (409, Data(#"{"error":{"code":"conflict","message":"Synthetic work-item creation conflict"}}"#.utf8))
            }
            workItemFixtureLock.lock(); defer { workItemFixtureLock.unlock() }
            if let existing = workItemFixtureRows.first(where: { $0["id"] as? String == "j1000003" }) { return (200, json(existing)) }
            let unassigned = body["unassigned"] as? Bool == true
            let item = workItemFixtureRow(id: "j1000003", projectID: projectID, title: title,
                description: body["description"] as? String ?? "",
                assigneeID: unassigned ? nil : "u0000001",
                category: body["category"] as? String ?? "unclassified")
            workItemFixtureRows.append(item)
            return (200, json(item))
        }
        if parts.count == 6, parts[3] == "work-items", method == "POST" {
            let itemID = parts[4], action = parts[5]
            guard request.value(forHTTPHeaderField: "Idempotency-Key")?.isEmpty == false else {
                return (400, Data(#"{"error":{"code":"invalid_argument","message":"Local work-item action is missing its idempotency key"}}"#.utf8))
            }
            guard let body = Self.jsonPayload(request) else {
                return (400, Data(#"{"error":{"code":"invalid_argument","message":"Local work-item action has an invalid JSON body"}}"#.utf8))
            }
            guard let expected = body["expected_version"] as? Int else {
                return (400, Data(#"{"error":{"code":"invalid_argument","message":"Local work-item action is missing expected_version"}}"#.utf8))
            }
            if action == "claim" {
                guard projectID == "j0000001" else {
                    return (403, Data(#"{"error":{"code":"forbidden","message":"本地只读项目不可认领"}}"#.utf8))
                }
                let updated = mutateWorkItemFixtureItem(id: itemID, expectedVersion: expected, matching: {
                    $0["project_id"] as? String == projectID && $0["assignee_id"] is NSNull &&
                        $0["state"] as? String != "delivered"
                }) { current in
                    var next = current
                    next["assignee_id"] = "u0000001"
                    return next
                }
                guard let updated, !(updated["assignee_id"] is NSNull) else {
                    return (409, Data(#"{"error":{"code":"conflict","message":"本地版本冲突"}}"#.utf8))
                }
                return (200, json(updated))
            }
            if action == "block", shouldConflictWorkItemBlock() {
                return (409, Data(#"{"error":{"code":"conflict","message":"本地版本冲突"}}"#.utf8))
            }
            let updated = mutateWorkItemFixtureItem(id: itemID, expectedVersion: expected) { current in
                var next = current
                switch action {
                case "block": next["state"] = "blocked"; next["blocked_reason"] = body["blocked_reason"] as? String ?? ""
                case "resume": next["state"] = "open"; next["blocked_reason"] = ""
                case "tasks":
                    var ids = current["task_ids"] as? [String] ?? []
                    if let taskID = body["task_id"] as? String, !ids.contains(taskID) { ids.append(taskID) }
                    next["task_ids"] = ids
                case "delivery":
                    next["state"] = "delivered"
                    next["delivery"] = ["task_id": body["task_id"] as? String ?? "",
                                        "workspace_id": body["workspace_id"] as? String ?? "",
                                        "revision": body["revision"] as? Int ?? 0]
                default: break
                }
                return next
            }
            guard let updated else { return (409, Data(#"{"error":{"code":"conflict","message":"本地版本冲突"}}"#.utf8)) }
            return (200, json(updated))
        }
        return nil
    }

    override class func canInit(with request: URLRequest) -> Bool {
        usesLocalFixture && request.url?.scheme == "https"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.initializeWorkItemFixtureIfNeeded()
        let isPortal = request.url?.host == "portal.120.25.178.93.sslip.io"
        let requestCursor = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?
            .queryItems?.first(where: { $0.name == "cursor" })?.value
        let shouldDelayResponse = isPortal &&
            ProcessInfo.processInfo.arguments.contains(Self.delayedAccountResponseFixtureLaunchArgument) &&
            Self.isAccountA(request) && request.httpMethod == "GET" &&
            request.url?.path == "/api/tasks" && requestCursor == "late-account-a-page"
        let shouldDelayChatResponse = isPortal &&
            ProcessInfo.processInfo.arguments.contains(Self.delayedAccountChatResponseFixtureLaunchArgument) &&
            Self.isAccountA(request) && request.httpMethod == "GET" &&
            request.url?.path == "/api/conversations/c0000003/messages"
        var statusCode = 200
        var shouldLoseTaskPagesApprovalResponse = false
        var shouldLoseTaskPagesActionResponse = false
        var shouldDelayTaskPagesApprovalResponse = false
        var shouldDelayTaskPagesActionResponse = false
        var shouldDelayTaskTabLifecycleEvent = false
        let workItemResponse = Self.workItemFixtureResponse(for: request)
        let resourceResponse = Self.resourceFixtureResponse(for: request)
        let body: Data
        var mediaResponseHeaders: [String: String] = [:]
        if isPortal, request.url?.path == "/api/auth/client-login",
           ProcessInfo.processInfo.arguments.contains(Self.workItemFixtureLaunchArgument) {
            Self.resetWorkItemFixture()
        }
        if isPortal, request.url?.path == "/api/auth/client-login",
           ProcessInfo.processInfo.arguments.contains(Self.mainChatFixtureLaunchArgument) {
            Self.resetMainChatFixture()
        }
        if isPortal, request.url?.path == "/api/auth/client-login",
           ProcessInfo.processInfo.arguments.contains(Self.chatAttachmentFixtureLaunchArgument) {
            Self.resetChatAttachmentFixture()
        }
        if isPortal, request.url?.path == "/api/auth/client-login",
           ProcessInfo.processInfo.arguments.contains("-morde.localExecutionFixture") {
            Self.resetExecutionFixture()
        }
        let personalAttachmentDownloadResponse = isPortal ? Self.personalAttachmentDownloadFixtureResponse(for: request) : nil
        let chatAttachmentResponse = isPortal ? Self.chatAttachmentFixtureResponse(for: request) : nil
        let executionResponse = isPortal ? Self.executionFixtureResponse(for: request) : nil
        if executionResponse?.status == -1 {
            client?.urlProtocol(self, didFailWithError: URLError(.networkConnectionLost))
            return
        }
        if let personalAttachmentDownloadResponse {
            statusCode = personalAttachmentDownloadResponse.status
            body = personalAttachmentDownloadResponse.body
            mediaResponseHeaders = personalAttachmentDownloadResponse.headers
        } else if let chatAttachmentResponse {
            statusCode = chatAttachmentResponse.status
            body = chatAttachmentResponse.body
        } else if let executionResponse {
            statusCode = executionResponse.status
            body = executionResponse.body
        } else if let resourceResponse {
            statusCode = resourceResponse.status
            body = resourceResponse.body
        } else if let workItemResponse {
            statusCode = workItemResponse.status
            body = workItemResponse.body
        } else if isPortal, request.url?.path == "/api/auth/client-web-session", request.httpMethod == "POST" {
            body = Data(#"{"web_session_credential":"chs_t1234567_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA","web_session_expires_at":"2100-01-01T00:00:00Z"}"#.utf8)
        } else if isPortal, request.url?.path == "/api/auth/register", request.httpMethod == "POST",
           request.value(forHTTPHeaderField: "Content-Type") == "application/json" {
            if ProcessInfo.processInfo.arguments.contains("-morde.localRegistrationBusyFixture") {
                let attempt = Self.nextRegistrationFixtureRequest()
                // nanoMuse: Keep the fake response pending so a rapid second tap exercises busy.
                Thread.sleep(forTimeInterval: attempt == 1 ? 1 : 2)
                if attempt == 1 {
                    statusCode = 201
                    body = Data(#"{"user":{"id":"u_localtest1","status":"pending"}}"#.utf8)
                } else {
                    statusCode = 409
                    body = Data(#"{"error":{"code":"conflict","message":"Duplicate local registration request detected","details":{}}}"#.utf8)
                }
            } else {
                statusCode = 201
                body = Data(#"{"user":{"id":"u_localtest1","status":"pending"}}"#.utf8)
            }
        } else if isPortal, request.url?.path == "/api/capabilities", request.httpMethod == "GET" {
            statusCode = 200
            if ProcessInfo.processInfo.arguments.contains(Self.hubFixtureLaunchArgument) {
                body = Data(#"{"service_instance_id":"00000000-0000-0000-0000-000000000001","api_version":"1","hub_version":"1","supported_features":["password_login","client_installations","ordered_client_login","hub"]}"#.utf8)
            } else {
                if ProcessInfo.processInfo.arguments.contains(Self.taskArtifactPreviewFixtureLaunchArgument) {
                    body = Data(#"{"service_instance_id":"00000000-0000-0000-0000-000000000001","api_version":"1","supported_features":["password_login","client_installations","ordered_client_login","task_api","cloud_tasks","workspace_sync"]}"#.utf8)
                } else if ProcessInfo.processInfo.arguments.contains(Self.resourceAcceptanceFixtureLaunchArgument) {
                    body = Data(#"{"service_instance_id":"00000000-0000-0000-0000-000000000001","api_version":"1","supported_features":["password_login","client_installations","ordered_client_login","workspace_sync"]}"#.utf8)
                } else if ProcessInfo.processInfo.arguments.contains(Self.taskMediaFixtureLaunchArgument) {
                    body = ProcessInfo.processInfo.arguments.contains(Self.taskMediaCapabilityDisabledFixtureLaunchArgument)
                        ? Data(#"{"service_instance_id":"00000000-0000-0000-0000-000000000001","api_version":"1","supported_features":["password_login","client_installations","ordered_client_login","task_api","cloud_tasks"]}"#.utf8)
                        : Data(#"{"service_instance_id":"00000000-0000-0000-0000-000000000001","api_version":"1","supported_features":["password_login","client_installations","ordered_client_login","task_api","cloud_tasks","task_media_generation"]}"#.utf8)
                } else if ProcessInfo.processInfo.arguments.contains(Self.taskPagesTaskActionServiceInstanceFixtureLaunchArgument),
                          Self.taskPagesTaskActionServiceInstanceChangedSnapshot {
                    body = Data(#"{"service_instance_id":"00000000-0000-0000-0000-000000000002","api_version":"1","supported_features":["password_login","client_installations","ordered_client_login","task_api"]}"#.utf8)
                } else if ProcessInfo.processInfo.arguments.contains(Self.mainChatFixtureLaunchArgument) {
                    body = Data(#"{"service_instance_id":"00000000-0000-0000-0000-000000000001","api_version":"1","supported_features":["password_login","client_installations","ordered_client_login","task_api"]}"#.utf8)
                } else if ProcessInfo.processInfo.arguments.contains(Self.taskSSEFixtureLaunchArgument) ||
                            ProcessInfo.processInfo.arguments.contains(Self.taskPagesFixtureLaunchArgument) {
                    body = Data(#"{"service_instance_id":"00000000-0000-0000-0000-000000000001","api_version":"1","supported_features":["password_login","client_installations","ordered_client_login","task_api"]}"#.utf8)
                } else if ProcessInfo.processInfo.arguments.contains(Self.accountIsolationFixtureLaunchArgument) {
                    body = Data(#"{"service_instance_id":"00000000-0000-0000-0000-000000000001","api_version":"1","supported_features":["password_login","client_installations","ordered_client_login","task_api"]}"#.utf8)
                } else {
                    body = Data(#"{"service_instance_id":"00000000-0000-0000-0000-000000000001","api_version":"1","supported_features":["password_login","client_installations","ordered_client_login"]}"#.utf8)
                }
            }
        } else if isPortal, request.url?.path == "/api/workspaces/wabc1234/manifest",
                  request.httpMethod == "GET",
                  ProcessInfo.processInfo.arguments.contains(Self.taskArtifactPreviewFixtureLaunchArgument) {
            let revision = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?
                .queryItems?.first(where: { $0.name == "revision" })?.value
            if revision == "3", let manifest = Self.taskArtifactPreviewManifest() {
                statusCode = 200
                body = manifest
            } else {
                statusCode = 404
                body = Data(#"{"error":{"code":"not_found","message":"Local artifact manifest not found"}}"#.utf8)
            }
        } else if isPortal, request.url?.path == "/api/tasks/q1234567/media/o1234567/preview",
                  request.httpMethod == "GET",
                  ProcessInfo.processInfo.arguments.contains(Self.taskMediaFixtureLaunchArgument) {
            statusCode = 200
            body = Self.taskMediaFixturePNG
            mediaResponseHeaders = ["Content-Type": "image/png", "Cache-Control": "private, no-store",
                                    "X-Content-Type-Options": "nosniff"]
        } else if isPortal, request.url?.path == "/api/auth/client-login", request.httpMethod == "POST" {
            if ProcessInfo.processInfo.arguments.contains(Self.approvedLaunchArgument) {
                statusCode = 200
                if ProcessInfo.processInfo.arguments.contains(Self.accountIsolationFixtureLaunchArgument) {
                    let isAccountA = request.value(forHTTPHeaderField: "X-Morde-Local-Account") == "account-a"
                    let installationID = isAccountA ? "i0000001" : "i0000002"
                    let credential = isAccountA ? "local-account-a-credential" : "local-account-b-credential"
                    body = Data("{\"installation_id\":\"\(installationID)\",\"client_credential\":\"\(credential)\",\"client_expires_at\":\"2100-01-01T00:00:00Z\"}".utf8)
                } else {
                    if ProcessInfo.processInfo.arguments.contains(Self.taskSSEFixtureLaunchArgument) ||
                        (ProcessInfo.processInfo.arguments.contains(Self.taskPagesFixtureLaunchArgument) &&
                         !ProcessInfo.processInfo.arguments.contains(Self.taskPagesTaskActionServiceInstanceFixtureLaunchArgument)) ||
                        ProcessInfo.processInfo.arguments.contains(Self.taskPagesApprovalUnknownRetryFixtureLaunchArgument) ||
                        ProcessInfo.processInfo.arguments.contains(Self.taskPagesApprovalRetryWithoutCommitFixtureLaunchArgument) ||
                        ProcessInfo.processInfo.arguments.contains(Self.taskPagesApprovalDelayFixtureLaunchArgument) ||
                        ProcessInfo.processInfo.arguments.contains(Self.taskPagesTimelineRecoveryFixtureLaunchArgument) ||
                        ProcessInfo.processInfo.arguments.contains(Self.taskPagesTimelinePermissionFixtureLaunchArgument) ||
                        ProcessInfo.processInfo.arguments.contains(Self.taskPagesTaskActionDelayFixtureLaunchArgument) ||
                        ProcessInfo.processInfo.arguments.contains(Self.taskPagesTaskActionUnknownRetryFixtureLaunchArgument) ||
                        (ProcessInfo.processInfo.arguments.contains(Self.taskPagesTaskActionServiceInstanceFixtureLaunchArgument) &&
                         !Self.taskPagesTaskActionServiceInstanceChangedSnapshot) {
                        Self.resetTaskFixture()
                    }
                    if ProcessInfo.processInfo.arguments.contains(Self.chatAttachmentFixtureLaunchArgument),
                       let login = Self.jsonPayload(request), let accountName = login["name"] as? String {
                        let suffix = String(SHA256.hash(data: Data(accountName.utf8))
                            .map { String(format: "%02x", $0) }.joined().prefix(7))
                        body = Data("{\"installation_id\":\"i\(suffix)\",\"client_credential\":\"local-client-credential\",\"client_expires_at\":\"2100-01-01T00:00:00Z\"}".utf8)
                    } else if ProcessInfo.processInfo.arguments.contains(Self.taskPagesTaskActionServiceInstanceFixtureLaunchArgument),
                       Self.taskPagesTaskActionServiceInstanceChangedSnapshot {
                        body = Data(#"{"installation_id":"i0000002","client_credential":"local-task-instance-2-credential","client_expires_at":"2100-01-01T00:00:00Z"}"#.utf8)
                    } else {
                        body = Data(#"{"installation_id":"i0000001","client_credential":"local-client-credential","client_expires_at":"2100-01-01T00:00:00Z"}"#.utf8)
                    }
                }
            } else if ProcessInfo.processInfo.arguments.contains("-morde.localRegistrationRejected") {
                statusCode = 403
                body = Data(#"{"error":{"code":"account_rejected","message":"account review was not approved"}}"#.utf8)
            } else if ProcessInfo.processInfo.arguments.contains("-morde.localRegistrationDisabled") {
                statusCode = 403
                body = Data(#"{"error":{"code":"account_disabled","message":"account is disabled"}}"#.utf8)
            } else {
                statusCode = 403
                body = Data(#"{"error":{"code":"account_pending","message":"account is awaiting administrator review"}}"#.utf8)
            }
        } else if isPortal, request.url?.path == "/api/auth/client-logout", request.httpMethod == "POST" {
            statusCode = 200
            body = Data("{}".utf8)
        } else if isPortal, ProcessInfo.processInfo.arguments.contains(Self.hubFixtureLaunchArgument),
                  ["/api/clients", "/api/devices"].contains(request.url?.path ?? ""), request.httpMethod == "GET" {
            statusCode = 200
            if request.url?.path == "/api/clients" {
                body = Data(#"{"items":[],"next_cursor":null}"#.utf8)
            } else {
                body = Data(#"{"items":[{"id":"i0000001","display_name":"This iPhone","platform":"ios","expires_at":"2100-01-01T00:00:00Z","revoked":false,"created_at":"2026-01-01T00:00:00Z","last_used_at":null,"online":true},{"id":"i7654321","display_name":"Local test device","platform":"desktop","expires_at":"2100-01-01T00:00:00Z","revoked":false,"created_at":"2026-01-01T00:00:00Z","last_used_at":null,"online":true},{"id":"i7654322","display_name":"Revoked local device","platform":"desktop","expires_at":"2100-01-01T00:00:00Z","revoked":true,"created_at":"2026-01-01T00:00:00Z","last_used_at":null,"online":true}]}"#.utf8)
            }
        } else if isPortal, request.url?.path == "/api/me", request.httpMethod == "GET" {
            statusCode = 200
            if ProcessInfo.processInfo.arguments.contains(Self.accountIsolationFixtureLaunchArgument) {
                body = Self.isAccountA(request)
                    ? Data(#"{"id":"u_accounta1","name":"account-a"}"#.utf8)
                    : Data(#"{"id":"u_accountb1","name":"account-b"}"#.utf8)
            } else if ProcessInfo.processInfo.arguments.contains(Self.resourceAcceptanceFixtureLaunchArgument) {
                body = Data(#"{"id":"u0000001","name":"Local resource user"}"#.utf8)
            } else {
                body = Data(#"{"id":"u_localtest1","name":"morde-test-user"}"#.utf8)
            }
        } else if isPortal, request.url?.path == "/api/me/preferences", request.httpMethod == "GET" {
            if ProcessInfo.processInfo.arguments.contains(Self.resourceDefaultHostPreferenceFailureFixtureLaunchArgument) {
                statusCode = 503
                body = Data(#"{"error":{"code":"unavailable","message":"Synthetic preference service unavailable"}}"#.utf8)
            } else {
                statusCode = 200
                body = Data(#"{"assistant_name":"morde","selected_model_id":null,"default_host_id":null,"updated_at":null}"#.utf8)
            }
        } else if isPortal, request.url?.path == "/api/model-connections", request.httpMethod == "GET" {
            statusCode = 200
            let needsModelFixture = ProcessInfo.processInfo.arguments.contains(Self.mainChatFixtureLaunchArgument) ||
                ProcessInfo.processInfo.arguments.contains(Self.noAdminModelFixtureLaunchArgument) ||
                ProcessInfo.processInfo.arguments.contains(Self.taskSequentialSendFixtureLaunchArgument) ||
                ProcessInfo.processInfo.arguments.contains(Self.taskQueueFixtureLaunchArgument) ||
                ProcessInfo.processInfo.arguments.contains(Self.taskTabLifecycleFixtureLaunchArgument)
            body = ProcessInfo.processInfo.arguments.contains(Self.noAdminModelFixtureLaunchArgument)
                ? Data(#"{"items":[{"id":"p3456789","shared":true,"checked_at":"2026-11-05T00:00:00Z"},{"id":"p2345678","shared":false,"checked_at":"2026-11-05T00:00:00Z"}]}"#.utf8)
                : needsModelFixture
                    ? Data(#"{"items":[{"id":"p1234567","shared":true,"checked_at":"2026-11-05T00:00:00Z"},{"id":"p3456789","shared":true,"checked_at":"2026-11-05T00:00:00Z"},{"id":"p2345678","shared":false,"checked_at":"2026-11-05T00:00:00Z"}]}"#.utf8)
                : Data(#"{"items":[]}"#.utf8)
        } else if isPortal, request.url?.path == "/api/personal-data/history/import", request.httpMethod == "POST",
                  ProcessInfo.processInfo.arguments.contains(Self.historyImportFixtureLaunchArgument) {
            let payload = Self.jsonPayload(request)
            let imported = payload?["messages"] as? [[String: Any]] ?? []
            let expected: [(String, String)] = [("user", "Local import message"),
                                                ("assistant", "Local import reply")]
            let validPayload = request.value(forHTTPHeaderField: "Authorization") == "Bearer local-client-credential" &&
                payload?["source_id"] as? String == MordePersonalHistoryImportContract.sourceID &&
                (payload?["device_account_id"] as? String)?.isEmpty == false &&
                (payload?["source_conversation_id"] as? String)?.isEmpty == false &&
                payload?["title"] as? String == "Local import fixture conversation" &&
                imported.count == expected.count && zip(imported, expected).allSatisfy { message, expected in
                    message["role"] as? String == expected.0 && message["content"] as? String == expected.1 &&
                    (message["source_message_id"] as? String)?.isEmpty == false &&
                    message["attachment_ids"] == nil
                }
            if validPayload {
                body = (try? JSONSerialization.data(withJSONObject: [
                    "conversation_id": "c7654321", "title": "Local import fixture conversation", "replay": false,
                    "messages": zip(imported, expected).enumerated().map { index, entry in
                        ["source_message_id": entry.0["source_message_id"] ?? "",
                         "message_id": String(format: "m%07d", index + 1),
                         "conversation_id": "c7654321", "role": entry.1.0, "content": entry.1.1,
                         "sequence": index + 1, "attachment_ids": [String](), "replay": false] as [String: Any]
                    },
                ])) ?? Data()
            } else {
                statusCode = 400
                body = Data(#"{"error":{"code":"invalid_argument","message":"History fixture accepts only the selected user and assistant text"}}"#.utf8)
            }
        } else if isPortal, request.url?.path.hasPrefix("/api/tasks/") == true,
                  request.url?.path.hasSuffix("/events") == true, request.httpMethod == "GET",
                  ProcessInfo.processInfo.arguments.contains(Self.taskPagesFixtureLaunchArgument),
                  ProcessInfo.processInfo.arguments.contains(Self.taskPagesTimelinePermissionFixtureLaunchArgument) {
            statusCode = 403
            body = Data(#"{"error":{"code":"forbidden","message":"Local task access was revoked"}}"#.utf8)
        } else if isPortal, request.url?.path == "/api/tasks/q0000101/events", request.httpMethod == "GET",
                  ProcessInfo.processInfo.arguments.contains(Self.taskPagesFixtureLaunchArgument),
                  (ProcessInfo.processInfo.arguments.contains(Self.taskPagesTimelineRecoveryFixtureLaunchArgument) ||
                   ProcessInfo.processInfo.arguments.contains(Self.taskPagesEventChainTimelineFixtureLaunchArgument)) {
            let requestCount = Self.markTaskFixtureEvent()
            let after = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?.queryItems?
                .first(where: { $0.name == "after" })?.value
            if requestCount == 1 {
                statusCode = 500
                body = Data(#"{"error":{"code":"unavailable","message":"Local task event connection interrupted"}}"#.utf8)
            } else if after == "8" {
                statusCode = 200
                let event = #"{"task_id":"q0000101","sequence":9,"type":"task.step","created_at":"2026-11-04T00:00:09Z","payload":{"kind":"agent","status":"succeeded","title":"Recovered event","summary":"Recovered after the latest task snapshot."}}"#
                body = Data("id: 9\nevent: task.step\ndata: \(event)\n\nid: 9\nevent: task.step\ndata: \(event)\n\n".utf8)
            } else if after == "9" {
                statusCode = 204
                body = Data()
            } else {
                statusCode = 200
                body = Data("id: 8\nevent: task.snapshot_required\ndata: {\"sequence\":8}\n\n".utf8)
            }
        } else if isPortal, request.url?.path.hasPrefix("/api/tasks/") == true,
                  request.url?.path.hasSuffix("/events") == true, request.httpMethod == "GET",
                  ProcessInfo.processInfo.arguments.contains(Self.taskPagesFixtureLaunchArgument) {
            let path = request.url?.path ?? ""
            let after = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?.queryItems?
                .first(where: { $0.name == "after" })?.value.flatMap(Int64.init) ?? 0
            if path == "/api/tasks/q0000001/events", after < 2 {
                statusCode = 200
                let step = #"{"task_id":"q0000001","sequence":1,"type":"task.step","created_at":"2026-11-04T00:00:01Z","payload":{"kind":"agent","status":"succeeded","title":"Local event fixture","summary":"A safe event from the synthetic stream."}}"#
                let budget = #"{"task_id":"q0000001","sequence":2,"type":"task.step","created_at":"2026-11-04T00:00:02Z","payload":{"kind":"budget","status":"succeeded","title":"Private budget field","summary":"This must never be shown."}}"#
                body = Data("id: 1\nevent: task.step\ndata: \(step)\n\nid: 2\nevent: task.step\ndata: \(budget)\n\n".utf8)
            } else if path == "/api/tasks/q0000001/events" {
                statusCode = 204
                body = Data()
            } else {
                statusCode = 204
                body = Data()
            }
        } else if isPortal, request.url?.path == "/api/tasks/q1234567/events", request.httpMethod == "GET",
                  (ProcessInfo.processInfo.arguments.contains(Self.taskSSEFixtureLaunchArgument) ||
                   ProcessInfo.processInfo.arguments.contains(Self.taskMediaFixtureLaunchArgument) ||
                   ProcessInfo.processInfo.arguments.contains(Self.taskTabLifecycleFixtureLaunchArgument)) {
            if ProcessInfo.processInfo.arguments.contains(Self.taskQueueFixtureLaunchArgument) {
                statusCode = 204
                body = Data()
            } else if ProcessInfo.processInfo.arguments.contains(Self.taskTabLifecycleFixtureLaunchArgument) {
                if Self.beginTaskTabLifecycleEvent() {
                    statusCode = 200
                    let payload = #"{"task_id":"q1234567","sequence":2,"type":"task.status","created_at":"2026-11-05T00:00:02Z","payload":{"status":"completed"}}"#
                    body = Data("id: 2\nevent: task.status\ndata: \(payload)\n\n".utf8)
                    shouldDelayTaskTabLifecycleEvent = true
                } else {
                    statusCode = 204
                    body = Data()
                }
            } else if ProcessInfo.processInfo.arguments.contains(Self.taskMediaFixtureLaunchArgument) ||
                ProcessInfo.processInfo.arguments.contains(Self.unknownTaskStatusFixtureLaunchArgument) ||
                ProcessInfo.processInfo.arguments.contains(Self.taskRelaunchFixtureLaunchArgument) ||
                ProcessInfo.processInfo.arguments.contains(Self.taskApprovalConflictFixtureLaunchArgument) ||
                ProcessInfo.processInfo.arguments.contains(Self.taskSequentialSendFixtureLaunchArgument) {
                statusCode = 204
                body = Data()
            } else {
                let eventCount = Self.markTaskFixtureEvent()
                let snapshotRequiredFixture = ProcessInfo.processInfo.arguments.contains(Self.taskSnapshotRequiredFixtureLaunchArgument)
                let resumedAfterSnapshot = request.url.flatMap {
                    URLComponents(url: $0, resolvingAgainstBaseURL: false)
                }?.queryItems?.first(where: { $0.name == "after" })?.value == "8"
                let disconnectRecoveryFixture = ProcessInfo.processInfo.arguments.contains(Self.taskDisconnectRecoveryFixtureLaunchArgument)
                if disconnectRecoveryFixture && eventCount == 1 {
                    statusCode = 500
                    body = Data(#"{"error":{"code":"unavailable","message":"Local SSE connection interrupted"}}"#.utf8)
                } else if snapshotRequiredFixture && eventCount > 1 && !resumedAfterSnapshot {
                    statusCode = 400
                    body = Data(#"{"error":{"code":"invalid_argument","message":"Expected cursor after snapshot sequence 8","details":{}}}"#.utf8)
                } else {
                    statusCode = 200
                    // nanoMuse: Mirror the server's in-band expired-cursor recovery frame locally.
                    if snapshotRequiredFixture && eventCount == 1 {
                        body = Data("id: 8\nevent: task.snapshot_required\ndata: {\"sequence\":8}\n\n".utf8)
                    } else if snapshotRequiredFixture {
                        let payload = #"{"task_id":"q1234567","sequence":9,"type":"task.status","created_at":"2026-11-04T00:00:09Z","payload":{"status":"completed"}}"#
                        body = Data("id: 9\nevent: task.status\ndata: \(payload)\n\n".utf8)
                    } else {
                        let payload = #"{"task_id":"q1234567","sequence":2,"type":"task.status","created_at":"2026-11-04T00:00:02Z","payload":{"status":"completed"}}"#
                        body = Data("id: 2\nevent: task.status\ndata: \(payload)\n\n".utf8)
                    }
                }
            }
        } else if isPortal, request.url?.path == "/api/tasks/q2345678/events", request.httpMethod == "GET",
                  ProcessInfo.processInfo.arguments.contains(Self.taskSequentialSendFixtureLaunchArgument) {
            statusCode = 204
            body = Data()
        } else if isPortal, request.url?.path.hasPrefix("/api/tasks/") == true,
                  request.url?.path.hasSuffix("/events") == true, request.httpMethod == "GET",
                  ProcessInfo.processInfo.arguments.contains(Self.accountIsolationFixtureLaunchArgument) {
            let isAccountA = Self.isAccountA(request)
            let expectedTaskID = isAccountA ? "q0000001" : "q0000002"
            if request.url?.path == "/api/tasks/\(expectedTaskID)/events" {
                statusCode = 204
                body = Data()
            } else {
                statusCode = 403
                body = Data(#"{"error":{"code":"forbidden","message":"Task belongs to another local fixture account"}}"#.utf8)
            }
        } else if isPortal, request.url?.path == "/api/tasks/q0000001/actions",
                  request.httpMethod == "POST",
                  (ProcessInfo.processInfo.arguments.contains(Self.taskPagesTaskActionDelayFixtureLaunchArgument) ||
                   ProcessInfo.processInfo.arguments.contains(Self.taskPagesTaskActionUnknownRetryFixtureLaunchArgument) ||
                   ProcessInfo.processInfo.arguments.contains(Self.taskPagesTaskActionServiceInstanceFixtureLaunchArgument)) {
            let unknownRetry = ProcessInfo.processInfo.arguments.contains(Self.taskPagesTaskActionUnknownRetryFixtureLaunchArgument)
            let serviceInstanceChange = ProcessInfo.processInfo.arguments.contains(Self.taskPagesTaskActionServiceInstanceFixtureLaunchArgument)
            let response = Self.taskPagesTaskActionResponse(
                key: request.value(forHTTPHeaderField: "Idempotency-Key"),
                payload: Self.jsonPayload(request), unknownRetry: unknownRetry,
                serviceInstanceChange: serviceInstanceChange)
            statusCode = response.status
            body = response.body
            shouldLoseTaskPagesActionResponse = response.shouldLoseResponse
            shouldDelayTaskPagesActionResponse = response.shouldDelayResponse
        } else if isPortal, request.url?.path == "/api/tasks/q0000101/approvals/r0000001/responses",
                  request.httpMethod == "POST",
                  ProcessInfo.processInfo.arguments.contains(Self.taskPagesApprovalDelayFixtureLaunchArgument) {
            let payload = Self.jsonPayload(request)
            if request.value(forHTTPHeaderField: "Idempotency-Key")?.isEmpty == false,
               payload?["version"] as? Int == 1,
               let decision = payload?["decision"] as? String,
               ["approve", "reject"].contains(decision) {
                Self.setTaskPagesApprovalDecision(decision)
                statusCode = 202
                body = Data(#"{"task_id":"q0000101","action":"approval_response","status":"completed","unsettled_operation_ids":[]}"#.utf8)
                shouldDelayTaskPagesApprovalResponse = true
            } else {
                statusCode = 409
                body = Data(#"{"error":{"code":"conflict","message":"Invalid local approval request"}}"#.utf8)
            }
        } else if isPortal, request.url?.path == "/api/tasks/q0000101/approvals/r0000001/responses",
                  request.httpMethod == "POST",
                  ProcessInfo.processInfo.arguments.contains(Self.taskPagesApprovalRefreshPendingFixtureLaunchArgument) {
            let payload = Self.jsonPayload(request)
            if request.value(forHTTPHeaderField: "Idempotency-Key")?.isEmpty == false,
               payload?["version"] as? Int == 1,
               ["approve", "reject"].contains(payload?["decision"] as? String ?? "") {
                statusCode = 202
                body = Data(#"{"task_id":"q0000101","action":"approval_response","status":"completed","unsettled_operation_ids":[]}"#.utf8)
            } else {
                statusCode = 409
                body = Data(#"{"error":{"code":"conflict","message":"Invalid local approval request"}}"#.utf8)
            }
        } else if isPortal, request.url?.path == "/api/tasks/q0000101/approvals/r0000001/responses",
                  request.httpMethod == "POST",
                  (ProcessInfo.processInfo.arguments.contains(Self.taskPagesApprovalUnknownRetryFixtureLaunchArgument) ||
                   ProcessInfo.processInfo.arguments.contains(Self.taskPagesApprovalRetryWithoutCommitFixtureLaunchArgument)) {
            let response = Self.taskPagesApprovalUnknownRetryResponse(
                key: request.value(forHTTPHeaderField: "Idempotency-Key"), payload: Self.jsonPayload(request),
                commitOnFirstAttempt: !ProcessInfo.processInfo.arguments.contains(Self.taskPagesApprovalRetryWithoutCommitFixtureLaunchArgument))
            statusCode = response.status
            body = response.body
            shouldLoseTaskPagesApprovalResponse = response.shouldLoseResponse
        } else if isPortal, request.url?.path == "/api/tasks/q0000101/approvals/r0000001/responses",
                  request.httpMethod == "POST",
                  ProcessInfo.processInfo.arguments.contains(Self.taskPagesFixtureLaunchArgument) {
            let payload = Self.jsonPayload(request)
            if payload?["version"] as? Int != 1 || !["approve", "reject"].contains(payload?["decision"] as? String ?? "") {
                statusCode = 409
                body = Data(#"{"error":{"code":"conflict","message":"Invalid local approval version"}}"#.utf8)
            } else {
                Self.setTaskPagesApprovalDecision(payload?["decision"] as? String)
                statusCode = 202
                body = Data(#"{"task_id":"q0000101","action":"approval_response","status":"completed","unsettled_operation_ids":[]}"#.utf8)
            }
        } else if isPortal, request.url?.path == "/api/tasks/q0000102/inputs", request.httpMethod == "POST",
                  ProcessInfo.processInfo.arguments.contains(Self.taskPagesFixtureLaunchArgument) {
            // nanoMuse: Validate the local clarification fixture exactly like the task input contract.
            let payload = Self.jsonPayload(request)
            let answer = (payload?["answer"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if request.value(forHTTPHeaderField: "Idempotency-Key")?.isEmpty != false ||
                payload?["clarification_id"] as? String != "r0000002" ||
                payload?["clarification_version"] as? Int != 1 || answer.isEmpty {
                statusCode = 409
                body = Data(#"{"error":{"code":"conflict","message":"Invalid local clarification response"}}"#.utf8)
            } else {
                Self.setTaskPagesClarificationAnswered()
                statusCode = 202
                body = Data(#"{"task_id":"q0000102","action":"clarification_response","status":"completed","unsettled_operation_ids":[]}"#.utf8)
            }
        } else if isPortal, request.url?.path.hasPrefix("/api/tasks/") == true,
                  let taskID = request.url?.path.split(separator: "/").last.map(String.init),
                  request.url?.path == "/api/tasks/\(taskID)", request.httpMethod == "GET",
                  taskID == "q0000102",
                  ProcessInfo.processInfo.arguments.contains(Self.taskPagesApprovalPartialFixtureLaunchArgument) {
            statusCode = 403
            body = Data(#"{"error":{"code":"forbidden","message":"Local task detail access is unavailable"}}"#.utf8)
        } else if isPortal, request.url?.path.hasPrefix("/api/tasks/") == true,
                  let taskID = request.url?.path.split(separator: "/").last.map(String.init),
                  request.url?.path == "/api/tasks/\(taskID)", request.httpMethod == "GET",
                  ProcessInfo.processInfo.arguments.contains(Self.taskPagesFixtureLaunchArgument) {
            if let task = Self.taskPagesDetail(id: taskID),
               let encoded = try? JSONSerialization.data(withJSONObject: task) {
                statusCode = 200
                body = encoded
            } else {
                statusCode = 404
                body = Data(#"{"error":{"code":"not_found","message":"Local Task fixture not found"}}"#.utf8)
            }
        } else if isPortal, ["/api/tasks/q1234567", "/api/tasks/q2345678"].contains(request.url?.path ?? ""), request.httpMethod == "GET",
                  (ProcessInfo.processInfo.arguments.contains(Self.taskSSEFixtureLaunchArgument) ||
                   ProcessInfo.processInfo.arguments.contains(Self.taskMediaFixtureLaunchArgument) ||
                   ProcessInfo.processInfo.arguments.contains(Self.taskTabLifecycleFixtureLaunchArgument)) {
            statusCode = 200
            if ProcessInfo.processInfo.arguments.contains(Self.taskQueueFixtureLaunchArgument) {
                body = (try? JSONSerialization.data(withJSONObject: Self.taskQueueFixtureTask())) ?? Data()
            } else if ProcessInfo.processInfo.arguments.contains(Self.taskTabLifecycleFixtureLaunchArgument) {
                body = (try? JSONSerialization.data(withJSONObject: Self.taskTabLifecycleTask())) ?? Data()
            } else if ProcessInfo.processInfo.arguments.contains(Self.taskMediaFixtureLaunchArgument) {
                let decision = Self.taskMediaFixtureDecisionSnapshot
                if decision == "approve" {
                    body = Data(#"{"id":"q1234567","conversation_id":"c1234567","host_id":null,"execution_location":"server","workspace_id":null,"input_revision":null,"objective":"local media fixture","status":"completed","event_sequence":2,"result":"Generated media saved in Workspace","current_step":null,"waiting_reason":null,"stop_request":null,"pending_request":null,"clarification_request":null,"batch_items":null,"updated_at":"2026-11-04T00:00:02Z"}"#.utf8)
                } else if decision == "reject" {
                    body = Data(#"{"id":"q1234567","conversation_id":"c1234567","host_id":null,"execution_location":"server","workspace_id":null,"input_revision":null,"objective":"local media fixture","status":"cancelled","event_sequence":2,"result":"Generated media discarded","current_step":null,"waiting_reason":null,"stop_request":null,"pending_request":null,"clarification_request":null,"batch_items":null,"updated_at":"2026-11-04T00:00:02Z"}"#.utf8)
                } else {
                    body = Self.taskMediaWaitingTask
                }
            } else if ProcessInfo.processInfo.arguments.contains(Self.taskSequentialSendFixtureLaunchArgument) {
                let contents = Self.taskSequentialSendContentsSnapshot
                let taskID = request.url?.lastPathComponent ?? ""
                if let index = contents.indices.first(where: { Self.taskSequentialID($0 + 1) == taskID }) {
                    let number = index + 1
                    body = (try? JSONSerialization.data(withJSONObject: Self.taskSequentialTask(number, content: contents[index]))) ?? Data()
                } else {
                    statusCode = 404
                    body = Data(#"{"error":{"code":"not_found","message":"Local sequential task not found"}}"#.utf8)
                }
            } else if ProcessInfo.processInfo.arguments.contains(Self.taskApprovalConflictFixtureLaunchArgument) {
                body = Self.didTaskApprovalConflictAction
                    ? Data(#"{"id":"q1234567","conversation_id":"c1234567","host_id":null,"execution_location":"server","workspace_id":null,"input_revision":null,"objective":"local approval conflict fixture","status":"completed","event_sequence":2,"result":"Refreshed server task state","current_step":null,"waiting_reason":null,"stop_request":null,"pending_request":null,"clarification_request":null,"batch_items":null,"updated_at":"2026-11-04T00:00:02Z"}"#.utf8)
                    : Data(#"{"id":"q1234567","conversation_id":"c1234567","host_id":null,"execution_location":"server","workspace_id":null,"input_revision":null,"objective":"local approval conflict fixture","status":"waiting_user","event_sequence":1,"result":null,"current_step":"Approval is ready","waiting_reason":"approval_required","stop_request":null,"pending_request":{"id":"r1234567","version":1,"title":"Local approval","content":"Approve the local fixture action?","impact":"The fixture will return a conflict and the updated server state."},"clarification_request":null,"batch_items":null,"updated_at":"2026-11-04T00:00:00Z"}"#.utf8)
            } else if ProcessInfo.processInfo.arguments.contains(Self.unknownTaskStatusFixtureLaunchArgument) {
                body = Data(#"{"id":"q1234567","conversation_id":"c1234567","host_id":null,"execution_location":"server","workspace_id":null,"input_revision":null,"objective":"local unknown status fixture","status":"future_status","event_sequence":1,"result":null,"current_step":null,"waiting_reason":null,"stop_request":null,"pending_request":null,"clarification_request":null,"batch_items":null,"updated_at":"2026-11-04T00:00:00Z"}"#.utf8)
            } else if Self.didTaskFixtureSeeEvent {
                let snapshotRequiredFixture = ProcessInfo.processInfo.arguments.contains(Self.taskSnapshotRequiredFixtureLaunchArgument)
                let sequence = snapshotRequiredFixture ? (Self.taskFixtureEventCountSnapshot > 1 ? 9 : 8) : 2
                let completed = !snapshotRequiredFixture || Self.taskFixtureEventCountSnapshot > 1
                let reply = snapshotRequiredFixture ? "Local snapshot-required fixture reply" :
                    (ProcessInfo.processInfo.arguments.contains(Self.taskDisconnectRecoveryFixtureLaunchArgument)
                     ? "Local disconnect recovery fixture reply" : "Local SSE fixture reply")
                if completed {
                    body = Data(#"{"id":"q1234567","conversation_id":"c1234567","host_id":null,"execution_location":"server","workspace_id":null,"input_revision":null,"objective":"local SSE fixture","status":"completed","event_sequence":\#(sequence),"result":"\#(reply)","current_step":null,"waiting_reason":null,"stop_request":null,"pending_request":null,"clarification_request":null,"batch_items":null,"updated_at":"2026-11-04T00:00:00Z","assistant_message":{"id":"m1234567","conversation_id":"c1234567","task_id":"q1234567","role":"assistant","content":"\#(reply)","status":"completed","created_at":"2026-11-04T00:00:00Z"}}"#.utf8)
                } else {
                    body = Data(#"{"id":"q1234567","conversation_id":"c1234567","host_id":null,"execution_location":"server","workspace_id":null,"input_revision":null,"objective":"local SSE fixture","status":"running","event_sequence":8,"result":null,"current_step":null,"waiting_reason":null,"stop_request":null,"pending_request":null,"clarification_request":null,"batch_items":null,"updated_at":"2026-11-04T00:00:00Z"}"#.utf8)
                }
            } else {
                body = Data(#"{"id":"q1234567","conversation_id":"c1234567","host_id":null,"execution_location":"server","workspace_id":null,"input_revision":null,"objective":"local SSE fixture","status":"running","event_sequence":1,"result":null,"current_step":null,"waiting_reason":null,"stop_request":null,"pending_request":null,"clarification_request":null,"batch_items":null,"updated_at":"2026-11-04T00:00:00Z"}"#.utf8)
            }
        } else if isPortal, request.url?.path == "/api/tasks/q1234567/approvals/r1234567/responses",
                  request.httpMethod == "POST",
                  ProcessInfo.processInfo.arguments.contains(Self.taskMediaFixtureLaunchArgument) {
            let decision = request.value(forHTTPHeaderField: "X-Morde-Local-Task-Decision") ??
                (((try? JSONSerialization.jsonObject(with: request.httpBody ?? Data())) as? [String: Any])?["decision"] as? String)
            Self.setTaskMediaFixtureDecision(decision)
            statusCode = 202
            body = Data(#"{"task_id":"q1234567","action":"approval_response","status":"waiting_user","unsettled_operation_ids":[]}"#.utf8)
        } else if isPortal, request.url?.path == "/api/tasks/q1234567/approvals/r1234567/responses",
                  request.httpMethod == "POST",
                  ProcessInfo.processInfo.arguments.contains(Self.taskApprovalConflictFixtureLaunchArgument) {
            Self.markTaskApprovalConflictAction()
            statusCode = 409
            body = Data(#"{"error":{"code":"conflict","message":"Task state changed before approval"}}"#.utf8)
        } else if isPortal, request.url?.path == "/api/conversations/c1234567/messages", request.httpMethod == "POST",
                  ProcessInfo.processInfo.arguments.contains(Self.taskQueueFixtureLaunchArgument) {
            let payload = Self.jsonPayload(request)
            let content = payload?["content"] as? String ?? ""
            let valid = payload?["expected_task_id"] as? String == "q1234567" &&
                payload?["model_id"] as? String == "p1234567" &&
                !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                request.value(forHTTPHeaderField: "Idempotency-Key")?.isEmpty == false
            if valid {
                let message: [String: Any] = [
                    "id": "m7654321", "conversation_id": "c1234567", "task_id": "q1234567",
                    "role": "user", "content": content, "status": NSNull(),
                    "delivery_status": "pending", "created_at": "2026-11-06T00:00:00Z",
                ]
                statusCode = 202
                body = (try? JSONSerialization.data(withJSONObject: [
                    "message": message, "task": Self.taskQueueFixtureTask(),
                ])) ?? Data()
            } else {
                statusCode = 400
                body = Data(#"{"error":{"code":"bad_request","message":"Queue fixture requires the active Task ID, model, and an idempotency key"}}"#.utf8)
            }
        } else if isPortal, request.url?.path == "/api/conversations/c1234567/messages", request.httpMethod == "POST",
                  ProcessInfo.processInfo.arguments.contains(Self.taskTabLifecycleFixtureLaunchArgument) {
            let payload = Self.jsonPayload(request)
            let objective = (payload?["content"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if objective.isEmpty || request.value(forHTTPHeaderField: "Idempotency-Key")?.isEmpty != false {
                statusCode = 400
                body = Data(#"{"error":{"code":"bad_request","message":"Lifecycle fixture expected content and Idempotency-Key"}}"#.utf8)
            } else {
                Self.markTaskTabLifecycleAccepted()
                let message: [String: Any] = [
                    "id": "m1234567", "conversation_id": "c1234567", "task_id": "q1234567",
                    "role": "user", "content": objective, "status": "completed",
                    "delivery_status": NSNull(), "created_at": "2026-11-05T00:00:00Z",
                ]
                statusCode = 200
                body = (try? JSONSerialization.data(withJSONObject: [
                    "message": message, "task": Self.taskTabLifecycleTask(),
                ])) ?? Data()
            }
        } else if isPortal, request.url?.path == "/api/conversations/c1234567/messages", request.httpMethod == "POST",
                  ProcessInfo.processInfo.arguments.contains(Self.taskSequentialSendFixtureLaunchArgument) {
            let content = request.value(forHTTPHeaderField: "X-Morde-Local-Task-Prompt") ?? ""
            let index = Self.recordTaskSequentialSend(content)
            if index <= 2 {
                let content = Self.taskSequentialSendContentsSnapshot[index - 1]
                let message = Self.taskSequentialMessage(index, content: content, role: "user")
                let task = Self.taskSequentialTask(index, content: content)
                statusCode = 200
                body = (try? JSONSerialization.data(withJSONObject: ["message": message, "task": task])) ?? Data()
            } else {
                statusCode = 409
                body = Data(#"{"error":{"code":"conflict","message":"Sequential fixture accepts two sends"}}"#.utf8)
            }
        } else if isPortal, request.httpMethod == "GET",
                  ProcessInfo.processInfo.arguments.contains(Self.accountIsolationFixtureLaunchArgument),
                  ["/api/tasks", "/api/tasks/q0000001", "/api/tasks/q0000002"].contains(request.url?.path ?? "") {
            let isAccountA = Self.isAccountA(request)
            let taskID = isAccountA ? "q0000001" : "q0000002"
            let conversationID = isAccountA ? "c0000001" : "c0000002"
            let marker = isAccountA ? "account-a-private-task" : "account-b-private-task"
            let task = #"{"id":"\#(taskID)","conversation_id":"\#(conversationID)","host_id":null,"execution_location":"server","workspace_id":null,"input_revision":null,"objective":"\#(marker)","status":"completed","event_sequence":1,"result":null,"current_step":null,"waiting_reason":null,"stop_request":null,"pending_request":null,"clarification_request":null,"batch_items":null,"updated_at":"2026-11-04T00:00:00Z"}"#
            let cursor = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?
                .queryItems?.first(where: { $0.name == "cursor" })?.value
            if request.url?.path == "/api/tasks", cursor == "late-account-a-page",
               Self.isAccountA(request),
               ProcessInfo.processInfo.arguments.contains(Self.delayedAccountResponseFixtureLaunchArgument) {
                let lateTask = #"{"id":"q0000003","conversation_id":"c0000001","host_id":null,"execution_location":"server","workspace_id":null,"input_revision":null,"objective":"account-a-late-private-task","status":"completed","event_sequence":1,"result":null,"current_step":null,"waiting_reason":null,"stop_request":null,"pending_request":null,"clarification_request":null,"batch_items":null,"updated_at":"2026-11-04T00:00:02Z"}"#
                statusCode = 200
                body = Data("{\"items\":[\(lateTask)],\"next_cursor\":null}".utf8)
            } else if request.url?.path == "/api/tasks" {
                statusCode = 200
                let nextCursor = Self.isAccountA(request) &&
                    ProcessInfo.processInfo.arguments.contains(Self.delayedAccountResponseFixtureLaunchArgument)
                    ? #""late-account-a-page""# : "null"
                body = Data("{\"items\":[\(task)],\"next_cursor\":\(nextCursor)}".utf8)
            } else if request.url?.path == "/api/tasks/\(taskID)" {
                statusCode = 200
                body = Data(task.utf8)
            } else {
                statusCode = 403
                body = Data(#"{"error":{"code":"forbidden","message":"Task belongs to another local fixture account"}}"#.utf8)
            }
        } else if isPortal, request.url?.path == "/api/me/main-conversation/ensure", request.httpMethod == "POST",
                  ProcessInfo.processInfo.arguments.contains(Self.mainChatFixtureLaunchArgument) {
            Self.ensureMainChatFixture()
            statusCode = 200
            body = Data(#"{"status":"ready","conversation_id":"c1234567","version":1}"#.utf8)
        } else if isPortal, request.url?.path == "/api/me/main-conversation", request.httpMethod == "GET" {
            statusCode = 200
            if ProcessInfo.processInfo.arguments.contains(Self.mainChatFixtureLaunchArgument) {
                body = Self.mainChatFixtureIsEnsured
                    ? Data(#"{"status":"ready","conversation_id":"c1234567","version":1}"#.utf8)
                    : Data(#"{"status":"uninitialized","conversation_id":"","version":0}"#.utf8)
            } else if ProcessInfo.processInfo.arguments.contains(Self.accountIsolationFixtureLaunchArgument) {
                body = Self.isAccountA(request)
                    ? Data(#"{"status":"ready","conversation_id":"c0000001","version":1}"#.utf8)
                    : Data(#"{"status":"ready","conversation_id":"c0000002","version":1}"#.utf8)
            } else {
                body = ProcessInfo.processInfo.arguments.contains(Self.taskSSEFixtureLaunchArgument) ||
                    ProcessInfo.processInfo.arguments.contains(Self.taskPagesFixtureLaunchArgument) ||
                    ProcessInfo.processInfo.arguments.contains(Self.taskMediaFixtureLaunchArgument)
                    ? Data(#"{"status":"ready","conversation_id":"c1234567","version":1}"#.utf8)
                    : Data(#"{"status":"uninitialized","conversation_id":"","version":0}"#.utf8)
            }
        } else if isPortal, request.url?.path == "/api/conversations", request.httpMethod == "POST",
                  ProcessInfo.processInfo.arguments.contains(Self.taskPagesFixtureLaunchArgument) {
            Self.setTaskPagesCreatedConversation()
            statusCode = 201
            body = Data(#"{"id":"c4567890","host_id":null,"title":"新对话","is_main":false}"#.utf8)
        } else if isPortal, request.url?.path == "/api/conversations", request.httpMethod == "GET",
                  ProcessInfo.processInfo.arguments.contains(Self.accountIsolationFixtureLaunchArgument) {
            statusCode = 200
            body = Self.isAccountA(request)
                ? Data(#"{"items":[{"id":"c0000001","host_id":null,"title":"Account A conversation","is_main":true},{"id":"c0000003","host_id":null,"title":"Account A delayed chat","is_main":false}],"next_cursor":null}"#.utf8)
                : Data(#"{"items":[{"id":"c0000002","host_id":null,"title":"Account B conversation","is_main":true}],"next_cursor":null}"#.utf8)
        } else if isPortal, request.httpMethod == "GET",
                  ["/api/conversations/c0000001/messages", "/api/conversations/c0000002/messages",
                   "/api/conversations/c0000003/messages"].contains(request.url?.path ?? ""),
                  ProcessInfo.processInfo.arguments.contains(Self.accountIsolationFixtureLaunchArgument) {
            let isAccountA = Self.isAccountA(request)
            let expectedConversation = isAccountA ? "c0000001" : "c0000002"
            if request.url?.path == "/api/conversations/\(expectedConversation)/messages" {
                statusCode = 200
                let marker = isAccountA ? "account-a" : "account-b"
                body = Data(#"{"items":[{"id":"m0000001","conversation_id":"\#(expectedConversation)","task_id":null,"role":"user","content":"\#(marker)-private-message","status":"completed","delivery_status":null,"created_at":"2026-11-04T00:00:00Z"},{"id":"m0000002","conversation_id":"\#(expectedConversation)","task_id":null,"role":"assistant","content":"\#(marker)-private-reply","status":"completed","delivery_status":null,"created_at":"2026-11-04T00:00:01Z"},{"id":"m0000003","conversation_id":"\#(expectedConversation)","task_id":null,"role":"user","content":"\#(marker)-private-message-2","status":"completed","delivery_status":null,"created_at":"2026-11-04T00:00:02Z"},{"id":"m0000004","conversation_id":"\#(expectedConversation)","task_id":null,"role":"assistant","content":"\#(marker)-private-reply-2","status":"completed","delivery_status":null,"created_at":"2026-11-04T00:00:03Z"}],"next_cursor":null}"#.utf8)
            } else if isAccountA, request.url?.path == "/api/conversations/c0000003/messages" {
                statusCode = 200
                body = Data(#"{"items":[{"id":"m0000005","conversation_id":"c0000003","task_id":null,"role":"user","content":"account-a-delayed-private-message","status":"completed","delivery_status":null,"created_at":"2026-11-04T00:00:04Z"}],"next_cursor":null}"#.utf8)
            } else {
                statusCode = 403
                body = Data(#"{"error":{"code":"forbidden","message":"Conversation belongs to another local fixture account"}}"#.utf8)
            }
        } else if isPortal, request.httpMethod == "GET",
                  ["/api/conversations/c1234567/messages", "/api/conversations/c2345678/messages"].contains(request.url?.path ?? ""),
                  ProcessInfo.processInfo.arguments.contains(Self.mainChatFixtureLaunchArgument) {
            let conversationID = request.url?.path == "/api/conversations/c1234567/messages" ? "c1234567" : "c2345678"
            if conversationID == "c1234567",
               ProcessInfo.processInfo.arguments.contains(Self.conversationHistoryPaginationFixtureLaunchArgument) {
                let cursor = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?
                    .queryItems?.first(where: { $0.name == "cursor" })?.value
                if cursor == "history-before-101" {
                    statusCode = 200
                    body = (try? JSONSerialization.data(withJSONObject: [
                        "items": Self.conversationHistoryFixtureMessages(from: 1, through: 100),
                        "next_cursor": NSNull(),
                    ])) ?? Data()
                } else if cursor == nil, Self.nextConversationHistoryFixtureInitialRequest() == 1 {
                    statusCode = 503
                    body = Data(#"{"error":{"code":"unavailable","message":"Local conversation history fixture failure"}}"#.utf8)
                } else if cursor == nil {
                    statusCode = 200
                    body = (try? JSONSerialization.data(withJSONObject: [
                        "items": Self.conversationHistoryFixtureMessages(from: 101, through: 200),
                        "next_cursor": "history-before-101",
                    ])) ?? Data()
                } else {
                    statusCode = 400
                    body = Data(#"{"error":{"code":"bad_request","message":"Unexpected local history cursor"}}"#.utf8)
                }
            } else {
                statusCode = 200
                let content = conversationID == "c1234567" ? "Main chat is ready." : "Side conversation is sidebar-only."
                body = Data("{\"items\":[{\"id\":\"m1234567\",\"conversation_id\":\"\(conversationID)\",\"task_id\":null,\"role\":\"assistant\",\"content\":\"\(content)\",\"status\":\"completed\",\"delivery_status\":null,\"created_at\":\"2026-11-05T00:00:00Z\"}],\"next_cursor\":null}".utf8)
            }
        } else if isPortal, request.url?.path == "/api/conversations/c1234567/messages", request.httpMethod == "GET",
                  ProcessInfo.processInfo.arguments.contains(Self.conversationFailureFixtureLaunchArgument) {
            statusCode = 503
            body = Data(#"{"error":{"code":"unavailable","message":"Local conversation fixture failure"}}"#.utf8)
        } else if isPortal, request.url?.path == "/api/conversations/c1234567/messages", request.httpMethod == "GET",
                  (ProcessInfo.processInfo.arguments.contains(Self.taskSSEFixtureLaunchArgument) ||
                   ProcessInfo.processInfo.arguments.contains(Self.taskPagesFixtureLaunchArgument)) {
            statusCode = 200
            if ProcessInfo.processInfo.arguments.contains(Self.taskSequentialSendFixtureLaunchArgument) {
                let contents = Self.taskSequentialSendContentsSnapshot
                var messages: [[String: Any]] = []
                for (offset, content) in contents.enumerated() {
                    let index = offset + 1
                    messages.append(Self.taskSequentialMessage(index, content: content, role: "user"))
                    messages.append(Self.taskSequentialMessage(index, content: "Local sequential reply \(index)", role: "assistant"))
                }
                body = (try? JSONSerialization.data(withJSONObject: ["items": messages, "next_cursor": NSNull()])) ?? Data()
            } else {
                body = Data(#"{"items":[],"next_cursor":null}"#.utf8)
            }
        } else if isPortal, request.httpMethod == "GET",
                  ["/api/conversations/c2345678/messages", "/api/conversations/c3456789/messages",
                   "/api/conversations/c4567890/messages"].contains(request.url?.path ?? ""),
                  ProcessInfo.processInfo.arguments.contains(Self.taskPagesFixtureLaunchArgument) {
            statusCode = 200
            body = request.url?.path == "/api/conversations/c2345678/messages"
                ? Data(#"{"items":[{"id":"m2345678","conversation_id":"c2345678","task_id":null,"role":"assistant","content":"First page chat","status":"completed","delivery_status":null,"created_at":"2026-11-04T00:00:00Z"}],"next_cursor":null}"#.utf8)
                : Data(#"{"items":[],"next_cursor":null}"#.utf8)
        } else if isPortal, request.url?.path == "/api/conversations", request.httpMethod == "GET",
                  ProcessInfo.processInfo.arguments.contains(Self.mainChatFixtureLaunchArgument),
                  // nanoMuse: The paged drawer fixture must take precedence when both fixtures are enabled.
                  !ProcessInfo.processInfo.arguments.contains(Self.taskPagesFixtureLaunchArgument) {
            statusCode = 200
            body = Data(#"{"items":[{"id":"c1234567","host_id":null,"title":"主会话","is_main":true},{"id":"c2345678","host_id":null,"title":"侧边栏历史会话","is_main":false}],"next_cursor":null}"#.utf8)
        } else if isPortal, request.url?.path == "/api/conversations", request.httpMethod == "GET",
                  (ProcessInfo.processInfo.arguments.contains(Self.taskSSEFixtureLaunchArgument) ||
                   ProcessInfo.processInfo.arguments.contains(Self.taskPagesFixtureLaunchArgument)) {
            if ProcessInfo.processInfo.arguments.contains(Self.conversationDrawerRetryFixtureLaunchArgument) &&
                Self.nextConversationDrawerListRequest() == 1 {
                statusCode = 503
                body = Data(#"{"error":{"code":"unavailable","message":"Local conversation drawer fixture failure"}}"#.utf8)
            } else if ProcessInfo.processInfo.arguments.contains(Self.taskPagesFixtureLaunchArgument) {
                statusCode = 200
                let cursor = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?
                    .queryItems?.first(where: { $0.name == "cursor" })?.value
                body = cursor == "drawer-page-2"
                    ? Data(#"{"items":[{"id":"c3456789","host_id":null,"title":"Needle match on page two","is_main":false}],"next_cursor":null}"#.utf8)
                    : Data((#"{"items":[{"id":"c1234567","host_id":null,"title":"Local SSE fixture","is_main":true},{"id":"c2345678","host_id":null,"title":"First page chat","is_main":false}"#
                        + (Self.taskPagesCreatedConversationSnapshot ? #",{"id":"c4567890","host_id":null,"title":"新对话","is_main":false}"# : "")
                        + #"],"next_cursor":"drawer-page-2"}"#).utf8)
            } else {
                statusCode = 200
                body = Data(#"{"items":[{"id":"c1234567","host_id":null,"title":"Local SSE fixture","is_main":true}],"next_cursor":null}"#.utf8)
            }
        } else if isPortal, request.url?.path == "/api/tasks", request.httpMethod == "GET",
                  ProcessInfo.processInfo.arguments.contains(Self.taskPagesRetryFixtureLaunchArgument) {
            let status = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?
                .queryItems?.first(where: { $0.name == "status" })?.value
            if status == "waiting_user" {
                statusCode = 200
                body = Data(#"{"items":[],"next_cursor":null}"#.utf8)
            } else if Self.nextTaskPagesRetryListRequest() <= 2 {
                statusCode = 503
                body = Data(#"{"error":{"code":"unavailable","message":"Local task list fixture failure"}}"#.utf8)
            } else {
                statusCode = 200
                body = Data(#"{"items":[],"next_cursor":null}"#.utf8)
            }
        } else if isPortal, request.url?.path == "/api/tasks", request.httpMethod == "GET",
                  ProcessInfo.processInfo.arguments.contains(Self.taskPagesEmptyIntermediateFixtureLaunchArgument) {
            let query = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?.queryItems ?? []
            let cursor = query.first(where: { $0.name == "cursor" })?.value
            let status = query.first(where: { $0.name == "status" })?.value
            let items = cursor == "empty-page-2" && status == nil
                ? [Self.taskPagesSummary(id: "q0000001", status: "running", objective: "Local task after an empty page")]
                : []
            let nextCursor: Any = status == nil && cursor == nil ? "empty-page-2" : NSNull()
            statusCode = 200
            body = (try? JSONSerialization.data(withJSONObject: ["items": items, "next_cursor": nextCursor])) ?? Data()
        } else if isPortal, request.url?.path == "/api/tasks", request.httpMethod == "GET",
                  ProcessInfo.processInfo.arguments.contains(Self.taskPagesEmptyFixtureLaunchArgument) {
            statusCode = 200
            body = Data(#"{"items":[],"next_cursor":null}"#.utf8)
        } else if isPortal, request.url?.path == "/api/tasks", request.httpMethod == "GET",
                  ProcessInfo.processInfo.arguments.contains(Self.taskPagesTaskDetailRequestsFixtureLaunchArgument) {
            let items = [
                Self.taskPagesSummary(id: "q0000101", status: "waiting_user", objective: "Local approval fixture"),
                Self.taskPagesSummary(id: "q0000102", status: "waiting_user", objective: "Local clarification fixture"),
            ]
            statusCode = 200
            body = (try? JSONSerialization.data(withJSONObject: ["items": items, "next_cursor": NSNull()])) ?? Data()
        } else if isPortal, request.url?.path == "/api/tasks", request.httpMethod == "GET",
                  ProcessInfo.processInfo.arguments.contains(Self.taskPagesFixtureLaunchArgument) {
            let query = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?.queryItems ?? []
            let status = query.first(where: { $0.name == "status" })?.value
            let cursor = query.first(where: { $0.name == "cursor" })?.value
            var items: [[String: Any]] = []
            var nextCursor: Any = NSNull()
            if status == "waiting_user" {
                if ProcessInfo.processInfo.arguments.contains(Self.taskPagesApprovalPartialFixtureLaunchArgument) {
                    items = [
                        Self.taskPagesSummary(id: "q0000101", status: "waiting_user", objective: "Confirmed local approval"),
                        Self.taskPagesSummary(id: "q0000102", status: "waiting_user", objective: "Unreadable local task detail"),
                    ]
                } else if ProcessInfo.processInfo.arguments.contains(Self.taskPagesApprovalPaginationFixtureLaunchArgument) {
                    if cursor == nil {
                        items.append(Self.taskPagesSummary(id: "q0000102", status: "waiting_user", objective: "Local clarification fixture"))
                        nextCursor = "approval-page-2"
                    } else if cursor == "approval-page-2", Self.taskPagesApprovalDecisionSnapshot == nil {
                        items.append(Self.taskPagesSummary(id: "q0000101", status: "waiting_user", objective: "Local approval fixture"))
                    }
                } else {
                    if Self.taskPagesApprovalDecisionSnapshot == nil {
                        items.append(Self.taskPagesSummary(id: "q0000101", status: "waiting_user", objective: "Local approval fixture"))
                    }
                    items.append(Self.taskPagesSummary(id: "q0000102", status: "waiting_user", objective: "Local clarification fixture"))
                }
            } else if status == nil, cursor == nil,
                      ProcessInfo.processInfo.arguments.contains(Self.taskPagesTimelineRecoveryFixtureLaunchArgument) ||
                        ProcessInfo.processInfo.arguments.contains(Self.taskPagesTimelinePermissionFixtureLaunchArgument) {
                var task = Self.taskPagesSummary(id: "q0000101", status: "running", objective: "Local task timeline fixture")
                task["conversation_id"] = "c7654321"
                items = [task]
            } else if status == nil, cursor == nil {
                items = (1...100).map { index in
                    let id = String(format: "q%07d", index)
                    return Self.taskPagesSummary(id: id, status: index == 1 ? "running" : "completed",
                                                 objective: index == 1 ? "Local task detail fixture" : "Local task \(index)")
                }
                nextCursor = "page-2"
            } else if status == nil, cursor == "page-2" {
                items = [
                    Self.taskPagesSummary(id: "q0000100", status: "completed", objective: "Repeated local task"),
                    Self.taskPagesSummary(id: "q0000101", status: "waiting_user", objective: "Local approval fixture"),
                    Self.taskPagesSummary(id: "q0000102", status: "waiting_user", objective: "Local clarification fixture"),
                    Self.taskPagesSummary(id: "q0000103", status: "future_status", objective: "Local unknown status fixture"),
                ]
            }
            statusCode = 200
            body = (try? JSONSerialization.data(withJSONObject: ["items": items, "next_cursor": nextCursor])) ?? Data()
        } else if isPortal, request.url?.path == "/api/tasks", request.httpMethod == "GET",
                  ProcessInfo.processInfo.arguments.contains(Self.taskSSEFixtureLaunchArgument) {
            statusCode = 200
            if ProcessInfo.processInfo.arguments.contains(Self.taskQueueFixtureLaunchArgument) {
                let task = Self.taskQueueFixtureTask()
                body = (try? JSONSerialization.data(withJSONObject: ["items": [task], "next_cursor": NSNull()])) ?? Data()
            } else if ProcessInfo.processInfo.arguments.contains(Self.taskTabLifecycleFixtureLaunchArgument) {
                let items = Self.taskTabLifecycleTaskAcceptedSnapshot ? [Self.taskTabLifecycleTask()] : []
                body = (try? JSONSerialization.data(withJSONObject: ["items": items, "next_cursor": NSNull()])) ?? Data()
            } else if ProcessInfo.processInfo.arguments.contains(Self.taskMediaFixtureLaunchArgument) {
                body = Data("{\"items\":[\(String(data: Self.taskMediaWaitingTask, encoding: .utf8) ?? "{}")],\"next_cursor\":null}".utf8)
            } else if ProcessInfo.processInfo.arguments.contains(Self.taskSequentialSendFixtureLaunchArgument) {
                let tasks = Self.taskSequentialSendContentsSnapshot.enumerated().map { index, content in
                    Self.taskSequentialTask(index + 1, content: content)
                }
                body = (try? JSONSerialization.data(withJSONObject: ["items": tasks, "next_cursor": NSNull()])) ?? Data()
            } else if ProcessInfo.processInfo.arguments.contains(Self.taskApprovalConflictFixtureLaunchArgument) {
                body = Data(#"{"items":[{"id":"q1234567","conversation_id":"c1234567","host_id":null,"execution_location":"server","workspace_id":null,"input_revision":null,"objective":"local approval conflict fixture","status":"waiting_user","event_sequence":1,"result":null,"current_step":"Approval is ready","waiting_reason":"approval_required","stop_request":null,"pending_request":{"id":"r1234567","version":1,"title":"Local approval","content":"Approve the local fixture action?","impact":"The fixture will return a conflict and the updated server state."},"clarification_request":null,"batch_items":null,"updated_at":"2026-11-04T00:00:00Z"}],"next_cursor":null}"#.utf8)
            } else if ProcessInfo.processInfo.arguments.contains(Self.unknownTaskStatusFixtureLaunchArgument) {
                body = Data(#"{"items":[{"id":"q1234567","conversation_id":"c1234567","host_id":null,"execution_location":"server","workspace_id":null,"input_revision":null,"objective":"local unknown status fixture","status":"future_status","event_sequence":1,"result":null,"current_step":null,"waiting_reason":null,"stop_request":null,"pending_request":null,"clarification_request":null,"batch_items":null,"updated_at":"2026-11-04T00:00:00Z"}],"next_cursor":null}"#.utf8)
            } else {
                body = Data(#"{"items":[{"id":"q1234567","conversation_id":"c1234567","host_id":null,"execution_location":"server","workspace_id":null,"input_revision":null,"objective":"local SSE fixture","status":"running","event_sequence":1,"result":null,"current_step":null,"waiting_reason":null,"stop_request":null,"pending_request":null,"clarification_request":null,"batch_items":null,"updated_at":"2026-11-04T00:00:00Z"}],"next_cursor":null}"#.utf8)
            }
        } else if isPortal, request.url?.path == "/api/available-models", request.httpMethod == "GET",
                  ProcessInfo.processInfo.arguments.contains(Self.mainChatFixtureLaunchArgument),
                  !ProcessInfo.processInfo.arguments.contains(Self.noAdminModelFixtureLaunchArgument) {
            statusCode = 200
            body = Data(#"{"items":[{"id":"p1234567","name":"Local Test Tool","capabilities":{"text":true,"tools":true}},{"id":"p2345678","name":"Local Personal Model","capabilities":{"text":true,"tools":true}},{"id":"p3456789","name":"Non-default shared model","capabilities":{"text":true,"tools":true}}],"default_model_configured":true,"default_model_id":"p1234567"}"#.utf8)
        } else if isPortal, request.url?.path == "/api/available-models", request.httpMethod == "GET",
                  ProcessInfo.processInfo.arguments.contains(Self.noAdminModelFixtureLaunchArgument) {
            statusCode = 200
            body = Data(#"{"items":[{"id":"p2345678","name":"Local Personal Model","capabilities":{"text":true,"tools":true}},{"id":"p3456789","name":"Non-default shared model","capabilities":{"text":true,"tools":true}}],"default_model_configured":false,"default_model_id":null}"#.utf8)
        } else if isPortal, request.url?.path == "/api/available-models", request.httpMethod == "GET",
                  (ProcessInfo.processInfo.arguments.contains(Self.taskSequentialSendFixtureLaunchArgument) ||
                   ProcessInfo.processInfo.arguments.contains(Self.taskTabLifecycleFixtureLaunchArgument)) {
            statusCode = 200
            body = Data(#"{"items":[{"id":"p1234567","name":"Local Test Tool","capabilities":{"text":true,"tools":true}}],"default_model_configured":true,"default_model_id":"p1234567"}"#.utf8)
        } else if isPortal, request.httpMethod == "GET",
                  ["/api/hosts", "/api/shared-hosts", "/api/workspaces", "/api/available-models",
                   "/api/conversations", "/api/tasks", "/api/notifications"].contains(request.url?.path ?? "") {
            statusCode = 200
            body = request.url?.path == "/api/available-models"
                ? Data(#"{"items":[],"default_model_configured":false,"default_model_id":null}"#.utf8)
                : Data(#"{"items":[],"next_cursor":null}"#.utf8)
        } else {
            statusCode = 400
            body = Data(#"{"error":{"message":"Local registration stub rejected the request"}}"#.utf8)
        }
        let contentType = mediaResponseHeaders["Content-Type"] ??
            (request.url?.path.hasSuffix("/events") == true ? "text/event-stream" : "application/json")
        var responseHeaders = ["Content-Type": contentType]
        for (name, value) in mediaResponseHeaders where name != "Content-Type" {
            responseHeaders[name] = value
        }
        if ProcessInfo.processInfo.arguments.contains(Self.taskSequentialSendFixtureLaunchArgument) {
            responseHeaders["Content-Length"] = String(body.count)
        }
        if shouldLoseTaskPagesApprovalResponse || shouldLoseTaskPagesActionResponse {
            client?.urlProtocol(self, didFailWithError: URLError(.networkConnectionLost))
            return
        }
        let shouldDelayExecutionStopResponse = isPortal && executionResponse?.status == 202 &&
            ProcessInfo.processInfo.arguments.contains(Self.executionDelayStopFixtureLaunchArgument) &&
            request.httpMethod == "POST" && request.url?.path == "/api/execution/stop-all"
        if shouldDelayResponse || shouldDelayChatResponse || shouldDelayExecutionStopResponse ||
            shouldDelayTaskPagesApprovalResponse || shouldDelayTaskPagesActionResponse || shouldDelayTaskTabLifecycleEvent {
            let delay: TimeInterval = shouldDelayTaskTabLifecycleEvent ? 4 : ((shouldDelayTaskPagesActionResponse || shouldDelayTaskPagesApprovalResponse) ? 3 :
                (shouldDelayExecutionStopResponse ? 4 : (shouldDelayChatResponse ? 25 : 12))
            )
            let workItem = DispatchWorkItem { [weak self] in
                if shouldDelayExecutionStopResponse { Self.finishExecutionFixtureStopResponse() }
                if shouldDelayTaskTabLifecycleEvent { Self.finishTaskTabLifecycleEvent() }
                self?.deliver(statusCode: statusCode, body: body, headers: responseHeaders)
            }
            delayedResponseLock.lock(); delayedResponseWorkItem = workItem; delayedResponseLock.unlock()
            DispatchQueue.global().asyncAfter(deadline: .now() + delay, execute: workItem)
            return
        }
        deliver(statusCode: statusCode, body: body, headers: responseHeaders)
    }

    private func deliver(statusCode: Int, body: Data, headers: [String: String]) {
        defer {
            delayedResponseLock.lock(); delayedResponseWorkItem = nil; delayedResponseLock.unlock()
        }
        guard let url = request.url, let response = HTTPURLResponse(url: url, statusCode: statusCode,
                                       httpVersion: "HTTP/1.1", headerFields: headers)
        else { client?.urlProtocol(self, didFailWithError: URLError(.badURL)); return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        delayedResponseLock.lock(); defer { delayedResponseLock.unlock() }
        let canceledDelayedStop = request.url?.path == "/api/execution/stop-all" && delayedResponseWorkItem != nil
        delayedResponseWorkItem?.cancel()
        delayedResponseWorkItem = nil
        if canceledDelayedStop { Self.finishExecutionFixtureStopResponse() }
    }
}
#endif

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

func isAllowedMordeHostDownload(requestURL: URL?, sourceURL: URL?, sourceIsMainFrame: Bool, relativeTo origin: URL) -> Bool {
    guard sourceIsMainFrame, isAllowedMordeHostNavigation(sourceURL, relativeTo: origin) else { return false }
    if isAllowedMordeHostNavigation(requestURL, relativeTo: origin) { return true }
    guard let requestURL, requestURL.scheme?.lowercased() == "blob",
          let blobOrigin = URL(string: String(requestURL.absoluteString.dropFirst("blob:".count))) else { return false }
    return isAllowedMordeHostNavigation(blobOrigin, relativeTo: origin)
}

func mordeHostDownloadDestination(
    suggestedFilename: String,
    directory: URL,
    reservedFilenames: Set<String> = [],
    fileExists: (URL) -> Bool = { FileManager.default.fileExists(atPath: $0.path) }
) -> URL? {
    guard directory.isFileURL else { return nil }
    let lastComponent = suggestedFilename.split(whereSeparator: { $0 == "/" || $0 == "\\" }).last.map(String.init) ?? ""
    let safeScalars = lastComponent.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) }
    var filename = String(String.UnicodeScalarView(safeScalars)).trimmingCharacters(in: .whitespacesAndNewlines)
    if filename.isEmpty || filename == "." || filename == ".." { filename = "download" }
    filename = String(filename.prefix(240))

    let reserved = Set(reservedFilenames.map { $0.folding(options: [.caseInsensitive], locale: Locale(identifier: "en_US_POSIX")) })
    let pathExtension = (filename as NSString).pathExtension
    let baseName = (filename as NSString).deletingPathExtension
    var candidateName = filename
    var suffix = 1
    var candidate = directory.appendingPathComponent(candidateName, isDirectory: false).standardizedFileURL
    while fileExists(candidate) || reserved.contains(candidateName.folding(options: [.caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))) {
        candidateName = pathExtension.isEmpty ? "\(baseName)-\(suffix)" : "\(baseName)-\(suffix).\(pathExtension)"
        candidate = directory.appendingPathComponent(candidateName, isDirectory: false).standardizedFileURL
        suffix += 1
    }
    guard candidate.deletingLastPathComponent() == directory.standardizedFileURL else { return nil }
    return candidate
}

func promoteMordeHostDownload(from partial: URL, to destination: URL) -> Bool {
    guard partial.isFileURL, destination.isFileURL,
          partial.deletingLastPathComponent().standardizedFileURL == destination.deletingLastPathComponent().standardizedFileURL else {
        return false
    }
    do {
        try FileManager.default.moveItem(at: partial, to: destination)
        return true
    } catch {
        return false
    }
}

func canStartMordeAction(busy: Bool) -> Bool { !busy }
func canRetryMordeBatchItem(taskStatus: String, itemStatus: String) -> Bool { taskStatus == "failed" && itemStatus == "failed" }

enum MordeResourceRoomSection: String, CaseIterable, Hashable, Identifiable {
    case computers
    case workspaces
    case files

    var id: String { rawValue }

    var title: String {
        switch self {
        case .computers: return "电脑"
        case .workspaces: return "Workspace"
        case .files: return "文件"
        }
    }

    var symbol: String {
        switch self {
        case .computers: return "desktopcomputer"
        case .workspaces: return "folder"
        case .files: return "doc.text"
        }
    }
}

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
// END Morde host navigation helpers

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
private struct MordeRegistrationResult: Decodable {
    struct User: Decodable { let id: String; let status: String }
    let user: User
}
private struct MordeCapabilities: Decodable {
    let service_instance_id: String
    let api_version: String
    let minimum_client_version: String?
    let hub_version: String?
    let supported_features: [String]
}
private struct MordeInstallation: Codable {
    let id: String
    let accountName: String
    let serviceOrigin: String?
    let serviceInstanceID: String?
    let accountID: String?
    let clientInstanceID: UUID?
    let revocationStatus: String?

    init(id: String, accountName: String, serviceOrigin: String? = nil, serviceInstanceID: String? = nil,
         accountID: String? = nil, clientInstanceID: UUID? = nil, revocationStatus: String? = "active") {
        self.id = id; self.accountName = accountName; self.serviceOrigin = serviceOrigin
        self.serviceInstanceID = serviceInstanceID; self.accountID = accountID
        self.clientInstanceID = clientInstanceID; self.revocationStatus = revocationStatus
    }
}
private struct MordeAuthorization: Codable { let credential: String; let expiresAt: String }
struct MordePage<Item: Decodable>: Decodable {
    let items: [Item]
    let next_cursor: String?
}
private struct MordeWorkspaceReference: Decodable, Identifiable {
    let id: String
    let name: String
    let revision: Int64
    let state: String
}
private struct MordeWorkspaceBinding: Decodable {
    let workspace: MordeWorkspaceReference
    let state: String
    let desired_revision: Int64
    let applied_revision: Int64
    let sync_state: String
}
private struct MordeWorkspaceDiffVersion: Decodable {
    let kind: String
    let path: String
    let symlink_target: String?
    let size_bytes: Int64?
    let sha256: String?
    let mode: Int?
    let mod_time_ns: Int64?
}
private struct MordeWorkspaceDiffChange: Decodable, Identifiable {
    let path: String
    let action: String
    let before: MordeWorkspaceDiffVersion?
    let after: MordeWorkspaceDiffVersion?
    let display_status: String
    let before_text: String?
    let after_text: String?
    var id: String { "\(action):\(path)" }
}
private struct MordeWorkspaceDiff: Decodable {
    let workspace_id: String
    let from_revision: Int64
    let to_revision: Int64
    let changes: [MordeWorkspaceDiffChange]
}
private struct MordeWorkspaceRestoreResult: Decodable {
    let workspace_id: String
    let target_revision: Int64
    let expected_current_revision: Int64
    let revision: Int64
    let replayed: Bool
}
private struct MordeHost: Decodable, Identifiable {
    let id: String
    let name: String
    let owner_id: String?
    let state: String
    let url: URL
    let control_state: String?
    let workspaces: [MordeWorkspaceBinding]?
}
private struct MordeHostControlTransition: Decodable {
    let action: String
    let phase: String
    let failure_reason: String?
}
private struct MordeHostControlStatus: Decodable {
    let host_id: String
    let control_state: String
    let control_version: Int64
    let control_actor_user_id: String?
    let control_lease_expires_at: String?
    let control_lease_active: Bool?
    let active_transition: MordeHostControlTransition?
    let pending_operation_ids: [String]?
}
private struct MordeSharedHost: Decodable, Identifiable {
    let id: String
    let name: String
    let state: String
    let url: URL
    let permissions: [String]
}
private struct MordeWorkspace: Decodable, Identifiable {
    let id: String
    let name: String
    let revision: Int
    let state: String
}
private struct MordeClientInstallation: Decodable, Identifiable {
    let id: String
    let display_name: String
    let revoked: Bool
}
private struct MordeDeviceInstallation: Decodable, Identifiable {
    let id: String
    let display_name: String
    let platform: String
    let expires_at: String
    let revoked: Bool
    let created_at: String
    let last_used_at: String?
    let online: Bool
}
private struct MordeDeviceList: Decodable { let items: [MordeDeviceInstallation] }
struct MordeProject: Decodable, Identifiable {
    let id: String
    let owner_id: String
    let name: String
    let description: String
    let version: Int64
}
struct MordeProjectMember: Decodable, Identifiable {
    let project_id: String
    let user_id: String
    let role: String
    let version: Int64
    var id: String { user_id }
}
private struct MordeProjectInvitation: Decodable, Identifiable {
    let id: String
    let project_id: String
    let inviter_id: String
    let invitee_id: String
    let role: String
    let state: String
    let version: Int64
}
private struct MordeProjectResource: Decodable, Identifiable {
    let project_id: String
    let kind: String
    let resource_id: String
    let version: Int64
    var id: String { "\(kind):\(resource_id)" }
}
struct MordeProjectWorkItemDelivery: Decodable {
    let task_id: String
    let workspace_id: String
    let revision: Int64
}
struct MordeProjectWorkItem: Decodable, Identifiable {
    let id: String
    let project_id: String
    let title: String
    let description: String
    let acceptance_criteria: [String]
    // nanoMuse: Category and unassigned ownership were added without changing legacy work-item states.
    let category: String?
    let assignee_id: String?
    let state: String
    let blocked_reason: String
    let task_ids: [String]
    let delivery: MordeProjectWorkItemDelivery?
    let version: Int64
}
struct MIFWorkItemDeliveryTarget: Identifiable, Equatable {
    let hostID: String
    let hostName: String
    let workspaceID: String
    let workspaceName: String
    let revision: Int64
    var id: String { "\(hostID):\(workspaceID)" }
}
private struct MordeProjectBudget: Decodable {
    let configured: Bool
    let currency: String
    let limit_micros: Int64
    let version: Int64
    let spent_micros: Int64
    let reserved_micros: Int64
    let has_unknown: Bool
}
private struct MordeProjectTokenUsage: Decodable {
    let input_tokens: Int64
    let output_tokens: Int64
}
private struct MordeProjectBudgetLedgerEntry: Decodable, Identifiable {
    let call_id: String
    let actor_id: String
    let task_id: String?
    let source: String
    let model_id: String
    let rate_version: Int64
    let currency: String
    let status: String
    let reserved_usage: MordeProjectTokenUsage
    let actual_usage: MordeProjectTokenUsage?
    let reserved_micros: Int64
    let actual_micros: Int64?
    let created_at: String
    var id: String { call_id }
}
struct MordeProjectConversation: Decodable, Identifiable {
    let id: String
    let project_id: String
    let owner_id: String
    let title: String
    let model_id: String?
    let created_at: String
    let updated_at: String
}
private struct MordeProjectConversationMessage: Decodable, Identifiable {
    let id: String
    let conversation_id: String
    let role: String
    let content: String
    let task_id: String?
    let delivery_status: String
    let created_at: String
    let owner_id: String
    let actor_id: String
}
private struct MordeProjectConversationTask: Decodable {
    let task: MordeTask
    let project_id: String
    let initiator_id: String

    private enum CodingKeys: String, CodingKey { case project_id, initiator_id }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        task = try MordeTask(from: decoder)
        project_id = try container.decode(String.self, forKey: .project_id)
        initiator_id = try container.decode(String.self, forKey: .initiator_id)
    }
}
private struct MordeProjectConversationAppendResponse: Decodable {
    let message: MordeProjectConversationMessage
    let task: MordeProjectConversationTask
}
private struct MordeModel: Decodable, Identifiable {
    struct Capabilities: Decodable { let text: Bool; let tools: Bool }
    let id: String; let name: String; let capabilities: Capabilities
}
private struct MordeAvailableModels: Decodable {
    let items: [MordeModel]
    let default_model_configured: Bool
    let default_model_id: String?
}
private struct MordeModelConnectionList: Decodable {
    struct Item: Decodable {
        let id: String
        let shared: Bool
        let checked_at: String?
    }
    let items: [Item]
}
private struct MordeLoadedModels {
    let items: [MordeModel]
    let defaultModelConfigured: Bool
    let defaultModelID: String?
    let personalModelIDs: Set<String>
}
private struct MordeConversation: Decodable, Identifiable {
    let id: String
    let host_id: String?
    let title: String
    let is_main: Bool?
}
struct MordeExecutionControl: Decodable, Equatable {
    struct Runtime: Decodable, Equatable {
        let state: String
        let runtime_generation: Int64
        let max_concurrent_tasks: Int
        let active_task_count: Int
    }

    let owner_id: String
    let state: String
    let epoch: Int64
    let pending_task_count: Int
    let runtime: Runtime
    let updated_at: String

    var isValid: Bool {
        ["enabled", "stopping", "disabled"].contains(state) && epoch > 0 && pending_task_count >= 0 &&
            ["not_started", "starting", "running", "stopping", "stopped", "failed"].contains(runtime.state) &&
            runtime.runtime_generation >= 0 && (0...16).contains(runtime.max_concurrent_tasks) &&
            runtime.active_task_count >= 0 && runtime.active_task_count <= runtime.max_concurrent_tasks &&
            !updated_at.isEmpty
    }
}
private struct MordeUserPreferences: Decodable {
    let default_host_id: String?
}
struct MordeBatchItem: Decodable, Identifiable { let id: String; let key: String; let status: String }
struct MordeTask: Decodable, Identifiable {
    struct Pending: Decodable {
        let id: String; let version: Int; let title: String; let content: String; let impact: String
        let kind: String?; let object: String?; let media_preview_operation_id: String?
    }
    struct Clarification: Decodable { let id: String; let version: Int; let question: String }
    struct StopRequest: Decodable { let status: String; let unsettled_operation_ids: [String] }
    struct Step: Decodable, Identifiable {
        let id: String; let sequence: Int; let kind: String; let status: String
        let title: String; let summary: String; let created_at: String
    }
    struct Artifact: Decodable, Identifiable {
        let id: String; let label: String; let media_type: String; let verified: Bool
        let workspace_id: String?
        let workspace_revision: Int64?
        let path: String?
        let size_bytes: Int64?
        let sha256: String?
        let created_at: String
    }
    let owner_id: String?; let initiator_id: String?
    let id: String; let conversation_id: String; let host_id: String?; let execution_location: String?
    let model_id: String?
    let workspace_id: String?; let input_revision: Int64?
    let objective: String; let status: String
    let event_sequence: Int64?
    let result: String?; let current_step: String?; let waiting_reason: String?; let stop_request: StopRequest?
    let pending_request: Pending?
    let clarification_request: Clarification?; let batch_items: [MordeBatchItem]?
    let steps: [Step]?; let artifacts: [Artifact]?; let updated_at: String
    let assistant_message: MordeClientMessage?

    var statusLabel: String {
        let key = MordeTaskStatusPresentation.localizationKey(
            status: status, waitingReason: waiting_reason, stopRequestStatus: stop_request?.status)
        return NSLocalizedString(key, comment: "Task status shown in the conversation")
    }
}

struct MordeTaskTimelineEvent: Decodable, Identifiable, Equatable {
    let task_id: String
    let sequence: Int64
    let type: String
    let created_at: String
    private let payload: MordePersonalJSONValue

    var id: Int64 { sequence }

    var display: (title: String, summary: String?)? {
        guard let values = payload.objectValue else { return (eventTitle, nil) }
        if type == "task.step" {
            if values["kind"]?.stringValue == "budget" { return nil }
            let title = values["title"]?.stringValue ?? AppLocalized("Task step updated")
            let pieces = [values["status"]?.stringValue.map { MordeTaskStatusPresentation.label(status: $0) },
                          values["summary"]?.stringValue].compactMap { $0 }.filter { !$0.isEmpty }
            let summary = pieces.joined(separator: " · ")
            return (title, summary.isEmpty ? nil : summary)
        }
        if type == "task.status", let status = values["status"]?.stringValue {
            return (AppLocalized("Task status updated"), MordeTaskStatusPresentation.label(status: status))
        }
        return (eventTitle, nil)
    }

    private var eventTitle: String {
        switch type {
        case "task.status": return AppLocalized("Task status updated")
        case "task.step": return AppLocalized("Task step updated")
        case "task.operation": return AppLocalized("Task operation updated")
        case "task.message": return AppLocalized("Task reply updated")
        case "task.batch_item": return AppLocalized("Batch item status updated")
        case "task.artifact": return AppLocalized("Task artifact updated")
        case "task.waiting_user": return AppLocalized("Waiting for your action")
        case "task.response": return AppLocalized("Task response updated")
        case "task.result": return AppLocalized("Task result updated")
        default: return AppLocalized("Task activity")
        }
    }
}

private extension MordePersonalJSONValue {
    var objectValue: [String: MordePersonalJSONValue]? {
        if case let .object(value) = self { return value }
        return nil
    }
    var stringValue: String? {
        if case let .string(value) = self { return value }
        return nil
    }
}

enum MordeTaskPageAction {
    case pause(expectedStatus: String)
    case resume
    case cancel(expectedStatus: String)
    case retryBatchItem(id: String)
}

private struct MordeTaskMediaPreviewControls: View {
    @ObservedObject var client: MordeClient
    let task: MordeTask
    let pending: MordeTask.Pending
    let canRespond: Bool
    let busy: Bool
    let isPendingCurrent: () -> Bool
    let onDecision: (String) async -> Bool

    @State private var previewFile: MordeTaskMediaPreviewFile?
    @State private var activePreviewURL: URL?
    @State private var loadingPreview = false
    @State private var responding = false
    @State private var previewFailure: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if client.taskMediaGenerationAvailable == true {
                Button(AppLocalized("Preview")) { Task { await loadPreview() } }
                    .accessibilityIdentifier("morde.task.media.preview")
                    .disabled(!canRespond || !isPendingCurrent() || busy || loadingPreview || responding)
            } else {
                Text(AppLocalized("Media preview unavailable"))
                    .font(.footnote).foregroundStyle(.secondary)
                    .accessibilityIdentifier("morde.task.media.unavailable")
            }
            if loadingPreview { ProgressView().controlSize(.small) }
            if let previewFailure {
                Text(previewFailure).font(.footnote).foregroundStyle(.orange)
            }
            if client.taskMediaGenerationAvailable != true, canRespond {
                Button(AppLocalized("拒绝"), role: .destructive) { Task { await decide("reject") } }
                    .accessibilityIdentifier("morde.task.media.discard")
                    .disabled(!isPendingCurrent() || busy || responding)
            }
        }
        .sheet(item: $previewFile, onDismiss: removePreviewFile) { file in
            NavigationStack {
                VStack(spacing: 12) {
                    NanoMuseQuickLook(url: file.fileURL)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Text(pending.impact).font(.footnote).foregroundStyle(.secondary)
                    Text(file.mediaType).font(.caption).foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .navigationTitle(pending.title)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(AppLocalized("Close")) { previewFile = nil }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    HStack {
                        Button(AppLocalized("拒绝"), role: .destructive) { Task { await decide("reject") } }
                            .accessibilityIdentifier("morde.task.media.discard")
                            .disabled(!canRespond || !isPendingCurrent() || busy || responding)
                        Spacer()
                        Button(AppLocalized("Save")) { Task { await decide("approve") } }
                            .accessibilityIdentifier("morde.task.media.save")
                            .disabled(!canRespond || !isPendingCurrent() ||
                                      client.taskMediaGenerationAvailable != true || busy || responding)
                    }
                    .padding()
                    .background(.bar)
                }
            }
        }
        .onChange(of: client.signedIn) { signedIn in
            if !signedIn { removePreviewFile() }
        }
        .onChange(of: isPendingCurrent()) { isCurrent in
            if !isCurrent { removePreviewFile() }
        }
        .onDisappear {
            if previewFile == nil { removePreviewFile() }
        }
    }

    private func loadPreview() async {
        guard let operationID = pending.media_preview_operation_id,
              MordeTaskResponsePolicy.mediaPreviewPath(taskID: task.id, operationID: operationID) != nil else { return }
        loadingPreview = true
        previewFailure = nil
        defer { loadingPreview = false }
        do {
            let file = try await client.downloadTaskMediaPreview(taskID: task.id, operationID: operationID)
            guard client.signedIn, isPendingCurrent() else {
                try? FileManager.default.removeItem(at: file.fileURL)
                return
            }
            activePreviewURL = file.fileURL
            previewFile = file
        } catch {
            previewFailure = error.localizedDescription
        }
    }

    private func decide(_ decision: String) async {
        guard canRespond, isPendingCurrent(), !busy, !responding,
              decision == "reject" || client.taskMediaGenerationAvailable == true else { return }
        responding = true
        defer { responding = false }
        if await onDecision(decision) { removePreviewFile() }
    }

    private func removePreviewFile() {
        if let activePreviewURL { try? FileManager.default.removeItem(at: activePreviewURL) }
        activePreviewURL = nil
        previewFile = nil
    }
}

private struct MordeNotification: Decodable, Identifiable {
    let id: String; let summary: String?; let redacted: Bool?; let actionable: Bool?
    let kind: String; let task_id: String?; let read_at: String?

    var displaySummary: String { MordeNotificationPresentationPolicy.summary(summary, redacted: redacted) }
    var canOpenTask: Bool {
        MordeNotificationPresentationPolicy.canOpenTask(kind: kind, redacted: redacted, actionable: actionable)
    }
}
private struct MordeTicket: Decodable { let url: URL }
private struct MordeEmpty: Decodable {}
private struct MordeMe: Decodable { let id: String; let name: String }
private struct MordeError: Decodable {
    struct Detail: Decodable { let code: String?; let message: String }
    let error: Detail

    var displayMessage: String {
        switch MordeAccountLoginFailure.fromAPIErrorCode(error.code) {
        case .pending: AppLocalized("Your account is waiting for administrator review.")
        case .rejected: AppLocalized("Your account review was not approved. Contact an administrator.")
        case .disabled: AppLocalized("Your account is disabled. Contact an administrator.")
        case nil: error.message
        }
    }
}
struct MordePersonalProfileBody: Codable, Equatable, Sendable {
    let name: String
    let avatar: String
    let emoji: String?
    let color: String?
    let description: String?
    let style: String?

    var isValidForWrite: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed == name, (1...60).contains(name.unicodeScalars.count),
              (description?.unicodeScalars.count ?? 0) <= 200,
              ["", "muse", "flat", "clay", "watercolor", "pixel", "line", "sticker"].contains(style ?? "") else { return false }
        switch avatar {
        case "dragon": return emoji == nil && color == nil
        case "emoji":
            guard let emoji, !emoji.isEmpty, emoji.unicodeScalars.count <= 16, let color else { return false }
            return color.range(of: "^#[0-9A-Fa-f]{6}$", options: .regularExpression) != nil
        default: return false
        }
    }
}
struct MordePersonalProfileObject: Decodable, Equatable, Sendable {
    let object_type: String
    let object_id: String
    let revision: Int64
    let body: MordePersonalProfileBody
}

struct MordePersonalSyncObject: Decodable, Equatable, Sendable {
    let object_type: String
    let object_id: String
    let revision: Int64
    let body: MordePersonalJSONValue

    func decodeBody<T: Decodable>(_ type: T.Type) throws -> T { try body.decode(type) }
}

struct MordePersonalSnapshotPage: Decodable, Equatable, Sendable {
    let watermark: Int64
    let items: [MordePersonalSyncObject]
    let next_cursor: String?
}
struct MordePersonalChange: Decodable, Equatable, Sendable {
    let change_sequence: Int64
    let object_type: String
    let object_id: String
    let revision: Int64
    let operation: String
    let mutation_id: String?
}
struct MordePersonalChangePage: Decodable, Equatable, Sendable {
    let items: [MordePersonalChange]
    let through_sequence: Int64
    let next_after_sequence: Int64
    let has_more: Bool
}
struct MordePersonalMutationReceipt: Decodable, Equatable, Sendable {
    let object_type: String
    let object_id: String
    let result_revision: Int64
    let account_change_sequence: Int64
    let replay: Bool
}

enum MordePersonalDataContract {
    static let syncObjectTypes: Set<String> = [
        "profile", "memory", "soul", "diary", "goal", "schedule", "feed_post",
        "feed_preferences", "idea_mark", "library_item", "skill_setting", "connector_setting",
    ]
    static let mutationObjectTypes: Set<String> = [
        "profile", "memory", "soul", "diary", "goal", "feed_post", "feed_preferences",
        "idea_mark", "library_item", "skill_setting", "connector_setting",
    ]

    static func isValidObjectIdentifier(type: String, id: String) -> Bool {
        guard syncObjectTypes.contains(type), id != ".", id != "..",
              id.range(of: "^[A-Za-z0-9._~-]{1,128}$", options: .regularExpression) != nil else { return false }
        switch type {
        case "profile", "feed_preferences": return id == "default"
        case "memory": return ["global", "user"].contains(id) || id.range(of: "^m_[0-9a-f]{8}$", options: .regularExpression) != nil
        case "schedule": return id.range(of: "^j[a-z0-9]{7}$", options: .regularExpression) != nil
        case "skill_setting": return id.hasPrefix("builtin_") && id.count > "builtin_".count
        case "connector_setting": return id.hasPrefix("catalogue_") && id.count > "catalogue_".count
        default: return true
        }
    }

    static func isValidIdempotencyKey(_ value: String) -> Bool {
        value.range(of: "^[A-Za-z0-9._~-]{8,128}$", options: .regularExpression) != nil
    }

    static func isValidUploadID(_ value: String) -> Bool {
        value.range(of: "^pu_[0-9a-f]{32}$", options: .regularExpression) != nil
    }

    static func isValidAttachmentID(_ value: String) -> Bool {
        value.range(of: "^pa_[0-9a-f]{32}$", options: .regularExpression) != nil
    }

    static func isValidAttachmentMediaType(_ value: String) -> Bool {
        guard value.utf8.count <= 128 else { return false }
        let components = value.split(separator: "/", omittingEmptySubsequences: false)
        guard components.count == 2 else { return false }
        let allowed = Set("abcdefghijklmnopqrstuvwxyz0123456789!#$%&'*+-.^_`|~".utf8)
        return components.allSatisfy { token in
            !token.isEmpty && token != "." && token != ".." && token.utf8.allSatisfy { allowed.contains($0) }
        }
    }
}

struct MordePersonalDataQuota: Decodable, Equatable, Sendable {
    let owner_id: String
    let used_bytes: Int64
    let reserved_bytes: Int64
    let quota_bytes: Int64
    let max_attachment_bytes: Int64
    let remaining_bytes: Int64
    let version: Int64

    var isValid: Bool {
        guard !owner_id.isEmpty, used_bytes >= 0, reserved_bytes >= 0, quota_bytes > 0,
              used_bytes <= Int64.max - reserved_bytes, max_attachment_bytes > 0,
              max_attachment_bytes <= Int64(Int32.max) * Int64(MordePersonalAttachmentHash.chunkBytes),
              version >= 1 else { return false }
        let committedAndReserved = used_bytes + reserved_bytes
        let expectedRemaining = committedAndReserved >= quota_bytes ? 0 : quota_bytes - committedAndReserved
        return remaining_bytes == expectedRemaining
    }
}

struct MordePersonalAttachmentUploadReceipt: Decodable, Equatable, Sendable {
    let upload_id: String
    let state: String
    let chunk_count: Int32
    let replay: Bool
}

struct MordePersonalAttachmentChunkReceipt: Decodable, Equatable, Sendable {
    let upload_id: String
    let sequence: Int32
    let replay: Bool
}

struct MordePersonalAttachmentCommitReceipt: Decodable, Equatable, Sendable {
    let attachment_id: String
    let object_type: String
    let object_id: String
    let result_revision: Int64
    let account_change_sequence: Int64
    let replay: Bool
}

struct MordePersonalStagedAttachment: Equatable, Sendable {
    let fileURL: URL
    let sizeBytes: Int64
    let sha256: String
}

struct MordePersonalAttachmentDownload: Equatable, Sendable {
    let attachmentID: String
    let fileURL: URL
    let sizeBytes: Int64
    let sha256: String
    let mediaType: String
}

private struct MordeTaskMediaPreviewFile: Identifiable {
    var id: String { fileURL.absoluteString }
    let fileURL: URL
    let mediaType: String
}

enum MordePersonalAttachmentHash {
    static let chunkBytes = 4 * 1024 * 1024

    static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func measure(fileURL: URL) throws -> (sizeBytes: Int64, sha256: String) {
        guard fileURL.isFileURL else { throw URLError(.badURL) }
        let file = try FileHandle(forReadingFrom: fileURL)
        defer { try? file.close() }
        var hasher = SHA256()
        var size: Int64 = 0
        while let data = try file.read(upToCount: chunkBytes), !data.isEmpty {
            size += Int64(data.count)
            hasher.update(data: data)
        }
        return (size, hasher.finalize().map { String(format: "%02x", $0) }.joined())
    }

    static func chunkCount(sizeBytes: Int64) -> Int32? {
        guard sizeBytes >= 0, sizeBytes <= Int64(Int32.max) * Int64(chunkBytes) else { return nil }
        if sizeBytes == 0 { return 0 }
        return Int32((sizeBytes - 1) / Int64(chunkBytes) + 1)
    }

    static func chunkSize(sizeBytes: Int64, sequence: Int32) -> Int? {
        guard let count = chunkCount(sizeBytes: sizeBytes), sequence >= 0, sequence < count else { return nil }
        let offset = Int64(sequence) * Int64(chunkBytes)
        return Int(min(Int64(chunkBytes), sizeBytes - offset))
    }
}

struct MordePersonalGoalStep: Codable, Equatable, Sendable {
    let id: String
    let title: String
    let status: String
    let note: String

    init(id: String, title: String, status: String, note: String = "") {
        self.id = id; self.title = title; self.status = status; self.note = note
    }

    private enum CodingKeys: String, CodingKey { case id, title, status, note }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        status = try container.decode(String.self, forKey: .status)
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
    }
}

struct MordePersonalGoalBody: Codable, Equatable, Sendable {
    let title: String
    let description: String
    let status: String
    let steps: [MordePersonalGoalStep]
    let related_material_ids: [String]

    var isValidForWrite: Bool {
        let opaqueID = "^[A-Za-z0-9._~-]{1,128}$"
        let stepStatuses = ["pending", "in_progress", "done", "blocked", "skipped"]
        return !title.isEmpty && title.unicodeScalars.count <= 200 && title == title.trimmingCharacters(in: .whitespacesAndNewlines) &&
            description.unicodeScalars.count <= 4096 && ["active", "paused", "done", "cancelled"].contains(status) &&
            steps.count <= 100 && steps.allSatisfy {
                $0.id.range(of: opaqueID, options: .regularExpression) != nil &&
                    !$0.title.isEmpty && $0.title.unicodeScalars.count <= 200 && $0.title == $0.title.trimmingCharacters(in: .whitespacesAndNewlines) &&
                    stepStatuses.contains($0.status) && $0.note.unicodeScalars.count <= 2000
            } && Set(steps.map(\.id)).count == steps.count && related_material_ids.count <= 100 &&
            related_material_ids.allSatisfy { $0.range(of: opaqueID, options: .regularExpression) != nil } &&
            Set(related_material_ids).count == related_material_ids.count
    }
}

struct MordePersonalGoalObject: Decodable, Equatable, Sendable {
    let object_type: String
    let object_id: String
    let revision: Int64
    let body: MordePersonalGoalBody
}

struct MordeScheduleAuthorizationState: Equatable, Sendable {
    let enabled: Bool
    let expiresAt: Date?

    static let disabled = MordeScheduleAuthorizationState(enabled: false, expiresAt: nil)
}

struct MordeScheduleTargetOption: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
}

struct MordeScheduleTargets: Equatable, Sendable {
    let hosts: [MordeScheduleTargetOption]
    let models: [MordeScheduleTargetOption]
}

struct MordeScheduleTimingDTO: Codable, Equatable, Sendable {
    var kind: String
    var run_at: String? = nil
    var starts_on: String? = nil
    var local_time: String? = nil
    var time_zone: String
    var weekdays: [Int]? = nil
}

struct MordeScheduleBudgetDTO: Codable, Equatable, Sendable {
    var active_seconds: Int64
    var tool_calls: Int64
    var model_tokens: Int64
}

struct MordeScheduleObservationDTO: Codable, Equatable, Sendable {
    var url: String
    var selector: String
    var field: String
}

struct MordeScheduleRunDTO: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var schedule_id: String
    var schedule_version: Int64
    var occurrence_key: String
    var scheduled_at: String? = nil
    var coalesced_count: Int64
    var status: String
    var skip_reason: String? = nil
    var task_id: String? = nil
    var notification_events: [String]
    var observation: MordeScheduleObservationDTO? = nil
    var observation_outcome: String
    var created_at: String
    var updated_at: String
    var finished_at: String? = nil
}

struct MordeScheduleDTO: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var version: Int64
    var status: String
    var host_id: String
    var model_id: String
    var objective: String
    var timing: MordeScheduleTimingDTO
    var budget: MordeScheduleBudgetDTO
    var misfire_policy: String
    var notification_events: [String]
    var observation: MordeScheduleObservationDTO? = nil
    var next_run_at: String? = nil
    var last_run: MordeScheduleRunDTO? = nil
    var current_run: MordeScheduleRunDTO? = nil
    var created_at: String
    var updated_at: String
}

struct MordeScheduleListPage: Codable, Equatable, Sendable {
    var items: [MordeScheduleDTO]
    var next_cursor: String
}

struct MordeScheduleRunListPage: Codable, Equatable, Sendable {
    var items: [MordeScheduleRunDTO]
    var next_cursor: String
}

struct MordeScheduleCreateRequest: Codable, Equatable, Sendable {
    var host_id: String
    var model_id: String
    var objective: String
    var timing: MordeScheduleTimingDTO
    var budget: MordeScheduleBudgetDTO
    var misfire_policy: String
    var notification_events: [String]
    var observation: MordeScheduleObservationDTO? = nil
}

struct MordeScheduleUpdateRequest: Codable, Equatable, Sendable {
    var expected_version: Int64
    var host_id: String? = nil
    var model_id: String? = nil
    var objective: String? = nil
    var timing: MordeScheduleTimingDTO? = nil
    var budget: MordeScheduleBudgetDTO? = nil
    var misfire_policy: String? = nil
    var notification_events: [String]? = nil
    var observation: MordeScheduleObservationDTO? = nil
}

struct MordeScheduleActionRequest: Codable, Equatable, Sendable {
    var action: String
    var expected_version: Int64
    var current_run_action: String? = nil
}

struct MordeScheduleActionResponse: Codable, Equatable, Sendable {
    var schedule: MordeScheduleDTO
    var current_run: MordeScheduleRunDTO? = nil
}

private struct MordeScheduleGrantResponse: Decodable {
    let credential: String
    let expires_at: String
}

private struct MordeStoredScheduleGrant: Codable {
    let credential: String
    let expiresAt: String
}
private struct MordeClientWebSession: Decodable {
    let web_session_credential: String
    let web_session_expires_at: String
}
private struct MordeWorkspaceDirectory: Decodable, Hashable {
    let path: String
}
private struct MordeWorkspaceManifest: Decodable {
    let workspace_id: String
    let revision: Int64
    let files: [MordeWorkspaceFile]
    let directories: [MordeWorkspaceDirectory]
    let next_cursor: String?
}
private enum MordeWorkspaceFileOperationAction: String {
    case rename, move, delete

    var title: String {
        switch self {
        case .rename: return "重命名"
        case .move: return "移动"
        case .delete: return "删除"
        }
    }
}
private struct MordeWorkspaceFileOperationResult: Decodable {
    let workspace_id: String
    let action: String
    let source_path: String
    let target_path: String
    let expected_current_revision: Int64
    let revision: Int64
    let replayed: Bool
}
private struct MordeWorkspaceSyncBlock: Decodable {
    let chunk: MordeWorkspaceChunk
    let role: String
    let received: Bool
}
private struct MordeWorkspaceDownloadAction: Decodable {
    let path: String
    let action: String
    let sha256: String?
    let size_bytes: Int64
    let applied: Bool
}
private struct MordeWorkspaceSyncSession: Decodable {
    let id: String
    let workspace_id: String
    let state: String
    let target_revision: Int64
    let planned_bytes: Int64
    let confirmed_bytes: Int64
    let transfer_blocks: [MordeWorkspaceSyncBlock]
    let download_actions: [MordeWorkspaceDownloadAction]
    let conflicts: [MordeWorkspaceSyncConflict]
}
private struct MordeWorkspaceSyncConflict: Decodable {
    let path: String
    let reason: String
}
private struct MordeWorkspaceLocalSelection: Identifiable {
    let id = UUID()
    let url: URL
    let file: MordeWorkspaceFile
}

private struct MordeChatAttachment: Identifiable, Equatable {
    let attachmentID: String
    let additionalAttachmentIDs: [String]
    let name: String
    let mediaType: String
    let sizeBytes: Int64

    var id: String { attachmentID }
    var allAttachmentIDs: [String] { [attachmentID] + additionalAttachmentIDs }
}

struct MordePreparedChatFile: Sendable {
    let url: URL
}

struct MordePreparedChatAttachment: Sendable {
    let name: String
    let files: [MordePreparedChatFile]
    let temporaryDirectory: URL?

    func discardTemporaryFiles() {
        if let temporaryDirectory { try? FileManager.default.removeItem(at: temporaryDirectory) }
    }
}

enum MordeChatAttachmentPreparation {
    private static let maxImageBytes = 512 * 1024
    private static let maxTextBytes = 48 * 1024
    private static let maxPDFTextPages = 100
    // shortcut: render the first 10 PDF pages, raise this when the task image budget supports larger PDFs.
    private static let maxPDFPreviewPages = 10

    static func prepare(_ sourceURL: URL) throws -> MordePreparedChatAttachment {
        try withMordeSecurityScope(sourceURL) {
            guard let type = UTType(filenameExtension: sourceURL.pathExtension),
                  type.conforms(to: .image) || type.conforms(to: .pdf) else {
                throw NSError(domain: "Morde", code: 415,
                              userInfo: [NSLocalizedDescriptionKey: "聊天附件仅支持图片与 PDF。"])
            }
            return type.conforms(to: .pdf) ? try preparePDF(sourceURL) : try prepareImage(sourceURL)
        }
    }

    private static func prepareImage(_ sourceURL: URL) throws -> MordePreparedChatAttachment {
        guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 1280,
                kCGImageSourceShouldCacheImmediately: false
              ] as CFDictionary) else {
            throw NSError(domain: "Morde", code: 415,
                          userInfo: [NSLocalizedDescriptionKey: "无法读取这张图片。"])
        }
        let data = try jpegData(UIImage(cgImage: thumbnail))
        let directory = try temporaryDirectory()
        do {
            let stem = sourceURL.deletingPathExtension().lastPathComponent
            let name = (stem.isEmpty ? "image" : stem) + ".jpg"
            try data.write(to: directory.appendingPathComponent(name), options: .atomic)
            return MordePreparedChatAttachment(name: name,
                files: [MordePreparedChatFile(url: directory.appendingPathComponent(name))], temporaryDirectory: directory)
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
    }

    private static func preparePDF(_ sourceURL: URL) throws -> MordePreparedChatAttachment {
        guard let document = PDFDocument(url: sourceURL), !document.isLocked, document.pageCount > 0 else {
            throw NSError(domain: "Morde", code: 415,
                          userInfo: [NSLocalizedDescriptionKey: "无法读取此 PDF，或 PDF 受密码保护。"])
        }
        let digest = try MordePersonalAttachmentHash.measure(fileURL: sourceURL).sha256
        let directory = try temporaryDirectory()
        do {
            var files = [MordePreparedChatFile(url: sourceURL)]
            var scalars = String.UnicodeScalarView()
            var textBytes = 0
            var textWasTruncated = false
            let textPageCount = min(document.pageCount, maxPDFTextPages)
            for index in 0..<textPageCount {
                guard let page = document.page(at: index) else { continue }
                let pageText = "\n--- Page \(index + 1) ---\n" + (page.string ?? "")
                for scalar in pageText.unicodeScalars {
                    let count = String(scalar).utf8.count
                    guard textBytes + count <= maxTextBytes else {
                        textWasTruncated = true
                        break
                    }
                    scalars.append(scalar)
                    textBytes += count
                }
                if textWasTruncated { break }
            }
            var extractedText = String(scalars)
            if extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                extractedText = "No selectable text was found. Inspect the page JPEG attachments."
            }
            if textWasTruncated || document.pageCount > maxPDFTextPages {
                extractedText += "\n[PDF text extraction is bounded; page images are attached for visual inspection.]"
            }
            let shortDigest = String(digest.prefix(12))
            let textName = "morde-解析-\(shortDigest)-文本.txt"
            try Data(extractedText.utf8).write(to: directory.appendingPathComponent(textName), options: .atomic)
            files.append(MordePreparedChatFile(url: directory.appendingPathComponent(textName)))

            for index in 0..<min(document.pageCount, maxPDFPreviewPages) {
                guard let page = document.page(at: index) else { continue }
                let data = try jpegData(page.thumbnail(of: CGSize(width: 1280, height: 720), for: .mediaBox))
                let pageName = String(format: "morde-解析-%@-第%02d页.jpg", shortDigest, index + 1)
                try data.write(to: directory.appendingPathComponent(pageName), options: .atomic)
                files.append(MordePreparedChatFile(url: directory.appendingPathComponent(pageName)))
            }
            return MordePreparedChatAttachment(name: sourceURL.lastPathComponent, files: files,
                                               temporaryDirectory: directory)
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
    }

    private static func jpegData(_ image: UIImage) throws -> Data {
        guard image.size.width > 0, image.size.height > 0 else { throw URLError(.cannotDecodeContentData) }
        var scale = min(1, 1280 / image.size.width, 720 / image.size.height)
        var quality: CGFloat = 0.82
        for _ in 0..<12 {
            let size = CGSize(width: max(1, image.size.width * scale), height: max(1, image.size.height * scale))
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            format.opaque = true
            let rendered = UIGraphicsImageRenderer(size: size, format: format).image { context in
                context.cgContext.setFillColor(UIColor.white.cgColor)
                context.cgContext.fill(CGRect(origin: .zero, size: size))
                image.draw(in: CGRect(origin: .zero, size: size))
            }
            let data = rendered.jpegData(compressionQuality: quality)
            if let data, data.count <= maxImageBytes { return data }
            if quality > 0.52 { quality -= 0.1 } else { scale *= 0.82; quality = 0.76 }
        }
        throw NSError(domain: "Morde", code: 413,
                      userInfo: [NSLocalizedDescriptionKey: "图片处理后仍超过模型可读取的大小。"])
    }

    private static func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("morde-chat-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

private func withMordeSecurityScope<T>(_ url: URL, _ operation: () throws -> T) rethrows -> T {
    let started = url.startAccessingSecurityScopedResource()
    defer { if started { url.stopAccessingSecurityScopedResource() } }
    return try operation()
}

// nanoMuse: Expose only the verified Morde sign-in state needed by the original app shell.
@MainActor final class MordeShellAuthorization: ObservableObject {
    static let shared = MordeShellAuthorization()
    @Published private(set) var signedIn = false
    @Published private(set) var personalDataScopeKey: String?
    @Published private(set) var scheduleAuthorizationState = MordeScheduleAuthorizationState.disabled

    func restoreForFirstRun() async {
        await MordeClient.shared.restoreLoginForFirstRun()
    }

    fileprivate func update(signedIn: Bool, personalDataScopeKey: String?,
                            scheduleAuthorizationState: MordeScheduleAuthorizationState) {
        self.signedIn = signedIn
        self.personalDataScopeKey = personalDataScopeKey
        self.scheduleAuthorizationState = scheduleAuthorizationState
    }

    func personalProfile() async throws -> MordePersonalProfileObject? {
        try await MordeClient.shared.personalProfile()
    }

    func personalObject(objectType: String, objectID: String) async throws -> MordePersonalSyncObject? {
        try await MordeClient.shared.personalObject(objectType: objectType, objectID: objectID)
    }

    func replacePersonalObject(objectType: String, objectID: String, baseRevision: Int64,
                               body: MordePersonalJSONValue, idempotencyKey: String) async throws -> MordePersonalMutationReceipt {
        try await MordeClient.shared.replacePersonalObject(objectType: objectType, objectID: objectID,
            baseRevision: baseRevision, body: body, idempotencyKey: idempotencyKey)
    }

    func deletePersonalObject(objectType: String, objectID: String, baseRevision: Int64,
                              idempotencyKey: String) async throws -> MordePersonalMutationReceipt {
        try await MordeClient.shared.deletePersonalObject(objectType: objectType, objectID: objectID,
            baseRevision: baseRevision, idempotencyKey: idempotencyKey)
    }

    func personalDataQuota() async throws -> MordePersonalDataQuota {
        try await MordeClient.shared.personalDataQuota()
    }

    func importPersonalHistory(_ request: MordePersonalHistoryImportRequest) async throws -> MordePersonalHistoryImportReceipt {
        try await MordeClient.shared.importPersonalHistory(request)
    }

    func uploadPersonalAttachment(objectID: String, baseRevision: Int64, fileURL: URL, sizeBytes: Int64,
                                  sha256: String, mediaType: String, idempotencyKey: String,
                                  progress: (@MainActor (Int64, Int64) -> Void)? = nil) async throws -> MordePersonalAttachmentCommitReceipt {
        try await MordeClient.shared.uploadPersonalAttachment(objectID: objectID, baseRevision: baseRevision,
            fileURL: fileURL, sizeBytes: sizeBytes, sha256: sha256, mediaType: mediaType,
            idempotencyKey: idempotencyKey, progress: progress)
    }

    func downloadPersonalAttachment(attachmentID: String) async throws -> MordePersonalAttachmentDownload {
        try await MordeClient.shared.downloadPersonalAttachment(attachmentID: attachmentID)
    }

    func replacePersonalProfile(baseRevision: Int64, body: MordePersonalProfileBody,
                                idempotencyKey: String) async throws -> MordePersonalMutationReceipt {
        try await MordeClient.shared.replacePersonalProfile(baseRevision: baseRevision, body: body,
                                                            idempotencyKey: idempotencyKey)
    }

    func personalSnapshot(cursor: String? = nil) async throws -> MordePersonalSnapshotPage {
        try await MordeClient.shared.personalSnapshot(cursor: cursor)
    }

    func personalChanges(afterSequence: Int64, throughSequence: Int64? = nil) async throws -> MordePersonalChangePage {
        try await MordeClient.shared.personalChanges(afterSequence: afterSequence, throughSequence: throughSequence)
    }

    func personalGoal(objectID: String) async throws -> MordePersonalGoalObject? {
        try await MordeClient.shared.personalGoal(objectID: objectID)
    }

    func replacePersonalGoal(objectID: String, baseRevision: Int64, body: MordePersonalGoalBody,
                             idempotencyKey: String) async throws -> MordePersonalMutationReceipt {
        try await MordeClient.shared.replacePersonalGoal(objectID: objectID, baseRevision: baseRevision,
                                                         body: body, idempotencyKey: idempotencyKey)
    }

    func deletePersonalGoal(objectID: String, baseRevision: Int64,
                            idempotencyKey: String) async throws -> MordePersonalMutationReceipt {
        try await MordeClient.shared.deletePersonalGoal(objectID: objectID, baseRevision: baseRevision,
                                                        idempotencyKey: idempotencyKey)
    }

    func enableCloudSchedules() async throws -> MordeScheduleAuthorizationState {
        try await MordeClient.shared.enableCloudSchedules()
    }

    func disableCloudSchedules() async throws -> MordeScheduleAuthorizationState {
        try await MordeClient.shared.disableCloudSchedules()
    }

    func scheduleTargets() async throws -> MordeScheduleTargets {
        try await MordeClient.shared.scheduleTargets()
    }

    func schedules(status: String? = nil, limit: Int = 50, cursor: String? = nil) async throws -> MordeScheduleListPage {
        try await MordeClient.shared.schedules(status: status, limit: limit, cursor: cursor)
    }

    func schedule(id: String) async throws -> MordeScheduleDTO {
        try await MordeClient.shared.schedule(id: id)
    }

    func createSchedule(_ request: MordeScheduleCreateRequest,
                        idempotencyKey: String) async throws -> MordeScheduleDTO {
        try await MordeClient.shared.createSchedule(request, idempotencyKey: idempotencyKey)
    }

    func updateSchedule(id: String, request: MordeScheduleUpdateRequest,
                        idempotencyKey: String) async throws -> MordeScheduleDTO {
        try await MordeClient.shared.updateSchedule(id: id, request: request, idempotencyKey: idempotencyKey)
    }

    func scheduleAction(id: String, request: MordeScheduleActionRequest,
                        idempotencyKey: String) async throws -> MordeScheduleActionResponse {
        try await MordeClient.shared.scheduleAction(id: id, request: request, idempotencyKey: idempotencyKey)
    }

    func scheduleRuns(id: String, limit: Int = 50, cursor: String? = nil) async throws -> MordeScheduleRunListPage {
        try await MordeClient.shared.scheduleRuns(id: id, limit: limit, cursor: cursor)
    }
}

@MainActor private final class MordeClient: ObservableObject {
    static let shared = MordeClient()
    private static let defaultServer = "https://portal.120.25.178.93.sslip.io"
    @Published var server: String
    @Published private var verifiedServiceInstanceID: String?
    @Published var user: MordeMe?
    @Published var hosts: [MordeHost] = []
    @Published var sharedHosts: [MordeSharedHost] = []
    @Published var workspaces: [MordeWorkspace] = []
    @Published private(set) var defaultHostID: String?
    @Published private(set) var defaultHostPreferenceState: MordeResourceLoadState = .loading
    @Published var hostOpenErrors: [String: String] = [:]
    @Published var cloudTasksAvailable: Bool?
    @Published var workspaceSyncAvailable: Bool?
    @Published var projectBudgetExecutionAvailable: Bool?
    @Published var projectWorkItemsV2Available: Bool?
    @Published var resourceStates: [MordeResource: MordeResourceLoadState] =
        Dictionary(uniqueKeysWithValues: MordeResource.allCases.map { ($0, .loading) })
    @Published var models: [MordeModel] = []
    @Published private(set) var defaultModelConfigured = false
    @Published private(set) var defaultModelID: String?
    @Published private(set) var personalModelIDs: Set<String> = []
    @Published var conversations: [MordeConversation] = []
    @Published var conversationNextCursor: String?
    @Published var loadingMoreConversations = false
    @Published var mainConversation: MordeMainConversation?
    @Published var mainConversationLoadError: String?
    @Published private(set) var executionControl: MordeExecutionControl?
    @Published private(set) var executionControlError: String?
    @Published private(set) var executionControlIsLoading = false
    @Published private(set) var executionControlActionInFlight = false
    @Published var messages: [MordeClientMessage] = []
    @Published var messageNextCursor: String?
    @Published var loadingEarlierMessages = false
    @Published var messageHistoryError: String?
    @Published var tasks: [MordeTask] = []
    @Published private(set) var taskPageDetails: [String: MordeTask] = [:]
    @Published private(set) var taskTimelineEvents: [String: [MordeTaskTimelineEvent]] = [:]
    @Published private(set) var taskTimelineErrors: [String: String] = [:]
    @Published private(set) var taskTimelineHistoryExpired: Set<String> = []
    @Published private(set) var taskTimelineLoading: Set<String> = []
    @Published private(set) var taskTimelineNoHistory: Set<String> = []
    @Published private(set) var taskPageActionErrors: [String: String] = [:]
    @Published var notifications: [MordeNotification] = []
    @Published var notificationNextCursor: String?
    @Published var loadingMoreNotifications = false
    @Published var hostControlStatuses: [String: MordeHostControlStatus] = [:]
    @Published var hostControlErrors: [String: String] = [:]
    @Published var hostControlActionInFlightFor: String?
    @Published var hostRestoreInFlightID: String?
    @Published var hubAvailable: Bool?
    @Published var clientInstallations: [MordeClientInstallation] = []
    @Published var clientInstallationsState: MordeResourceLoadState = .loading
    @Published var clientInstallationsActionError: String?
    @Published var clientInstallationsNotice: String?
    @Published var revokingClientInstallationID: String?
    @Published var devices: [MordeDeviceInstallation] = []
    @Published var devicesState: MordeResourceLoadState = .loading
    @Published var hubRelayError: String?
    @Published var hubRelayNotice: String?
    @Published var hubRelayWorkingID: String?
    @Published var projects: [MordeProject] = []
    @Published var projectInvitations: [MordeProjectInvitation] = []
    @Published var projectMembers: [MordeProjectMember] = []
    @Published var projectResources: [MordeProjectResource] = []
    @Published var projectWorkItems: [MordeProjectWorkItem] = []
    @Published var projectWorkItemsState: MordeResourceLoadState = .loading
    @Published var projectBudget: MordeProjectBudget?
    @Published var projectBudgetLedger: [MordeProjectBudgetLedgerEntry] = []
    @Published var projectBudgetState: MordeResourceLoadState = .loading
    @Published var projectConversations: [MordeProjectConversation] = []
    @Published var projectConversationsState: MordeResourceLoadState = .loading
    @Published var selectedProjectConversationID: String?
    @Published var projectConversationMessages: [MordeProjectConversationMessage] = []
    @Published var projectConversationMessagesState: MordeResourceLoadState = .loading
    @Published var projectConversationTask: MordeTask?
    @Published var projectConversationError: String?
    @Published var recentProjectInvitations: [String: [MordeProjectInvitation]] = [:]
    @Published var selectedProjectID: String?
    @Published var projectsState: MordeResourceLoadState = .loading
    @Published var projectInvitationsState: MordeResourceLoadState = .loading
    @Published var projectDetailState: MordeResourceLoadState = .loading
    @Published var registrationMessage: String?
    @Published var projectActionInFlight = false
    @Published var projectActionError: String?
    @Published var projectNotice: String?
    private var projectLoadGeneration = UUID()
    private var projectDetailLoadGeneration = UUID()
    private var projectExecutionLoadGeneration = UUID()
    private var projectWorkItemsLoadGeneration = UUID()
    private var projectConversationLoadGeneration = UUID()
    private var projectConversationMessagesGeneration = UUID()
    private var devicesLoadGeneration = UUID()
    @Published var currentConversation: String?
    @Published var currentTask: MordeTask?
    @Published var hostURL: URL?
    @Published var error: String?
    @Published var busy = false
    @Published var taskAPIAvailable: Bool?
    @Published var taskMediaGenerationAvailable: Bool?

    private let keychain = MordeKeychain()
    private let loginStateStore = MordeLoginStateStore()
    private let revocationStore = MordeRevocationStore()
#if DEBUG
    private let urlSession: URLSession = {
        guard MordeAuthURLProtocol.usesLocalFixture else {
            return .shared
        }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MordeAuthURLProtocol.self]
        return URLSession(configuration: configuration)
    }()
#else
    private let urlSession = URLSession.shared
#endif
    private static let scopedInstallationPrefix = "morde.installation.scope."
    private static let activeInstallationsKey = "morde.installation.activeScopes.v1"
    private static let listResources: [MordeResource] = [
        .hosts, .sharedHosts, .workspaces, .models, .conversations, .tasks, .notifications,
    ]
    private var installationLookupKey: String?
    private var resourceLoadGeneration = UUID()
    private var resourceLoadIsInProgress = false
    private var conversationLoadGeneration = UUID()
    private var conversationLoadMoreGeneration = UUID()
    private var messageLoadMoreGeneration = UUID()
    private var taskDetailLoadGenerations: [String: UUID] = [:]
    private var clientInstallationsLoadGeneration = UUID()
    private var hostControlLoadGenerations: [String: UUID] = [:]
    private var hostControlActionGeneration = UUID()
    private var executionControlGeneration = UUID()
    private var executionControlActionGeneration = UUID()
    private var followsMainConversation = false
    private var portalSessionCredential: String?
    private var portalSessionExpiresAt: Date?
    private var portalSessionScope: MordeClientDataScope?

    private func publishShellAuthorization() {
        MordeShellAuthorization.shared.update(signedIn: signedIn, personalDataScopeKey: personalDataScopeKey,
                                              scheduleAuthorizationState: scheduleAuthorizationState)
    }

    private func scheduleGrantKey(for scope: MordeClientDataScope) -> String {
        "schedule-grant.\(scope.storageKey)"
    }

    private func validStoredScheduleGrant(_ value: MordeStoredScheduleGrant?, now: Date = Date()) -> Bool {
        guard let value, value.credential.hasPrefix("chc_"), value.credential.count <= 512,
              !value.credential.contains(where: { $0.isWhitespace }),
              let expiry = Self.parseISO8601(value.expiresAt) else { return false }
        return expiry.timeIntervalSince(now) > 0 && expiry.timeIntervalSince(now) <= 12 * 60 * 60 + 5 * 60
    }

    private func storedScheduleGrant(for scope: MordeClientDataScope, now: Date = Date()) -> MordeStoredScheduleGrant? {
        guard let raw = keychain.get(scheduleGrantKey(for: scope)), let data = raw.data(using: .utf8),
              let value = try? JSONDecoder().decode(MordeStoredScheduleGrant.self, from: data),
              validStoredScheduleGrant(value, now: now) else {
            keychain.remove(scheduleGrantKey(for: scope))
            return nil
        }
        return value
    }

    private var scheduleAuthorizationState: MordeScheduleAuthorizationState {
        guard signedIn, let installation, let scope = authorizationScope(for: installation),
              let grant = storedScheduleGrant(for: scope), let expiresAt = Self.parseISO8601(grant.expiresAt) else {
            return .disabled
        }
        return MordeScheduleAuthorizationState(enabled: true, expiresAt: expiresAt)
    }

    private func scheduleGrantCredential() throws -> String {
        guard signedIn, let installation, let scope = authorizationScope(for: installation),
              let grant = storedScheduleGrant(for: scope) else {
            publishShellAuthorization()
            throw NSError(domain: "Morde", code: 403,
                          userInfo: [NSLocalizedDescriptionKey: "云端 Schedule 尚未启用或授权已到期"])
        }
        return grant.credential
    }

    func enableCloudSchedules() async throws -> MordeScheduleAuthorizationState {
        guard signedIn, let installation, let scope = authorizationScope(for: installation) else {
            throw NSError(domain: "Morde", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "登录已到期，请重新登录"])
        }
        if storedScheduleGrant(for: scope) != nil {
            publishShellAuthorization()
            return scheduleAuthorizationState
        }
        let grant: MordeScheduleGrantResponse = try await call("/api/auth/client-schedule-grant", method: "POST")
        guard grant.credential.hasPrefix("chc_"), grant.credential.count <= 512,
              !grant.credential.contains(where: { $0.isWhitespace }),
              let expiresAt = Self.parseISO8601(grant.expires_at),
              expiresAt.timeIntervalSinceNow > 0,
              expiresAt.timeIntervalSinceNow <= 12 * 60 * 60 + 5 * 60,
              let currentInstallation = self.installation,
              authorizationScope(for: currentInstallation) == scope else {
            throw URLError(.cannotParseResponse)
        }
        let stored = MordeStoredScheduleGrant(credential: grant.credential, expiresAt: grant.expires_at)
        let data = try JSONEncoder().encode(stored)
        try keychain.set(String(decoding: data, as: UTF8.self), key: scheduleGrantKey(for: scope))
        publishShellAuthorization()
        return scheduleAuthorizationState
    }

    func disableCloudSchedules() async throws -> MordeScheduleAuthorizationState {
        guard signedIn, let installation, let scope = authorizationScope(for: installation) else {
            throw NSError(domain: "Morde", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "登录已到期，请重新登录"])
        }
        let _: MordeEmpty = try await call("/api/auth/client-schedule-grant", method: "DELETE")
        keychain.remove(scheduleGrantKey(for: scope))
        publishShellAuthorization()
        return scheduleAuthorizationState
    }

    private func validScheduleID(_ id: String) -> Bool {
        id != "." && id != ".." && id.range(of: "^[A-Za-z0-9._~-]{1,128}$", options: .regularExpression) != nil
    }

    private func scheduleIdempotencyKeyIsValid(_ key: String) -> Bool {
        key.range(of: "^[A-Za-z0-9][A-Za-z0-9._:-]{7,127}$", options: .regularExpression) != nil
    }

    private func jsonDictionary<Value: Encodable>(_ value: Value) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }
        return dictionary
    }

    private func validSchedule(_ value: MordeScheduleDTO) -> Bool {
        validScheduleID(value.id) && value.version > 0 && !value.host_id.isEmpty &&
            !value.model_id.isEmpty && !value.objective.isEmpty
    }

    func scheduleTargets() async throws -> MordeScheduleTargets {
        guard signedIn else {
            throw NSError(domain: "Morde", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "登录已到期，请重新登录"])
        }
        guard resourceState(.hosts).isLoaded, resourceState(.models).isLoaded else {
            throw NSError(domain: "Morde", code: 503,
                          userInfo: [NSLocalizedDescriptionKey: "Host 或模型列表尚未就绪，请先刷新 Morde 资源。"])
        }
        let runnableHosts = hosts.filter(hostIsReady).map {
            MordeScheduleTargetOption(id: $0.id, name: $0.name.isEmpty ? $0.id : $0.name)
        }
        let capableModels = models.filter { $0.capabilities.text && $0.capabilities.tools }.map {
            MordeScheduleTargetOption(id: $0.id, name: $0.name.isEmpty ? $0.id : $0.name)
        }
        return MordeScheduleTargets(hosts: runnableHosts, models: capableModels)
    }

    func schedules(status: String?, limit: Int, cursor: String?) async throws -> MordeScheduleListPage {
        guard (1...100).contains(limit), status.map({ ["enabled", "disabled", "completed"].contains($0) }) ?? true,
              cursor.map({ $0.count <= 2048 }) ?? true else { throw URLError(.badURL) }
        var components = URLComponents()
        components.path = "/api/schedules"
        components.queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        if let status { components.queryItems?.append(URLQueryItem(name: "status", value: status)) }
        if let cursor, !cursor.isEmpty { components.queryItems?.append(URLQueryItem(name: "cursor", value: cursor)) }
        guard let path = components.string else { throw URLError(.badURL) }
        let page: MordeScheduleListPage = try await call(path, scheduleAuthorized: true)
        guard page.next_cursor.count <= 2048, page.items.allSatisfy(validSchedule) else {
            throw URLError(.cannotParseResponse)
        }
        return page
    }

    func schedule(id: String) async throws -> MordeScheduleDTO {
        guard validScheduleID(id) else { throw URLError(.badURL) }
        let value: MordeScheduleDTO = try await call("/api/schedules/\(id)", scheduleAuthorized: true)
        guard validSchedule(value), value.id == id else { throw URLError(.cannotParseResponse) }
        return value
    }

    func createSchedule(_ value: MordeScheduleCreateRequest,
                        idempotencyKey: String) async throws -> MordeScheduleDTO {
        guard scheduleIdempotencyKeyIsValid(idempotencyKey) else { throw URLError(.badURL) }
        let created: MordeScheduleDTO = try await call("/api/schedules", method: "POST",
            body: jsonDictionary(value), key: idempotencyKey, scheduleAuthorized: true)
        guard validSchedule(created) else { throw URLError(.cannotParseResponse) }
        return created
    }

    func updateSchedule(id: String, request value: MordeScheduleUpdateRequest,
                        idempotencyKey: String) async throws -> MordeScheduleDTO {
        guard validScheduleID(id), value.expected_version > 0,
              scheduleIdempotencyKeyIsValid(idempotencyKey) else { throw URLError(.badURL) }
        let updated: MordeScheduleDTO = try await call("/api/schedules/\(id)", method: "PUT",
            body: jsonDictionary(value), key: idempotencyKey, scheduleAuthorized: true)
        guard validSchedule(updated), updated.id == id else { throw URLError(.cannotParseResponse) }
        return updated
    }

    func scheduleAction(id: String, request value: MordeScheduleActionRequest,
                        idempotencyKey: String) async throws -> MordeScheduleActionResponse {
        guard validScheduleID(id), value.expected_version > 0,
              ["enable", "disable"].contains(value.action),
              value.current_run_action.map({ ["continue", "cancel"].contains($0) }) ?? true,
              scheduleIdempotencyKeyIsValid(idempotencyKey) else { throw URLError(.badURL) }
        let result: MordeScheduleActionResponse = try await call("/api/schedules/\(id)/actions", method: "POST",
            body: jsonDictionary(value), key: idempotencyKey, scheduleAuthorized: true)
        guard validSchedule(result.schedule), result.schedule.id == id else { throw URLError(.cannotParseResponse) }
        if let run = result.current_run, run.schedule_id != id || !validScheduleID(run.id) {
            throw URLError(.cannotParseResponse)
        }
        return result
    }

    func scheduleRuns(id: String, limit: Int, cursor: String?) async throws -> MordeScheduleRunListPage {
        guard validScheduleID(id), (1...100).contains(limit), cursor.map({ $0.count <= 2048 }) ?? true else {
            throw URLError(.badURL)
        }
        var components = URLComponents()
        components.path = "/api/schedules/\(id)/runs"
        components.queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        if let cursor, !cursor.isEmpty { components.queryItems?.append(URLQueryItem(name: "cursor", value: cursor)) }
        guard let path = components.string else { throw URLError(.badURL) }
        let page: MordeScheduleRunListPage = try await call(path, scheduleAuthorized: true)
        guard page.next_cursor.count <= 2048,
              page.items.allSatisfy({ $0.schedule_id == id && validScheduleID($0.id) }) else {
            throw URLError(.cannotParseResponse)
        }
        return page
    }

    func taskPage(status: String? = nil, cursor: String? = nil) async throws -> MordePage<MordeTask> {
        let statuses = ["queued", "running", "waiting_user", "pausing", "paused", "cancelling",
                        "completed", "failed", "cancelled"]
        guard status.map({ statuses.contains($0) }) ?? true,
              cursor.map({ $0.count <= 2048 }) ?? true,
              let scope = currentDataScope else { throw URLError(.badURL) }
        var components = URLComponents()
        components.path = "/api/tasks"
        components.queryItems = [URLQueryItem(name: "limit", value: "100")]
        if let status { components.queryItems?.append(URLQueryItem(name: "status", value: status)) }
        if let cursor, !cursor.isEmpty { components.queryItems?.append(URLQueryItem(name: "cursor", value: cursor)) }
        guard let path = components.string else { throw URLError(.badURL) }
        let page: MordePage<MordeTask> = try await call(path)
        guard scope == currentDataScope, page.next_cursor.map({ $0.count <= 2048 }) ?? true,
              page.next_cursor.map({ !$0.isEmpty && $0 != cursor }) ?? true,
              page.items.allSatisfy({ MordeTaskResponsePolicy.hasValidTaskID($0.id) }),
              Set(page.items.map(\.id)).count == page.items.count else {
            throw URLError(.cannotParseResponse)
        }
        return page
    }

    func task(id: String) async throws -> MordeTask {
        guard MordeTaskResponsePolicy.hasValidTaskID(id), let scope = currentDataScope else {
            throw URLError(.badURL)
        }
        let generation = UUID()
        taskDetailLoadGenerations[id] = generation
        defer { if taskDetailLoadGenerations[id] == generation { taskDetailLoadGenerations.removeValue(forKey: id) } }
        let value: MordeTask = try await call("/api/tasks/\(id)")
        guard scope == currentDataScope, taskDetailLoadGenerations[id] == generation else {
            throw CancellationError()
        }
        guard value.id == id else { throw URLError(.cannotParseResponse) }
        taskPageDetails[id] = value
        return value
    }

    @discardableResult
    func actOnTaskPage(taskID: String, action: MordeTaskPageAction) async -> Bool {
        guard let task = taskPageDetails[taskID],
              let path = MordeTaskResponsePolicy.actionPath(taskID: taskID) else { return false }
        let body: [String: Any]
        switch action {
        case .pause(let expectedStatus):
            guard task.status == expectedStatus, ["queued", "running"].contains(expectedStatus) else { return false }
            body = ["action": "pause", "expected_status": expectedStatus]
        case .resume:
            guard task.status == "paused" else { return false }
            body = ["action": "resume", "expected_status": "paused"]
        case .cancel(let expectedStatus):
            guard task.status == expectedStatus,
                  ["queued", "running", "paused", "waiting_user"].contains(expectedStatus) else { return false }
            body = ["action": "cancel", "expected_status": expectedStatus]
        case .retryBatchItem(let id):
            guard task.status == "failed",
                  let item = task.batch_items?.first(where: { $0.id == id }),
                  canRetryMordeBatchItem(taskStatus: task.status, itemStatus: item.status) else { return false }
            body = ["action": "retry_batch_item", "batch_item_id": id]
        }
        return await submitTaskAction(taskID: taskID, path: path, body: body,
                                      updateCurrentTask: currentTask?.id == taskID)
    }

    @discardableResult
    func respondToTaskPageApproval(taskID: String, approvalID: String, version: Int,
                                   decision: String) async -> Bool {
        guard let task = taskPageDetails[taskID],
              let pending = task.pending_request, pending.id == approvalID, pending.version == version,
              pending.kind == nil || pending.kind == "approval",
              let path = MordeTaskResponsePolicy.approvalPath(taskID: taskID, approvalID: approvalID),
              ["approve", "reject"].contains(decision) else {
            taskPageActionErrors[taskID] = "审批请求已失效，请刷新 Task 后重试。"
            return false
        }
        return await submitTaskAction(taskID: taskID, path: path,
                                      body: ["version": version, "decision": decision],
                                      updateCurrentTask: currentTask?.id == taskID)
    }

    // nanoMuse: Task pages can answer requests even when the task is not selected in chat.
    @discardableResult
    func answerTaskPageClarification(taskID: String, clarificationID: String, version: Int,
                                     answer: String) async -> Bool {
        let text = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let task = taskPageDetails[taskID],
              let clarification = task.clarification_request,
              clarification.id == clarificationID, clarification.version == version,
              version > 0, MordeTaskResponsePolicy.hasValidRequestID(clarificationID),
              MordeTaskResponsePolicy.hasValidAnswer(text),
              let path = MordeTaskResponsePolicy.inputPath(taskID: taskID) else {
            taskPageActionErrors[taskID] = "请检查补充信息内容，并刷新 Task 状态后重试。"
            return false
        }
        return await submitTaskAction(taskID: taskID, path: path,
                                      body: ["clarification_id": clarificationID,
                                             "clarification_version": version, "answer": text],
                                      updateCurrentTask: currentTask?.id == taskID)
    }

    private var personalDataScopeKey: String? {
        guard signedIn, let user, let instanceID = verifiedServiceInstanceID,
              let origin = MordeLoginStateStore.serviceOrigin(server),
              let scope = MordeClientDataScope(serviceOrigin: origin, serviceInstanceID: instanceID,
                                               accountID: user.id, installationID: "personal-data-v1") else { return nil }
        return scope.storageKey
    }

    func resourceState(_ resource: MordeResource) -> MordeResourceLoadState {
        resourceStates[resource] ?? .loading
    }

    func loadDefaultHostPreference() async {
        guard let scope = currentDataScope else {
            defaultHostID = nil
            defaultHostPreferenceState = .failed("Not signed in to Morde.")
            return
        }
        defaultHostPreferenceState = .loading
        do {
            let preferences: MordeUserPreferences = try await portalCall("/api/me/preferences", expectedScope: scope)
            guard scope == currentDataScope else { return }
            if let id = preferences.default_host_id,
               id.range(of: #"^h[a-z0-9]{7}$"#, options: .regularExpression) == nil {
                throw URLError(.cannotParseResponse)
            }
            defaultHostID = preferences.default_host_id
            defaultHostPreferenceState = .loaded
        } catch {
            guard scope == currentDataScope else { return }
            defaultHostID = nil
            defaultHostPreferenceState = .failed(error.localizedDescription)
        }
    }

    private func setResourceState(_ state: MordeResourceLoadState, for resource: MordeResource) {
        var updated = resourceStates
        updated[resource] = state
        resourceStates = updated
    }

    private func messagesIncludingAssistantSnapshot(_ task: MordeTask, in messages: [MordeClientMessage]) -> [MordeClientMessage] {
        MordeTaskSnapshotMessageMerge.merge(messages, snapshot: task.assistant_message,
                                            taskID: task.id, conversationID: task.conversation_id)
    }

    private func applyCurrentTaskAssistantSnapshot(_ task: MordeTask) {
        guard MordeConversationTaskState.belongs(taskConversationID: task.conversation_id,
                                               toSelectedConversationID: currentConversation) else { return }
        messages = messagesIncludingAssistantSnapshot(task, in: messages)
    }

    private func beginResourceLoad() -> UUID {
        let generation = UUID()
        resourceLoadGeneration = generation
        hosts = []; sharedHosts = []; workspaces = []; models = []
        defaultModelConfigured = false; defaultModelID = nil; personalModelIDs = []
        conversations = []; conversationNextCursor = nil; tasks = []; notifications = []
        notificationNextCursor = nil; loadingMoreNotifications = false
        for resource in Self.listResources { setResourceState(.loading, for: resource) }
        return generation
    }

    private func markListResourcesFailed(_ message: String, generation: UUID) {
        guard generation == resourceLoadGeneration else { return }
        for resource in Self.listResources { setResourceState(.failed(message), for: resource) }
    }

    private func loadResource<Value>(
        _ resource: MordeResource,
        generation: UUID,
        fetch: () async throws -> Value,
        apply: (Value) -> Void,
        clear: () -> Void
    ) async {
        guard generation == resourceLoadGeneration else { return }
        setResourceState(.loading, for: resource)
        do {
            let value = try await fetch()
            guard generation == resourceLoadGeneration, !Task.isCancelled else { return }
            apply(value)
            setResourceState(.loaded, for: resource)
        } catch {
            guard generation == resourceLoadGeneration, !Task.isCancelled else { return }
            clear()
            setResourceState(.failed(error.localizedDescription), for: resource)
        }
    }

    init() {
        if let savedServer = UserDefaults.standard.string(forKey: "morde.server")?.trimmingCharacters(in: .whitespacesAndNewlines),
           !savedServer.isEmpty {
            self.server = savedServer
        } else {
            self.server = Self.defaultServer
        }
        if let origin = MordeLoginStateStore.serviceOrigin(self.server) {
            self.installationLookupKey = Self.activeInstallationMap()[origin]
        }
        if !revocationStore.pending().isEmpty {
            self.error = "有服务器安装撤销尚未确认；本机已退出并保留撤销标识。"
        }
    }

    private static func activeInstallationMap() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: activeInstallationsKey) as? [String: String] ?? [:]
    }

    private static func installationLookupKey(origin: String, serviceInstanceID: String,
                                              accountName: String) -> String? {
        MordeClientDataScope.installationLookupKey(origin: origin, serviceInstanceID: serviceInstanceID,
                                                   accountName: accountName)
    }

    private func storedInstallation(_ lookupKey: String) -> MordeInstallation? {
        guard let data = UserDefaults.standard.data(forKey: Self.scopedInstallationPrefix + lookupKey) else { return nil }
        return try? JSONDecoder().decode(MordeInstallation.self, from: data)
    }
    private func installationForLogin(origin: String, serviceInstanceID: String,
                                      accountName: String) -> (installation: MordeInstallation, lookupKey: String)? {
        if let key = Self.installationLookupKey(origin: origin, serviceInstanceID: serviceInstanceID,
                                                accountName: accountName),
           let record = storedInstallation(key), record.revocationStatus == "active",
           MordeLoginContract.mayRenewInstallation(
            installationOrigin: record.serviceOrigin, installationServiceInstanceID: record.serviceInstanceID,
            selectedServer: origin, selectedServiceInstanceID: serviceInstanceID,
            legacyServer: nil, installationAccount: record.accountName, accountName: accountName) {
            return (record, key)
        }
        if let legacy = legacyInstallation,
           MordeLoginContract.mayRenewInstallation(
            installationOrigin: legacy.serviceOrigin, installationServiceInstanceID: legacy.serviceInstanceID,
            selectedServer: origin, selectedServiceInstanceID: serviceInstanceID,
            legacyServer: UserDefaults.standard.string(forKey: "morde.server"),
            installationAccount: legacy.accountName, accountName: accountName),
           let key = Self.installationLookupKey(origin: origin, serviceInstanceID: serviceInstanceID,
                                                accountName: accountName) {
            return (legacy, key)
        }
        return nil
    }
    private func saveInstallation(_ installation: MordeInstallation, lookupKey: String,
                                  makeActive: Bool) throws {
        let data = try JSONEncoder().encode(installation)
        UserDefaults.standard.set(data, forKey: Self.scopedInstallationPrefix + lookupKey)
        guard makeActive,
              let origin = installation.serviceOrigin.flatMap(MordeLoginStateStore.serviceOrigin) else { return }
        var active = Self.activeInstallationMap()
        active[origin] = lookupKey
        UserDefaults.standard.set(active, forKey: Self.activeInstallationsKey)
        installationLookupKey = lookupKey
    }
    private func updateActiveInstallation(_ installation: MordeInstallation) {
        guard let lookupKey = installationLookupKey,
              let data = try? JSONEncoder().encode(installation) else { return }
        UserDefaults.standard.set(data, forKey: Self.scopedInstallationPrefix + lookupKey)
    }
    private func revocationScope(for installation: MordeInstallation) -> MordeClientDataScope? {
        guard let origin = installation.serviceOrigin,
              let serviceID = installation.serviceInstanceID else { return nil }
        let accountID = user?.id ?? installation.accountID ?? installation.accountName
        return MordeClientDataScope(serviceOrigin: origin, serviceInstanceID: serviceID,
                                    accountID: accountID, installationID: installation.id)
    }

    private var authorization: MordeAuthorization? {
        guard let installation,
              let serviceID = installation.serviceInstanceID,
              verifiedServiceInstanceID == serviceID,
              let scope = authorizationScope(for: installation),
              let raw = keychain.get("authorization.\(scope.storageKey)"),
              let data = raw.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(MordeAuthorization.self, from: data)
    }
    private func authorizationScope(for installation: MordeInstallation) -> MordeClientDataScope? {
        guard let origin = MordeLoginStateStore.serviceOrigin(server),
              installation.serviceOrigin == origin,
              let serviceID = installation.serviceInstanceID else { return nil }
        return MordeClientDataScope(serviceOrigin: origin, serviceInstanceID: serviceID,
                                    accountID: installation.accountName, installationID: installation.id)
    }
    private var installation: MordeInstallation? {
        guard let lookupKey = installationLookupKey,
              let installation = storedInstallation(lookupKey),
              installation.revocationStatus == "active",
              installation.serviceInstanceID != nil,
              installation.serviceOrigin == MordeLoginStateStore.serviceOrigin(server) else { return nil }
        return installation
    }
    private var legacyInstallation: MordeInstallation? {
        guard let data = UserDefaults.standard.data(forKey: "morde.installation") else { return nil }
        return try? JSONDecoder().decode(MordeInstallation.self, from: data)
    }
    private var currentDataScope: MordeClientDataScope? {
        guard let installation, let user,
              let serviceID = installation.serviceInstanceID,
              verifiedServiceInstanceID == serviceID,
              installation.accountID == nil || installation.accountID == user.id,
              let origin = MordeLoginStateStore.serviceOrigin(server) else { return nil }
        return MordeClientDataScope(serviceOrigin: origin, serviceInstanceID: serviceID,
                                    accountID: user.id, installationID: installation.id)
    }
    var taskPageScopeKey: String? { currentDataScope?.storageKey }
    private var recentConversation: MordeScopedRecentConversation? {
        guard let scope = currentDataScope,
              let data = UserDefaults.standard.data(forKey: "morde.recentConversation.\(scope.storageKey)"),
              let recent = try? JSONDecoder().decode(MordeScopedRecentConversation.self, from: data),
              recent.matches(scope: scope) else { return nil }
        return recent
    }
    private func saveRecentConversation(_ conversationID: String?) {
        guard let scope = currentDataScope else { return }
        let recent = MordeScopedRecentConversation(scope: scope, conversationID: conversationID)
        guard let data = try? JSONEncoder().encode(recent) else { return }
        UserDefaults.standard.set(data, forKey: "morde.recentConversation.\(scope.storageKey)")
    }
    private func pendingSendAttempt(for scope: MordeClientDataScope) -> MordeRetryAttempt? {
        MordeRetryAttempt.decodePersisted(from: .standard, scope: scope)
    }
    private func storePendingSendAttempt(_ attempt: MordeRetryAttempt?, for scope: MordeClientDataScope) {
        let storageKey = "morde.pendingSendAttempt.\(scope.storageKey)"
        guard let attempt else {
            UserDefaults.standard.removeObject(forKey: storageKey)
            return
        }
        guard attempt.scope == scope, let data = try? JSONEncoder().encode(attempt) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
    private func clearPendingSend(for scope: MordeClientDataScope, matching key: String) {
        guard pendingSendAttempt(for: scope)?.key == key else { return }
        storePendingSendAttempt(nil, for: scope)
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

    private func clearAuthorization(for installation: MordeInstallation) {
        if let scope = authorizationScope(for: installation) {
            keychain.remove("authorization.\(scope.storageKey)")
        }
    }
    private func clearLegacyAuthorization() {
        keychain.remove("authorization")
        keychain.remove("credential")
    }

    func refreshExpiredAuthorization(now: Date = Date()) {
        guard let authorization,
              MordeCredentialExpiry.status(expiresAt: authorization.expiresAt, now: now) == .expired else { return }
        if let installation { clearAuthorization(for: installation) }
        resetViewState()
        error = "登录已到期，请重新登录"
    }

    func authorizationExpiryDelay(at now: Date = Date()) -> TimeInterval? {
        MordeCredentialExpiry.secondsUntilExpiry(expiresAt: authorization?.expiresAt, now: now)
    }

    private func checkCapabilities() async throws -> MordeCapabilities {
        // nanoMuse: Keep submission disabled while the capability endpoint is pending or has failed.
        cloudTasksAvailable = nil
        taskAPIAvailable = nil
        workspaceSyncAvailable = nil
        projectBudgetExecutionAvailable = nil
        projectWorkItemsV2Available = nil
        hubAvailable = nil
        taskMediaGenerationAvailable = nil
        let capabilities: MordeCapabilities
        do {
            capabilities = try await call("/api/capabilities", authorized: false)
        } catch {
            let nsError = error as NSError
            let failure = MordeCapabilitiesFailure.classify(domain: nsError.domain, code: nsError.code)
            throw NSError(domain: "Morde.Capabilities", code: nsError.code,
                          userInfo: [NSLocalizedDescriptionKey: failure.message(underlying: error.localizedDescription)])
        }
        let instanceID = UUID(uuidString: capabilities.service_instance_id)
        guard instanceID != nil, capabilities.service_instance_id.lowercased() != "00000000-0000-0000-0000-000000000000",
              capabilities.api_version == "1",
              MordeLoginContract.supportsOrderedClientLogin(capabilities.supported_features) else {
            throw NSError(domain: "Morde.Capabilities", code: 426,
                          userInfo: [NSLocalizedDescriptionKey: MordeCapabilitiesFailure.incompatible.message()])
        }
        if let minimum = capabilities.minimum_client_version {
            let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            guard MordeClientVersion.meetsMinimum(current: current, minimum: minimum) else {
                throw NSError(domain: "Morde.Capabilities", code: 426,
                              userInfo: [NSLocalizedDescriptionKey: MordeCapabilitiesFailure.minimumVersion.message()])
            }
        }
        cloudTasksAvailable = MordeTaskCapability.cloudWorkerIsAvailable(capabilities.supported_features)
        taskAPIAvailable = MordeTaskCapability.taskAPIIsAvailable(capabilities.supported_features)
        workspaceSyncAvailable = MordeWorkspaceSyncCapability.isAvailable(capabilities.supported_features)
        projectBudgetExecutionAvailable = MordeProjectExecutionCapability.isAvailable(capabilities.supported_features)
        projectWorkItemsV2Available = capabilities.supported_features.contains("project_work_items_v2")
        hubAvailable = capabilities.hub_version == "1" && capabilities.supported_features.contains("hub")
        taskMediaGenerationAvailable = MordeTaskCapability.mediaGenerationIsAvailable(capabilities.supported_features)
        return capabilities
    }

    func setServer(_ value: String) throws {
        guard let url = URL(string: value), let normalized = MordeLoginStateStore.serviceOrigin(value),
              (url.path.isEmpty || url.path == "/"),
              url.user == nil, url.password == nil, url.query == nil, url.fragment == nil else {
            throw NSError(domain: "Morde", code: 1, userInfo: [NSLocalizedDescriptionKey: "请输入 HTTPS 服务地址"])
        }
        let previousServer = UserDefaults.standard.string(forKey: "morde.server") ?? server
        let previousOrigin = MordeLoginStateStore.serviceOrigin(previousServer)
        let nextOrigin = MordeLoginStateStore.serviceOrigin(normalized)
        if previousOrigin != nextOrigin {
            if let previousOrigin { try? loginStateStore.invalidatePendingAttempts(origin: previousOrigin) }
            verifiedServiceInstanceID = nil
            resetViewState()
        }
        server = normalized
        installationLookupKey = nextOrigin.flatMap { Self.activeInstallationMap()[$0] }
        UserDefaults.standard.set(normalized, forKey: "morde.server")
    }

    private func resetViewState() {
        // nanoMuse: Keep the original app shell's Morde sign-in gate in sync with local authorization resets.
        resourceLoadGeneration = UUID()
        resourceLoadIsInProgress = false
        conversationLoadGeneration = UUID()
        conversationLoadMoreGeneration = UUID()
        messageLoadMoreGeneration = UUID()
        taskDetailLoadGenerations = [:]
        clientInstallationsLoadGeneration = UUID()
        devicesLoadGeneration = UUID()
        projectLoadGeneration = UUID()
        projectDetailLoadGeneration = UUID()
        projectExecutionLoadGeneration = UUID()
        projectConversationLoadGeneration = UUID()
        projectConversationMessagesGeneration = UUID()
        hostControlLoadGenerations = [:]
        hostRestoreInFlightID = nil
        hostControlActionGeneration = UUID()
        user = nil; hosts = []; sharedHosts = []; workspaces = []; models = []
        defaultModelConfigured = false; defaultModelID = nil; personalModelIDs = []
        defaultHostID = nil; defaultHostPreferenceState = .failed("Not signed in to Morde.")
        hostOpenErrors = [:]
        conversations = []; conversationNextCursor = nil; loadingMoreConversations = false
        messages = []; messageNextCursor = nil; loadingEarlierMessages = false; messageHistoryError = nil
        tasks = []; notifications = []; notificationNextCursor = nil
        taskPageDetails = [:]; taskTimelineEvents = [:]; taskTimelineErrors = [:]
        taskTimelineHistoryExpired = []; taskTimelineLoading = []; taskTimelineNoHistory = []
        taskPageActionErrors = [:]
        loadingMoreNotifications = false
        clientInstallations = []
        hostControlStatuses = [:]; hostControlErrors = [:]; hostControlActionInFlightFor = nil
        devices = []; devicesState = .failed(String(localized: "Not signed in to Morde."))
        hubRelayError = nil; hubRelayNotice = nil; hubRelayWorkingID = nil
        projects = []; projectInvitations = []; projectMembers = []; projectResources = []
        projectWorkItems = []; projectBudget = nil; projectBudgetLedger = []
        projectWorkItemsState = .failed("Not signed in to Morde.")
        projectBudgetState = .failed("Not signed in to Morde.")
        projectConversations = []; selectedProjectConversationID = nil; projectConversationMessages = []
        projectConversationTask = nil; projectConversationError = nil
        projectConversationsState = .failed("Not signed in to Morde.")
        projectConversationMessagesState = .failed("Not signed in to Morde.")
        recentProjectInvitations = [:]; selectedProjectID = nil
        projectsState = .failed("Not signed in to Morde.")
        projectInvitationsState = .failed("Not signed in to Morde.")
        projectDetailState = .failed("Not signed in to Morde.")
        projectActionInFlight = false; projectActionError = nil; projectNotice = nil
        clientInstallationsState = .failed(String(localized: "Not signed in to Morde."))
        clientInstallationsActionError = nil; clientInstallationsNotice = nil
        revokingClientInstallationID = nil
        currentConversation = nil; currentTask = nil; hostURL = nil
        mainConversation = nil; mainConversationLoadError = nil; followsMainConversation = false
        executionControl = nil; executionControlError = nil; executionControlIsLoading = false
        executionControlActionInFlight = false
        executionControlGeneration = UUID(); executionControlActionGeneration = UUID()
        portalSessionCredential = nil; portalSessionExpiresAt = nil; portalSessionScope = nil
        cloudTasksAvailable = nil
        taskAPIAvailable = nil
        workspaceSyncAvailable = nil
        projectBudgetExecutionAvailable = nil
        projectWorkItemsV2Available = nil
        hubAvailable = nil
        taskMediaGenerationAvailable = nil
        for resource in MordeResource.allCases { setResourceState(.loading, for: resource) }
        retryAction = nil
        retryActionScopeKey = nil
        publishShellAuthorization()
    }

    private func call<T: Decodable>(_ path: String, method: String = "GET", body: [String: Any]? = nil,
                                    key: String? = nil, authorized: Bool = true,
                                    handleUnauthorized: Bool = true,
                                    scheduleAuthorized: Bool = false,
                                    rawBody: Data? = nil, contentType: String? = nil,
                                    headers: [String: String] = [:]) async throws -> T {
        let (data, _) = try await responseData(path, method: method, body: body, key: key,
            authorized: authorized, handleUnauthorized: handleUnauthorized,
            scheduleAuthorized: scheduleAuthorized, rawBody: rawBody, contentType: contentType, headers: headers)
        return try JSONDecoder().decode(T.self, from: data.isEmpty ? Data("{}".utf8) : data)
    }

    private func responseData(_ path: String, method: String, body: [String: Any]?, key: String?,
                              authorized: Bool, handleUnauthorized: Bool, scheduleAuthorized: Bool,
                              rawBody: Data? = nil, contentType: String? = nil,
                              headers: [String: String] = [:]) async throws -> (Data, HTTPURLResponse) {
        guard body == nil || rawBody == nil else { throw URLError(.badURL) }
        let requestServer = server
        let requestInstallation = installation
        let requestOrigin = MordeLoginStateStore.serviceOrigin(requestServer)
        let requestScope = requestInstallation.flatMap { authorizationScope(for: $0) }
        let credential: String?
        if scheduleAuthorized {
            credential = try scheduleGrantCredential()
        } else if authorized {
            refreshExpiredAuthorization()
            guard let validCredential = token else {
                throw NSError(domain: "Morde", code: 401,
                              userInfo: [NSLocalizedDescriptionKey: "登录已到期，请重新登录"])
            }
            credential = validCredential
        } else { credential = nil }
        guard let base = URL(string: requestServer), let url = URL(string: path, relativeTo: base)?.absoluteURL,
              requestOrigin != nil, url.host == base.host, url.port == base.port, url.scheme == base.scheme else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpShouldHandleCookies = false
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Request-Id")
        if let credential { request.setValue("Bearer \(credential)", forHTTPHeaderField: "Authorization") }
        if let key { request.setValue(key, forHTTPHeaderField: "Idempotency-Key") }
        for (name, value) in headers { request.setValue(value, forHTTPHeaderField: name) }
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains(MordeAuthURLProtocol.taskSequentialSendFixtureLaunchArgument),
           method == "POST", path == "/api/conversations/c1234567/messages",
           let content = body?["content"] as? String {
            request.setValue(content, forHTTPHeaderField: "X-Morde-Local-Task-Prompt")
        }
        if ProcessInfo.processInfo.arguments.contains(MordeAuthURLProtocol.taskMediaFixtureLaunchArgument),
           method == "POST", path == "/api/tasks/q1234567/approvals/r1234567/responses",
           let decision = body?["decision"] as? String {
            request.setValue(decision, forHTTPHeaderField: "X-Morde-Local-Task-Decision")
        }
#endif
        if let body {
            request.setValue(contentType ?? "application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } else if let rawBody {
            if let contentType { request.setValue(contentType, forHTTPHeaderField: "Content-Type") }
            request.httpBody = rawBody
        }
        let data: Data
        let response: URLResponse
        (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        var recordedUnconfirmedLogout = false
        if http.statusCode == 401 && scheduleAuthorized, let credential,
           let currentInstallation = installation,
           let currentScope = authorizationScope(for: currentInstallation),
           storedScheduleGrant(for: currentScope)?.credential == credential {
            keychain.remove(scheduleGrantKey(for: currentScope))
            publishShellAuthorization()
        }
        if http.statusCode == 401 && authorized && !scheduleAuthorized && handleUnauthorized,
           let credential, let requestScope, let requestOrigin, let requestInstallation,
           MordeUnauthorizedResponsePolicy.shouldClearAuthorization(
            requestCredential: credential, currentCredential: token, requestScope: requestScope,
            currentScope: installation.flatMap { authorizationScope(for: $0) },
            hasPendingLoginIntent: loginStateStore.hasPendingIntent(
                origin: requestOrigin, accountName: requestInstallation.accountName),
            isCancelled: Task.isCancelled) {
            signOutLocally(installation: requestInstallation)
            recordedUnconfirmedLogout = true
        }
        guard (200..<300).contains(http.statusCode) else {
            if let conflict = MordePersonalRevisionConflict.decode(data) { throw conflict }
            let reason = try? JSONDecoder().decode(MordeError.self, from: data)
            throw NSError(domain: "Morde", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: recordedUnconfirmedLogout
                            ? "本机已退出；服务器安装撤销尚未确认，撤销标识已保留。"
                            : (reason?.displayMessage ?? "请求失败 (\(http.statusCode))")])
        }
        return (data, http)
    }

    private func downloadResponseFile(_ path: String) async throws -> (URL, HTTPURLResponse) {
        let requestServer = server
        let requestInstallation = installation
        let requestOrigin = MordeLoginStateStore.serviceOrigin(requestServer)
        let requestScope = requestInstallation.flatMap { authorizationScope(for: $0) }
        refreshExpiredAuthorization()
        guard let credential = token else {
            throw NSError(domain: "Morde", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "登录已到期，请重新登录"])
        }
        guard let base = URL(string: requestServer), let url = URL(string: path, relativeTo: base)?.absoluteURL,
              requestOrigin != nil, url.host == base.host, url.port == base.port, url.scheme == base.scheme else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = false
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Request-Id")
        request.setValue("Bearer \(credential)", forHTTPHeaderField: "Authorization")
        let temporaryURL: URL
        let response: URLResponse
#if DEBUG
        if MordeAuthURLProtocol.usesLocalFixture {
            // URLSession download tasks bypass the app's URLProtocol fixtures.
            let (data, fixtureResponse) = try await urlSession.data(for: request)
            let fixtureFile = FileManager.default.temporaryDirectory
                .appendingPathComponent("morde-fixture-download-\(UUID().uuidString.lowercased())")
            try data.write(to: fixtureFile, options: .atomic)
            temporaryURL = fixtureFile
            response = fixtureResponse
        } else {
            (temporaryURL, response) = try await urlSession.download(for: request)
        }
#else
        (temporaryURL, response) = try await urlSession.download(for: request)
#endif
        guard let http = response as? HTTPURLResponse else {
            try? FileManager.default.removeItem(at: temporaryURL)
            throw URLError(.badServerResponse)
        }
        var recordedUnconfirmedLogout = false
        if http.statusCode == 401, let currentInstallation = installation,
           let currentScope = authorizationScope(for: currentInstallation), let requestScope,
           MordeUnauthorizedResponsePolicy.shouldClearAuthorization(
            requestCredential: credential, currentCredential: token, requestScope: requestScope,
            currentScope: currentScope,
            hasPendingLoginIntent: requestOrigin.map {
                loginStateStore.hasPendingIntent(origin: $0, accountName: currentInstallation.accountName)
            } ?? false,
            isCancelled: Task.isCancelled) {
            signOutLocally(installation: requestInstallation)
            recordedUnconfirmedLogout = true
        }
        guard (200..<300).contains(http.statusCode) else {
            let data = (try? Data(contentsOf: temporaryURL)) ?? Data()
            try? FileManager.default.removeItem(at: temporaryURL)
            let reason = try? JSONDecoder().decode(MordeError.self, from: data)
            throw NSError(domain: "Morde", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: recordedUnconfirmedLogout
                            ? "本机已退出；服务器安装撤销尚未确认，撤销标识已保留。"
                            : (reason?.displayMessage ?? "请求失败 (\(http.statusCode))")])
        }
        return (temporaryURL, http)
    }

    private func personalObjectPath(type: String, id: String) throws -> String {
        guard MordePersonalDataContract.isValidObjectIdentifier(type: type, id: id) else { throw URLError(.badURL) }
        return "/api/personal-data/\(type)/\(id)"
    }

    func personalObject(objectType: String, objectID: String) async throws -> MordePersonalSyncObject? {
        let path = try personalObjectPath(type: objectType, id: objectID)
        do {
            let object: MordePersonalSyncObject = try await call(path)
            guard object.object_type == objectType, object.object_id == objectID, object.revision > 0,
                  case .object = object.body,
                  ((try? JSONEncoder().encode(object.body).count) ?? Int.max) <= 1_048_576 else {
                throw URLError(.cannotParseResponse)
            }
            return object
        } catch let error as NSError where error.domain == "Morde" && error.code == 404 {
            return nil
        }
    }

    func replacePersonalObject(objectType: String, objectID: String, baseRevision: Int64,
                               body: MordePersonalJSONValue, idempotencyKey: String) async throws -> MordePersonalMutationReceipt {
        guard MordePersonalDataContract.mutationObjectTypes.contains(objectType),
              MordePersonalDataContract.isValidObjectIdentifier(type: objectType, id: objectID),
              baseRevision >= 0, MordePersonalDataContract.isValidIdempotencyKey(idempotencyKey),
              case .object = body else { throw URLError(.badURL) }
        let encoded = try JSONEncoder().encode(body)
        guard encoded.count <= 1_048_576,
              let bodyObject = try JSONSerialization.jsonObject(with: encoded) as? [String: Any] else {
            throw URLError(.dataLengthExceedsMaximum)
        }
        let receipt: MordePersonalMutationReceipt = try await call(
            try personalObjectPath(type: objectType, id: objectID), method: "PUT",
            body: ["base_revision": baseRevision, "body": bodyObject], key: idempotencyKey)
        guard receipt.object_type == objectType, receipt.object_id == objectID,
              receipt.result_revision > 0, receipt.account_change_sequence > 0 else {
            throw URLError(.cannotParseResponse)
        }
        return receipt
    }

    func deletePersonalObject(objectType: String, objectID: String, baseRevision: Int64,
                              idempotencyKey: String) async throws -> MordePersonalMutationReceipt {
        guard MordePersonalDataContract.mutationObjectTypes.contains(objectType),
              MordePersonalDataContract.isValidObjectIdentifier(type: objectType, id: objectID),
              baseRevision >= 0, MordePersonalDataContract.isValidIdempotencyKey(idempotencyKey) else {
            throw URLError(.badURL)
        }
        let receipt: MordePersonalMutationReceipt = try await call(
            try personalObjectPath(type: objectType, id: objectID), method: "DELETE",
            body: ["base_revision": baseRevision], key: idempotencyKey)
        guard receipt.object_type == objectType, receipt.object_id == objectID,
              receipt.result_revision > 0, receipt.account_change_sequence > 0 else {
            throw URLError(.cannotParseResponse)
        }
        return receipt
    }

    func personalDataQuota() async throws -> MordePersonalDataQuota {
        let quota: MordePersonalDataQuota = try await call("/api/personal-data/quota")
        guard quota.isValid else { throw URLError(.cannotParseResponse) }
        return quota
    }

    func importPersonalHistory(_ request: MordePersonalHistoryImportRequest) async throws -> MordePersonalHistoryImportReceipt {
        guard MordePersonalHistoryImportContract.isValid(request) else { throw URLError(.badURL) }
        let receipt: MordePersonalHistoryImportReceipt = try await call(
            "/api/personal-data/history/import", method: "POST", body: try jsonDictionary(request))
        guard MordePersonalHistoryImportContract.isValid(receipt, for: request) else {
            throw URLError(.cannotParseResponse)
        }
        return receipt
    }

    func uploadPersonalAttachment(objectID: String, baseRevision: Int64, fileURL: URL, sizeBytes: Int64,
                                  sha256: String, mediaType: String, idempotencyKey: String,
                                  progress: (@MainActor (Int64, Int64) -> Void)? = nil) async throws -> MordePersonalAttachmentCommitReceipt {
        guard fileURL.isFileURL, baseRevision >= 0, sizeBytes >= 0,
              sizeBytes <= Int64(Int32.max) * Int64(MordePersonalAttachmentHash.chunkBytes),
              MordePersonalDataContract.isValidObjectIdentifier(type: "library_item", id: objectID),
              MordePersonalDataContract.isValidIdempotencyKey(idempotencyKey),
              sha256.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil,
              MordePersonalDataContract.isValidAttachmentMediaType(mediaType),
              let expectedChunkCount = MordePersonalAttachmentHash.chunkCount(sizeBytes: sizeBytes) else {
            throw URLError(.badURL)
        }
        let measured = try await Task.detached(priority: .utility) {
            try MordePersonalAttachmentHash.measure(fileURL: fileURL)
        }.value
        guard measured.sizeBytes == sizeBytes, measured.sha256 == sha256 else {
            throw NSError(domain: "Morde", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "附件暂存文件大小或 SHA-256 已变化，请重新暂存。"])
        }
        let createBody: [String: Any] = [
            "object_id": objectID, "base_revision": baseRevision, "size_bytes": sizeBytes,
            "sha256": sha256, "media_type": mediaType,
        ]
        let upload: MordePersonalAttachmentUploadReceipt = try await call(
            "/api/personal-data/uploads", method: "POST", body: createBody, key: idempotencyKey)
        guard MordePersonalDataContract.isValidUploadID(upload.upload_id),
              upload.chunk_count == expectedChunkCount,
              ["active", "committed"].contains(upload.state) else {
            throw URLError(.cannotParseResponse)
        }

        let commitKey = MordePersonalAttachmentHash.sha256(Data((idempotencyKey + "\u{0}commit").utf8))
        if upload.state == "committed" {
            let receipt: MordePersonalAttachmentCommitReceipt = try await call(
                "/api/personal-data/uploads/\(upload.upload_id)/commit", method: "POST", key: commitKey)
            guard MordePersonalDataContract.isValidAttachmentID(receipt.attachment_id),
                  receipt.object_type == "library_item", receipt.object_id == objectID,
                  receipt.result_revision > 0, receipt.account_change_sequence > 0 else {
                throw URLError(.cannotParseResponse)
            }
            return receipt
        }

        let file = try FileHandle(forReadingFrom: fileURL)
        defer { try? file.close() }
        var sentBytes: Int64 = 0
        for sequence in 0..<expectedChunkCount {
            guard let chunkSize = MordePersonalAttachmentHash.chunkSize(sizeBytes: sizeBytes, sequence: sequence) else {
                throw URLError(.cannotParseResponse)
            }
            let offset = Int64(sequence) * Int64(MordePersonalAttachmentHash.chunkBytes)
            try file.seek(toOffset: UInt64(offset))
            guard let chunk = try file.read(upToCount: chunkSize), chunk.count == chunkSize else {
                throw NSError(domain: "Morde", code: 409,
                              userInfo: [NSLocalizedDescriptionKey: "附件暂存文件已变化，分块读取失败。"])
            }
            let chunkDigest = MordePersonalAttachmentHash.sha256(chunk)
            let chunkReceipt: MordePersonalAttachmentChunkReceipt = try await call(
                "/api/personal-data/uploads/\(upload.upload_id)/chunks/\(sequence)", method: "PUT",
                key: nil, rawBody: chunk, contentType: "application/octet-stream",
                headers: ["X-Chunk-SHA256": chunkDigest, "Content-Length": String(chunk.count)])
            guard chunkReceipt.upload_id == upload.upload_id, chunkReceipt.sequence == sequence else {
                throw URLError(.cannotParseResponse)
            }
            sentBytes += Int64(chunk.count)
            progress?(sentBytes, sizeBytes)
        }

        let receipt: MordePersonalAttachmentCommitReceipt = try await call(
            "/api/personal-data/uploads/\(upload.upload_id)/commit", method: "POST", key: commitKey)
        guard MordePersonalDataContract.isValidAttachmentID(receipt.attachment_id),
              receipt.object_type == "library_item", receipt.object_id == objectID,
              receipt.result_revision > 0, receipt.account_change_sequence > 0 else {
            throw URLError(.cannotParseResponse)
        }
        return receipt
    }

    func downloadPersonalAttachment(attachmentID: String) async throws -> MordePersonalAttachmentDownload {
        guard MordePersonalDataContract.isValidAttachmentID(attachmentID) else { throw URLError(.badURL) }
        let (downloadedURL, response) = try await downloadResponseFile("/api/personal-data/attachments/\(attachmentID)")
        do {
            guard let contentLength = Int64(response.value(forHTTPHeaderField: "Content-Length") ?? ""),
                  contentLength >= 0,
                  let etag = response.value(forHTTPHeaderField: "ETag"), etag.hasPrefix("\""), etag.hasSuffix("\""),
                  etag.count == 66,
                  let mediaType = response.value(forHTTPHeaderField: "Content-Type"), !mediaType.isEmpty else {
                throw URLError(.cannotParseResponse)
            }
            let digest = String(etag.dropFirst().dropLast())
            guard digest.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil else {
                throw URLError(.cannotParseResponse)
            }
            let measured = try await Task.detached(priority: .utility) {
                try MordePersonalAttachmentHash.measure(fileURL: downloadedURL)
            }.value
            guard measured.sizeBytes == contentLength, measured.sha256 == digest else {
                throw URLError(.cannotParseResponse)
            }
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent("morde-attachment-\(UUID().uuidString.lowercased())", isDirectory: false)
            try FileManager.default.moveItem(at: downloadedURL, to: destination)
            return MordePersonalAttachmentDownload(attachmentID: attachmentID, fileURL: destination,
                sizeBytes: contentLength, sha256: digest, mediaType: mediaType)
        } catch {
            MIFLibraryTemporaryFileCleanup.discard(downloadedURL)
            throw error
        }
    }

    fileprivate func downloadTaskMediaPreview(taskID: String, operationID: String) async throws -> MordeTaskMediaPreviewFile {
        guard taskMediaGenerationAvailable == true,
              let path = MordeTaskResponsePolicy.mediaPreviewPath(taskID: taskID, operationID: operationID),
              let scope = currentDataScope else { throw URLError(.badURL) }
        let (downloadedURL, response) = try await downloadResponseFile(path)
        do {
            guard currentDataScope == scope, taskMediaGenerationAvailable == true,
                  let rawMediaType = response.value(forHTTPHeaderField: "Content-Type") else {
                throw URLError(.cancelled)
            }
            let mediaType = rawMediaType.split(separator: ";", maxSplits: 1).first.map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            } ?? ""
            let extensions = ["image/png": "png", "image/jpeg": "jpg", "image/webp": "webp",
                              "video/mp4": "mp4", "audio/mpeg": "mp3", "audio/ogg": "ogg",
                              "audio/opus": "opus", "audio/wav": "wav", "audio/aac": "aac"]
            let cacheDirectives = Set((response.value(forHTTPHeaderField: "Cache-Control") ?? "")
                .split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
            guard let fileExtension = extensions[mediaType],
                  cacheDirectives.contains("private"), cacheDirectives.contains("no-store"),
                  response.value(forHTTPHeaderField: "X-Content-Type-Options")?.lowercased() == "nosniff",
                  let size = (try FileManager.default.attributesOfItem(atPath: downloadedURL.path)[.size] as? NSNumber)?.int64Value,
                  size > 0, size <= 300 * 1_048_576,
                  response.value(forHTTPHeaderField: "Content-Length").flatMap(Int64.init).map({ $0 == size }) ?? true else {
                throw URLError(.cannotParseResponse)
            }
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent("morde-task-media-\(UUID().uuidString.lowercased()).\(fileExtension)")
            try FileManager.default.moveItem(at: downloadedURL, to: destination)
            return MordeTaskMediaPreviewFile(fileURL: destination, mediaType: mediaType)
        } catch {
            try? FileManager.default.removeItem(at: downloadedURL)
            throw error
        }
    }

    func personalProfile() async throws -> MordePersonalProfileObject? {
        do {
            let object: MordePersonalProfileObject = try await call("/api/personal-data/profile/default")
            guard object.object_type == "profile", object.object_id == "default", object.revision > 0 else {
                throw URLError(.cannotParseResponse)
            }
            return object
        } catch let error as NSError where error.domain == "Morde" && error.code == 404 {
            return nil
        }
    }

    func replacePersonalProfile(baseRevision: Int64, body: MordePersonalProfileBody,
                                idempotencyKey: String) async throws -> MordePersonalMutationReceipt {
        guard baseRevision >= 0, body.isValidForWrite,
              idempotencyKey.range(of: "^[A-Za-z0-9][A-Za-z0-9._:-]{7,127}$", options: .regularExpression) != nil else {
            throw URLError(.badURL)
        }
        var profile: [String: Any] = ["name": body.name, "avatar": body.avatar]
        if let emoji = body.emoji { profile["emoji"] = emoji }
        if let color = body.color { profile["color"] = color }
        if let description = body.description { profile["description"] = description }
        if let style = body.style { profile["style"] = style }
        let receipt: MordePersonalMutationReceipt = try await call("/api/personal-data/profile/default", method: "PUT",
            body: ["base_revision": baseRevision, "body": profile], key: idempotencyKey)
        guard receipt.object_type == "profile", receipt.object_id == "default", receipt.result_revision > 0,
              receipt.account_change_sequence > 0 else { throw URLError(.cannotParseResponse) }
        return receipt
    }

    private func validPersonalGoalID(_ objectID: String) -> Bool {
        objectID != "." && objectID != ".." &&
            objectID.range(of: "^[A-Za-z0-9._~-]{1,128}$", options: .regularExpression) != nil
    }

    private func validPersonalIdempotencyKey(_ key: String) -> Bool {
        key.range(of: "^[A-Za-z0-9][A-Za-z0-9._:-]{7,127}$", options: .regularExpression) != nil
    }

    func personalGoal(objectID: String) async throws -> MordePersonalGoalObject? {
        guard validPersonalGoalID(objectID) else { throw URLError(.badURL) }
        do {
            let object: MordePersonalGoalObject = try await call("/api/personal-data/goal/\(objectID)")
            guard object.object_type == "goal", object.object_id == objectID, object.revision > 0,
                  object.body.isValidForWrite else { throw URLError(.cannotParseResponse) }
            return object
        } catch let error as NSError where error.domain == "Morde" && error.code == 404 {
            return nil
        }
    }

    func replacePersonalGoal(objectID: String, baseRevision: Int64, body: MordePersonalGoalBody,
                             idempotencyKey: String) async throws -> MordePersonalMutationReceipt {
        guard validPersonalGoalID(objectID), baseRevision >= 0, body.isValidForWrite,
              validPersonalIdempotencyKey(idempotencyKey) else { throw URLError(.badURL) }
        let steps: [[String: Any]] = body.steps.map { [
            "id": $0.id, "title": $0.title, "status": $0.status, "note": $0.note,
        ] }
        let value: [String: Any] = [
            "title": body.title, "description": body.description, "status": body.status,
            "steps": steps, "related_material_ids": body.related_material_ids,
        ]
        let receipt: MordePersonalMutationReceipt = try await call("/api/personal-data/goal/\(objectID)", method: "PUT",
            body: ["base_revision": baseRevision, "body": value], key: idempotencyKey)
        guard receipt.object_type == "goal", receipt.object_id == objectID, receipt.result_revision > 0,
              receipt.account_change_sequence > 0 else { throw URLError(.cannotParseResponse) }
        return receipt
    }

    func deletePersonalGoal(objectID: String, baseRevision: Int64,
                            idempotencyKey: String) async throws -> MordePersonalMutationReceipt {
        guard validPersonalGoalID(objectID), baseRevision >= 0,
              validPersonalIdempotencyKey(idempotencyKey) else { throw URLError(.badURL) }
        let receipt: MordePersonalMutationReceipt = try await call("/api/personal-data/goal/\(objectID)", method: "DELETE",
            body: ["base_revision": baseRevision], key: idempotencyKey)
        guard receipt.object_type == "goal", receipt.object_id == objectID, receipt.result_revision > 0,
              receipt.account_change_sequence > 0 else { throw URLError(.cannotParseResponse) }
        return receipt
    }

    func personalSnapshot(cursor: String?) async throws -> MordePersonalSnapshotPage {
        var components = URLComponents()
        components.path = "/api/sync/snapshot"
        components.queryItems = [URLQueryItem(name: "limit", value: "100")]
        if let cursor {
            guard cursor.count <= 2048 else { throw URLError(.badURL) }
            components.queryItems?.append(URLQueryItem(name: "cursor", value: cursor))
        }
        guard let path = components.string else { throw URLError(.badURL) }
        let page: MordePersonalSnapshotPage = try await call(path)
        guard page.watermark >= 0, page.next_cursor.map({ $0.count <= 2048 }) ?? true else {
            throw URLError(.cannotParseResponse)
        }
        for item in page.items {
            guard item.revision > 0,
                  MordePersonalDataContract.isValidObjectIdentifier(type: item.object_type, id: item.object_id),
                  case .object = item.body,
                  ((try? JSONEncoder().encode(item.body).count) ?? Int.max) <= 1_048_576 else {
                throw URLError(.cannotParseResponse)
            }
        }
        return page
    }

    func personalChanges(afterSequence: Int64, throughSequence: Int64?) async throws -> MordePersonalChangePage {
        guard afterSequence >= 0, throughSequence.map({ $0 >= afterSequence }) ?? true else { throw URLError(.badURL) }
        var components = URLComponents()
        components.path = "/api/sync/changes"
        components.queryItems = [URLQueryItem(name: "after_sequence", value: String(afterSequence)),
                                 URLQueryItem(name: "limit", value: "100")]
        if let throughSequence {
            components.queryItems?.append(URLQueryItem(name: "through_sequence", value: String(throughSequence)))
        }
        guard let path = components.string else { throw URLError(.badURL) }
        let page: MordePersonalChangePage = try await call(path)
        guard page.through_sequence >= afterSequence,
              throughSequence.map({ page.through_sequence <= $0 }) ?? true,
              page.next_after_sequence >= afterSequence,
              page.next_after_sequence <= page.through_sequence,
              (!page.has_more || page.next_after_sequence > afterSequence),
              (page.has_more || page.next_after_sequence == page.through_sequence) else {
            throw URLError(.cannotParseResponse)
        }
        var previousSequence = afterSequence
        for change in page.items {
            guard change.change_sequence > previousSequence,
                  change.change_sequence <= page.through_sequence, change.revision > 0,
                  MordePersonalDataContract.isValidObjectIdentifier(type: change.object_type, id: change.object_id),
                  ["upsert", "delete"].contains(change.operation),
                  change.mutation_id.map({ MordePersonalDataContract.isValidIdempotencyKey($0) }) ?? true else {
                throw URLError(.cannotParseResponse)
            }
            previousSequence = change.change_sequence
        }
        if page.has_more, page.next_after_sequence != previousSequence { throw URLError(.cannotParseResponse) }
        return page
    }

    func portalSessionForWebView() async throws -> (credential: String, expiresAt: Date) {
        try await portalWebSession(forceRenew: false)
    }

    private func portalWebSession(forceRenew: Bool) async throws -> (credential: String, expiresAt: Date) {
        guard let scope = currentDataScope else { throw CancellationError() }
        if !forceRenew, portalSessionScope == scope, let credential = portalSessionCredential,
           let expiresAt = portalSessionExpiresAt, expiresAt.timeIntervalSinceNow > 30 {
            return (credential, expiresAt)
        }
        let session: MordeClientWebSession = try await call("/api/auth/client-web-session", method: "POST")
        guard scope == currentDataScope else { throw CancellationError() }
        guard session.web_session_credential.range(
            of: "^chs_t[a-z0-9]{7}_[A-Za-z0-9_-]{43}$", options: .regularExpression) != nil,
              let expiresAt = Self.parseISO8601(session.web_session_expires_at), expiresAt > Date() else {
            throw URLError(.cannotParseResponse)
        }
        portalSessionCredential = session.web_session_credential
        portalSessionExpiresAt = expiresAt
        portalSessionScope = scope
        return (session.web_session_credential, expiresAt)
    }

    private func portalData(_ path: String, method: String = "GET", body: Data? = nil,
                            contentType: String? = nil, key: String? = nil,
                            expectedScope: MordeClientDataScope? = nil,
                            renewalAttempt: Int = 0) async throws -> Data {
        guard let requestScope = expectedScope ?? currentDataScope,
              requestScope == currentDataScope else { throw CancellationError() }
        let portalSession = try await portalWebSession(forceRenew: renewalAttempt > 0)
        guard requestScope == currentDataScope, portalSessionScope == requestScope else { throw CancellationError() }
        let requestServer = server
        guard let base = URL(string: requestServer),
              let url = URL(string: path, relativeTo: base)?.absoluteURL,
              MordeLoginStateStore.serviceOrigin(requestServer) != nil,
              url.scheme == base.scheme, url.host == base.host, url.port == base.port else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpShouldHandleCookies = false
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Request-Id")
        request.setValue("ch_portal=\(portalSession.credential)", forHTTPHeaderField: "Cookie")
        var origin = URLComponents()
        origin.scheme = base.scheme
        origin.host = base.host
        origin.port = base.port
        if let origin = origin.string { request.setValue(origin, forHTTPHeaderField: "Origin") }
        if let key { request.setValue(key, forHTTPHeaderField: "Idempotency-Key") }
        if let contentType { request.setValue(contentType, forHTTPHeaderField: "Content-Type") }
        if let body { request.httpBody = body }
        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode == 401, renewalAttempt == 0 {
            guard requestScope == currentDataScope, portalSessionScope == requestScope else { throw CancellationError() }
            portalSessionCredential = nil
            portalSessionExpiresAt = nil
            portalSessionScope = nil
            return try await portalData(path, method: method, body: body, contentType: contentType,
                                        key: key, expectedScope: requestScope, renewalAttempt: 1)
        }
        guard requestScope == currentDataScope else { throw CancellationError() }
        guard (200..<300).contains(http.statusCode) else {
            let reason = try? JSONDecoder().decode(MordeError.self, from: data)
            throw NSError(domain: "Morde", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: reason?.displayMessage ?? "请求失败 (\(http.statusCode))"])
        }
        return data
    }

    private func portalCall<T: Decodable>(_ path: String, method: String = "GET",
                                          body: [String: Any]? = nil, key: String? = nil,
                                          expectedScope: MordeClientDataScope? = nil) async throws -> T {
        let bytes = try body.map { try JSONSerialization.data(withJSONObject: $0) }
        let data = try await portalData(path, method: method, body: bytes,
                                        contentType: bytes == nil ? nil : "application/json", key: key,
                                        expectedScope: expectedScope)
        return try JSONDecoder().decode(T.self, from: data.isEmpty ? Data("{}".utf8) : data)
    }

    private func executionAttemptStorageKey(_ scope: MordeClientDataScope) -> String {
        "morde.pendingExecutionControl.\(scope.storageKey)"
    }

    private func removeExecutionAttempt(_ scope: MordeClientDataScope, actionPrefix: String) {
        let key = executionAttemptStorageKey(scope)
        guard let attempt = UserDefaults.standard.data(forKey: key)
            .flatMap({ try? JSONDecoder().decode(MordeRetryAttempt.self, from: $0) }),
              attempt.scope == scope, attempt.fingerprint.hasPrefix(actionPrefix) else { return }
        UserDefaults.standard.removeObject(forKey: key)
    }

    func refreshExecutionControl() async {
        guard let scope = currentDataScope else {
            executionControl = nil
            executionControlError = "尚未登录 Morde。"
            return
        }
        let generation = UUID()
        executionControlGeneration = generation
        executionControlIsLoading = true
        defer {
            if executionControlGeneration == generation { executionControlIsLoading = false }
        }
        do {
            let control: MordeExecutionControl = try await portalCall("/api/execution", expectedScope: scope)
            guard executionControlGeneration == generation, scope == currentDataScope,
                  control.isValid, control.owner_id == user?.id,
                  Self.parseISO8601(control.updated_at) != nil else { throw URLError(.cannotParseResponse) }
            executionControl = control
            executionControlError = nil
            if control.state == "disabled" { removeExecutionAttempt(scope, actionPrefix: "execution:stop:") }
            if control.state == "enabled" { removeExecutionAttempt(scope, actionPrefix: "execution:enable:") }
        } catch {
            guard executionControlGeneration == generation, scope == currentDataScope else { return }
            executionControlError = error.localizedDescription
        }
    }

    func setCloudExecutionEnabled(_ enabled: Bool) async -> Bool {
        guard !executionControlActionInFlight else { return false }
        guard let scope = currentDataScope else {
            executionControlError = "尚未登录 Morde。"
            return false
        }
        guard let current = executionControl, current.isValid, current.owner_id == user?.id else {
            await refreshExecutionControl()
            return false
        }
        let action = enabled ? "enable" : "stop"
        guard current.state == (enabled ? "disabled" : "enabled") else { return false }
        let fingerprint = "execution:\(action):\(current.epoch)"
        let key = executionAttemptStorageKey(scope)
        let attempt = UserDefaults.standard.data(forKey: key)
            .flatMap { try? JSONDecoder().decode(MordeRetryAttempt.self, from: $0) }
            .flatMap { $0.matches(scope: scope, fingerprint: fingerprint) ? $0 : nil }
            ?? MordeRetryAttempt(scope: scope, fingerprint: fingerprint, key: UUID().uuidString)
        guard let persisted = try? JSONEncoder().encode(attempt) else {
            executionControlError = "无法保存执行控制请求标识。"
            return false
        }
        UserDefaults.standard.set(persisted, forKey: key)

        let generation = UUID()
        executionControlActionGeneration = generation
        executionControlActionInFlight = true
        executionControlError = nil
        defer {
            if executionControlActionGeneration == generation { executionControlActionInFlight = false }
        }
        do {
            let path = enabled ? "/api/execution/enable" : "/api/execution/stop-all"
            let updated: MordeExecutionControl = try await portalCall(
                path, method: "POST", body: ["expected_epoch": current.epoch], key: attempt.key,
                expectedScope: scope)
            let stateMatchesAction = enabled
                ? updated.state == "enabled"
                : ["stopping", "disabled"].contains(updated.state)
            guard executionControlActionGeneration == generation, scope == currentDataScope,
                  updated.isValid, updated.owner_id == user?.id, updated.epoch > current.epoch,
                  Self.parseISO8601(updated.updated_at) != nil, stateMatchesAction else {
                throw URLError(.cannotParseResponse)
            }
            executionControl = updated
            if enabled || updated.state == "disabled" {
                UserDefaults.standard.removeObject(forKey: key)
                return true
            }
            for _ in 0..<15 {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                guard executionControlActionGeneration == generation, scope == currentDataScope else { return false }
                await refreshExecutionControl()
                if executionControl?.state == "disabled" { return true }
                if executionControl?.state != "stopping" { return false }
            }
            return false
        } catch {
            guard executionControlActionGeneration == generation, scope == currentDataScope else { return false }
            let failure = error as NSError
            if failure.domain == "Morde", [400, 403, 409].contains(failure.code) {
                UserDefaults.standard.removeObject(forKey: key)
            }
            executionControlError = failure.code == 409
                ? "执行状态已在其他客户端变化，正在刷新。"
                : error.localizedDescription
            if failure.code == 409 { await refreshExecutionControl() }
            return false
        }
    }

    private func projectPagePath(_ path: String, cursor: String?, queryItems: [URLQueryItem] = []) -> String? {
        var components = URLComponents()
        components.path = path
        components.queryItems = [URLQueryItem(name: "limit", value: "100")] + queryItems
        if let cursor { components.queryItems?.append(URLQueryItem(name: "cursor", value: cursor)) }
        return components.string
    }

    private func projectPages<Item: Decodable>(_ path: String, scope: MordeClientDataScope,
                                               queryItems: [URLQueryItem] = []) async throws -> [Item] {
        var cursor: String?
        var seenCursors = Set<String>()
        var items: [Item] = []
        for _ in 0..<100 {
            guard scope == currentDataScope,
                  let pagePath = projectPagePath(path, cursor: cursor, queryItems: queryItems) else {
                throw CancellationError()
            }
            let page: MordePage<Item> = try await portalCall(pagePath, expectedScope: scope)
            guard scope == currentDataScope else { throw CancellationError() }
            items.append(contentsOf: page.items)
            guard let next = page.next_cursor else { return items }
            guard !MordePersonalSnapshotCursorPolicy.repeats(next, seen: &seenCursors) else {
                throw URLError(.cannotParseResponse)
            }
            cursor = next
        }
        throw URLError(.cannotParseResponse)
    }

    private func isValidProject(_ value: MordeProject) -> Bool {
        MordeProjectPolicy.hasValidID(value.id) && MordeProjectPolicy.hasValidUserID(value.owner_id) &&
            !value.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && value.name.unicodeScalars.count <= 120 &&
            value.description.unicodeScalars.count <= 2000 && value.version > 0
    }

    private func isValidProjectInvitation(_ value: MordeProjectInvitation) -> Bool {
        MordeProjectPolicy.hasValidInvitationID(value.id) && MordeProjectPolicy.hasValidID(value.project_id) &&
            MordeProjectPolicy.hasValidUserID(value.inviter_id) && MordeProjectPolicy.hasValidUserID(value.invitee_id) &&
            ["member", "viewer"].contains(value.role) && ["pending", "accepted", "revoked"].contains(value.state) &&
            value.version > 0
    }

    private func isValidProjectWorkItem(_ value: MordeProjectWorkItem, projectID: String) -> Bool {
        let validDelivery = value.delivery.map {
            value.state == "delivered" && MordeProjectPolicy.hasValidTaskID($0.task_id) &&
                value.task_ids.contains($0.task_id) &&
                MordeProjectPolicy.hasValidResourceID(kind: "workspace", id: $0.workspace_id) && $0.revision > 0
        } ?? (value.state != "delivered")
        let validBlocker = value.state == "blocked"
            ? (1...2000).contains(value.blocked_reason.unicodeScalars.count)
            : value.blocked_reason.isEmpty
        let validAssignee = value.assignee_id.map { MordeProjectPolicy.hasValidUserID($0) } ??
            (projectWorkItemsV2Available == true)
        let validCategory = value.category.map { ["bug", "request", "unclassified"].contains($0) } ?? true
        return MordeProjectPolicy.hasValidID(value.id) && value.project_id == projectID &&
            !value.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && value.title.unicodeScalars.count <= 200 &&
            value.description.unicodeScalars.count <= 4096 && value.acceptance_criteria.count <= 100 &&
            validAssignee && validCategory && ["open", "blocked", "delivered"].contains(value.state) &&
            validBlocker && value.task_ids.count <= 100 && value.task_ids.allSatisfy(MordeProjectPolicy.hasValidTaskID) &&
            Set(value.task_ids).count == value.task_ids.count && value.version > 0 && validDelivery
    }

    private func isValidProjectBudget(_ value: MordeProjectBudget) -> Bool {
        value.limit_micros >= 0 && value.spent_micros >= 0 && value.reserved_micros >= 0 &&
            value.version >= 0 && (value.configured
                ? value.currency.range(of: "^[A-Z]{3}$", options: .regularExpression) != nil && value.version > 0 && value.limit_micros > 0
                : value.currency.isEmpty && value.version == 0 && value.limit_micros == 0)
    }

    func loadProjects(includeProjectBudget: Bool = true) async {
        guard let scope = currentDataScope else {
            projects = []; projectInvitations = []; projectsState = .failed("Not signed in to Morde.")
            projectInvitationsState = .failed("Not signed in to Morde."); return
        }
        let generation = UUID()
        projectLoadGeneration = generation
        projectsState = .loading
        do {
            let values: [MordeProject] = try await projectPages("/api/projects", scope: scope)
            guard generation == projectLoadGeneration, scope == currentDataScope else { return }
            guard values.allSatisfy(isValidProject), Set(values.map(\.id)).count == values.count else {
                throw URLError(.cannotParseResponse)
            }
            projects = values
            projectsState = .loaded
            if let selectedProjectID, !values.contains(where: { $0.id == selectedProjectID }) {
                self.selectedProjectID = nil
                projectMembers = []; projectResources = []; recentProjectInvitations = [:]
                projectWorkItems = []; projectBudget = nil; projectBudgetLedger = []
                projectConversations = []; selectedProjectConversationID = nil; projectConversationMessages = []
                projectConversationTask = nil
                projectDetailState = .loaded
                projectWorkItemsState = .loaded; projectBudgetState = .loaded
                projectConversationsState = .loaded; projectConversationMessagesState = .loaded
            }
        } catch {
            guard generation == projectLoadGeneration, scope == currentDataScope else { return }
            projects = []; selectedProjectID = nil; projectMembers = []; projectResources = []
            projectWorkItems = []; projectBudget = nil; projectBudgetLedger = []
            projectConversations = []; selectedProjectConversationID = nil; projectConversationMessages = []
            projectConversationTask = nil
            projectsState = .failed(error.localizedDescription)
            projectDetailState = .failed(error.localizedDescription)
            projectWorkItemsState = .failed(error.localizedDescription)
            projectBudgetState = .failed(error.localizedDescription)
            projectConversationsState = .failed(error.localizedDescription)
            projectConversationMessagesState = .failed(error.localizedDescription)
        }

        do {
            let values: [MordeProjectInvitation] = try await projectPages("/api/me/project-invitations", scope: scope)
            guard generation == projectLoadGeneration, scope == currentDataScope else { return }
            guard values.allSatisfy({ isValidProjectInvitation($0) && $0.invitee_id == user?.id }) else {
                throw URLError(.cannotParseResponse)
            }
            projectInvitations = values.filter { $0.state == "pending" }
            projectInvitationsState = .loaded
        } catch {
            guard generation == projectLoadGeneration, scope == currentDataScope else { return }
            projectInvitations = []
            projectInvitationsState = .failed(error.localizedDescription)
        }

        if let id = selectedProjectID { await loadProjectDetail(id) }
        if let id = selectedProjectID {
            if includeProjectBudget { await loadProjectExecution(id) }
            else { await loadProjectWorkItems(id) }
        }
        if let id = selectedProjectID { await loadProjectConversations(id) }
    }

    func selectProject(_ id: String, includeProjectBudget: Bool = true) async {
        guard MordeProjectPolicy.hasValidID(id), projects.contains(where: { $0.id == id }) else { return }
        if selectedProjectID != id {
            selectedProjectConversationID = nil; projectConversationMessages = []; projectConversationTask = nil
            projectConversations = []; projectConversationMessagesState = .loading
        }
        selectedProjectID = id
        await loadProjectDetail(id)
        if includeProjectBudget { await loadProjectExecution(id) }
        else { await loadProjectWorkItems(id) }
        await loadProjectConversations(id)
    }

    func loadProjectExecution(_ id: String) async {
        guard let scope = currentDataScope, MordeProjectPolicy.hasValidID(id),
              projects.contains(where: { $0.id == id }) else { return }
        let generation = UUID()
        projectExecutionLoadGeneration = generation
        await loadProjectWorkItems(id)
        guard generation == projectExecutionLoadGeneration,
              selectedProjectID == id, scope == currentDataScope else { return }
        guard projectBudgetExecutionAvailable == true else {
            projectBudget = nil; projectBudgetLedger = []
            projectBudgetState = .failed("当前服务未声明项目预算执行能力。")
            return
        }
        projectBudgetState = .loading
        do {
            let budget: MordeProjectBudget = try await portalCall("/api/projects/\(id)/budget", expectedScope: scope)
            guard generation == projectExecutionLoadGeneration, selectedProjectID == id, scope == currentDataScope,
                  isValidProjectBudget(budget) else { throw URLError(.cannotParseResponse) }
            let ledger: [MordeProjectBudgetLedgerEntry] = try await projectPages("/api/projects/\(id)/budget/ledger", scope: scope)
            guard generation == projectExecutionLoadGeneration, selectedProjectID == id, scope == currentDataScope,
                  ledger.allSatisfy({ MordeProjectPolicy.hasValidUserID($0.actor_id) && $0.rate_version > 0 &&
                      $0.reserved_micros > 0 && ($0.actual_micros.map { $0 >= 0 } ?? true) &&
                      ["client", "chat", "task"].contains($0.source) && ["reserved", "settled", "unknown"].contains($0.status) }) else {
                throw URLError(.cannotParseResponse)
            }
            projectBudget = budget; projectBudgetLedger = ledger
            projectBudgetState = .loaded
        } catch {
            guard generation == projectExecutionLoadGeneration, selectedProjectID == id, scope == currentDataScope else { return }
            projectBudget = nil; projectBudgetLedger = []
            projectBudgetState = .failed(error.localizedDescription)
        }
    }

    func loadProjectWorkItems(_ id: String) async {
        guard let scope = currentDataScope, MordeProjectPolicy.hasValidID(id),
              projects.contains(where: { $0.id == id }) else { return }
        let generation = UUID()
        projectWorkItemsLoadGeneration = generation
        projectWorkItemsState = .loading
        do {
            let queryItems = projectWorkItemsV2Available == true
                ? [URLQueryItem(name: "include_unassigned", value: "true")] : []
            let items: [MordeProjectWorkItem] = try await projectPages(
                "/api/projects/\(id)/work-items", scope: scope, queryItems: queryItems)
            guard generation == projectWorkItemsLoadGeneration, selectedProjectID == id, scope == currentDataScope else { return }
            guard items.allSatisfy({ isValidProjectWorkItem($0, projectID: id) }), Set(items.map(\.id)).count == items.count else {
                throw URLError(.cannotParseResponse)
            }
            projectWorkItems = items
            projectWorkItemsState = .loaded
        } catch {
            guard generation == projectWorkItemsLoadGeneration, selectedProjectID == id, scope == currentDataScope else { return }
            projectWorkItems = []
            projectWorkItemsState = .failed(error.localizedDescription)
        }
    }

    private func isValidProjectConversation(_ value: MordeProjectConversation, projectID: String) -> Bool {
        MordeProjectPolicy.hasValidConversationID(value.id) && value.project_id == projectID &&
            MordeProjectPolicy.hasValidUserID(value.owner_id) && value.title.unicodeScalars.count <= 120 &&
            (value.model_id?.unicodeScalars.count ?? 0) <= 256
    }

    private func isValidProjectConversationMessage(_ value: MordeProjectConversationMessage,
                                                   conversationID: String) -> Bool {
        value.id.range(of: #"^m[a-z0-9]{7}$"#, options: .regularExpression) != nil &&
            value.conversation_id == conversationID && ["user", "assistant"].contains(value.role) &&
            value.content.unicodeScalars.count <= 32768 && ["pending", "applied", "unknown"].contains(value.delivery_status) &&
            MordeProjectPolicy.hasValidUserID(value.owner_id) && MordeProjectPolicy.hasValidUserID(value.actor_id) &&
            value.task_id.map { $0.range(of: #"^q[a-z0-9]{7}$"#, options: .regularExpression) != nil } ?? true
    }

    func loadProjectConversations(_ projectID: String) async {
        guard projectBudgetExecutionAvailable == true, let scope = currentDataScope,
              MordeProjectPolicy.hasValidID(projectID), projects.contains(where: { $0.id == projectID }) else {
            projectConversations = []; selectedProjectConversationID = nil; projectConversationMessages = []
            projectConversationsState = .failed("当前服务未声明项目会话能力。")
            projectConversationMessagesState = .failed("当前服务未声明项目会话能力。")
            return
        }
        let generation = UUID()
        projectConversationLoadGeneration = generation
        projectConversationsState = .loading
        do {
            let values: [MordeProjectConversation] = try await projectPages("/api/projects/\(projectID)/conversations", scope: scope)
            guard generation == projectConversationLoadGeneration, selectedProjectID == projectID, scope == currentDataScope else { return }
            guard values.allSatisfy({ isValidProjectConversation($0, projectID: projectID) }),
                  Set(values.map(\.id)).count == values.count else { throw URLError(.cannotParseResponse) }
            projectConversations = values
            projectConversationsState = .loaded
            if let selectedProjectConversationID, !values.contains(where: { $0.id == selectedProjectConversationID }) {
                self.selectedProjectConversationID = nil; projectConversationMessages = []; projectConversationTask = nil
                projectConversationMessagesState = .loaded
            }
        } catch {
            guard generation == projectConversationLoadGeneration, selectedProjectID == projectID, scope == currentDataScope else { return }
            projectConversations = []; selectedProjectConversationID = nil; projectConversationMessages = []
            projectConversationTask = nil; projectConversationsState = .failed(error.localizedDescription)
            projectConversationMessagesState = .failed(error.localizedDescription)
            return
        }
        if let selected = selectedProjectConversationID { await loadProjectConversationMessages(projectID: projectID, conversationID: selected) }
    }

    func selectProjectConversation(_ conversationID: String) async {
        guard MordeProjectPolicy.hasValidConversationID(conversationID),
              projectConversations.contains(where: { $0.id == conversationID && $0.project_id == selectedProjectID }) else { return }
        selectedProjectConversationID = conversationID
        projectConversationMessages = []; projectConversationTask = nil
        projectConversationError = nil
        await loadProjectConversationMessages(projectID: selectedProjectID ?? "", conversationID: conversationID)
    }

    func loadProjectConversationMessages(projectID: String, conversationID: String) async {
        guard projectBudgetExecutionAvailable == true, let scope = currentDataScope,
              MordeProjectPolicy.hasValidID(projectID), MordeProjectPolicy.hasValidConversationID(conversationID),
              projectConversations.contains(where: { $0.id == conversationID && $0.project_id == projectID }) else { return }
        let generation = UUID()
        projectConversationMessagesGeneration = generation
        projectConversationMessagesState = .loading
        projectConversationError = nil
        do {
            let values: [MordeProjectConversationMessage] = try await projectPages(
                "/api/projects/\(projectID)/conversations/\(conversationID)/messages", scope: scope)
            guard generation == projectConversationMessagesGeneration,
                  selectedProjectID == projectID, selectedProjectConversationID == conversationID,
                  scope == currentDataScope else { return }
            guard values.allSatisfy({ isValidProjectConversationMessage($0, conversationID: conversationID) }),
                  Set(values.map(\.id)).count == values.count else { throw URLError(.cannotParseResponse) }
            projectConversationMessages = values
            projectConversationMessagesState = .loaded
            projectConversationTask = nil
            guard let conversation = projectConversations.first(where: { $0.id == conversationID }),
                  let taskID = MordeProjectPolicy.restorableTaskID(
                    ownerID: conversation.owner_id, currentUserID: user?.id,
                    messages: values.map { (actorID: $0.actor_id, taskID: $0.task_id) }) else { return }
            do {
                let task: MordeTask = try await call("/api/tasks/\(taskID)")
                guard generation == projectConversationMessagesGeneration,
                      selectedProjectID == projectID, selectedProjectConversationID == conversationID,
                      scope == currentDataScope else { return }
                guard task.id == taskID, task.conversation_id == conversationID else {
                    throw URLError(.cannotParseResponse)
                }
                projectConversationTask = task
            } catch {
                guard generation == projectConversationMessagesGeneration,
                      selectedProjectID == projectID, selectedProjectConversationID == conversationID,
                      scope == currentDataScope else { return }
                projectConversationError = "Task 状态恢复失败；请稍后刷新。"
            }
        } catch {
            guard generation == projectConversationMessagesGeneration,
                  selectedProjectID == projectID, selectedProjectConversationID == conversationID,
                  scope == currentDataScope else { return }
            projectConversationMessages = []; projectConversationMessagesState = .failed(error.localizedDescription)
        }
    }

    func createProjectConversation(projectID: String, title: String) async -> Bool {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !projectActionInFlight, projectBudgetExecutionAvailable == true,
              let scope = currentDataScope, projects.contains(where: { $0.id == projectID }),
              projectMembers.first(where: { $0.project_id == projectID && $0.user_id == user?.id })
                .map({ MordeProjectPolicy.canManageWorkItems(role: $0.role) }) == true,
              title.unicodeScalars.count <= 120, !title.contains("\0") else {
            projectConversationError = "当前账号没有创建项目会话的权限，或会话标题超出 120 字。"
            return false
        }
        projectActionInFlight = true; projectConversationError = nil
        defer { projectActionInFlight = false }
        do {
            let conversation: MordeProjectConversation = try await projectMutation(
                "/api/projects/\(projectID)/conversations", body: ["title": title], scope: scope)
            guard scope == currentDataScope, isValidProjectConversation(conversation, projectID: projectID),
                  conversation.owner_id == user?.id else { throw URLError(.cannotParseResponse) }
            await loadProjectConversations(projectID)
            guard scope == currentDataScope else { return false }
            selectedProjectConversationID = conversation.id
            await loadProjectConversationMessages(projectID: projectID, conversationID: conversation.id)
            projectNotice = "项目共享会话已创建。"
            return true
        } catch {
            projectConversationError = error.localizedDescription
            return false
        }
    }

    func appendProjectConversationMessage(projectID: String, conversationID: String, content: String,
                                          modelID: String, hostID: String, workspaceID: String) async -> Bool {
        let content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !projectActionInFlight, projectBudgetExecutionAvailable == true,
              let scope = currentDataScope, projects.contains(where: { $0.id == projectID }),
              selectedProjectConversationID == conversationID,
              projectConversations.contains(where: { $0.id == conversationID && $0.project_id == projectID }),
              projectMembers.first(where: { $0.project_id == projectID && $0.user_id == user?.id })
                .map({ MordeProjectPolicy.canManageWorkItems(role: $0.role) }) == true,
              (1...32768).contains(content.unicodeScalars.count), !content.contains("\0"),
              models.contains(where: { $0.id == modelID && $0.capabilities.text && $0.capabilities.tools }),
              !targetIsUnavailable(hostID: hostID, workspaceID: workspaceID) else {
            projectConversationError = "请核对项目权限、模型和唯一就绪的电脑/Workspace 目标后重试。"
            return false
        }
        let host = hostID.isEmpty ? nil : ownedHost(hostID)
        guard hostID.isEmpty || host.map(canOpenHost) == true,
              workspaceID.isEmpty || host.flatMap({ workspaceBindings(for: $0.id).first(where: { $0.workspace.id == workspaceID }) })
                .map(workspaceIsReady) == true else {
            projectConversationError = "所选电脑或 Workspace 当前未就绪；项目会话不会提交。"
            return false
        }
        var body: [String: Any] = ["model_id": modelID, "content": content]
        if let task = projectConversationTask, task.conversation_id == conversationID,
           MordeProjectExecutionCapability.canContinueTask(status: task.status) {
            body["expected_task_id"] = task.id
        }
        if !hostID.isEmpty { body["host_id"] = hostID }
        if !workspaceID.isEmpty {
            guard let binding = workspaceBindings(for: hostID).first(where: { $0.workspace.id == workspaceID }),
                  workspaceIsReady(binding) else { return false }
            body["workspace_id"] = workspaceID
            body["input_revision"] = binding.workspace.revision
        }
        projectActionInFlight = true; projectConversationError = nil
        defer { projectActionInFlight = false }
        do {
            let response: MordeProjectConversationAppendResponse = try await projectMutation(
                "/api/projects/\(projectID)/conversations/\(conversationID)/messages", body: body, scope: scope)
            let task = response.task.task
            guard scope == currentDataScope, isValidProjectConversationMessage(response.message, conversationID: conversationID),
                  response.message.actor_id == user?.id, response.task.project_id == projectID,
                  response.task.initiator_id == user?.id, task.id.range(of: #"^q[a-z0-9]{7}$"#, options: .regularExpression) != nil,
                  task.conversation_id == conversationID, task.updated_at.isEmpty == false,
                  response.message.task_id == task.id else { throw URLError(.cannotParseResponse) }
            projectConversationTask = task
            await loadProjectConversationMessages(projectID: projectID, conversationID: conversationID)
            projectNotice = "项目消息已提交，Task 状态以服务端返回为准。"
            return true
        } catch {
            projectConversationError = error.localizedDescription
            return false
        }
    }

    func refreshProjectConversationTask() async {
        guard let scope = currentDataScope, let current = projectConversationTask,
              let projectID = selectedProjectID, current.conversation_id == selectedProjectConversationID,
              projectConversations.contains(where: {
                  $0.id == current.conversation_id && $0.project_id == projectID && $0.owner_id == user?.id
              }), MordeProjectPolicy.hasValidTaskID(current.id) else {
            projectConversationError = "只有共享会话创建者可以刷新 Task 状态。"
            return
        }
        do {
            let refreshed: MordeTask = try await call("/api/tasks/\(current.id)")
            guard scope == currentDataScope, selectedProjectID == projectID,
                  selectedProjectConversationID == current.conversation_id, refreshed.id == current.id,
                  refreshed.conversation_id == current.conversation_id else { throw URLError(.cannotParseResponse) }
            projectConversationTask = refreshed
        } catch { projectConversationError = error.localizedDescription }
    }

    func respondToProjectConversationApproval(taskID: String, approvalID: String,
                                              version: Int, decision: String) async -> Bool {
        guard let task = projectConversationTask, task.id == taskID,
              task.pending_request?.id == approvalID, task.pending_request?.version == version,
              ["approve", "reject"].contains(decision),
              let path = MordeTaskResponsePolicy.approvalPath(taskID: taskID, approvalID: approvalID) else {
            projectConversationError = "审批请求已变化，请刷新 Task 后重试。"
            return false
        }
        return await submitProjectConversationTaskAction(
            taskID: taskID, path: path, body: ["version": version, "decision": decision])
    }

    func answerProjectConversationClarification(taskID: String, clarificationID: String,
                                                version: Int, answer: String) async -> Bool {
        let answer = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let task = projectConversationTask, task.id == taskID,
              task.clarification_request?.id == clarificationID,
              task.clarification_request?.version == version,
              MordeTaskResponsePolicy.hasValidRequestID(clarificationID),
              MordeTaskResponsePolicy.hasValidAnswer(answer),
              let path = MordeTaskResponsePolicy.inputPath(taskID: taskID) else {
            projectConversationError = "请检查补充信息，并刷新 Task 后重试。"
            return false
        }
        return await submitProjectConversationTaskAction(
            taskID: taskID, path: path,
            body: ["clarification_id": clarificationID, "clarification_version": version, "answer": answer])
    }

    private func submitProjectConversationTaskAction(taskID: String, path: String,
                                                    body: [String: Any]) async -> Bool {
        guard !projectActionInFlight, let scope = currentDataScope,
              let projectID = selectedProjectID, let conversationID = selectedProjectConversationID,
              let task = projectConversationTask, task.id == taskID, task.conversation_id == conversationID,
              MordeProjectPolicy.hasValidTaskID(taskID), path.hasPrefix("/api/tasks/\(taskID)/"),
              projectConversations.contains(where: {
                  $0.id == conversationID && $0.project_id == projectID && $0.owner_id == user?.id
              }) else {
            projectConversationError = "只有共享会话创建者可以处理 Task 审批或澄清。"
            return false
        }
        let attempt: MordeRetryAttempt
        do {
            attempt = try projectMutationAttempt(scope: scope, path: path, body: body)
        } catch {
            projectConversationError = error.localizedDescription
            return false
        }
        projectActionInFlight = true
        defer { projectActionInFlight = false }
        do {
            struct Response: Decodable { let task_id: String }
            let response: Response = try await call(path, method: "POST", body: body, key: attempt.key)
            guard response.task_id == taskID else { throw URLError(.cannotParseResponse) }
            clearProjectMutationAttempt(scope: scope, key: attempt.key)
            do {
                let refreshed: MordeTask = try await call("/api/tasks/\(taskID)")
                guard scope == currentDataScope, selectedProjectID == projectID,
                      selectedProjectConversationID == conversationID, refreshed.id == taskID,
                      refreshed.conversation_id == conversationID else { throw URLError(.cannotParseResponse) }
                projectConversationTask = refreshed
                projectConversationError = nil
            } catch {
                projectConversationError = "操作已提交，但 Task 状态刷新失败；请稍后重新打开会话确认。"
            }
            return true
        } catch {
            if (error as NSError).code == 409 {
                do {
                    let refreshed: MordeTask = try await call("/api/tasks/\(taskID)")
                    guard scope == currentDataScope, selectedProjectID == projectID,
                          selectedProjectConversationID == conversationID, refreshed.id == taskID,
                          refreshed.conversation_id == conversationID else { throw URLError(.cannotParseResponse) }
                    projectConversationTask = refreshed
                    clearProjectMutationAttempt(scope: scope, key: attempt.key)
                    projectConversationError = "Task 状态已变化，已刷新当前状态。请核对后再操作。"
                } catch {
                    projectConversationError = "Task 状态已变化，但刷新失败；上一项操作仍待重试确认。"
                }
            } else {
                projectConversationError = error.localizedDescription
            }
            return false
        }
    }

    func createProjectWorkItem(projectID: String, title: String, description: String,
                               category: String? = nil, unassigned: Bool = false) async -> Bool {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !projectActionInFlight, let scope = currentDataScope,
              projects.contains(where: { $0.id == projectID }),
              MordeProjectPolicy.canManageWorkItems(role: projectMembers.first(where: {
                  $0.project_id == projectID && $0.user_id == user?.id
              })?.role),
              (1...200).contains(title.unicodeScalars.count), description.unicodeScalars.count <= 4096,
              !title.contains("\0"), !description.contains("\0"),
              (category == nil || projectWorkItemsV2Available == true),
              (!unassigned || projectWorkItemsV2Available == true),
              category.map({ ["bug", "request"].contains($0) }) ?? true else {
            projectActionError = "请确认你有项目成员权限，并填写不超过 200 字的工作项标题。"
            return false
        }
        projectActionInFlight = true; projectActionError = nil; projectNotice = nil
        defer { projectActionInFlight = false }
        do {
            var body: [String: Any] = ["title": title, "description": description]
            if let category { body["category"] = category }
            if unassigned { body["unassigned"] = true }
            let item: MordeProjectWorkItem = try await projectMutation(
                "/api/projects/\(projectID)/work-items", body: body, scope: scope)
            guard scope == currentDataScope, isValidProjectWorkItem(item, projectID: projectID),
                  (!unassigned || item.assignee_id == nil), category.map({ item.category == $0 }) ?? true else {
                throw URLError(.cannotParseResponse)
            }
            await loadProjectWorkItems(projectID)
            projectNotice = "工作项已创建。"
            return true
        } catch { await handleProjectMutationError(error, scope: scope, includeProjectBudget: false); return false }
    }

    func claimProjectWorkItem(projectID: String, item: MordeProjectWorkItem) async -> Bool {
        guard !projectActionInFlight, projectWorkItemsV2Available == true,
              let scope = currentDataScope,
              let actorID = user?.id, MordeProjectPolicy.hasValidUserID(actorID),
              selectedProjectID == projectID,
              projectMembers.first(where: { $0.project_id == projectID && $0.user_id == user?.id })
                .map({ MordeProjectPolicy.canManageWorkItems(role: $0.role) }) == true,
              isValidProjectWorkItem(item, projectID: projectID), item.assignee_id == nil,
              item.state != "delivered" else {
            projectActionError = "此工作项当前不可认领。"
            return false
        }
        projectActionInFlight = true; projectActionError = nil; projectNotice = nil
        defer { projectActionInFlight = false }
        do {
            let updated: MordeProjectWorkItem = try await projectMutation(
                "/api/projects/\(projectID)/work-items/\(item.id)/claim",
                body: ["expected_version": item.version], scope: scope)
            guard scope == currentDataScope, selectedProjectID == projectID,
                  isValidProjectWorkItem(updated, projectID: projectID),
                  updated.assignee_id == actorID, updated.version > item.version else {
                throw URLError(.cannotParseResponse)
            }
            await loadProjectWorkItems(projectID)
            projectNotice = "工作项已认领。"
            return true
        } catch { await handleProjectMutationError(error, scope: scope, includeProjectBudget: false); return false }
    }

    func setProjectBudget(projectID: String, currency: String, limitMicros: Int64) async -> Bool {
        guard !projectActionInFlight, projectBudgetExecutionAvailable == true,
              let scope = currentDataScope, let project = projects.first(where: { $0.id == projectID }),
              projectBudgetState.isLoaded, let budget = projectBudget,
              MordeProjectPolicy.isOwner(ownerID: project.owner_id, currentUserID: user?.id),
              MordeProjectPolicy.canSetBudget(role: "owner", currency: currency, limitMicros: limitMicros) else {
            projectActionError = "仅项目负责人可设置预算；金额需为正整数微单位，币种需为三位大写代码。"
            return false
        }
        projectActionInFlight = true; projectActionError = nil; projectNotice = nil
        defer { projectActionInFlight = false }
        do {
            let updated: MordeProjectBudget = try await projectMutation(
                "/api/projects/\(projectID)/budget", method: "PUT",
                body: ["currency": currency, "limit_micros": limitMicros, "expected_version": budget.version], scope: scope)
            guard scope == currentDataScope, isValidProjectBudget(updated), updated.configured,
                  updated.currency == currency, updated.limit_micros == limitMicros,
                  updated.version > budget.version else { throw URLError(.cannotParseResponse) }
            await loadProjectExecution(projectID)
            projectNotice = "项目预算已更新。"
            return true
        } catch { await handleProjectMutationError(error, scope: scope); return false }
    }

    func setProjectWorkItemBlocked(projectID: String, item: MordeProjectWorkItem, reason: String) async -> Bool {
        let reason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !projectActionInFlight, let scope = currentDataScope,
              projectMembers.first(where: { $0.project_id == projectID && $0.user_id == user?.id })
                .map({ MordeProjectPolicy.canManageWorkItems(role: $0.role) }) == true,
              isValidProjectWorkItem(item, projectID: projectID), item.state == "open",
              (1...2000).contains(reason.unicodeScalars.count), !reason.contains("\0") else { return false }
        projectActionInFlight = true; projectActionError = nil; projectNotice = nil
        defer { projectActionInFlight = false }
        do {
            let updated: MordeProjectWorkItem = try await projectMutation(
                "/api/projects/\(projectID)/work-items/\(item.id)/block",
                body: ["blocked_reason": reason, "expected_version": item.version], scope: scope)
            guard scope == currentDataScope, isValidProjectWorkItem(updated, projectID: projectID), updated.state == "blocked" else {
                throw URLError(.cannotParseResponse)
            }
            await loadProjectWorkItems(projectID)
            projectNotice = "工作项已标记为阻塞。"
            return true
        } catch { await handleProjectMutationError(error, scope: scope, includeProjectBudget: false); return false }
    }

    func resumeProjectWorkItem(projectID: String, item: MordeProjectWorkItem) async -> Bool {
        guard !projectActionInFlight, let scope = currentDataScope,
              projectMembers.first(where: { $0.project_id == projectID && $0.user_id == user?.id })
                .map({ MordeProjectPolicy.canManageWorkItems(role: $0.role) }) == true,
              isValidProjectWorkItem(item, projectID: projectID), item.state == "blocked" else { return false }
        projectActionInFlight = true; projectActionError = nil; projectNotice = nil
        defer { projectActionInFlight = false }
        do {
            let updated: MordeProjectWorkItem = try await projectMutation(
                "/api/projects/\(projectID)/work-items/\(item.id)/resume",
                body: ["expected_version": item.version], scope: scope)
            guard scope == currentDataScope, isValidProjectWorkItem(updated, projectID: projectID), updated.state == "open" else {
                throw URLError(.cannotParseResponse)
            }
            await loadProjectWorkItems(projectID)
            projectNotice = "工作项已恢复。"
            return true
        } catch { await handleProjectMutationError(error, scope: scope, includeProjectBudget: false); return false }
    }

    func linkProjectWorkItemTask(projectID: String, item: MordeProjectWorkItem, taskID: String) async -> Bool {
        guard !projectActionInFlight,
              let scope = currentDataScope, projects.contains(where: { $0.id == projectID }),
              projectMembers.first(where: { $0.project_id == projectID && $0.user_id == user?.id })
                .map({ MordeProjectPolicy.canManageWorkItems(role: $0.role) }) == true,
              let task = projectConversationTask, task.id == taskID,
              task.conversation_id == selectedProjectConversationID,
              projectConversations.contains(where: { $0.id == task.conversation_id && $0.project_id == projectID }),
              isValidProjectWorkItem(item, projectID: projectID),
              MordeProjectPolicy.canLinkTask(role: projectMembers.first(where: {
                  $0.project_id == projectID && $0.user_id == user?.id
              })?.role, state: item.state, taskID: taskID, taskIDs: item.task_ids) else {
            projectActionError = "请选择当前项目会话中的 Task，并确认工作项仍可关联。"
            return false
        }
        projectActionInFlight = true; projectActionError = nil; projectNotice = nil
        defer { projectActionInFlight = false }
        do {
            let updated: MordeProjectWorkItem = try await projectMutation(
                "/api/projects/\(projectID)/work-items/\(item.id)/tasks",
                body: ["task_id": taskID, "expected_version": item.version], scope: scope)
            guard scope == currentDataScope, selectedProjectID == projectID,
                  isValidProjectWorkItem(updated, projectID: projectID), updated.task_ids.contains(taskID),
                  updated.version > item.version else { throw URLError(.cannotParseResponse) }
            await loadProjectWorkItems(projectID)
            projectNotice = "Task 已关联到工作项。"
            return true
        } catch { await handleProjectMutationError(error, scope: scope, includeProjectBudget: false); return false }
    }

    func recordProjectWorkItemDelivery(projectID: String, item: MordeProjectWorkItem,
                                       taskID: String, hostID: String, workspaceID: String) async -> Bool {
        let role = projectMembers.first(where: { $0.project_id == projectID && $0.user_id == user?.id })?.role
        guard !projectActionInFlight,
              let scope = currentDataScope, projects.contains(where: { $0.id == projectID }),
              let task = projectConversationTask, task.id == taskID,
              task.conversation_id == selectedProjectConversationID,
              projectConversations.contains(where: { $0.id == task.conversation_id && $0.project_id == projectID }),
              isValidProjectWorkItem(item, projectID: projectID),
              let host = ownedHost(hostID), canOpenHost(host),
              let binding = workspaceBindings(for: hostID).first(where: { $0.workspace.id == workspaceID }),
              workspaceIsReady(binding),
              MordeProjectPolicy.canRecordDelivery(role: role, state: item.state, taskID: taskID,
                                                    taskIDs: item.task_ids, workspaceID: workspaceID,
                                                    revision: Int64(binding.workspace.revision)) else {
            projectActionError = "仅可为当前项目中关联的 Task 登记已就绪 Workspace 当前版本；服务端还会验证已保存产物。"
            return false
        }
        let revision = Int64(binding.workspace.revision)
        projectActionInFlight = true; projectActionError = nil; projectNotice = nil
        defer { projectActionInFlight = false }
        do {
            let updated: MordeProjectWorkItem = try await projectMutation(
                "/api/projects/\(projectID)/work-items/\(item.id)/delivery",
                body: ["task_id": taskID, "workspace_id": workspaceID,
                       "revision": revision, "expected_version": item.version], scope: scope)
            guard scope == currentDataScope, selectedProjectID == projectID,
                  isValidProjectWorkItem(updated, projectID: projectID), updated.state == "delivered",
                  updated.version > item.version, updated.delivery?.task_id == taskID,
                  updated.delivery?.workspace_id == workspaceID, updated.delivery?.revision == revision else {
                throw URLError(.cannotParseResponse)
            }
            await loadProjectWorkItems(projectID)
            projectNotice = "服务端已核验并登记 Workspace 交付版本；本操作未传送文件。"
            return true
        } catch { await handleProjectMutationError(error, scope: scope, includeProjectBudget: false); return false }
    }

    private func loadProjectDetail(_ id: String) async {
        guard let scope = currentDataScope, MordeProjectPolicy.hasValidID(id),
              let project = projects.first(where: { $0.id == id }) else { return }
        let generation = UUID()
        projectDetailLoadGeneration = generation
        projectDetailState = .loading
        projectMembers = []; projectResources = []
        do {
            let members: [MordeProjectMember] = try await projectPages("/api/projects/\(id)/members", scope: scope)
            guard generation == projectDetailLoadGeneration, selectedProjectID == id, scope == currentDataScope else { return }
            let ownerMembers = members.filter { $0.role == "owner" }
            guard members.allSatisfy({ $0.project_id == id && MordeProjectPolicy.hasValidUserID($0.user_id) &&
                ["owner", "member", "viewer"].contains($0.role) && $0.version > 0 }) &&
                Set(members.map(\.user_id)).count == members.count && ownerMembers.count == 1 &&
                ownerMembers.first?.user_id == project.owner_id else { throw URLError(.cannotParseResponse) }
            let resources: [MordeProjectResource] = try await projectPages("/api/projects/\(id)/resources", scope: scope)
            guard generation == projectDetailLoadGeneration, selectedProjectID == id, scope == currentDataScope else { return }
            guard resources.allSatisfy({ $0.project_id == id && MordeProjectPolicy.hasValidResourceID(kind: $0.kind, id: $0.resource_id) &&
                $0.version > 0 }) && Set(resources.map(\.id)).count == resources.count else {
                throw URLError(.cannotParseResponse)
            }
            projectMembers = members
            projectResources = resources
            projectDetailState = .loaded
        } catch {
            guard generation == projectDetailLoadGeneration, selectedProjectID == id, scope == currentDataScope else { return }
            projectMembers = []; projectResources = []
            projectDetailState = .failed(error.localizedDescription)
        }
    }

    private func projectMutationAttempt(scope: MordeClientDataScope, path: String,
                                        body: [String: Any]?) throws -> MordeRetryAttempt {
        guard let fingerprint = MordeActionRetryAttempt.fingerprint(
            taskID: scope.storageKey, endpoint: path, body: body ?? [:]) else { throw URLError(.badURL) }
        let storageKey = "morde.pendingProjectMutation.\(scope.storageKey)"
        let saved = UserDefaults.standard.data(forKey: storageKey)
            .flatMap { try? JSONDecoder().decode(MordeRetryAttempt.self, from: $0) }
        if let saved, saved.scope == scope,
           !MordeProjectPolicy.canContinuePendingMutation(saved.fingerprint, requestedFingerprint: fingerprint) {
            throw NSError(domain: "Morde.PendingProjectMutation", code: 409,
                          userInfo: [NSLocalizedDescriptionKey: "上一项项目操作结果尚未确认；请先用相同操作重试，以免重复执行。"])
        }
        let attempt = saved.flatMap { $0.matches(scope: scope, fingerprint: fingerprint) ? $0 : nil }
            ?? MordeRetryAttempt(scope: scope, fingerprint: fingerprint, key: UUID().uuidString)
        if let data = try? JSONEncoder().encode(attempt) { UserDefaults.standard.set(data, forKey: storageKey) }
        return attempt
    }

    private func clearProjectMutationAttempt(scope: MordeClientDataScope, key: String) {
        let storageKey = "morde.pendingProjectMutation.\(scope.storageKey)"
        guard let saved = UserDefaults.standard.data(forKey: storageKey)
            .flatMap({ try? JSONDecoder().decode(MordeRetryAttempt.self, from: $0) }),
              saved.scope == scope, saved.key == key else { return }
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    private func projectMutation<T: Decodable>(_ path: String, method: String = "POST",
                                               body: [String: Any]? = nil,
                                               scope: MordeClientDataScope) async throws -> T {
        let attempt = try projectMutationAttempt(scope: scope, path: path, body: body)
        let bytes = try body.map { try JSONSerialization.data(withJSONObject: $0) }
        let data: Data
        do {
            data = try await portalData(path, method: method, body: bytes,
                                        contentType: bytes == nil ? nil : "application/json",
                                        key: attempt.key, expectedScope: scope)
        } catch {
            // nanoMuse: A server-confirmed version conflict did not apply; allow the refreshed action's new version.
            if (error as NSError).code == 409 { clearProjectMutationAttempt(scope: scope, key: attempt.key) }
            throw error
        }
        let result = try JSONDecoder().decode(T.self, from: data.isEmpty ? Data("{}".utf8) : data)
        clearProjectMutationAttempt(scope: scope, key: attempt.key)
        return result
    }

    private func projectMutationNoContent(_ path: String, method: String,
                                          body: [String: Any], scope: MordeClientDataScope) async throws {
        let attempt = try projectMutationAttempt(scope: scope, path: path, body: body)
        let bytes = try JSONSerialization.data(withJSONObject: body)
        do {
            _ = try await portalData(path, method: method, body: bytes, contentType: "application/json",
                                     key: attempt.key, expectedScope: scope)
        } catch {
            if (error as NSError).code == 409 { clearProjectMutationAttempt(scope: scope, key: attempt.key) }
            throw error
        }
        clearProjectMutationAttempt(scope: scope, key: attempt.key)
    }

    private func handleProjectMutationError(_ error: Error, scope: MordeClientDataScope,
                                            includeProjectBudget: Bool = true) async {
        guard scope == currentDataScope else { return }
        if (error as NSError).domain == "Morde.PendingProjectMutation" {
            projectActionError = error.localizedDescription
            return
        }
        let conflict = (error as NSError).code == 409
        if conflict { await loadProjects(includeProjectBudget: includeProjectBudget) }
        guard scope == currentDataScope else { return }
        projectActionError = conflict
            ? "项目状态已变化，已刷新最新内容。请核对后再操作。"
            : error.localizedDescription
    }

    func createProject(name: String, description: String) async -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !projectActionInFlight else { return false }
        guard let scope = currentDataScope else {
            projectActionError = "登录状态尚未确认，请稍后重试。"
            return false
        }
        guard (1...120).contains(trimmedName.unicodeScalars.count), description.unicodeScalars.count <= 2000,
              !trimmedName.contains("\0"), !description.contains("\0") else {
            projectActionError = "项目名称必填且不超过 120 字，描述不超过 2000 字。"
            return false
        }
        projectActionInFlight = true; projectActionError = nil; projectNotice = nil
        defer { projectActionInFlight = false }
        do {
            let path = "/api/projects"
            let value: MordeProject = try await projectMutation(path, body: ["name": trimmedName, "description": description], scope: scope)
            guard scope == currentDataScope, isValidProject(value), value.owner_id == user?.id else { return false }
            selectedProjectID = value.id
            await loadProjects()
            guard scope == currentDataScope else { return false }
            projectNotice = "项目已创建。"
            return true
        } catch { await handleProjectMutationError(error, scope: scope); return false }
    }

    func acceptProjectInvitation(_ invitation: MordeProjectInvitation) async -> Bool {
        guard let scope = currentDataScope, !projectActionInFlight,
              isValidProjectInvitation(invitation),
              MordeProjectPolicy.canAcceptInvitation(state: invitation.state, inviteeID: invitation.invitee_id,
                                                      currentUserID: user?.id) else { return false }
        projectActionInFlight = true; projectActionError = nil; projectNotice = nil
        defer { projectActionInFlight = false }
        do {
            let member: MordeProjectMember = try await projectMutation(
                "/api/project-invitations/\(invitation.id)/accept", scope: scope)
            guard scope == currentDataScope, member.project_id == invitation.project_id,
                  member.user_id == user?.id, member.role == invitation.role, member.version > 0 else {
                throw URLError(.cannotParseResponse)
            }
            selectedProjectID = invitation.project_id
            await loadProjects()
            guard scope == currentDataScope else { return false }
            projectNotice = "已接受项目邀请。"
            return true
        } catch { await handleProjectMutationError(error, scope: scope); return false }
    }

    func inviteProjectMember(projectID: String, userID: String, role: String) async -> Bool {
        guard !projectActionInFlight else { return false }
        guard let scope = currentDataScope,
              let project = projects.first(where: { $0.id == projectID }),
              MordeProjectPolicy.isOwner(ownerID: project.owner_id, currentUserID: user?.id),
              MordeProjectPolicy.hasValidUserID(userID), userID != user?.id,
              ["member", "viewer"].contains(role) else {
            projectActionError = "请填写当前服务中已存在的其他用户 ID，并选择成员或只读权限。"
            return false
        }
        projectActionInFlight = true; projectActionError = nil; projectNotice = nil
        defer { projectActionInFlight = false }
        do {
            let path = "/api/projects/\(projectID)/members"
            let invitation: MordeProjectInvitation = try await projectMutation(
                path, body: ["user_id": userID, "role": role, "expected_version": project.version], scope: scope)
            guard scope == currentDataScope, isValidProjectInvitation(invitation), invitation.project_id == projectID,
                  invitation.inviter_id == user?.id, invitation.invitee_id == userID,
                  invitation.role == role, invitation.state == "pending" else {
                throw URLError(.cannotParseResponse)
            }
            var recent = recentProjectInvitations[projectID] ?? []
            recent.removeAll { $0.id == invitation.id }
            recent.append(invitation)
            recentProjectInvitations[projectID] = recent
            await loadProjects()
            projectNotice = "已创建待接受邀请。当前服务没有提供负责人待处理邀请列表；本次邀请仅在本机当前会话中可撤销。"
            return true
        } catch { await handleProjectMutationError(error, scope: scope); return false }
    }

    func revokeProjectInvitation(_ invitation: MordeProjectInvitation) async -> Bool {
        guard let scope = currentDataScope, !projectActionInFlight,
              isValidProjectInvitation(invitation), invitation.state == "pending",
              recentProjectInvitations[invitation.project_id]?.contains(where: { $0.id == invitation.id }) == true,
              projects.first(where: { $0.id == invitation.project_id }).map({
                  MordeProjectPolicy.isOwner(ownerID: $0.owner_id, currentUserID: user?.id)
              }) == true else { return false }
        projectActionInFlight = true; projectActionError = nil; projectNotice = nil
        defer { projectActionInFlight = false }
        do {
            let path = "/api/projects/\(invitation.project_id)/invitations/\(invitation.id)"
            try await projectMutationNoContent(path, method: "DELETE",
                                               body: ["expected_version": invitation.version], scope: scope)
            guard scope == currentDataScope else { return false }
            recentProjectInvitations[invitation.project_id]?.removeAll { $0.id == invitation.id }
            await loadProjects()
            projectNotice = "已撤销项目邀请。"
            return true
        } catch { await handleProjectMutationError(error, scope: scope); return false }
    }

    func updateProjectMember(projectID: String, member: MordeProjectMember, role: String) async -> Bool {
        guard let scope = currentDataScope, !projectActionInFlight,
              projects.first(where: { $0.id == projectID }).map({
                  MordeProjectPolicy.isOwner(ownerID: $0.owner_id, currentUserID: user?.id)
              }) == true,
              member.project_id == projectID, member.user_id != user?.id,
              MordeProjectPolicy.hasValidUserID(member.user_id), ["member", "viewer"].contains(role) else { return false }
        projectActionInFlight = true; projectActionError = nil; projectNotice = nil
        defer { projectActionInFlight = false }
        do {
            let path = "/api/projects/\(projectID)/members/\(member.user_id)"
            let result: MordeProjectMember = try await projectMutation(
                path, method: "PATCH", body: ["role": role, "expected_version": member.version], scope: scope)
            guard scope == currentDataScope, result.project_id == projectID, result.user_id == member.user_id,
                  result.role == role, result.version > member.version else { throw URLError(.cannotParseResponse) }
            await loadProjects()
            projectNotice = "成员权限已更新。"
            return true
        } catch { await handleProjectMutationError(error, scope: scope); return false }
    }

    func removeProjectMember(projectID: String, member: MordeProjectMember) async -> Bool {
        guard let scope = currentDataScope, !projectActionInFlight,
              projects.first(where: { $0.id == projectID }).map({
                  MordeProjectPolicy.isOwner(ownerID: $0.owner_id, currentUserID: user?.id)
              }) == true,
              member.project_id == projectID, member.user_id != user?.id,
              MordeProjectPolicy.hasValidUserID(member.user_id) else { return false }
        projectActionInFlight = true; projectActionError = nil; projectNotice = nil
        defer { projectActionInFlight = false }
        do {
            let path = "/api/projects/\(projectID)/members/\(member.user_id)"
            try await projectMutationNoContent(path, method: "DELETE",
                                               body: ["expected_version": member.version], scope: scope)
            guard scope == currentDataScope else { return false }
            await loadProjects()
            projectNotice = "成员已从项目移除。"
            return true
        } catch { await handleProjectMutationError(error, scope: scope); return false }
    }

    func transferProjectOwner(projectID: String, to userID: String) async -> Bool {
        guard let scope = currentDataScope, !projectActionInFlight,
              let project = projects.first(where: { $0.id == projectID }),
              MordeProjectPolicy.isOwner(ownerID: project.owner_id, currentUserID: user?.id),
              let target = projectMembers.first(where: { $0.user_id == userID && $0.project_id == projectID }),
              MordeProjectPolicy.canTransferOwnership(ownerID: project.owner_id, currentUserID: user?.id,
                                                       targetUserID: userID, targetRole: target.role) else { return false }
        projectActionInFlight = true; projectActionError = nil; projectNotice = nil
        defer { projectActionInFlight = false }
        do {
            let value: MordeProject = try await projectMutation(
                "/api/projects/\(projectID)/owner-transfer",
                body: ["user_id": userID, "expected_version": project.version], scope: scope)
            guard scope == currentDataScope, isValidProject(value), value.id == projectID,
                  value.owner_id == userID, value.version > project.version else { throw URLError(.cannotParseResponse) }
            await loadProjects()
            projectNotice = "项目负责人已更新。"
            return true
        } catch { await handleProjectMutationError(error, scope: scope); return false }
    }

    func addProjectResource(projectID: String, kind: String, resourceID: String) async -> Bool {
        guard !projectActionInFlight else { return false }
        guard let scope = currentDataScope,
              let project = projects.first(where: { $0.id == projectID }),
              MordeProjectPolicy.isOwner(ownerID: project.owner_id, currentUserID: user?.id),
              MordeProjectPolicy.hasValidResourceID(kind: kind, id: resourceID),
              (kind == "host" ? hosts.contains(where: { $0.id == resourceID }) : workspaces.contains(where: { $0.id == resourceID })) else {
            projectActionError = "请先选择当前账号可访问的电脑或 Workspace。"
            return false
        }
        projectActionInFlight = true; projectActionError = nil; projectNotice = nil
        defer { projectActionInFlight = false }
        do {
            let resource: MordeProjectResource = try await projectMutation(
                "/api/projects/\(projectID)/resources",
                body: ["kind": kind, "resource_id": resourceID, "expected_version": project.version], scope: scope)
            guard scope == currentDataScope, resource.project_id == projectID, resource.kind == kind,
                  resource.resource_id == resourceID, resource.version > 0 else { throw URLError(.cannotParseResponse) }
            await loadProjects()
            projectNotice = "资源关联已添加。关联不会授予项目成员 Host 或 Workspace 权限。"
            return true
        } catch { await handleProjectMutationError(error, scope: scope); return false }
    }

    func removeProjectResource(_ resource: MordeProjectResource) async -> Bool {
        guard let scope = currentDataScope, !projectActionInFlight,
              let project = projects.first(where: { $0.id == resource.project_id }),
              MordeProjectPolicy.isOwner(ownerID: project.owner_id, currentUserID: user?.id),
              projectResources.contains(where: { $0.id == resource.id }),
              MordeProjectPolicy.hasValidResourceID(kind: resource.kind, id: resource.resource_id) else { return false }
        projectActionInFlight = true; projectActionError = nil; projectNotice = nil
        defer { projectActionInFlight = false }
        do {
            try await projectMutationNoContent("/api/projects/\(resource.project_id)/resources", method: "DELETE",
                                               body: ["kind": resource.kind, "resource_id": resource.resource_id,
                                                      "expected_version": project.version], scope: scope)
            guard scope == currentDataScope else { return false }
            await loadProjects()
            projectNotice = "资源关联已移除。"
            return true
        } catch { await handleProjectMutationError(error, scope: scope); return false }
    }

    private static func parseISO8601(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }

    private func requireWorkspaceSync() throws {
        guard workspaceSyncAvailable == true else {
            throw NSError(domain: "Morde.WorkspaceSync", code: 503,
                          userInfo: [NSLocalizedDescriptionKey: "服务端尚未开放 Workspace 文件传输"])
        }
    }

    func loadWorkspaceManifest(workspaceID: String, revision: Int, cursor: String? = nil,
                               prefix: String? = nil) async throws -> MordeWorkspaceManifest {
        try requireWorkspaceSync()
        guard Self.validWorkspaceID(workspaceID), let scope = currentDataScope else { throw URLError(.badURL) }
        var components = URLComponents()
        components.path = "/api/workspaces/\(workspaceID)/manifest"
        components.queryItems = [URLQueryItem(name: "revision", value: String(revision)),
                                 URLQueryItem(name: "limit", value: "100")]
        if let cursor { components.queryItems?.append(URLQueryItem(name: "cursor", value: cursor)) }
        if let prefix = try MordeWorkspaceTransferSupport.normalizedManifestPrefix(prefix ?? "") {
            components.queryItems?.append(URLQueryItem(name: "prefix", value: prefix))
        }
        guard let path = components.string else { throw URLError(.badURL) }
        let page: MordeWorkspaceManifest = try await portalCall(path)
        guard scope == currentDataScope else { throw CancellationError() }
        let directoryPaths = page.directories.map(\.path)
        let workspacePaths = page.files.map(\.path) + directoryPaths.filter { $0 != "." }
        let hasValidRootMarker = directoryPaths.filter { $0 == "." }.count <= 1 &&
            (!directoryPaths.contains(".") || (prefix == nil && cursor == nil))
        guard page.workspace_id == workspaceID, page.revision == Int64(revision),
              hasValidRootMarker,
              MordeWorkspaceTransferSupport.hasCaseInsensitiveUniquePaths(workspacePaths) else {
            throw URLError(.cannotParseResponse)
        }
        return page
    }

    func verifiedTaskArtifactFile(workspaceID: String, revision: Int64, path: String,
                                  sizeBytes: Int64, sha256: String, scopeKey: String) async throws -> MordeWorkspaceFile {
        guard signedIn, scopeKey == taskPageScopeKey, revision >= 0, revision <= Int64(Int.max), sizeBytes >= 0,
              sha256.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil else {
            throw URLError(.badURL)
        }
        try MordeWorkspaceTransferSupport.validatePath(path)
        try requireWorkspaceSync()

        var cursor: String?
        var seenCursors = Set<String>()
        for _ in 0..<1_000 {
            let page = try await loadWorkspaceManifest(workspaceID: workspaceID, revision: Int(revision), cursor: cursor)
            guard scopeKey == taskPageScopeKey else { throw CancellationError() }
            if let file = page.files.first(where: { $0.path == path }) {
                guard file.sizeBytes == sizeBytes, file.sha256 == sha256 else {
                    throw MordeWorkspaceTransferError.changedFile
                }
                _ = try await verifyLocalWorkspaceFile(workspaceID: workspaceID, file: file)
                guard scopeKey == taskPageScopeKey else { throw CancellationError() }
                return file
            }
            guard let next = page.next_cursor else { break }
            guard seenCursors.insert(next).inserted else { throw MordeWorkspaceTransferError.invalidManifest }
            cursor = next
        }
        throw MordeWorkspaceTransferError.changedFile
    }

    func loadWorkspaceDiff(workspaceID: String, fromRevision: Int64,
                           toRevision: Int64) async throws -> MordeWorkspaceDiff {
        try requireWorkspaceSync()
        guard let scope = currentDataScope else { throw CancellationError() }
        guard Self.validWorkspaceID(workspaceID), fromRevision >= 0, toRevision >= 0,
              fromRevision != toRevision else { throw URLError(.badURL) }
        var components = URLComponents()
        components.path = "/api/workspaces/\(workspaceID)/diff"
        components.queryItems = [URLQueryItem(name: "from_revision", value: String(fromRevision)),
                                 URLQueryItem(name: "to_revision", value: String(toRevision))]
        guard let path = components.string else { throw URLError(.badURL) }
        let diff: MordeWorkspaceDiff = try await portalCall(path)
        guard scope == currentDataScope else { throw CancellationError() }
        guard diff.workspace_id == workspaceID, diff.from_revision == fromRevision,
              diff.to_revision == toRevision, diff.changes.count <= 500,
              diff.changes.allSatisfy({ change in
                  ([change.path] + [change.before?.path, change.after?.path].compactMap { $0 })
                    .allSatisfy { (try? MordeWorkspaceTransferSupport.validatePath($0)) != nil } &&
                  ["added", "removed", "changed", "renamed"].contains(change.action) &&
                  ["text", "binary", "too_large", "metadata_only", "not_applicable"].contains(change.display_status)
              }) else { throw URLError(.cannotParseResponse) }
        return diff
    }

    func restoreWorkspace(workspaceID: String, targetRevision: Int64, expectedCurrentRevision: Int64,
                          paths: [String], idempotencyKey: String) async throws -> MordeWorkspaceRestoreResult {
        try requireWorkspaceSync()
        guard let scope = currentDataScope else { throw CancellationError() }
        guard Self.validWorkspaceID(workspaceID), targetRevision >= 0, expectedCurrentRevision >= 0,
              !paths.isEmpty, paths.count <= 1000,
              MordeWorkspaceTransferSupport.hasCaseInsensitiveUniquePaths(paths),
              MordePersonalDataContract.isValidIdempotencyKey(idempotencyKey) else { throw URLError(.badURL) }
        let result: MordeWorkspaceRestoreResult = try await portalCall(
            "/api/workspaces/\(workspaceID)/restore", method: "POST",
            body: ["target_revision": targetRevision, "expected_current_revision": expectedCurrentRevision,
                   "paths": paths], key: idempotencyKey)
        guard scope == currentDataScope else { throw CancellationError() }
        guard result.workspace_id == workspaceID, result.target_revision == targetRevision,
              result.expected_current_revision == expectedCurrentRevision,
              result.revision >= expectedCurrentRevision else { throw URLError(.cannotParseResponse) }
        return result
    }

    func applyWorkspaceFileOperation(workspaceID: String, action: MordeWorkspaceFileOperationAction,
                                     sourcePath: String, targetPath: String,
                                     expectedCurrentRevision: Int64) async throws -> MordeWorkspaceFileOperationResult {
        try requireWorkspaceSync()
        guard Self.validWorkspaceID(workspaceID), expectedCurrentRevision >= 0 else { throw URLError(.badURL) }
        try MordeWorkspaceTransferSupport.validatePath(sourcePath)
        if action == .delete {
            guard targetPath.isEmpty else { throw URLError(.badURL) }
        } else {
            try MordeWorkspaceTransferSupport.validatePath(targetPath)
            guard targetPath != sourcePath else { throw URLError(.badURL) }
        }
        let key = MordeWorkspaceTransferSupport.idempotencyKey([
            "file-operation", workspaceID, action.rawValue, String(expectedCurrentRevision), sourcePath, targetPath,
        ])
        let result: MordeWorkspaceFileOperationResult = try await portalCall(
            "/api/workspaces/\(workspaceID)/file-operations", method: "POST",
            body: ["action": action.rawValue, "source_path": sourcePath, "target_path": targetPath,
                   "expected_current_revision": expectedCurrentRevision, "write_enabled": true], key: key)
        guard result.workspace_id == workspaceID, result.action == action.rawValue,
              result.source_path == sourcePath, result.target_path == targetPath,
              result.expected_current_revision == expectedCurrentRevision,
              result.revision >= expectedCurrentRevision else { throw URLError(.cannotParseResponse) }
        return result
    }

    func uploadWorkspaceFiles(workspaceID: String, baseRevision: Int, selections: [MordeWorkspaceLocalSelection],
                              progress: @escaping @MainActor (Int64, Int64) -> Void) async throws -> MordeWorkspaceSyncSession {
        try requireWorkspaceSync()
        guard Self.validWorkspaceID(workspaceID), !selections.isEmpty else { throw URLError(.badURL) }
        let sources = selections.map { (url: $0.url, path: $0.file.path) }
        let files = try await Task.detached(priority: .userInitiated) {
            try sources.map { source in
                try withMordeSecurityScope(source.url) {
                    try MordeWorkspaceTransferSupport.scan(url: source.url, path: source.path)
                }
            }
        }.value
        guard files == selections.map(\.file),
              MordeWorkspaceTransferSupport.hasCaseInsensitiveUniquePaths(files.map(\.path)) else {
            throw MordeWorkspaceTransferError.changedFile
        }
        let encoded = try JSONEncoder().encode(files)
        guard let filePayload = try JSONSerialization.jsonObject(with: encoded) as? [[String: Any]] else {
            throw URLError(.cannotParseResponse)
        }
        var transferFiles: [String: (URL, Int, MordeWorkspaceChunk)] = [:]
        for selection in selections {
            for (index, chunk) in selection.file.chunks.enumerated() where transferFiles[chunk.sha256] == nil {
                transferFiles[chunk.sha256] = (selection.url, index, chunk)
            }
        }
        let createBody: [String: Any] = [
            "direction": "upload", "policy": "compare_merge", "base_revision": baseRevision,
            "scope": files.map(\.path), "files": filePayload,
        ]
        var session: MordeWorkspaceSyncSession = try await portalCall(
            "/api/workspaces/\(workspaceID)/sync-sessions", method: "POST",
            body: createBody, key: UUID().uuidString)
        guard session.workspace_id == workspaceID, Self.validSyncSessionID(session.id) else {
            throw URLError(.cannotParseResponse)
        }
        guard session.conflicts.isEmpty else {
            throw NSError(domain: "Morde", code: 409,
                          userInfo: [NSLocalizedDescriptionKey: "所选文件与 Workspace 当前版本冲突：\(session.conflicts.map(\.path).joined(separator: "、"))。请刷新文件并重新确认。"])
        }
        var confirmed = session.confirmed_bytes
        progress(confirmed, session.planned_bytes)
        for block in session.transfer_blocks where block.role == "upload" && !block.received {
            guard let source = transferFiles[block.chunk.sha256], source.2 == block.chunk else {
                throw URLError(.cannotParseResponse)
            }
            let data = try await Task.detached(priority: .userInitiated) {
                try withMordeSecurityScope(source.0) {
                    try MordeWorkspaceTransferSupport.readChunk(url: source.0, index: source.1, expected: source.2)
                }
            }.value
            _ = try await portalData("/api/workspaces/\(workspaceID)/sync-sessions/\(session.id)/blocks/\(block.chunk.sha256)",
                                     method: "PUT", body: data, contentType: "application/octet-stream")
            confirmed += block.chunk.sizeBytes
            progress(confirmed, session.planned_bytes)
        }
        session = try await portalCall(
            "/api/workspaces/\(workspaceID)/sync-sessions/\(session.id)/commit", method: "POST",
            key: UUID().uuidString)
        guard session.state == "completed" else {
            throw NSError(domain: "Morde", code: 409,
                          userInfo: [NSLocalizedDescriptionKey: "文件已传输，但 Workspace 检查点尚未确认（\(session.state)）。请刷新后核对状态。"])
        }
        await refreshWorkspaces()
        return session
    }

    func downloadWorkspaceFile(workspaceID: String, revision: Int, file: MordeWorkspaceFile,
                               progress: @escaping @MainActor (Int64, Int64) -> Void) async throws -> URL {
        try requireWorkspaceSync()
        guard Self.validWorkspaceID(workspaceID), Self.validRevision(revision) else { throw URLError(.badURL) }
        try MordeWorkspaceTransferSupport.validatePath(file.path)
        let destination = try Self.workspaceDownloadURL(workspaceID: workspaceID, path: file.path, createParents: true)
        var existingLocalCopy = false
        if FileManager.default.fileExists(atPath: destination.path) {
            let existing = try await Task.detached(priority: .userInitiated) {
                try withMordeSecurityScope(destination) {
                    try MordeWorkspaceTransferSupport.scan(url: destination, path: file.path)
                }
            }.value
            guard existing == file else { throw MordeWorkspaceTransferError.targetExists }
            existingLocalCopy = true
        }

        let createBody: [String: Any] = [
            "direction": "download", "policy": "fill_missing", "base_revision": revision,
            "scope": [file.path], "files": [[String: Any]](),
        ]
        var session: MordeWorkspaceSyncSession = try await portalCall(
            "/api/workspaces/\(workspaceID)/sync-sessions", method: "POST",
            body: createBody, key: UUID().uuidString)
        guard session.workspace_id == workspaceID, Self.validSyncSessionID(session.id) else {
            throw URLError(.cannotParseResponse)
        }
        let actions = session.download_actions.filter { $0.path == file.path }
        guard actions.count == 1, let action = actions.first, action.action == "upsert",
              action.sha256 == file.sha256, action.size_bytes == file.sizeBytes else {
            throw NSError(domain: "Morde", code: 409,
                          userInfo: [NSLocalizedDescriptionKey: "Workspace 文件版本已变化，请刷新清单后重新下载。"])
        }
        let downloadBlocks = session.transfer_blocks.filter { $0.role == "download" }
        let blockMap = Dictionary(downloadBlocks.map { ($0.chunk.sha256, $0.chunk) }, uniquingKeysWith: { first, _ in first })
        guard file.chunks.allSatisfy({ blockMap[$0.sha256] == $0 }) else { throw URLError(.cannotParseResponse) }
        var confirmed: Int64 = 0
        progress(confirmed, session.planned_bytes)
        if !existingLocalCopy {
            try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            let writer = try MordeWorkspaceDownloadWriter(file: file, to: destination)
            do {
                for chunk in file.chunks {
                    let data = try await portalData(
                        "/api/workspaces/\(workspaceID)/sync-sessions/\(session.id)/blocks/\(chunk.sha256)")
                    try writer.append(data, expected: chunk)
                    confirmed += chunk.sizeBytes
                    progress(confirmed, session.planned_bytes)
                }
                try writer.finish()
            } catch {
                writer.cancel()
                throw error
            }
        }
        for chunk in file.chunks {
            _ = try await portalData(
                "/api/workspaces/\(workspaceID)/sync-sessions/\(session.id)/blocks/\(chunk.sha256)/ack",
                method: "POST")
        }
        let actionAck: [String: Any] = ["path": file.path, "action": "upsert",
                                        "sha256": file.sha256, "size_bytes": file.sizeBytes]
        _ = try await portalData(
            "/api/workspaces/\(workspaceID)/sync-sessions/\(session.id)/download-actions/ack",
            method: "POST", body: try JSONSerialization.data(withJSONObject: actionAck),
            contentType: "application/json")
        session = try await portalCall(
            "/api/workspaces/\(workspaceID)/sync-sessions/\(session.id)/commit", method: "POST",
            key: UUID().uuidString)
        guard session.state == "completed" else {
            throw NSError(domain: "Morde", code: 409,
                          userInfo: [NSLocalizedDescriptionKey: "文件已核验并保存，但下载检查点尚未确认（\(session.state)）。"])
        }
        return destination
    }

    func refreshWorkspaces() async {
        guard let scope = currentDataScope else { return }
        let generation = resourceLoadGeneration
        do {
            let page: MordePage<MordeWorkspace> = try await call("/api/workspaces")
            guard scope == currentDataScope, generation == resourceLoadGeneration else { return }
            workspaces = page.items
            setResourceState(.loaded, for: .workspaces)
        } catch {
            guard scope == currentDataScope, generation == resourceLoadGeneration else { return }
            workspaces = []
            setResourceState(.failed(error.localizedDescription), for: .workspaces)
        }
    }

    func localWorkspaceFileURL(workspaceID: String, path: String) -> URL? {
        try? Self.workspaceDownloadURL(workspaceID: workspaceID, path: path)
    }

    func verifyLocalWorkspaceFile(workspaceID: String, file: MordeWorkspaceFile) async throws -> URL {
        let url = try Self.workspaceDownloadURL(workspaceID: workspaceID, path: file.path)
        let actual = try await Task.detached(priority: .userInitiated) {
            try withMordeSecurityScope(url) {
                try MordeWorkspaceTransferSupport.scan(url: url, path: file.path)
            }
        }.value
        guard actual == file else { throw MordeWorkspaceTransferError.changedFile }
        return url
    }

    func verifyLocalTaskArtifactFile(workspaceID: String, file: MordeWorkspaceFile,
                                     scopeKey: String) async throws -> URL {
        guard signedIn, workspaceSyncAvailable == true, scopeKey == taskPageScopeKey else {
            throw CancellationError()
        }
        let url = try await verifyLocalWorkspaceFile(workspaceID: workspaceID, file: file)
        guard signedIn, workspaceSyncAvailable == true, scopeKey == taskPageScopeKey else {
            throw CancellationError()
        }
        return url
    }

    func removeLocalWorkspaceFile(workspaceID: String, path: String) throws {
        let url = try Self.workspaceDownloadURL(workspaceID: workspaceID, path: path)
        try MordeWorkspaceTransferSupport.removeRegularFileWithoutFollowingSymlinks(url)
    }

    private static func validWorkspaceID(_ value: String) -> Bool {
        value.range(of: "^w[a-z0-9]{7}$", options: .regularExpression) != nil
    }

    private static func validSyncSessionID(_ value: String) -> Bool {
        value.range(of: "^p[a-z0-9]{7}$", options: .regularExpression) != nil
    }

    private static func validRevision(_ value: Int) -> Bool { value >= 0 }

    private static func workspaceDownloadURL(workspaceID: String, path: String,
                                             createParents: Bool = false) throws -> URL {
        guard validWorkspaceID(workspaceID) else { throw URLError(.badURL) }
        try MordeWorkspaceTransferSupport.validatePath(path)
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let downloadRoot = documents.appendingPathComponent("Morde Workspace Files", isDirectory: true)
        if !MordeWorkspaceTransferSupport.pathEntryExists(downloadRoot), createParents {
            try FileManager.default.createDirectory(at: downloadRoot, withIntermediateDirectories: false)
        }
        if MordeWorkspaceTransferSupport.pathEntryExists(downloadRoot),
           !MordeWorkspaceTransferSupport.isDirectoryWithoutFollowingSymlinks(downloadRoot) {
            throw MordeWorkspaceTransferError.invalidPath
        }
        let root = downloadRoot.appendingPathComponent(workspaceID, isDirectory: true)
        if !MordeWorkspaceTransferSupport.pathEntryExists(root), createParents {
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        }
        if MordeWorkspaceTransferSupport.pathEntryExists(root),
           !MordeWorkspaceTransferSupport.isDirectoryWithoutFollowingSymlinks(root) {
            throw MordeWorkspaceTransferError.invalidPath
        }
        var parent = root
        let components = path.split(separator: "/").map(String.init)
        for component in components.dropLast() {
            parent.appendPathComponent(component, isDirectory: true)
            if createParents {
                if !MordeWorkspaceTransferSupport.pathEntryExists(parent) {
                    try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: false)
                }
            }
            if MordeWorkspaceTransferSupport.pathEntryExists(parent),
               !MordeWorkspaceTransferSupport.isDirectoryWithoutFollowingSymlinks(parent) {
                throw MordeWorkspaceTransferError.invalidPath
            }
        }
        let destination = parent.appendingPathComponent(components.last!, isDirectory: false)
            .standardizedFileURL
        guard destination.path.hasPrefix(root.standardizedFileURL.path + "/") else {
            throw MordeWorkspaceTransferError.invalidPath
        }
        return destination
    }

    // nanoMuse: Registration creates a pending account only; it must not save a Client credential.
    func register(name: String, password: String) async {
        guard !busy else { return }
        guard let payload = MordeRegistrationPayload.make(name: name, password: password) else {
            error = String(localized: "Enter a username and password.")
            return
        }
        busy = true; defer { busy = false }
        registrationMessage = nil
        do {
            try setServer(server)
            let result: MordeRegistrationResult = try await call(
                "/api/auth/register", method: "POST", body: payload.jsonObject, authorized: false)
            guard !result.user.id.isEmpty, result.user.status == "pending" else {
                throw URLError(.cannotParseResponse)
            }
            registrationMessage = String(localized: "Registration submitted. Your account is waiting for administrator review.")
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func login(name: String, password: String) async {
        guard !busy else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !password.isEmpty else { return }
        busy = true; defer { busy = false }
        var intent: MordeLoginIntent?
        var attempt: MordeLoginAttemptTicket?
        do {
            try setServer(server)
            guard let origin = MordeLoginStateStore.serviceOrigin(server) else { throw URLError(.badURL) }
            let loginIntent = try loginStateStore.registerIntent(origin: origin, accountName: trimmedName)
            intent = loginIntent
            let capabilities = try await checkCapabilities()
            guard let loginAttempt = try loginStateStore.beginAttempt(
                for: loginIntent, serviceInstanceID: capabilities.service_instance_id) else { return }
            attempt = loginAttempt
            var body: [String: Any] = ["name": trimmedName, "password": password,
                                       "platform": "ios", "display_name": UIDevice.current.name,
                                       "client_instance_id": loginAttempt.clientInstanceID.uuidString,
                                       "attempt_generation": loginAttempt.attemptGeneration]
            let previousInstallation = installationForLogin(origin: origin,
                                                            serviceInstanceID: capabilities.service_instance_id,
                                                            accountName: trimmedName)?.installation
            if let previousInstallation,
               MordeLoginContract.mayRenewInstallation(
                installationOrigin: previousInstallation.serviceOrigin,
                installationServiceInstanceID: previousInstallation.serviceInstanceID,
                selectedServer: loginAttempt.origin,
                selectedServiceInstanceID: loginAttempt.serviceInstanceID,
                legacyServer: UserDefaults.standard.string(forKey: "morde.server"),
                installationAccount: previousInstallation.accountName,
                accountName: trimmedName
               ) {
                body["renewal_installation_id"] = previousInstallation.id
            }
            var loginHeaders: [String: String] = [:]
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains(MordeAuthURLProtocol.accountIsolationFixtureLaunchArgument) {
                // nanoMuse: Let the in-process fixture distinguish its synthetic accounts without parsing request bodies.
                loginHeaders["X-Morde-Local-Account"] = trimmedName
            }
#endif
            let result: MordeLoginResult = try await call("/api/auth/client-login", method: "POST",
                body: body, key: loginAttempt.idempotencyKey, authorized: false, headers: loginHeaders)
            guard !result.installation_id.isEmpty, !result.client_credential.isEmpty,
                  MordeCredentialExpiry.validCredential(result.client_credential, expiresAt: result.client_expires_at) != nil else {
                throw URLError(.cannotParseResponse)
            }
            let stored = MordeAuthorization(credential: result.client_credential, expiresAt: result.client_expires_at)
            guard let lookupKey = Self.installationLookupKey(origin: loginAttempt.origin,
                                                             serviceInstanceID: loginAttempt.serviceInstanceID,
                                                             accountName: trimmedName),
                  let credentialScope = MordeClientDataScope(serviceOrigin: loginAttempt.origin,
                                                             serviceInstanceID: loginAttempt.serviceInstanceID,
                                                             accountID: trimmedName,
                                                             installationID: result.installation_id) else {
                throw URLError(.cannotParseResponse)
            }
            let newInstallation = MordeInstallation(id: result.installation_id, accountName: trimmedName,
                                                     serviceOrigin: loginAttempt.origin,
                                                     serviceInstanceID: loginAttempt.serviceInstanceID,
                                                     accountID: nil,
                                                     clientInstanceID: loginAttempt.clientInstanceID,
                                                     revocationStatus: "active")
            let accepted = try loginStateStore.commitIfCurrent(loginAttempt) {
                try keychain.set(String(decoding: JSONEncoder().encode(stored), as: UTF8.self),
                                 key: "authorization.\(credentialScope.storageKey)")
                try saveInstallation(newInstallation, lookupKey: lookupKey, makeActive: true)
            }
            guard accepted else { return }
            verifiedServiceInstanceID = loginAttempt.serviceInstanceID
            publishShellAuthorization()
            UserDefaults.standard.removeObject(forKey: "morde.installation")
            clearLegacyAuthorization()
            error = nil
            registrationMessage = nil
            await load()
        } catch {
            if let intent, !loginStateStore.isLatest(intent) { return }
            if let attempt, !loginStateStore.isCurrent(attempt) { return }
            if let intent { _ = try? loginStateStore.finish(intent) }
            self.error = error.localizedDescription
        }
    }

    func signOut() async {
        guard !busy else { return }
        busy = true; defer { busy = false }
        let oldInstallation = installation
        var confirmed = false
        if signedIn, oldInstallation != nil {
            do {
                let _: MordeEmpty = try await call("/api/auth/client-logout", method: "POST",
                                                   handleUnauthorized: false)
                confirmed = true
            } catch { confirmed = false }
        }
        signOutLocally(installation: oldInstallation, confirmed: confirmed)
        if !confirmed { error = "本机已退出；服务器安装撤销尚未确认，撤销标识已保留。" }
    }

    var currentClientInstallationID: String? { installation?.id }

    func loadClientInstallations() async {
        let generation = UUID()
        clientInstallationsLoadGeneration = generation
        clientInstallations = []
        clientInstallationsState = .loading
        clientInstallationsActionError = nil
        clientInstallationsNotice = nil
        guard signedIn, let requestScope = currentDataScope else {
            clientInstallationsState = .failed(String(localized: "Not signed in to Morde."))
            return
        }
        do {
            let page: MordePage<MordeClientInstallation> = try await call("/api/clients")
            guard generation == clientInstallationsLoadGeneration,
                  requestScope == currentDataScope, !Task.isCancelled else { return }
            guard page.items.allSatisfy({ MordeClientInstallationPolicy.isValidID($0.id) }) else {
                throw URLError(.cannotParseResponse)
            }
            clientInstallations = page.items
            clientInstallationsState = .loaded
        } catch {
            guard generation == clientInstallationsLoadGeneration,
                  requestScope == currentDataScope, !Task.isCancelled else { return }
            clientInstallations = []
            clientInstallationsState = .failed(error.localizedDescription)
        }
    }

    func loadDevices() async {
        let generation = UUID()
        devicesLoadGeneration = generation
        devices = []
        devicesState = .loading
        hubRelayError = nil
        hubRelayNotice = nil
        guard signedIn, let requestScope = currentDataScope else {
            devicesState = .failed(String(localized: "Not signed in to Morde."))
            return
        }
        do {
            let response: MordeDeviceList = try await call("/api/devices")
            guard generation == devicesLoadGeneration, requestScope == currentDataScope, !Task.isCancelled else { return }
            let ids = response.items.map(\.id)
            guard Set(ids).count == ids.count,
                  response.items.allSatisfy({ device in
                    MordeClientInstallationPolicy.isValidID(device.id) &&
                        !device.display_name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                        device.display_name.unicodeScalars.count <= 100 &&
                        ["desktop", "android", "ios"].contains(device.platform) &&
                        Self.parseISO8601(device.expires_at) != nil && Self.parseISO8601(device.created_at) != nil &&
                        (device.last_used_at.map { Self.parseISO8601($0) != nil } ?? true)
                  }) else { throw URLError(.cannotParseResponse) }
            devices = response.items.sorted { $0.display_name.localizedCaseInsensitiveCompare($1.display_name) == .orderedAscending }
            devicesState = .loaded
        } catch {
            guard generation == devicesLoadGeneration, requestScope == currentDataScope, !Task.isCancelled else { return }
            devices = []
            devicesState = .failed(error.localizedDescription)
        }
    }

    func openURLOnDevice(_ deviceID: String, input: String) async {
        guard hubAvailable == true,
              let device = devices.first(where: { $0.id == deviceID }), device.online, !device.revoked,
              deviceID != currentClientInstallationID,
              let destination = URL(string: input), (try? MordeHubRelayPolicy.validateOpenURL(destination)) != nil,
              let portalServer = URL(string: server), let credential = token,
              let requestScope = currentDataScope, hubRelayWorkingID == nil else { return }
        hubRelayWorkingID = deviceID
        hubRelayError = nil
        hubRelayNotice = nil
        defer { if hubRelayWorkingID == deviceID { hubRelayWorkingID = nil } }
        do {
            try await MordeHubRelay.open(url: destination, on: deviceID, portalServer: portalServer, credential: credential)
            guard requestScope == currentDataScope else { return }
            hubRelayNotice = "目标设备已确认打开链接。"
        } catch {
            guard requestScope == currentDataScope else { return }
            hubRelayError = hubRelayMessage(error)
        }
    }

    private func hubRelayMessage(_ error: Error) -> String {
        guard let error = error as? MordeHubRelayError else {
            return "未收到目标设备确认；实际打开状态未知：\(error.localizedDescription)"
        }
        switch error {
        case .targetOffline: return "目标设备当前离线，接力未确认。"
        case .timeout: return "未收到目标设备确认；实际打开状态未知，请在目标设备检查。"
        case .callRejected(let reason): return "目标设备未确认打开链接（\(reason)）。"
        case .invalidCredential: return "Morde 登录凭证不可用，请重新登录。"
        case .invalidURL: return "请输入有效的 HTTP 或 HTTPS 链接。"
        case .targetIsCurrentDevice: return "不能将链接接力到当前设备。"
        case .invalidPortalServer, .invalidTarget, .malformedFrame, .unsupportedFrame:
            return "Hub 响应无法验证；接力结果未知。"
        }
    }

    func revokeClientInstallation(_ target: MordeClientInstallation) async {
        guard let path = MordeClientInstallationPolicy.revokePath(
            for: target.id, currentInstallationID: currentClientInstallationID),
              !target.revoked,
              let requestScope = currentDataScope,
              revokingClientInstallationID == nil else { return }
        revokingClientInstallationID = target.id
        clientInstallationsActionError = nil
        clientInstallationsNotice = nil
        defer { revokingClientInstallationID = nil }
        do {
            let _: MordeEmpty = try await call(path, method: "DELETE")
            guard requestScope == currentDataScope else { return }
            clientInstallations.removeAll { $0.id == target.id }
            clientInstallationsNotice = String(localized: "Installation revoked.")
        } catch {
            guard requestScope == currentDataScope else { return }
            clientInstallationsActionError = error.localizedDescription
        }
    }

    var isLoadingResources: Bool { resourceLoadIsInProgress }

    func refreshResourceLists() async {
        guard signedIn, let scope = currentDataScope, !resourceLoadIsInProgress else { return }
        let generation = resourceLoadGeneration
        resourceLoadIsInProgress = true
        defer { if generation == resourceLoadGeneration { resourceLoadIsInProgress = false } }
        await loadResource(.hosts, generation: generation, fetch: {
            let page: MordePage<MordeHost> = try await self.call("/api/hosts")
            return page.items
        }, apply: { self.hosts = $0 }, clear: { self.hosts = [] })
        await loadResource(.sharedHosts, generation: generation, fetch: {
            let page: MordePage<MordeSharedHost> = try await self.call("/api/shared-hosts")
            return page.items
        }, apply: { self.sharedHosts = $0 }, clear: { self.sharedHosts = [] })
        await loadResource(.workspaces, generation: generation, fetch: {
            let page: MordePage<MordeWorkspace> = try await self.call("/api/workspaces")
            return page.items
        }, apply: { self.workspaces = $0 }, clear: { self.workspaces = [] })
        guard scope == currentDataScope, generation == resourceLoadGeneration else { return }
        await loadDefaultHostPreference()
        await refreshHostControls()
    }

    func load() async {
        guard !resourceLoadIsInProgress else { return }
        let generation = beginResourceLoad()
        resourceLoadIsInProgress = true
        defer { if generation == resourceLoadGeneration { resourceLoadIsInProgress = false } }
        // nanoMuse: Keep the verified sign-in fence stable while refreshing resources from the same service.
        cloudTasksAvailable = nil
        taskAPIAvailable = nil
        guard let activeInstallation = installation else {
            verifiedServiceInstanceID = nil
            resetViewState()
            return
        }
        do {
            let capabilities = try await checkCapabilities()
            guard generation == resourceLoadGeneration, !Task.isCancelled else { return }
            guard activeInstallation.serviceOrigin == MordeLoginStateStore.serviceOrigin(server),
                  activeInstallation.serviceInstanceID == capabilities.service_instance_id.lowercased() else {
                verifiedServiceInstanceID = nil
                resetViewState()
                error = "Morde 后端服务实例已变化，请重新登录"
                return
            }
            verifiedServiceInstanceID = capabilities.service_instance_id.lowercased()
            publishShellAuthorization()
            refreshExpiredAuthorization()
            guard signedIn else { return }
            let me: MordeMe = try await call("/api/me")
            guard generation == resourceLoadGeneration, !Task.isCancelled else { return }
            if let storedAccountID = activeInstallation.accountID, storedAccountID != me.id {
                signOutLocally(installation: activeInstallation)
                error = "当前安装所属账号已变化，请重新登录"
                return
            }
            if activeInstallation.accountID != me.id {
                let updated = MordeInstallation(id: activeInstallation.id, accountName: activeInstallation.accountName,
                                                 serviceOrigin: activeInstallation.serviceOrigin,
                                                 serviceInstanceID: activeInstallation.serviceInstanceID,
                                                 accountID: me.id, clientInstanceID: activeInstallation.clientInstanceID,
                                                 revocationStatus: "active")
                updateActiveInstallation(updated)
            }
            user = me
            publishShellAuthorization()
            await loadResource(.hosts, generation: generation, fetch: {
                let page: MordePage<MordeHost> = try await self.call("/api/hosts")
                return page.items
            }, apply: { self.hosts = $0 }, clear: { self.hosts = [] })
            await loadResource(.sharedHosts, generation: generation, fetch: {
                let page: MordePage<MordeSharedHost> = try await self.call("/api/shared-hosts")
                return page.items
            }, apply: { self.sharedHosts = $0 }, clear: { self.sharedHosts = [] })
            await loadResource(.workspaces, generation: generation, fetch: {
                let page: MordePage<MordeWorkspace> = try await self.call("/api/workspaces")
                return page.items
            }, apply: { self.workspaces = $0 }, clear: { self.workspaces = [] })
            await loadResource(.models, generation: generation, fetch: {
                let available: MordeAvailableModels = try await self.call("/api/available-models")
                let connections: MordeModelConnectionList = try await self.call("/api/model-connections")
                let eligible = available.items.filter { $0.capabilities.text && $0.capabilities.tools }
                let eligibleIDs = Set(eligible.map(\.id))
                let defaultID = available.default_model_id.flatMap { eligibleIDs.contains($0) ? $0 : nil }
                let configured = available.default_model_configured && defaultID != nil
                let personalIDs = Set(connections.items.filter { !$0.shared && $0.checked_at != nil }.map(\.id))
                    .intersection(eligibleIDs)
                let allowedIDs = personalIDs.union(configured ? Set([defaultID].compactMap { $0 }) : [])
                return MordeLoadedModels(
                    items: eligible.filter { allowedIDs.contains($0.id) },
                    defaultModelConfigured: configured,
                    defaultModelID: configured ? defaultID : nil,
                    personalModelIDs: personalIDs)
            }, apply: {
                self.models = $0.items
                self.defaultModelConfigured = $0.defaultModelConfigured
                self.defaultModelID = $0.defaultModelID
                self.personalModelIDs = $0.personalModelIDs
            }, clear: {
                self.models = []
                self.defaultModelConfigured = false
                self.defaultModelID = nil
                self.personalModelIDs = []
            })
            await loadResource(.conversations, generation: generation, fetch: {
                let page: MordePage<MordeConversation> = try await self.call("/api/conversations?limit=100")
                return page
            }, apply: { self.conversations = $0.items; self.conversationNextCursor = $0.next_cursor },
               clear: { self.conversations = []; self.conversationNextCursor = nil })
            await loadResource(.tasks, generation: generation, fetch: {
                let page: MordePage<MordeTask> = try await self.call("/api/tasks?limit=100")
                return page.items
            }, apply: { self.tasks = $0 }, clear: { self.tasks = [] })
            var notificationsCursor: String?
            await loadResource(.notifications, generation: generation, fetch: {
                let page: MordePage<MordeNotification> = try await self.call("/api/notifications?limit=100")
                notificationsCursor = page.next_cursor
                return page.items
            }, apply: { self.notifications = $0; self.notificationNextCursor = notificationsCursor },
               clear: { self.notifications = []; self.notificationNextCursor = nil })
            guard generation == resourceLoadGeneration, !Task.isCancelled else { return }

            await loadMainConversation(generation: generation)
            if resourceState(.conversations).isLoaded {
                let shouldFollowMain = MordeConversationSelectionPolicy.shouldFollowMain(
                    currentlySelected: currentConversation, wasFollowingMain: followsMainConversation)
                let currentID = shouldFollowMain && mainConversation?.status == "ready"
                    ? mainConversation?.conversation_id : currentConversation
                if currentID != nil { followsMainConversation = shouldFollowMain && mainConversation?.status == "ready" }
                if let currentID {
                    if !conversations.contains(where: { $0.id == currentID }) {
                        do {
                            let item: MordeConversation = try await call("/api/conversations/\(currentID)")
                            guard generation == resourceLoadGeneration, !Task.isCancelled else { return }
                            conversations.insert(item, at: 0)
                        } catch { /* The message request below reports an inaccessible selection. */ }
                    }
                    currentConversation = currentID
                    await showConversation(currentID, followsMain: followsMainConversation)
                } else {
                    currentConversation = nil; currentTask = nil; messages = []
                    followsMainConversation = false
                    setResourceState(.loaded, for: .messages)
                    setResourceState(.loaded, for: .taskDetail)
                }
            }
            error = nil
        } catch {
            guard generation == resourceLoadGeneration, !Task.isCancelled, signedIn else { return }
            markListResourcesFailed(error.localizedDescription, generation: generation)
            self.error = error.localizedDescription
        }
    }

    // nanoMuse: Restore only the signed-in fence before the original shell decides whether to show first-run setup.
    func restoreLoginForFirstRun() async {
        guard let activeInstallation = installation else { return }
        do {
            let capabilities = try await checkCapabilities()
            guard installation?.id == activeInstallation.id else { return }
            guard activeInstallation.serviceOrigin == MordeLoginStateStore.serviceOrigin(server),
                  activeInstallation.serviceInstanceID == capabilities.service_instance_id.lowercased() else {
                verifiedServiceInstanceID = nil
                resetViewState()
                error = "Morde 后端服务实例已变化，请重新登录"
                return
            }
            verifiedServiceInstanceID = capabilities.service_instance_id.lowercased()
            publishShellAuthorization()
            refreshExpiredAuthorization()
        } catch {
            guard installation?.id == activeInstallation.id else { return }
            self.error = error.localizedDescription
        }
    }

    private func loadMainConversation(generation: UUID) async {
        let scope = currentDataScope
        guard scope != nil else { return }
        do {
            var state: MordeMainConversation = try await call("/api/me/main-conversation")
            guard generation == resourceLoadGeneration, scope == currentDataScope else { return }
            if state.status == "uninitialized", taskAPIAvailable == true {
                state = try await call("/api/me/main-conversation/ensure", method: "POST", key: UUID().uuidString)
                guard generation == resourceLoadGeneration, scope == currentDataScope else { return }
            }
            guard state.isValid else {
                throw URLError(.cannotParseResponse)
            }
            mainConversation = state
            mainConversationLoadError = nil
        } catch {
            guard generation == resourceLoadGeneration, scope == currentDataScope else { return }
            mainConversation = nil
            mainConversationLoadError = error.localizedDescription
        }
    }

    private func refreshMainConversation(scope: MordeClientDataScope) async throws -> MordeMainConversation {
        let state: MordeMainConversation = try await call("/api/me/main-conversation")
        guard scope == currentDataScope else { throw CancellationError() }
        guard state.isValid else { throw URLError(.cannotParseResponse) }
        mainConversation = state
        mainConversationLoadError = nil
        return state
    }

    func setMainConversation(_ id: String) async -> Bool {
        guard let scope = currentDataScope else {
            error = "登录状态尚未确认，请稍后重试。"
            return false
        }
        do {
            let current = try await refreshMainConversation(scope: scope)
            let updated: MordeMainConversation = try await call(
                "/api/me/main-conversation", method: "PUT",
                body: ["conversation_id": id, "expected_version": current.version], key: UUID().uuidString)
            guard updated.status == "ready", updated.conversation_id == id,
                  scope == currentDataScope else { throw CancellationError() }
            mainConversation = updated
            followsMainConversation = true
            if !conversations.contains(where: { $0.id == id }) {
                let item: MordeConversation = try await call("/api/conversations/\(id)")
                guard scope == currentDataScope else { return false }
                conversations.insert(item, at: 0)
            }
            await showConversation(id, followsMain: true)
            error = nil
            return true
        } catch {
            guard scope == currentDataScope else { return false }
            let conflict = (error as NSError).code == 409
            do { _ = try await refreshMainConversation(scope: scope) } catch { mainConversationLoadError = error.localizedDescription }
            self.error = conflict
                ? "主会话已在其他客户端变更。已刷新服务器状态，请重新选择。"
                : error.localizedDescription
            return false
        }
    }

    func createConversation() async -> Bool {
        guard taskAPIAvailable == true else {
            error = "当前服务未确认开放 Task API，暂时不能创建对话。"
            return false
        }
        guard let scope = currentDataScope else {
            error = "登录状态尚未确认，请稍后重试。"
            return false
        }
        let fingerprint = MordeTaskAttempt.fingerprint(conversationID: nil, hostID: "", modelID: "", objective: "create-conversation")
        let key = "morde.pendingConversationCreate.\(scope.storageKey)"
        let attempt = (UserDefaults.standard.data(forKey: key)
            .flatMap { try? JSONDecoder().decode(MordeRetryAttempt.self, from: $0) })
            .flatMap { $0.matches(scope: scope, fingerprint: fingerprint) ? $0 : nil }
            ?? MordeRetryAttempt(scope: scope, fingerprint: fingerprint, key: UUID().uuidString)
        if let data = try? JSONEncoder().encode(attempt) { UserDefaults.standard.set(data, forKey: key) }
        do {
            let item: MordeConversation = try await call("/api/conversations", method: "POST",
                                                         body: ["title": "新对话"], key: attempt.key)
            guard scope == currentDataScope else { return false }
            if (UserDefaults.standard.data(forKey: key)
                .flatMap { try? JSONDecoder().decode(MordeRetryAttempt.self, from: $0) })?.key == attempt.key {
                UserDefaults.standard.removeObject(forKey: key)
            }
            conversations.removeAll { $0.id == item.id }
            conversations.insert(item, at: 0)
            await showConversation(item.id, followsMain: false)
            error = nil
            return true
        } catch {
            guard scope == currentDataScope else { return false }
            self.error = error.localizedDescription
            return false
        }
    }

    func retryConversations() async {
        guard signedIn, taskAPIAvailable == true, let scope = currentDataScope else { return }
        let generation = resourceLoadGeneration
        await loadResource(.conversations, generation: generation, fetch: {
            try await self.call("/api/conversations?limit=100")
        }, apply: { (page: MordePage<MordeConversation>) in
            self.conversations = page.items
            self.conversationNextCursor = page.next_cursor
        }, clear: {
            self.conversations = []
            self.conversationNextCursor = nil
        })
        guard scope == currentDataScope, generation == resourceLoadGeneration else { return }
    }

    func loadMoreConversations() async {
        guard taskAPIAvailable == true, let cursor = conversationNextCursor,
              !cursor.isEmpty, !loadingMoreConversations, let scope = currentDataScope else { return }
        var components = URLComponents()
        components.path = "/api/conversations"
        components.queryItems = [URLQueryItem(name: "limit", value: "100"),
                                 URLQueryItem(name: "cursor", value: cursor)]
        guard let path = components.string else { return }
        let generation = UUID()
        conversationLoadMoreGeneration = generation
        loadingMoreConversations = true
        defer {
            if conversationLoadMoreGeneration == generation { loadingMoreConversations = false }
        }
        do {
            let page: MordePage<MordeConversation> = try await call(path)
            guard scope == currentDataScope, conversationLoadMoreGeneration == generation else { return }
            var existing = Set(conversations.map(\.id))
            conversations += page.items.filter { existing.insert($0.id).inserted }
            conversationNextCursor = page.next_cursor
        } catch {
            guard scope == currentDataScope, conversationLoadMoreGeneration == generation else { return }
            self.error = error.localizedDescription
        }
    }

    func chooseConversation(_ id: String) async {
        await showConversation(id, followsMain: false)
    }

    func followMainConversation() async {
        guard let scope = currentDataScope else { return }
        do {
            let main = try await refreshMainConversation(scope: scope)
            guard scope == currentDataScope else { return }
            guard main.status == "ready" else {
                currentConversation = nil
                currentTask = nil
                messages = []
                messageNextCursor = nil
                loadingEarlierMessages = false
                messageHistoryError = nil
                followsMainConversation = false
                return
            }
            await showConversation(main.conversation_id, followsMain: true)
        } catch {
            guard scope == currentDataScope else { return }
            self.error = error.localizedDescription
        }
    }

    private func showConversation(_ id: String, followsMain: Bool) async {
        guard let scope = currentDataScope else { return }
        let generation = UUID()
        conversationLoadGeneration = generation
        messageLoadMoreGeneration = UUID()
        loadingEarlierMessages = false
        messageNextCursor = nil
        messageHistoryError = nil
        self.followsMainConversation = followsMain
        currentConversation = id
        saveRecentConversation(id)
        messages = []
        if !MordeConversationTaskState.belongs(taskConversationID: currentTask?.conversation_id,
                                               toSelectedConversationID: id) {
            currentTask = nil
        }
        setResourceState(.loading, for: .messages)
        setResourceState(.loading, for: .taskDetail)
        var loadingResource: MordeResource = .messages
        do {
            guard let path = conversationMessagesPath(id: id) else { throw URLError(.badURL) }
            let page: MordePage<MordeClientMessage> = try await call(path)
            guard scope == currentDataScope, generation == conversationLoadGeneration,
                  currentConversation == id else { return }
            messages = page.items
            messageNextCursor = page.next_cursor
            setResourceState(.loaded, for: .messages)
            if let cachedTask = currentTask,
               MordeConversationTaskState.belongs(taskConversationID: cachedTask.conversation_id, toSelectedConversationID: id) {
                messages = messagesIncludingAssistantSnapshot(cachedTask, in: messages)
            }
            let taskListState = resourceState(.tasks)
            guard taskListState.isLoaded else {
                if let failureMessage = taskListState.failureMessage {
                    setResourceState(.failed(failureMessage), for: .taskDetail)
                } else {
                    setResourceState(.loading, for: .taskDetail)
                }
                return
            }
            if let latest = tasks.filter({ $0.conversation_id == id }).max(by: { $0.updated_at < $1.updated_at }) {
                loadingResource = .taskDetail
                let task: MordeTask = try await call("/api/tasks/\(latest.id)")
                guard scope == currentDataScope, generation == conversationLoadGeneration,
                      currentConversation == id else { return }
                guard MordeConversationTaskState.belongs(
                    taskConversationID: task.conversation_id, toSelectedConversationID: id) else {
                    throw URLError(.cannotParseResponse)
                }
                currentTask = task
                messages = messagesIncludingAssistantSnapshot(task, in: messages)
                setResourceState(.loaded, for: .taskDetail)
            } else {
                currentTask = nil
                setResourceState(.loaded, for: .taskDetail)
            }
        } catch {
            if scope == currentDataScope, generation == conversationLoadGeneration, currentConversation == id {
                setResourceState(.failed(error.localizedDescription), for: loadingResource)
                if loadingResource != .messages { self.error = error.localizedDescription }
            }
        }
    }

    private func conversationMessagesPath(id: String, cursor: String? = nil) -> String? {
        guard !id.isEmpty else { return nil }
        var components = URLComponents()
        components.path = "/api/conversations/\(id)/messages"
        var queryItems = [URLQueryItem(name: "limit", value: "100")]
        if let cursor {
            guard !cursor.isEmpty, cursor.utf8.count <= 1024 else { return nil }
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        components.queryItems = queryItems
        return components.string
    }

    func retryCurrentConversationMessages() async {
        guard let id = currentConversation else { return }
        await showConversation(id, followsMain: followsMainConversation)
    }

    func loadEarlierMessages() async {
        guard let scope = currentDataScope,
              let id = currentConversation,
              let cursor = messageNextCursor,
              let path = conversationMessagesPath(id: id, cursor: cursor),
              !loadingEarlierMessages else { return }
        let conversationGeneration = conversationLoadGeneration
        let generation = UUID()
        messageLoadMoreGeneration = generation
        loadingEarlierMessages = true
        messageHistoryError = nil
        defer {
            if messageLoadMoreGeneration == generation { loadingEarlierMessages = false }
        }
        do {
            let page: MordePage<MordeClientMessage> = try await call(path)
            guard scope == currentDataScope, conversationGeneration == conversationLoadGeneration,
                  generation == messageLoadMoreGeneration, currentConversation == id else { return }
            guard page.items.allSatisfy({ $0.conversation_id == id }), page.next_cursor != cursor else {
                throw URLError(.cannotParseResponse)
            }
            var existingIDs = Set(messages.map(\.id))
            let olderMessages = page.items.filter { existingIDs.insert($0.id).inserted }
            messages = olderMessages + messages
            messageNextCursor = page.next_cursor
        } catch {
            guard scope == currentDataScope, conversationGeneration == conversationLoadGeneration,
                  generation == messageLoadMoreGeneration, currentConversation == id else { return }
            messageHistoryError = error.localizedDescription
        }
    }

    func startNewConversation() async { _ = await createConversation() }

    private func hostIsReady(_ host: MordeHost) -> Bool {
        MordeTaskTargetPolicy.hostIsReady(state: host.state, controlState: host.control_state)
    }
    private func workspaceIsReady(_ binding: MordeWorkspaceBinding) -> Bool {
        MordeTaskTargetPolicy.workspaceIsReady(
            bindingState: binding.state, workspaceState: binding.workspace.state, syncState: binding.sync_state,
            appliedRevision: binding.applied_revision, desiredRevision: binding.desired_revision,
            workspaceRevision: binding.workspace.revision)
    }
    func targetIsUnavailable(hostID: String, workspaceID: String) -> Bool {
        let selectedHost = hosts.first(where: { $0.id == hostID })
        let bindings = selectedHost?.workspaces ?? []
        let selectedBinding = bindings.first(where: { $0.workspace.id == workspaceID })
        return MordeTaskTargetPolicy.targetIsUnavailable(
            hostID: hostID, workspaceID: workspaceID, workspaceBindingCount: bindings.count,
            hostExists: selectedHost != nil && resourceState(.hosts).isLoaded,
            hostReady: selectedHost.map(hostIsReady) ?? false,
            workspaceExists: selectedBinding != nil && resourceState(.workspaces).isLoaded,
            workspaceReady: selectedBinding.map(workspaceIsReady) == true && resourceState(.workspaces).isLoaded)
    }
    func isReady(_ host: MordeHost) -> Bool { hostIsReady(host) }
    func workspaceBindings(for hostID: String) -> [MordeWorkspaceBinding] {
        hosts.first(where: { $0.id == hostID })?.workspaces ?? []
    }
    func isReady(_ binding: MordeWorkspaceBinding) -> Bool { workspaceIsReady(binding) }
    func canOpenHost(_ host: MordeHost) -> Bool {
        host.state == "running" && host.workspaces?.count == 1 && host.workspaces?.first.map(workspaceIsReady) == true
    }
    func canRestoreHost(_ host: MordeHost) -> Bool {
        MordeTaskTargetPolicy.canRestoreHost(
            state: host.state, isOwner: host.owner_id == user?.id,
            workspaceBindingCount: host.workspaces?.count ?? 0,
            workspaceReady: host.workspaces?.first.map(workspaceIsReady) == true)
    }
    private func ownedHost(_ hostID: String) -> MordeHost? {
        guard let userID = user?.id else { return nil }
        return hosts.first { $0.id == hostID && $0.owner_id == userID }
    }

    func restoreHost(_ hostID: String) async {
        guard hostRestoreInFlightID == nil, let scope = currentDataScope,
              let host = ownedHost(hostID), canRestoreHost(host) else { return }
        hostRestoreInFlightID = hostID
        defer { hostRestoreInFlightID = nil }
        do {
            let restored: MordeHost = try await call("/api/hosts/\(hostID)/restore", method: "POST")
            guard scope == currentDataScope, restored.id == hostID, restored.owner_id == user?.id else {
                throw URLError(.cannotParseResponse)
            }
            await load()
        } catch {
            guard scope == currentDataScope else { return }
            self.error = error.localizedDescription
        }
    }
    private func validControlStatus(_ status: MordeHostControlStatus, hostID: String) -> Bool {
        guard status.host_id == hostID, status.control_version >= 0,
              ["ai", "taking_over", "user", "returning"].contains(status.control_state),
              status.control_actor_user_id.map({ $0.isEmpty || $0.range(of: "^u[a-z0-9]{7}$", options: .regularExpression) != nil }) ?? true else { return false }
        if status.control_lease_active == true {
            guard status.control_state == "user", let actorID = status.control_actor_user_id, !actorID.isEmpty,
                  let expiry = status.control_lease_expires_at, Self.parseISO8601(expiry) != nil else { return false }
        }
        return true
    }
    func refreshHostControls() async {
        guard currentDataScope != nil, let userID = user?.id else { return }
        for host in hosts where host.owner_id == userID { await loadHostControl(host.id) }
    }
    func loadHostControl(_ hostID: String, clearError: Bool = true) async {
        guard hostID.range(of: "^h[a-z0-9]{7}$", options: .regularExpression) != nil,
              ownedHost(hostID) != nil, let requestScope = currentDataScope else { return }
        let generation = UUID()
        hostControlLoadGenerations[hostID] = generation
        hostControlStatuses.removeValue(forKey: hostID)
        do {
            let status: MordeHostControlStatus = try await call("/api/hosts/\(hostID)/control")
            guard hostControlLoadGenerations[hostID] == generation, requestScope == currentDataScope else { return }
            guard validControlStatus(status, hostID: hostID) else {
                if clearError { hostControlErrors[hostID] = "控制状态响应无法验证。" }
                return
            }
            hostControlStatuses[hostID] = status
            if clearError { hostControlErrors.removeValue(forKey: hostID) }
        } catch {
            guard hostControlLoadGenerations[hostID] == generation, requestScope == currentDataScope else { return }
            if clearError { hostControlErrors[hostID] = error.localizedDescription }
        }
    }
    func takeOverHostControl(_ hostID: String) async {
        await performHostControlAction(hostID, action: "take_over")
    }
    func releaseHostControl(_ hostID: String) async {
        await performHostControlAction(hostID, action: "release")
    }
    private func performHostControlAction(_ hostID: String, action: String) async {
        guard hostControlActionInFlightFor == nil,
              let host = ownedHost(hostID), host.state == "running",
              let status = hostControlStatuses[hostID], let currentUserID = user?.id,
              (action == "take_over"
                ? MordeHostControlPolicy.canTakeOver(state: status.control_state,
                    actorID: status.control_actor_user_id, leaseActive: status.control_lease_active,
                    transitioning: status.active_transition != nil)
                : MordeHostControlPolicy.canRelease(state: status.control_state,
                    actorID: status.control_actor_user_id, currentUserID: currentUserID,
                    leaseActive: status.control_lease_active, transitioning: status.active_transition != nil)),
              let requestScope = currentDataScope else { return }
        let generation = UUID()
        hostControlActionGeneration = generation
        hostControlActionInFlightFor = hostID
        hostControlLoadGenerations[hostID] = UUID()
        hostControlErrors.removeValue(forKey: hostID)
        defer { if hostControlActionGeneration == generation { hostControlActionInFlightFor = nil } }
        do {
            let result: MordeHostControlStatus = try await call("/api/hosts/\(hostID)/control/actions", method: "POST",
                body: ["action": action, "request_id": UUID().uuidString.lowercased(),
                       "expected_control_version": status.control_version])
            guard hostControlActionGeneration == generation, requestScope == currentDataScope,
                  validControlStatus(result, hostID: hostID), result.control_lease_active != nil,
                  result.control_actor_user_id != nil else { throw URLError(.cannotParseResponse) }
            hostControlStatuses[hostID] = result
            hostControlErrors.removeValue(forKey: hostID)
            if result.pending_operation_ids?.isEmpty == false {
                hostControlErrors[hostID] = "控制交接正在等待运行中的操作结束。"
            }
        } catch {
            guard hostControlActionGeneration == generation, requestScope == currentDataScope else { return }
            hostControlErrors[hostID] = error.localizedDescription
            await loadHostControl(hostID, clearError: false)
            hostControlErrors[hostID] = error.localizedDescription
        }
    }
    func renewHostControlLease(_ hostID: String) async {
        guard hostControlActionInFlightFor == nil,
              let host = ownedHost(hostID), host.state == "running",
              let status = hostControlStatuses[hostID], let currentUserID = user?.id,
              MordeHostControlPolicy.canRenew(state: status.control_state, actorID: status.control_actor_user_id,
                  currentUserID: currentUserID, leaseActive: status.control_lease_active,
                  transitioning: status.active_transition != nil),
              let requestScope = currentDataScope else { return }
        let generation = UUID()
        hostControlActionGeneration = generation
        hostControlActionInFlightFor = hostID
        hostControlLoadGenerations[hostID] = UUID()
        hostControlErrors.removeValue(forKey: hostID)
        defer { if hostControlActionGeneration == generation { hostControlActionInFlightFor = nil } }
        do {
            let result: MordeHostControlStatus = try await call("/api/hosts/\(hostID)/control/lease/renew", method: "POST",
                body: ["expected_control_version": status.control_version])
            guard hostControlActionGeneration == generation, requestScope == currentDataScope,
                  validControlStatus(result, hostID: hostID), result.control_lease_active != nil,
                  result.control_actor_user_id != nil else { throw URLError(.cannotParseResponse) }
            hostControlStatuses[hostID] = result
        } catch {
            guard hostControlActionGeneration == generation, requestScope == currentDataScope else { return }
            hostControlErrors[hostID] = error.localizedDescription
            await loadHostControl(hostID, clearError: false)
            hostControlErrors[hostID] = error.localizedDescription
        }
    }
    func taskTargetDescription(_ task: MordeTask) -> String {
        let host = task.host_id.flatMap { id in hosts.first(where: { $0.id == id }) }
        let binding = task.workspace_id.flatMap { id in
            host?.workspaces?.first(where: { $0.workspace.id == id })
        }
        return MordeTaskTargetPresentation.fixedTarget(
            executionLocation: task.execution_location, hostID: task.host_id,
            hostName: host?.name, hostState: host?.state,
            workspaceID: task.workspace_id, workspaceName: binding?.workspace.name,
            inputRevision: task.input_revision)
    }

    func isRecentConversation(_ id: String) -> Bool {
        recentConversation?.scope == currentDataScope && recentConversation?.conversationID == id
    }

    func send(_ objective: String, host: String, workspace: String, model: String,
              attachmentIDs: [String] = [], queueingTask: MordeTask? = nil) async -> Bool {
        guard !objective.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        let normalizedAttachmentIDs = attachmentIDs.sorted()
        guard normalizedAttachmentIDs.count <= 16,
              Set(normalizedAttachmentIDs).count == normalizedAttachmentIDs.count,
              normalizedAttachmentIDs.allSatisfy(MordePersonalDataContract.isValidAttachmentID) else {
            error = "聊天附件列表无效，请移除附件后重试。"
            return false
        }
        if queueingTask != nil && !normalizedAttachmentIDs.isEmpty {
            error = "当前任务运行期间只能排入文字消息；附件请在任务结束后发送。"
            return false
        }
        guard taskAPIAvailable == true else {
            error = "当前 Morde 服务未确认开放任务 API，请刷新服务状态后重试。"
            return false
        }
        guard let conversationID = currentConversation else {
            error = "尚未选择对话。请先从列表选择一条对话，或创建“新对话”后再发送。"
            return false
        }
        guard defaultModelConfigured else {
            error = "管理员尚未配置可用的默认模型，暂不能发送云端任务。"
            return false
        }
        let allowedModelIDs = Set(models.map(\.id))
        guard MordeTaskModelSelection.canSubmit(modelID: model, resourceState: resourceState(.models),
                                                allowedModelIDs: allowedModelIDs) else {
            error = "模型列表未成功读取，或所选模型已不可用。请刷新列表并重新选择。"
            return false
        }
        guard !targetIsUnavailable(hostID: host, workspaceID: workspace) else {
            error = "所选电脑或 Workspace 当前不可用，请刷新后重新选择。"
            return false
        }
        let workspaceBinding: MordeWorkspaceBinding?
        if !workspace.isEmpty {
            guard let binding = workspaceBindings(for: host).first(where: { $0.workspace.id == workspace }),
                  workspaceIsReady(binding) else {
                error = "所选 Workspace 尚未就绪，请刷新后重新选择。"
                return false
            }
            workspaceBinding = binding
        } else {
            workspaceBinding = nil
        }
        guard let sendScope = currentDataScope else { return false }
        if let queueingTask {
            guard queueingTask.conversation_id == conversationID,
                  ["queued", "running"].contains(queueingTask.status),
                  queueingTask.model_id == model,
                  queueingTask.host_id == (host.isEmpty ? nil : host),
                  queueingTask.workspace_id == (workspace.isEmpty ? nil : workspace),
                  workspace.isEmpty || queueingTask.input_revision != nil else {
                error = "当前任务的模型或执行目标已变化，无法加入队列；请确认任务后重试。"
                return false
            }
        }
        let previousAttempt = pendingSendAttempt(for: sendScope)
        let expectedTaskID = queueingTask?.id ?? previousAttempt?.expectedTaskID
        let fingerprint = MordeTaskAttempt.fingerprint(conversationID: currentConversation, hostID: host,
                                                       workspaceID: workspace, modelID: model, objective: objective,
                                                       attachmentIDs: normalizedAttachmentIDs,
                                                       expectedTaskID: expectedTaskID)
        var attempt = previousAttempt
        // shortcut: one unresolved send per account scope until the service supports key reconciliation.
        guard MordeTaskAttempt.canContinuePendingAttempt(attempt?.fingerprint, requestedFingerprint: fingerprint) else {
            error = "上一条消息的处理结果尚未确认。恢复原内容和目标并重试，确认后再发送新消息。"
            return false
        }
        if attempt == nil {
            attempt = MordeRetryAttempt(scope: sendScope, fingerprint: fingerprint, key: UUID().uuidString,
                                        inputRevision: queueingTask?.input_revision ?? workspaceBinding?.workspace.revision,
                                        expectedTaskID: expectedTaskID)
            storePendingSendAttempt(attempt, for: sendScope)
        }
        busy = true; defer { busy = false }
        do {
            struct Appended: Decodable { let message: MordeClientMessage; let task: MordeTask }
            let task: MordeTask
            var target: [String: Any] = [:]
            if !host.isEmpty { target["host_id"] = host }
            if let workspaceBinding {
                target["workspace_id"] = workspace
                // A retry must keep the revision that was hashed into its original idempotency request.
                target["input_revision"] = attempt?.inputRevision ?? workspaceBinding.workspace.revision
            }
            if let expectedTaskID { target["expected_task_id"] = expectedTaskID }
            var messageBody: [String: Any] = ["model_id": model, "content": objective]
            if !normalizedAttachmentIDs.isEmpty { messageBody["attachment_ids"] = normalizedAttachmentIDs }
            let response: Appended = try await call("/api/conversations/\(conversationID)/messages", method: "POST",
                                                     body: target.merging(messageBody) { _, new in new },
                                                     key: attempt?.key)
            task = response.task
            guard task.conversation_id == conversationID,
                  expectedTaskID == nil || task.id == expectedTaskID,
                  response.message.conversation_id == conversationID,
                  response.message.task_id == task.id else { throw URLError(.cannotParseResponse) }
            if let key = attempt?.key { clearPendingSend(for: sendScope, matching: key) }
            currentConversation = task.conversation_id; currentTask = task
            setResourceState(.loaded, for: .taskDetail)
            await load()
            guard currentDataScope == sendScope,
                  MordeConversationTaskState.belongs(taskConversationID: task.conversation_id,
                                                     toSelectedConversationID: currentConversation) else { return true }
            let displayedTask = currentTask.flatMap { $0.id == task.id ? $0 : nil } ?? task
            currentTask = displayedTask
            setResourceState(.loaded, for: .taskDetail)
            messages = messagesIncludingAssistantSnapshot(displayedTask, in: messages)
            if let index = messages.firstIndex(where: { $0.id == response.message.id }) {
                let existing = messages[index]
                if existing.delivery_status == nil, let deliveryStatus = response.message.delivery_status {
                    messages[index] = MordeClientMessage(
                        id: existing.id, conversation_id: existing.conversation_id, task_id: existing.task_id,
                        role: existing.role, content: existing.content, attachment_ids: existing.attachment_ids,
                        status: existing.status,
                        delivery_status: deliveryStatus, created_at: existing.created_at)
                }
            } else {
                messages.append(response.message)
            }
            return true
        } catch { self.error = error.localizedDescription; return false }
    }

    // nanoMuse: preserve the caller's idempotency key after a lost action response.
    private var retryAction: MordeActionRetryAttempt?
    private var retryActionScopeKey: String?
    @discardableResult func act(_ body: [String: Any]) async -> Bool {
        guard let task = currentTask, let path = MordeTaskResponsePolicy.actionPath(taskID: task.id) else { return false }
        return await submitTaskAction(taskID: task.id, path: path, body: body)
    }

    @discardableResult func respondToApproval(taskID: String, approvalID: String, version: Int,
                                              decision: String) async -> Bool {
        guard taskID == currentTask?.id,
              let path = MordeTaskResponsePolicy.approvalPath(taskID: taskID, approvalID: approvalID), version > 0,
              ["approve", "reject"].contains(decision) else {
            error = "审批请求已失效，请刷新 Task 后重试。"
            return false
        }
        return await submitTaskAction(taskID: taskID, path: path,
                                      body: ["version": version, "decision": decision])
    }

    @discardableResult func answerClarification(taskID: String, clarificationID: String, version: Int,
                                                answer: String) async -> Bool {
        let text = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard taskID == currentTask?.id,
              let path = MordeTaskResponsePolicy.inputPath(taskID: taskID),
              MordeTaskResponsePolicy.hasValidRequestID(clarificationID), version > 0,
              MordeTaskResponsePolicy.hasValidAnswer(text) else {
            error = "请检查补充信息内容，并刷新 Task 状态后重试。"
            return false
        }
        return await submitTaskAction(taskID: taskID, path: path,
                                      body: ["clarification_id": clarificationID,
                                             "clarification_version": version, "answer": text])
    }

    private func reportTaskPageActionError(_ message: String, taskID: String, updateCurrentTask: Bool) {
        if updateCurrentTask { error = message }
        else { taskPageActionErrors[taskID] = message }
    }

    @discardableResult private func submitTaskAction(taskID: String, path: String,
                                                      body: [String: Any],
                                                      updateCurrentTask: Bool = true) async -> Bool {
        let selectedConversationID = updateCurrentTask ? currentConversation : nil
        func selectedTaskIsCurrent() -> Bool {
            guard updateCurrentTask, let selectedConversationID else { return false }
            return currentConversation == selectedConversationID && currentTask?.id == taskID
        }
        func report(_ message: String) {
            reportTaskPageActionError(message, taskID: taskID,
                                      updateCurrentTask: selectedTaskIsCurrent())
        }
        let isLoadedTarget = updateCurrentTask ? currentTask?.id == taskID : taskPageDetails[taskID] != nil
        guard canStartMordeAction(busy: busy), isLoadedTarget,
              let actionScope = currentDataScope,
              MordeTaskResponsePolicy.hasValidTaskID(taskID), path.hasPrefix("/api/tasks/\(taskID)/") else { return false }
        if retryActionScopeKey != actionScope.storageKey {
            retryAction = nil
            retryActionScopeKey = nil
        }
        guard let fingerprint = MordeActionRetryAttempt.fingerprint(taskID: taskID, endpoint: path, body: body) else {
            report("操作请求无法编码，请检查内容后重试。")
            return false
        }
        guard MordeTaskAttempt.canContinuePendingAttempt(retryAction?.fingerprint,
                                                          requestedFingerprint: fingerprint) else {
            report("上一条任务操作结果尚未确认。请先重试原操作或刷新任务状态。")
            return false
        }
        retryAction = MordeActionRetryAttempt.reusing(retryAction, for: fingerprint)
        retryActionScopeKey = actionScope.storageKey
        busy = true; defer { busy = false }
        do {
            struct Response: Decodable { let task_id: String }
            let response: Response = try await call(path, method: "POST", body: body,
                                                    key: retryAction?.idempotencyKey)
            guard actionScope == currentDataScope else { return false }
            guard response.task_id == taskID else { throw URLError(.cannotParseResponse) }
            do {
                let refreshed = try await task(id: taskID)
                guard actionScope == currentDataScope else { return false }
                if selectedTaskIsCurrent() {
                    currentTask = refreshed
                    setResourceState(.loaded, for: .taskDetail)
                    applyCurrentTaskAssistantSnapshot(refreshed)
                }
                retryAction = nil
                retryActionScopeKey = nil
                if selectedTaskIsCurrent() { error = nil }
                else { taskPageActionErrors.removeValue(forKey: taskID) }
            } catch {
                guard actionScope == currentDataScope else { return false }
                if selectedTaskIsCurrent() { setResourceState(.failed(error.localizedDescription), for: .taskDetail) }
                report("操作已提交，但任务状态刷新失败，请稍后重新打开任务确认。")
            }
            return true
        } catch {
            guard actionScope == currentDataScope else { return false }
            if (error as NSError).code == 409 {
                retryAction = nil
                retryActionScopeKey = nil
                do {
                    let refreshed = try await task(id: taskID)
                    guard actionScope == currentDataScope else { return false }
                    if selectedTaskIsCurrent() {
                        currentTask = refreshed
                        setResourceState(.loaded, for: .taskDetail)
                        applyCurrentTaskAssistantSnapshot(refreshed)
                    }
                    report("任务状态已变化，已刷新最新状态。请核对后再操作。")
                } catch {
                    guard actionScope == currentDataScope else { return false }
                    if selectedTaskIsCurrent() { setResourceState(.failed(error.localizedDescription), for: .taskDetail) }
                    report("任务状态已变化，但刷新最新状态失败。请检查网络后再操作。")
                }
            } else {
                let failure = error as NSError
                if failure.domain == "Morde", (400..<500).contains(failure.code),
                   failure.code != 408, failure.code != 429 {
                    retryAction = nil
                    retryActionScopeKey = nil
                    report(error.localizedDescription)
                } else if body["action"] as? String == "cancel" {
                    do {
                        let refreshed = try await task(id: taskID)
                        guard actionScope == currentDataScope else { return false }
                        if selectedTaskIsCurrent() {
                            currentTask = refreshed
                            setResourceState(.loaded, for: .taskDetail)
                            applyCurrentTaskAssistantSnapshot(refreshed)
                        }
                        report("取消请求结果未知，已刷新任务状态；请以服务端当前状态为准。")
                    } catch {
                        guard actionScope == currentDataScope else { return false }
                        if selectedTaskIsCurrent() { setResourceState(.failed(error.localizedDescription), for: .taskDetail) }
                        report("取消请求结果未知，且任务状态刷新失败；请稍后重试读取状态。")
                    }
                } else {
                    report("任务操作结果未知；请重试相同操作或刷新 Task 状态确认。")
                }
            }
            return false
        }
    }

    func watchCurrentTask() async {
        guard let id = currentTask?.id, currentConversation == currentTask?.conversation_id else { return }
        await watchTaskEvents(taskID: id, updatesCurrentConversation: true)
    }

    func watchTaskTimeline(taskID: String) async {
        guard MordeTaskResponsePolicy.hasValidTaskID(taskID), taskID != currentTask?.id else { return }
        await watchTaskEvents(taskID: taskID, updatesCurrentConversation: false)
    }

    private func appendTaskTimelineEvent(_ event: MordeTaskTimelineEvent) {
        guard event.display != nil else { return }
        var events = taskTimelineEvents[event.task_id] ?? []
        guard !events.contains(where: { $0.sequence == event.sequence }) else { return }
        events.append(event)
        events.sort { $0.sequence < $1.sequence }
        taskTimelineEvents[event.task_id] = events
        taskTimelineNoHistory.remove(event.task_id)
        taskTimelineErrors.removeValue(forKey: event.task_id)
    }

    private func watchTaskEvents(taskID: String, updatesCurrentConversation: Bool) async {
        guard let taskScope = currentDataScope else { return }
        let selectedConversationID = updatesCurrentConversation ? currentConversation : nil
        let initialSequence = updatesCurrentConversation ? currentTask?.event_sequence ?? 0 : 0
        func selectedTaskIsCurrent() -> Bool {
            guard updatesCurrentConversation, let selectedConversationID else { return !updatesCurrentConversation }
            return currentConversation == selectedConversationID && currentTask?.id == taskID
        }
        var cursor = ""
        taskTimelineLoading.insert(taskID)
        taskTimelineErrors.removeValue(forKey: taskID)
        while !Task.isCancelled && taskScope == currentDataScope &&
                selectedTaskIsCurrent() {
            guard let credential = token, let requestInstallation = installation,
                  let requestScope = authorizationScope(for: requestInstallation) else {
                taskTimelineLoading.remove(taskID)
                return
            }
            do {
                guard var components = URLComponents(string: "\(requestScope.serviceOrigin)/api/tasks/\(taskID)/events") else { return }
                if !cursor.isEmpty { components.queryItems = [URLQueryItem(name: "after", value: cursor)] }
                guard let url = components.url else { return }
                var request = URLRequest(url: url)
                request.setValue("Bearer \(credential)", forHTTPHeaderField: "Authorization")
                request.cachePolicy = .reloadIgnoringLocalCacheData
                let (bytes, response) = try await urlSession.bytes(for: request)
                guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
                guard !Task.isCancelled, taskScope == currentDataScope else { return }
                if http.statusCode == 401 {
                    if MordeUnauthorizedResponsePolicy.shouldClearAuthorization(
                        requestCredential: credential, currentCredential: token, requestScope: requestScope,
                        currentScope: installation.flatMap { authorizationScope(for: $0) },
                        hasPendingLoginIntent: loginStateStore.hasPendingIntent(
                            origin: requestScope.serviceOrigin, accountName: requestInstallation.accountName),
                        isCancelled: Task.isCancelled) {
                        signOutLocally(installation: requestInstallation)
                    }
                    taskTimelineLoading.remove(taskID)
                    return
                }
                if http.statusCode == 403 || http.statusCode == 404 {
                    let message = AppLocalized("Current account can no longer read this task")
                    taskPageDetails.removeValue(forKey: taskID)
                    taskPageActionErrors.removeValue(forKey: taskID)
                    taskTimelineEvents.removeValue(forKey: taskID)
                    taskTimelineHistoryExpired.remove(taskID)
                    taskTimelineNoHistory.remove(taskID)
                    taskTimelineErrors[taskID] = message
                    taskTimelineLoading.remove(taskID)
                    if selectedTaskIsCurrent() {
                        setResourceState(.failed(message), for: .taskDetail)
                        self.error = message
                    }
                    return
                }
                if http.statusCode == 204 {
                    if cursor.isEmpty && (taskTimelineEvents[taskID] ?? []).isEmpty {
                        taskTimelineNoHistory.insert(taskID)
                    }
                    taskTimelineLoading.remove(taskID)
                    return
                }
                guard http.statusCode == 200 else { throw URLError(.badServerResponse) }
                taskTimelineErrors.removeValue(forKey: taskID)
                taskTimelineLoading.remove(taskID)
                var event = ""
                var eventID = ""
                var data = ""
                var line = Data()
                // AsyncBytes.lines omits empty lines, so parse raw bytes to keep SSE frame boundaries.
                for try await byte in bytes {
                    if Task.isCancelled || taskScope != currentDataScope { return }
                    guard line.count < 65_536 || byte == 0x0A else { throw URLError(.dataLengthExceedsMaximum) }
                    if byte != 0x0A {
                        line.append(byte)
                        continue
                    }
                    guard let decodedLine = String(data: line, encoding: .utf8) else { throw URLError(.cannotParseResponse) }
                    line.removeAll(keepingCapacity: true)
                    let text = decodedLine.trimmingCharacters(in: .whitespacesAndNewlines)
                    if text.hasPrefix("id:") { eventID = String(text.dropFirst(3)).trimmingCharacters(in: .whitespaces) }
                    else if text.hasPrefix("event:") { event = String(text.dropFirst(6)).trimmingCharacters(in: .whitespaces) }
                    else if text.hasPrefix("data:") {
                        if !data.isEmpty { data += "\n" }
                        data += String(text.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                    } else if text.isEmpty && !event.isEmpty {
                        guard let sequence = Int64(eventID), sequence > 0 else { throw URLError(.cannotParseResponse) }
                        if event == "task.snapshot_required" {
                            struct SnapshotRequired: Decodable { let sequence: Int64 }
                            let required = try JSONDecoder().decode(SnapshotRequired.self, from: Data(data.utf8))
                            guard required.sequence == sequence else { throw URLError(.cannotParseResponse) }
                            let snapshot = try await task(id: taskID)
                            guard let snapshotSequence = snapshot.event_sequence,
                                  let nextCursor = MordeTaskSnapshotCursor.resumeCursor(
                                    eventID: eventID, snapshotSequence: snapshotSequence) else {
                                throw URLError(.cannotParseResponse)
                            }
                            taskTimelineHistoryExpired.insert(taskID)
                            cursor = nextCursor
                            if updatesCurrentConversation {
                                guard selectedTaskIsCurrent(), snapshot.conversation_id == selectedConversationID else { return }
                                guard let path = conversationMessagesPath(id: snapshot.conversation_id) else {
                                    throw URLError(.badURL)
                                }
                                let page: MordePage<MordeClientMessage> = try await call(path)
                                guard selectedTaskIsCurrent(), taskScope == currentDataScope else { return }
                                currentTask = snapshot
                                messages = messagesIncludingAssistantSnapshot(snapshot, in: page.items)
                                messageNextCursor = page.next_cursor
                                messageHistoryError = nil
                                messageLoadMoreGeneration = UUID()
                                loadingEarlierMessages = false
                                setResourceState(.loaded, for: .taskDetail)
                                setResourceState(.loaded, for: .messages)
                            }
                            if ["completed", "failed", "cancelled"].contains(snapshot.status) {
                                taskTimelineLoading.remove(taskID)
                                return
                            }
                            break
                        }
                        let streamed = try JSONDecoder().decode(MordeTaskTimelineEvent.self, from: Data(data.utf8))
                        guard streamed.task_id == taskID, streamed.sequence == sequence,
                              streamed.type == event else { throw URLError(.cannotParseResponse) }
                        appendTaskTimelineEvent(streamed)
                        cursor = eventID
                        if updatesCurrentConversation {
                            guard sequence >= initialSequence else {
                                event = ""; eventID = ""; data = ""
                                continue
                            }
                            let snapshot = try await task(id: taskID)
                            guard let snapshotSequence = snapshot.event_sequence,
                                  snapshot.conversation_id == selectedConversationID,
                                  let nextCursor = MordeTaskSnapshotCursor.resumeCursor(
                                    eventID: eventID, snapshotSequence: snapshotSequence) else {
                                throw URLError(.cannotParseResponse)
                            }
                            guard let path = conversationMessagesPath(id: snapshot.conversation_id) else {
                                throw URLError(.badURL)
                            }
                            let page: MordePage<MordeClientMessage> = try await call(path)
                            guard selectedTaskIsCurrent(), taskScope == currentDataScope else { return }
                            currentTask = snapshot
                            messages = messagesIncludingAssistantSnapshot(snapshot, in: page.items)
                            messageNextCursor = page.next_cursor
                            messageHistoryError = nil
                            messageLoadMoreGeneration = UUID()
                            loadingEarlierMessages = false
                            setResourceState(.loaded, for: .taskDetail)
                            setResourceState(.loaded, for: .messages)
                            cursor = nextCursor
                            if ["completed", "failed", "cancelled"].contains(snapshot.status) {
                                taskTimelineLoading.remove(taskID)
                                return
                            }
                        } else if ["task.status", "task.waiting_user", "task.result"].contains(event) {
                            let snapshot = try await task(id: taskID)
                            if ["completed", "failed", "cancelled"].contains(snapshot.status) {
                                taskTimelineLoading.remove(taskID)
                                return
                            }
                        }
                        event = ""; eventID = ""; data = ""
                    }
                }
            } catch {
                if !Task.isCancelled && taskScope == currentDataScope {
                    taskTimelineErrors[taskID] = error.localizedDescription
                    if selectedTaskIsCurrent() {
                        setResourceState(.failed(error.localizedDescription), for: .taskDetail)
                        self.error = error.localizedDescription
                    }
                    let failure = error as NSError
                    if failure.domain == "Morde", [401, 403, 404].contains(failure.code) {
                        taskTimelineLoading.remove(taskID)
                        return
                    }
                }
            }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
        taskTimelineLoading.remove(taskID)
    }

    func openHost(_ id: String, shared: Bool = false) async {
        guard let scope = currentDataScope else { return }
        do {
            let origin: URL
            if shared {
                guard let host = sharedHosts.first(where: { $0.id == id }),
                      host.state == "running", host.permissions.contains("desktop:view") else {
                    throw NSError(domain: "Morde.Workspace", code: 403,
                                  userInfo: [NSLocalizedDescriptionKey: "当前共享电脑未授予桌面观察权限"])
                }
                origin = host.url
            } else {
                guard let host = ownedHost(id), canOpenHost(host) else {
                    throw NSError(domain: "Morde.Workspace", code: 409,
                                  userInfo: [NSLocalizedDescriptionKey: "电脑必须绑定且只绑定一个已就绪 Workspace 后才能打开"])
                }
                origin = host.url
            }
            guard origin.scheme == "https", origin.host != nil else { throw URLError(.badURL) }
            let suffix = shared ? "observation-ticket" : "enter"
            let ticket: MordeTicket = try await call("/api/hosts/\(id)/\(suffix)", method: "POST")
            guard scope == currentDataScope else { return }
            guard isValidMordeHostTicketURL(ticket.url, for: origin) else { throw URLError(.badURL) }
            hostURL = ticket.url
            hostOpenErrors.removeValue(forKey: id)
        } catch {
            guard scope == currentDataScope else { return }
            hostOpenErrors[id] = error.localizedDescription
        }
    }

    func openNotification(_ notice: MordeNotification) async -> Bool {
        var focusedTask = false
        let scope = currentDataScope
        do {
            let _: MordeEmpty = try await call("/api/notifications/\(notice.id)/read", method: "POST")
            if notice.canOpenTask, let id = notice.task_id {
                let linkedTask: MordeTask = try await call("/api/tasks/\(id)")
                guard linkedTask.id == id else { throw URLError(.cannotParseResponse) }
                await chooseConversation(linkedTask.conversation_id)
                guard MordeConversationTaskState.belongs(
                    taskConversationID: linkedTask.conversation_id,
                    toSelectedConversationID: currentConversation) else { return false }
                currentTask = linkedTask
                applyCurrentTaskAssistantSnapshot(linkedTask)
                focusedTask = true
            }
        } catch { self.error = error.localizedDescription }
        await refreshNotifications(scope: scope)
        return focusedTask
    }

    private func notificationPage(cursor: String?) async throws -> MordePage<MordeNotification> {
        guard cursor.map({ !$0.isEmpty && $0.utf8.count <= 1024 }) ?? true else { throw URLError(.badURL) }
        var components = URLComponents()
        components.path = "/api/notifications"
        components.queryItems = [URLQueryItem(name: "limit", value: "100")]
        if let cursor { components.queryItems?.append(URLQueryItem(name: "cursor", value: cursor)) }
        guard let path = components.string else { throw URLError(.badURL) }
        return try await call(path)
    }

    private func refreshNotifications(scope: MordeClientDataScope?) async {
        guard let scope else { return }
        let generation = resourceLoadGeneration
        do {
            let page = try await notificationPage(cursor: nil)
            guard scope == currentDataScope, generation == resourceLoadGeneration else { return }
            notifications = page.items
            notificationNextCursor = page.next_cursor
            setResourceState(.loaded, for: .notifications)
        } catch {
            guard scope == currentDataScope, generation == resourceLoadGeneration else { return }
            setResourceState(.failed(error.localizedDescription), for: .notifications)
            self.error = error.localizedDescription
        }
    }

    func loadMoreNotifications() async {
        guard !loadingMoreNotifications, let cursor = notificationNextCursor,
              !cursor.isEmpty, let scope = currentDataScope else { return }
        let generation = resourceLoadGeneration
        loadingMoreNotifications = true
        defer { loadingMoreNotifications = false }
        do {
            let page = try await notificationPage(cursor: cursor)
            guard scope == currentDataScope, generation == resourceLoadGeneration else { return }
            guard page.next_cursor != cursor,
                  MordeNotificationPresentationPolicy.canAppendPage(
                    currentIDs: notifications.map(\.id), pageIDs: page.items.map(\.id)) else {
                throw URLError(.cannotParseResponse)
            }
            notifications += page.items
            notificationNextCursor = page.next_cursor
        } catch {
            guard scope == currentDataScope, generation == resourceLoadGeneration else { return }
            self.error = "无法读取更多通知：\(error.localizedDescription)"
        }
    }

    private func signOutLocally(installation target: MordeInstallation? = nil, confirmed: Bool = false) {
        let oldInstallation = target ?? installation
        var localStateFailed = false
        if let oldInstallation {
            let status = confirmed ? "confirmed" : "unconfirmed"
            if let scope = revocationScope(for: oldInstallation) {
                do {
                    try revocationStore.record(MordeRevocationRecord(
                        scope: scope, clientInstanceID: oldInstallation.clientInstanceID, confirmed: confirmed))
                } catch { localStateFailed = true }
            } else {
                localStateFailed = true
            }
            clearAuthorization(for: oldInstallation)
            let lookupKey = installationLookupKey ?? oldInstallation.serviceOrigin.flatMap { origin in
                guard let serviceID = oldInstallation.serviceInstanceID else { return nil }
                return Self.installationLookupKey(origin: origin, serviceInstanceID: serviceID,
                                                  accountName: oldInstallation.accountName)
            }
            if let lookupKey {
                let inactive = MordeInstallation(id: oldInstallation.id, accountName: oldInstallation.accountName,
                                                 serviceOrigin: oldInstallation.serviceOrigin,
                                                 serviceInstanceID: oldInstallation.serviceInstanceID,
                                                 accountID: oldInstallation.accountID,
                                                 clientInstanceID: oldInstallation.clientInstanceID,
                                                 revocationStatus: status)
                do { try saveInstallation(inactive, lookupKey: lookupKey, makeActive: false) }
                catch { localStateFailed = true }
                var active = Self.activeInstallationMap()
                if let origin = oldInstallation.serviceOrigin.flatMap(MordeLoginStateStore.serviceOrigin),
                   active[origin] == lookupKey {
                    active.removeValue(forKey: origin)
                    UserDefaults.standard.set(active, forKey: Self.activeInstallationsKey)
                }
            }
            do {
                if let origin = oldInstallation.serviceOrigin,
                   let serviceID = oldInstallation.serviceInstanceID {
                    try loginStateStore.rotateClientInstanceID(origin: origin, serviceInstanceID: serviceID,
                                                                accountName: oldInstallation.accountName)
                } else {
                    try loginStateStore.invalidatePendingAttempts(origin: oldInstallation.serviceOrigin,
                                                                  accountName: oldInstallation.accountName)
                }
            } catch { localStateFailed = true }
        } else {
            try? loginStateStore.invalidatePendingAttempts(origin: server)
        }
        installationLookupKey = nil
        verifiedServiceInstanceID = nil
        resetViewState()
        if !confirmed || localStateFailed {
            var messages: [String] = []
            if !confirmed { messages.append("本机已退出；服务器安装撤销尚未确认，撤销标识已保留。") }
            if localStateFailed { messages.append("无法完整保存本机撤销状态，请检查设备存储。") }
            error = messages.joined(separator: "\n")
        } else {
            error = nil
        }
    }
}

@MainActor final class MIFTaskPageStore: ObservableObject {
    static let shared = MIFTaskPageStore()
    let objectWillChange = ObservableObjectPublisher()
    private let client = MordeClient.shared
    private var observation: AnyCancellable?

    private init() {
        observation = client.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var isSignedIn: Bool { client.signedIn }
    // nanoMuse: Keep task detail actions on the same in-flight lock as chat actions.
    var actionInFlight: Bool { client.busy }
    var scopeKey: String? { client.taskPageScopeKey }
    var currentTask: MordeTask? { client.currentTask }
    var taskAPIAvailable: Bool? { client.taskAPIAvailable }
    var workspaceSyncAvailable: Bool? { client.workspaceSyncAvailable }
    var taskMediaGenerationAvailable: Bool? { client.taskMediaGenerationAvailable }
    var tasks: [MordeTask] { client.tasks }
    var details: [String: MordeTask] { client.taskPageDetails }
    var timelineEvents: [String: [MordeTaskTimelineEvent]] { client.taskTimelineEvents }
    var timelineErrors: [String: String] { client.taskTimelineErrors }
    var expiredTimelines: Set<String> { client.taskTimelineHistoryExpired }
    var loadingTimelines: Set<String> { client.taskTimelineLoading }
    var emptyTimelines: Set<String> { client.taskTimelineNoHistory }
    var actionErrors: [String: String] { client.taskPageActionErrors }

    func taskPage(status: String? = nil, cursor: String? = nil) async throws -> MordePage<MordeTask> {
        try await client.taskPage(status: status, cursor: cursor)
    }
    func task(id: String) async throws -> MordeTask { try await client.task(id: id) }
    func actOnTask(taskID: String, action: MordeTaskPageAction) async -> Bool {
        await client.actOnTaskPage(taskID: taskID, action: action)
    }
    func respondToApproval(taskID: String, approvalID: String, version: Int, decision: String) async -> Bool {
        await client.respondToTaskPageApproval(taskID: taskID, approvalID: approvalID,
                                               version: version, decision: decision)
    }
    func answerClarification(taskID: String, clarificationID: String, version: Int,
                             answer: String) async -> Bool {
        await client.answerTaskPageClarification(taskID: taskID, clarificationID: clarificationID,
                                                 version: version, answer: answer)
    }
    // nanoMuse: Reuse the guarded media preview and cleanup path on standalone task pages.
    func mediaApprovalControls(task: MordeTask, pending: MordeTask.Pending) -> some View {
        MordeTaskMediaPreviewControls(
            client: client, task: task, pending: pending,
            canRespond: client.signedIn, busy: client.busy,
            isPendingCurrent: {
                guard let current = self.client.taskPageDetails[task.id]?.pending_request else { return false }
                return current.id == pending.id && current.version == pending.version &&
                    current.media_preview_operation_id == pending.media_preview_operation_id
            },
            onDecision: { decision in
                await self.client.respondToTaskPageApproval(taskID: task.id, approvalID: pending.id,
                                                            version: pending.version, decision: decision)
            })
    }
    func watchTimeline(taskID: String) async { await client.watchTaskTimeline(taskID: taskID) }
    func verifiedTaskArtifactFile(workspaceID: String, revision: Int64, path: String,
                                  sizeBytes: Int64, sha256: String, scopeKey: String) async throws -> MordeWorkspaceFile {
        try await client.verifiedTaskArtifactFile(workspaceID: workspaceID, revision: revision, path: path,
                                                  sizeBytes: sizeBytes, sha256: sha256, scopeKey: scopeKey)
    }
    func verifyLocalTaskArtifactFile(workspaceID: String, file: MordeWorkspaceFile,
                                     scopeKey: String) async throws -> URL {
        try await client.verifyLocalTaskArtifactFile(workspaceID: workspaceID, file: file, scopeKey: scopeKey)
    }
}

struct MIFConversationDrawerItem: Identifiable {
    let id: String
    let title: String
    let isMain: Bool
}

@MainActor final class MIFConversationDrawerStore: ObservableObject {
    static let shared = MIFConversationDrawerStore()
    let objectWillChange = ObservableObjectPublisher()
    private let client = MordeClient.shared
    private var observation: AnyCancellable?

    private init() {
        observation = client.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var conversations: [MIFConversationDrawerItem] {
        client.conversations.map {
            MIFConversationDrawerItem(id: $0.id, title: $0.title,
                                     isMain: $0.id == client.mainConversation?.conversation_id)
        }
    }
    var currentID: String? { client.currentConversation }
    var mainID: String? { client.mainConversation?.conversation_id }
    var nextCursor: String? { client.conversationNextCursor }
    var loadingMore: Bool { client.loadingMoreConversations }
    var hasLoaded: Bool { client.resourceState(.conversations).isLoaded }
    var isLoading: Bool {
        if case .loading = client.resourceState(.conversations) { return true }
        return false
    }
    var error: String? { client.resourceState(.conversations).failureMessage }

    func loadMore() async { await client.loadMoreConversations() }
    func retry() async { await client.retryConversations() }
    func choose(_ id: String) async { await client.chooseConversation(id) }
    func create() async { await client.startNewConversation() }
    func followMain() async { await client.followMainConversation() }
}

@MainActor final class MIFResourcePageStore: ObservableObject {
    static let shared = MIFResourcePageStore()
    let objectWillChange = ObservableObjectPublisher()
    private let client = MordeClient.shared
    private var observation: AnyCancellable?

    private init() {
        observation = client.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var scopeKey: String? { client.taskPageScopeKey }
    var hostURL: URL? { client.hostURL }
    func dismissHost() { client.hostURL = nil }

    var state: MIFResourcePageState {
        let ownedHosts = (client.user?.id).map { userID in
            client.hosts.filter { $0.owner_id == userID }
        } ?? []
        let ownedHostViews = ownedHosts.map { host in
            let workspaceNames = host.workspaces?.map { $0.workspace.name }.filter { !$0.isEmpty }.joined(separator: " · ")
            return MIFResourcePageState.Host(
                id: host.id, name: host.name, scope: .owned, status: Self.status(host.state),
                workspaceSummary: workspaceNames?.isEmpty == false ? workspaceNames : nil,
                canOpen: client.canOpenHost(host), control: control(for: host),
                error: client.hostOpenErrors[host.id] ?? client.hostControlErrors[host.id])
        }
        let sharedHosts = client.sharedHosts.map { host in
            MIFResourcePageState.Host(
                id: host.id, name: host.name, scope: .sharedReadOnly, status: Self.status(host.state),
                workspaceSummary: nil, canOpen: host.state == "running" && host.permissions.contains("desktop:view"),
                control: nil, error: client.hostOpenErrors[host.id])
        }
        let workspaces = client.workspaces.map { workspace in
            let binding = client.hosts.compactMap { host in
                host.workspaces?.first(where: { $0.workspace.id == workspace.id }).map { (host, $0) }
            }.first
            let status: MIFResourcePageState.Workspace.Status
            if workspace.state != "ready" {
                status = .unavailable
            } else if let binding {
                if binding.1.sync_state == "syncing" || binding.1.sync_state == "pending" {
                    status = .syncing
                } else {
                    status = client.isReady(binding.1) ? .ready : .unavailable
                }
            } else {
                status = .unbound
            }
            return MIFResourcePageState.Workspace(
                id: workspace.id, name: workspace.name, status: status,
                hostName: binding?.0.name, isReadOnly: false,
                canOpenFiles: workspace.state == "ready" && client.workspaceSyncAvailable == true)
        }
        let hostResourceStates = [client.resourceState(.hosts), client.resourceState(.sharedHosts)]
        let workspaceResourceState = client.resourceState(.workspaces)
        let hostErrors = hostResourceStates.compactMap(\.failureMessage)
        let hostsState = MIFResourcePageState.ListState(
            isLoading: hostResourceStates.contains { state in
                if case .loading = state { return true }
                return false
            },
            loadError: hostErrors.isEmpty ? nil : hostErrors.joined(separator: " · "))
        let workspacesState = MIFResourcePageState.ListState(
            isLoading: workspaceResourceState == .loading,
            loadError: workspaceResourceState.failureMessage)
        let errors = [hostsState.loadError, workspacesState.loadError].compactMap { $0 }
        let loading = hostsState.isLoading || workspacesState.isLoading
        let target: MIFResourcePageState.DefaultTarget
        switch client.defaultHostPreferenceState {
        case .loading, .failed:
            target = .unknown
        case .loaded:
            if let id = client.defaultHostID {
                let host = ownedHosts.first { $0.id == id }
                let workspace = host?.workspaces?.count == 1 ? host?.workspaces?.first?.workspace.name : nil
                target = .configured(hostName: host?.name, workspaceName: workspace)
            } else {
                target = .notConfigured
            }
        }
        return MIFResourcePageState(
            isLoading: loading, loadError: errors.isEmpty ? nil : errors.joined(separator: " · "),
            hostsState: hostsState, workspacesState: workspacesState,
            defaultTarget: target, hosts: ownedHostViews + sharedHosts, workspaces: workspaces)
    }

    private var isResourceListLoading: Bool {
        [client.resourceState(.hosts), client.resourceState(.sharedHosts), client.resourceState(.workspaces)]
            .contains { if case .loading = $0 { return true }; return false }
    }

    func refresh() async {
        while client.isLoadingResources && !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        guard !Task.isCancelled else { return }
        await client.refreshResourceLists()
    }
    func loadIfNeeded() async {
        guard client.signedIn else { return }
        while (client.isLoadingResources || isResourceListLoading) && !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        guard !Task.isCancelled else { return }
        let listsAreLoaded = [client.resourceState(.hosts), client.resourceState(.sharedHosts),
                              client.resourceState(.workspaces)].allSatisfy(\.isLoaded)
        if listsAreLoaded {
            await client.loadDefaultHostPreference()
            await client.refreshHostControls()
        } else {
            await client.refreshResourceLists()
        }
    }
    func refreshControls() async { await client.refreshHostControls() }
    func refreshControl(_ id: String) async { await client.loadHostControl(id) }
    func openHost(_ id: String) async {
        let shared = client.sharedHosts.contains { $0.id == id }
        if shared {
            guard let host = client.sharedHosts.first(where: { $0.id == id }), host.state == "running",
                  host.permissions.contains("desktop:view") else { return }
        } else {
            guard let userID = client.user?.id,
                  client.hosts.contains(where: { $0.id == id && $0.owner_id == userID }) else { return }
        }
        await client.openHost(id, shared: shared)
    }
    func control(_ id: String, action: MIFResourceControlAction) async {
        switch action {
        case .takeOver: await client.takeOverHostControl(id)
        case .returnToAI: await client.releaseHostControl(id)
        case .renewLease: await client.renewHostControlLease(id)
        }
    }

    private func control(for host: MordeHost) -> MIFResourcePageState.Control? {
        guard let userID = client.user?.id, host.owner_id == userID else { return nil }
        guard let status = client.hostControlStatuses[host.id] else {
            return MIFResourcePageState.Control(
                state: .unknown, lease: .unknown, leaseExpiresAt: nil, transitionSummary: nil,
                isLoading: client.hostControlErrors[host.id] == nil,
                isActionInFlight: client.hostControlActionInFlightFor == host.id,
                canTakeOver: false, canReturnToAI: false, canRenewLease: false,
                error: client.hostControlErrors[host.id])
        }
        let transitioning = status.active_transition != nil
        let isUser = status.control_state == "user"
        let state: MIFResourcePageState.Control.State = transitioning
            ? (status.active_transition?.action == "release" ? .returning : .takingOver)
            : (status.control_state == "ai" ? .ai : (isUser ? .user : .unknown))
        let lease: MIFResourcePageState.Control.Lease = status.control_lease_active == true
            ? .active : (status.control_lease_active == false ? (isUser ? .expired : .none) : .unknown)
        return MIFResourcePageState.Control(
            state: state, lease: lease, leaseExpiresAt: status.control_lease_expires_at,
            transitionSummary: status.active_transition.map { "\($0.action) · \($0.phase)" },
            isLoading: false, isActionInFlight: client.hostControlActionInFlightFor == host.id,
            canTakeOver: MordeHostControlPolicy.canTakeOver(
                state: status.control_state, actorID: status.control_actor_user_id,
                leaseActive: status.control_lease_active, transitioning: transitioning),
            canReturnToAI: MordeHostControlPolicy.canRelease(
                state: status.control_state, actorID: status.control_actor_user_id,
                currentUserID: userID, leaseActive: status.control_lease_active, transitioning: transitioning),
            canRenewLease: MordeHostControlPolicy.canRenew(
                state: status.control_state, actorID: status.control_actor_user_id,
                currentUserID: userID, leaseActive: status.control_lease_active, transitioning: transitioning),
            error: client.hostControlErrors[host.id])
    }

    private static func status(_ value: String) -> MIFResourcePageState.Host.Status {
        switch value {
        case "running": .running
        case "starting", "provisioning": .starting
        case "stopped": .stopped
        case "offline", "failed", "deleting", "deleted": .offline
        default: .unknown
        }
    }
}

@MainActor final class MIFExecutionControlStore: ObservableObject {
    static let shared = MIFExecutionControlStore()
    let objectWillChange = ObservableObjectPublisher()
    private let client = MordeClient.shared
    private var observation: AnyCancellable?

    private init() {
        observation = client.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var state: String? { client.executionControl?.state }
    var pendingTaskCount: Int? { client.executionControl?.pending_task_count }
    var activeTaskCount: Int? { client.executionControl?.runtime.active_task_count }
    var error: String? { client.executionControlError }
    var isLoading: Bool { client.executionControlIsLoading }
    var isBusy: Bool { client.executionControlActionInFlight }
    var isSignedIn: Bool { client.signedIn }

    func refresh() async { await client.refreshExecutionControl() }
    func stopAll() async { _ = await client.setCloudExecutionEnabled(false) }
    func enable() async { _ = await client.setCloudExecutionEnabled(true) }
}

@MainActor final class MIFWorkItemPageStore: ObservableObject {
    static let shared = MIFWorkItemPageStore()
    let objectWillChange = ObservableObjectPublisher()
    private let client = MordeClient.shared
    private var observation: AnyCancellable?

    private init() {
        observation = client.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var isSignedIn: Bool { client.signedIn }
    var scopeKey: String? { client.taskPageScopeKey }
    var projects: [MordeProject] { client.projects }
    var projectsState: MordeResourceLoadState { client.projectsState }
    var selectedProjectID: String? { client.selectedProjectID }
    var workItems: [MordeProjectWorkItem] { client.projectWorkItems }
    var workItemsState: MordeResourceLoadState { client.projectWorkItemsState }
    var supportsWorkItemsV2: Bool { client.projectWorkItemsV2Available == true }
    var conversations: [MordeProjectConversation] { client.projectConversations }
    var conversationsState: MordeResourceLoadState { client.projectConversationsState }
    var selectedConversationID: String? { client.selectedProjectConversationID }
    var currentTask: MordeTask? {
        guard let projectID = client.selectedProjectID,
              let conversationID = client.selectedProjectConversationID,
              client.projectConversations.contains(where: { $0.id == conversationID && $0.project_id == projectID }),
              client.projectConversationTask?.conversation_id == conversationID else { return nil }
        return client.projectConversationTask
    }
    var conversationError: String? { client.projectConversationError }
    var actionInFlight: Bool { client.projectActionInFlight }
    var actionError: String? { client.projectActionError }
    var notice: String? { client.projectNotice }
    var deliveryTargets: [MIFWorkItemDeliveryTarget] {
        client.hosts.filter { $0.owner_id == client.user?.id && client.canOpenHost($0) }.flatMap { host in
            return client.workspaceBindings(for: host.id).compactMap { binding in
                guard client.isReady(binding) else { return nil }
                return MIFWorkItemDeliveryTarget(
                    hostID: host.id, hostName: host.name, workspaceID: binding.workspace.id,
                    workspaceName: binding.workspace.name, revision: Int64(binding.workspace.revision))
            }
        }
    }

    func role(in projectID: String) -> String? {
        client.projectMembers.first(where: { $0.project_id == projectID && $0.user_id == client.user?.id })?.role
    }
    func canManage(in projectID: String) -> Bool {
        MordeProjectPolicy.canManageWorkItems(role: role(in: projectID))
    }
    func canClaim(in projectID: String) -> Bool { supportsWorkItemsV2 && canManage(in: projectID) }
    func load() async { await client.loadProjects(includeProjectBudget: false) }
    func selectProject(_ id: String) async { await client.selectProject(id, includeProjectBudget: false) }
    func selectConversation(_ id: String) async { await client.selectProjectConversation(id) }
    func create(projectID: String, title: String, description: String,
                category: String? = nil, unassigned: Bool = false) async -> Bool {
        await client.createProjectWorkItem(projectID: projectID, title: title, description: description,
                                           category: category, unassigned: unassigned)
    }
    func block(projectID: String, item: MordeProjectWorkItem, reason: String) async -> Bool {
        await client.setProjectWorkItemBlocked(projectID: projectID, item: item, reason: reason)
    }
    func resume(projectID: String, item: MordeProjectWorkItem) async -> Bool {
        await client.resumeProjectWorkItem(projectID: projectID, item: item)
    }
    func claim(projectID: String, item: MordeProjectWorkItem) async -> Bool {
        await client.claimProjectWorkItem(projectID: projectID, item: item)
    }
    func linkTask(projectID: String, item: MordeProjectWorkItem, taskID: String) async -> Bool {
        await client.linkProjectWorkItemTask(projectID: projectID, item: item, taskID: taskID)
    }
    func recordDelivery(projectID: String, item: MordeProjectWorkItem,
                        target: MIFWorkItemDeliveryTarget, taskID: String) async -> Bool {
        await client.recordProjectWorkItemDelivery(projectID: projectID, item: item, taskID: taskID,
                                                   hostID: target.hostID, workspaceID: target.workspaceID)
    }
}

public struct MordeEmbeddedView: View {
    private let ownsLifecycle: Bool
    public init(ownsLifecycle: Bool = true) { self.ownsLifecycle = ownsLifecycle }

    public var body: some View {
        // The design tab bar is 62 pt tall with 8/16 pt top/bottom spacing.
        MordeClientContainer(layout: .full, ownsLifecycle: ownsLifecycle, bottomOverlay: 86)
    }
}

struct MordeAccountSettingsView: View {
    @StateObject private var client = MordeClient.shared
    @State private var confirmsSignOut = false

    private var serviceAddress: String {
        MordeLoginStateStore.serviceOrigin(client.server) ?? String(localized: "No valid HTTPS service address is configured")
    }

    var body: some View {
        List {
            Section("Morde account") {
                if client.signedIn, let user = client.user {
                    LabeledContent("Name", value: user.name.isEmpty ? String(localized: "Not provided") : user.name)
                    LabeledContent("Account ID", value: user.id)
                } else if client.signedIn {
                    Text("Loading account information…")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Not signed in to Morde.")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("morde.account.signedOut")
                }
            }

            Section("Service") {
                LabeledContent("Service address", value: serviceAddress)
            }

#if MINIS_CLOUD_ONLY
            NanoMuseMordePersonalSyncSection(quotaLoader: {
                let value = try await MordeShellAuthorization.shared.personalDataQuota()
                return NanoMuseMordePersonalDataQuota(owner_id: value.owner_id,
                    used_bytes: value.used_bytes, reserved_bytes: value.reserved_bytes,
                    quota_bytes: value.quota_bytes, max_attachment_bytes: value.max_attachment_bytes,
                    remaining_bytes: value.remaining_bytes, version: value.version)
            })
            Section("Personal data") {
                NavigationLink {
                    NanoMuseMordeProfileView()
                } label: {
                    Label("Personal profile", systemImage: "person.crop.circle")
                }
            }
#endif

            if client.signedIn {
                Section {
                    NavigationLink {
                        MordePortalSettingsView(page: .hostMembers)
                    } label: {
                        Label("Host members", systemImage: "person.2")
                    }
                    NavigationLink {
                        MordePortalSettingsView(page: .modelConnections)
                    } label: {
                        Label("Model connections", systemImage: "point.3.connected.trianglepath.dotted")
                    }
                    NavigationLink {
                        MordePortalSettingsView(page: .apiKeys)
                    } label: {
                        Label("API Keys", systemImage: "key.horizontal")
                    }
                } header: {
                    Text("Workspace and account settings")
                } footer: {
                    Text("These pages use a short-lived user session for this installation. Server permissions still apply; no client credential is given to the web page.")
                }

                Section {
                    NavigationLink {
                        MordeClientInstallationsSettingsView()
                    } label: {
                        Label("Manage client installations", systemImage: "laptopcomputer.and.iphone")
                    }
                    .accessibilityIdentifier("morde.account.manageInstallations")
                } footer: {
                    Text("View and revoke devices signed in to this Morde account.")
                }

                Section {
                    Button("Sign out of this account", role: .destructive) {
                        confirmsSignOut = true
                    }
                    .accessibilityIdentifier("morde.account.signOut")
                    .disabled(client.busy)
                } footer: {
                    Text("After signing out, this device will need to sign in to Morde again.")
                }
            }

            if let error = client.error, !error.isEmpty {
                Section("Status") {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: 86).accessibilityHidden(true)
        }
        .navigationTitle("Morde account")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Sign out of Morde?", isPresented: $confirmsSignOut, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) {
                Task { await client.signOut() }
            }
            .accessibilityIdentifier("morde.account.signOut.confirm")
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This signs out only the current Morde client session on this device.")
        }
        .task {
            if client.signedIn, client.user == nil {
                await client.load()
            }
        }
    }
}

private enum MordePortalSettingsPage {
    case hostMembers
    case modelConnections
    case apiKeys

    var title: String {
        switch self {
        case .hostMembers: return "Host members"
        case .modelConnections: return "Model connections"
        case .apiKeys: return "API Keys"
        }
    }

    var path: String {
        switch self {
        case .hostMembers: return "/hosts"
        case .modelConnections: return "/connections"
        case .apiKeys: return "/apikeys"
        }
    }
}

private struct MordePortalSettingsSession {
    let credential: String
    let expiresAt: Date
}

private struct MordePortalSettingsView: View {
    @StateObject private var client = MordeClient.shared
    @Environment(\.dismiss) private var dismiss
    let page: MordePortalSettingsPage
    @State private var session: MordePortalSettingsSession?
    @State private var error: String?
    @State private var loading = false

    var body: some View {
        Group {
            if let session, let origin = URL(string: client.server) {
                MordePortalSettingsWebView(origin: origin, path: page.path,
                                           credential: session.credential, expiresAt: session.expiresAt)
                    .id(session.credential)
                    .ignoresSafeArea(edges: .bottom)
            } else if loading {
                ProgressView("Opening secure settings…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield").font(.title2).foregroundStyle(.secondary)
                    Text(error ?? "Sign in to Morde to open this page.")
                        .multilineTextAlignment(.center).foregroundStyle(.secondary)
                    Button("Retry") { Task { await openPage() } }
                        .disabled(!client.signedIn)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(page.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { if session == nil { await openPage() } }
        .onChange(of: client.signedIn) { signedIn in
            if !signedIn { dismiss() }
        }
    }

    @MainActor
    private func openPage() async {
        guard !loading else { return }
        loading = true
        defer { loading = false }
        do {
            let value = try await client.portalSessionForWebView()
            guard let origin = URL(string: client.server),
                  isAllowedMordePortalNavigation(URL(string: page.path, relativeTo: origin)?.absoluteURL,
                                                 relativeTo: origin) else {
                throw URLError(.badURL)
            }
            session = MordePortalSettingsSession(credential: value.credential, expiresAt: value.expiresAt)
            error = nil
        } catch {
            session = nil
            self.error = error.localizedDescription
        }
    }
}

private struct MordePortalSettingsWebView: UIViewRepresentable {
    let origin: URL
    let path: String
    let credential: String
    let expiresAt: Date

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        guard let host = origin.host,
              let cookie = HTTPCookie(properties: [
                .name: "ch_portal", .value: credential, .domain: host, .path: "/",
                .secure: "TRUE", .expires: expiresAt,
                HTTPCookiePropertyKey("HttpOnly"): "TRUE",
              ]),
              let url = URL(string: path, relativeTo: origin)?.absoluteURL else { return webView }
        context.coordinator.install(cookie, in: configuration.websiteDataStore.httpCookieStore, thenLoad: url, in: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.stopLoading()
        uiView.navigationDelegate = nil
        coordinator.clearCookie()
    }

    func makeCoordinator() -> Coordinator { Coordinator(origin: origin) }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let origin: URL
        private var cookieStore: WKHTTPCookieStore?
        private var cookie: HTTPCookie?

        init(origin: URL) { self.origin = origin }

        func install(_ cookie: HTTPCookie, in store: WKHTTPCookieStore, thenLoad url: URL, in webView: WKWebView) {
            self.cookie = cookie
            cookieStore = store
            Task { @MainActor in
                await store.setCookie(cookie)
                webView.load(URLRequest(url: url))
            }
        }

        func clearCookie() {
            guard let cookieStore, let cookie else { return }
            Task { @MainActor in await cookieStore.deleteCookie(cookie) }
            self.cookie = nil
            self.cookieStore = nil
        }

        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(isAllowedMordePortalNavigation(action.request.url, relativeTo: origin) ? .allow : .cancel)
        }
    }
}

private struct MordeWorkspacePreviewItem: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

private struct MordeWorkspaceFilesView: View {
    private enum WorkspaceTool: String, Identifiable {
        case upload
        case history

        var id: String { rawValue }
        var title: String { self == .upload ? "上传文件" : "版本比较与恢复" }
    }

    private struct WorkspaceBreadcrumb: Identifiable {
        let title: String
        let path: String
        var id: String { path }
    }

    @StateObject private var client = MordeClient.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedWorkspaceID = ""
    @State private var workspaceTool: WorkspaceTool?
    @State private var shareUnavailable = false
    @State private var files: [MordeWorkspaceFile] = []
    @State private var directories: [String] = []
    @State private var currentDirectoryPath = ""
    @State private var appliedDirectoryPath: String?
    @State private var historyFromRevision = ""
    @State private var workspaceDiff: MordeWorkspaceDiff?
    @State private var selectedDiffChanges = Set<String>()
    @State private var workspaceHistoryLoading = false
    @State private var workspaceHistoryError: String?
    @State private var workspaceHistoryNotice: String?
    @State private var confirmWorkspaceRestore = false
    @State private var manifestRevision: Int64?
    @State private var nextCursor: String?
    @State private var manifestLoading = false
    @State private var manifestGeneration = 0
    @State private var manifestError: String?
    @State private var showFileImporter = false
    @State private var selectedFiles: [MordeWorkspaceLocalSelection] = []
    @State private var confirmUpload = false
    @State private var confirmDownload = false
    @State private var selectedDownload: MordeWorkspaceFile?
    @State private var filePathOperation: MordeWorkspaceFileOperationAction?
    @State private var filePathOperationFile: MordeWorkspaceFile?
    @State private var filePathOperationRevision: Int64?
    @State private var filePathOperationInput = ""
    @State private var selectedCloudDelete: MordeWorkspaceFile?
    @State private var selectedCloudDeleteRevision: Int64?
    @State private var confirmCloudDelete = false
    @State private var deleteLocalCopy = false
    @State private var selectedLocalFile: MordeWorkspaceFile?
    @State private var isTransferring = false
    @State private var transferProgress: (Int64, Int64)?
    @State private var errorMessage: String?
    @State private var previewItem: MordeWorkspacePreviewItem?

    init(initialWorkspaceID: String? = nil) {
        _selectedWorkspaceID = State(initialValue: initialWorkspaceID ?? "")
    }

    private var selectedWorkspace: MordeWorkspace? {
        client.workspaces.first { $0.id == selectedWorkspaceID }
    }

    private var workspaceBreadcrumbs: [WorkspaceBreadcrumb] {
        var paths = [WorkspaceBreadcrumb(title: selectedWorkspace?.name ?? "Workspace", path: "")]
        var path = ""
        for component in currentDirectoryPath.split(separator: "/") {
            path = path.isEmpty ? String(component) : "\(path)/\(component)"
            paths.append(WorkspaceBreadcrumb(title: String(component), path: path))
        }
        return paths
    }

    private var appliedDirectoryPrefix: String {
        guard let appliedDirectoryPath, !appliedDirectoryPath.isEmpty else { return "" }
        return "\(appliedDirectoryPath)/"
    }

    private var directSubdirectoryPaths: [String] {
        guard appliedDirectoryPath != nil else { return [] }
        var paths = Set<String>()
        for directory in directories where directory != "." && directory.hasPrefix(appliedDirectoryPrefix) {
            let remainingPath = directory.dropFirst(appliedDirectoryPrefix.count)
            guard !remainingPath.isEmpty else { continue }
            let name = String(remainingPath.prefix { $0 != "/" })
            let path = "\(appliedDirectoryPrefix)\(name)"
            guard (try? MordeWorkspaceTransferSupport.validatePath(path)) != nil else { continue }
            paths.insert(path)
        }
        for file in files where file.path.hasPrefix(appliedDirectoryPrefix) {
            let remainingPath = file.path.dropFirst(appliedDirectoryPrefix.count)
            guard let separator = remainingPath.firstIndex(of: "/") else { continue }
            let name = String(remainingPath[..<separator])
            let path = "\(appliedDirectoryPrefix)\(name)"
            guard (try? MordeWorkspaceTransferSupport.validatePath(path)) != nil else { continue }
            paths.insert(path)
        }
        return paths.sorted {
            workspacePathName($0).localizedStandardCompare(workspacePathName($1)) == .orderedAscending
        }
    }

    private var directFileRows: [MordeWorkspaceFile] {
        guard appliedDirectoryPath != nil else { return [] }
        return files.filter { file in
            guard file.path.hasPrefix(appliedDirectoryPrefix) else { return false }
            return !file.path.dropFirst(appliedDirectoryPrefix.count).contains("/")
        }.sorted {
            workspacePathName($0.path).localizedStandardCompare(workspacePathName($1.path)) == .orderedAscending
        }
    }

    private var canMutateWorkspaceFiles: Bool {
        guard client.workspaceSyncAvailable == true, !isTransferring,
              let manifestRevision, let selectedWorkspace else { return false }
        return manifestRevision == Int64(selectedWorkspace.revision)
    }

    private var filePathOperationTarget: String? {
        guard let action = filePathOperation, action != .delete, let file = filePathOperationFile else { return nil }
        return try? MordeWorkspaceTransferSupport.fileOperationTargetPath(
            action: action.rawValue, sourcePath: file.path, input: filePathOperationInput)
    }

    private var selectedBytes: Int64 { selectedFiles.reduce(0) { $0 + $1.file.sizeBytes } }
    private var selectedRestorePaths: [String] {
        guard let workspaceDiff else { return [] }
        var paths = Set<String>()
        for change in workspaceDiff.changes where selectedDiffChanges.contains(change.id) {
            paths.insert(change.path)
            if let path = change.before?.path { paths.insert(path) }
            if let path = change.after?.path { paths.insert(path) }
        }
        return paths.sorted()
    }
    private var workspaceHistoryCanRestore: Bool {
        guard let workspaceDiff, let selectedWorkspace else { return false }
        return workspaceDiff.to_revision == Int64(selectedWorkspace.revision) && !selectedRestorePaths.isEmpty
    }
    private var selectionSummary: String {
        let count = selectedFiles.count
        let size = Self.fileSize(selectedBytes)
        return "范围：\(count) 个明确路径 · \(size)。未选路径不会被删除。"
    }

    private func navigateToDirectory(_ path: String) {
        guard path != currentDirectoryPath else { return }
        guard path.isEmpty || (try? MordeWorkspaceTransferSupport.validatePath(path)) != nil else { return }
        manifestGeneration += 1
        manifestLoading = false
        currentDirectoryPath = path
        files = []
        directories = []
        nextCursor = nil
        manifestRevision = nil
        manifestError = nil
        appliedDirectoryPath = nil
    }

    private func workspacePathName(_ path: String) -> String {
        path.split(separator: "/").last.map(String.init) ?? path
    }

    private var workspaceBreadcrumbBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(workspaceBreadcrumbs) { crumb in
                    if !crumb.path.isEmpty {
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    if crumb.path == currentDirectoryPath {
                        Text(crumb.title).foregroundStyle(.secondary)
                    } else {
                        Button(crumb.title) { navigateToDirectory(crumb.path) }
                            .buttonStyle(.plain)
                    }
                }
            }
            .font(.subheadline)
        }
        .accessibilityLabel("Workspace 路径")
    }

    private func directoryRow(_ path: String) -> some View {
        Button { navigateToDirectory(path) } label: {
            HStack(spacing: 12) {
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(workspacePathName(path)).font(.headline)
                    Text("目录").font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("morde.workspace.directory.\(path)")
    }

    private func localSelectionRow(_ selection: MordeWorkspaceLocalSelection) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(selection.file.path).font(.headline)
            Text("\(Self.fileSize(selection.file.sizeBytes)) · SHA-256")
                .font(.caption).foregroundStyle(.secondary)
            Text(verbatim: selection.file.sha256)
                .font(.system(size: 12, design: .monospaced))
                .textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
        }
    }

    private var uploadSelectionSection: some View {
        Section {
            Button("选择文件") { showFileImporter = true }
                .disabled(isTransferring || selectedWorkspace == nil || client.workspaceSyncAvailable != true)
            if selectedFiles.isEmpty {
                Text("尚未选择文件。取消文件选择或本确认框都不会上传。")
                    .font(.footnote).foregroundStyle(.secondary)
            } else {
                ForEach(selectedFiles) { selection in localSelectionRow(selection) }
                Text(selectionSummary).font(.footnote).foregroundStyle(.secondary)
                Button("上传并确认检查点") { confirmUpload = true }
                    .disabled(isTransferring || client.workspaceSyncAvailable != true)
            }
            if let (done, total) = transferProgress, isTransferring {
                ProgressView(value: total == 0 ? 1 : Double(done) / Double(total))
                Text("已确认 \(Self.fileSize(done)) / \(Self.fileSize(total))")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        } header: {
            Text("选择并确认上传范围")
        } footer: {
            Text("只上传下方列出的文件；每个文件最多 300 MiB。服务端确认全部分块和 SHA-256 后才提交不可变 Workspace 检查点。")
        }
    }

    private var manifestSection: some View {
        Section {
            workspaceBreadcrumbBar
            if client.workspaceSyncAvailable != true {
                Text(client.workspaceSyncAvailable == false
                     ? "服务端未开放 Workspace 文件传输；上传和下载已锁定。"
                     : "正在确认服务端 Workspace 文件能力。")
                    .foregroundStyle(.secondary)
            } else if let manifestError {
                Text("文件清单暂不可用：\(manifestError)").foregroundStyle(.orange)
            } else if manifestLoading {
                ProgressView("正在读取文件清单…")
            } else if manifestRevision != nil && files.isEmpty && directories.isEmpty && nextCursor == nil {
                Text("此目录当前没有文件。")
                    .foregroundStyle(.secondary)
            } else if manifestRevision == nil {
                Text("选择获准 Workspace 后读取真实文件清单。")
                    .foregroundStyle(.secondary)
            }
            ForEach(directSubdirectoryPaths, id: \.self) { path in directoryRow(path) }
            ForEach(directFileRows) { file in fileRow(file) }
            if nextCursor != nil {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                    .task(id: nextCursor) { await loadManifest(reset: false) }
            }
        } header: {
            Text("文件")
        } footer: {
            if let manifestRevision {
                Text("文件来自 Workspace v\(manifestRevision) 的真实清单。下载只写入本机应用目录；不会覆盖已存在的本机文件。")
            }
        }
    }

    private var workspaceHistorySection: some View {
        Section {
            TextField("恢复来源版本号", text: $historyFromRevision)
                .keyboardType(.numberPad)
            Button("比较来源版本与当前版本") { Task { await loadWorkspaceDiff() } }
                .disabled(workspaceHistoryLoading || selectedWorkspace == nil)
            if workspaceHistoryLoading {
                ProgressView("正在读取 Workspace 差异…")
            }
            if let workspaceHistoryError {
                Text(workspaceHistoryError).font(.footnote).foregroundStyle(.orange)
            }
            if let workspaceHistoryNotice {
                Text(workspaceHistoryNotice).font(.footnote).foregroundStyle(.secondary)
            }
            if let workspaceDiff {
                Text("v\(workspaceDiff.from_revision) → v\(workspaceDiff.to_revision) · \(workspaceDiff.changes.count) 项")
                    .font(.caption).foregroundStyle(.secondary)
                if workspaceDiff.changes.isEmpty {
                    Text("这两个版本之间没有差异。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                ForEach(workspaceDiff.changes) { change in
                    Button {
                        if !selectedDiffChanges.insert(change.id).inserted {
                            selectedDiffChanges.remove(change.id)
                        }
                    } label: {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: selectedDiffChanges.contains(change.id)
                                  ? "checkmark.circle.fill" : "circle")
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(workspaceDiffActionTitle(change.action)) · \(change.path)")
                                    .font(.footnote)
                                if let before = change.before?.path, before != change.path {
                                    Text("原路径：\(before)").font(.caption).foregroundStyle(.secondary)
                                }
                                Text(workspaceDiffStatusTitle(change.display_status))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    if change.display_status == "text" {
                        if let beforeText = change.before_text {
                            Text("旧版本：\n\(beforeText)").font(.caption.monospaced()).textSelection(.enabled)
                        }
                        if let afterText = change.after_text {
                            Text("当前版本：\n\(afterText)").font(.caption.monospaced()).textSelection(.enabled)
                        }
                    }
                }
                Button("恢复所选路径…") { confirmWorkspaceRestore = true }
                    .disabled(workspaceHistoryLoading || !workspaceHistoryCanRestore)
            }
        } header: {
            Text("版本差异与恢复")
        } footer: {
            Text("只对比已确认版本。恢复会创建新版本，不改写历史；服务端会重新检查权限、当前版本和 Host 写入状态。")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                NanoMuseRoundButton(symbol: "chevron.left", label: "返回资源", size: 40) { dismiss() }
                Text(selectedWorkspace?.name ?? "Workspace")
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                    .accessibilityIdentifier("morde.workspace.title")
                    .contextMenu {
                        Button {
                            workspaceTool = .upload
                        } label: {
                            Label("上传文件", systemImage: "arrow.up.doc")
                        }
                        .disabled(selectedWorkspace == nil || client.workspaceSyncAvailable != true || isTransferring)
                        Button {
                            workspaceTool = .history
                        } label: {
                            Label("版本比较与恢复", systemImage: "clock.arrow.circlepath")
                        }
                        .disabled(selectedWorkspace == nil || isTransferring)
                    }
                Spacer(minLength: 8)
                NanoMuseRoundButton(symbol: "square.and.arrow.up", label: "分享这个 Workspace", size: 40) {
                    shareUnavailable = true
                }
                .accessibilityIdentifier("morde.workspace.share")
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 52)

            List {
            manifestSection
            if isTransferring {
                Section("传输中") {
                    if let (done, total) = transferProgress {
                        ProgressView(value: total == 0 ? 1 : Double(done) / Double(total))
                        Text("已确认 \(Self.fileSize(done)) / \(Self.fileSize(total))")
                            .font(.footnote).foregroundStyle(.secondary)
                    } else {
                        ProgressView("正在提交 Workspace 操作…")
                    }
                }
            }
            }
            .accessibilityIdentifier("morde.workspace.files")
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $workspaceTool) { tool in
            NavigationStack {
                List {
                    if tool == .upload { uploadSelectionSection }
                    else { workspaceHistorySection }
                }
                .navigationTitle(tool.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("完成") { workspaceTool = nil }
                    }
                }
                .confirmationDialog("确认上传 \(selectedFiles.count) 个文件？", isPresented: $confirmUpload,
                                    titleVisibility: .visible) {
                    Button("上传并提交检查点") { Task { await uploadSelection() } }
                    Button("取消", role: .cancel) {}
                } message: {
                    Text("\(selectedWorkspace?.name ?? "Workspace") · \(selectedFiles.map { $0.file.path }.joined(separator: "、")) · \(Self.fileSize(selectedBytes))。")
                }
                .confirmationDialog("确认恢复 Workspace 路径？", isPresented: $confirmWorkspaceRestore,
                                    titleVisibility: .visible) {
                    Button("恢复所选路径", role: .destructive) { Task { await restoreWorkspaceChanges() } }
                        .disabled(!workspaceHistoryCanRestore || workspaceHistoryLoading)
                    Button("取消", role: .cancel) {}
                } message: {
                    if let workspaceDiff {
                        let paths = selectedRestorePaths
                        let visiblePaths = paths.prefix(8).joined(separator: "、")
                        let remainder = paths.count > 8 ? " 等 \(paths.count) 个路径" : ""
                        Text("从 v\(workspaceDiff.from_revision) 恢复到当前 v\(workspaceDiff.to_revision)：\(visiblePaths)\(remainder)。服务端可能因版本变化、绑定电脑或未完成写入而拒绝。")
                    }
                }
            }
        }
        .alert("Workspace 分享暂未接入", isPresented: $shareUnavailable) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("当前服务没有分享链接和访问权限接口。")
        }
        .refreshable { await loadManifest(reset: true) }
        .onChange(of: client.workspaces.map(\.id)) { ids in
            if !ids.contains(selectedWorkspaceID) { selectedWorkspaceID = ids.first ?? "" }
        }
        .onChange(of: selectedWorkspaceID) { _ in
            manifestGeneration += 1
            manifestLoading = false
            currentDirectoryPath = ""
            appliedDirectoryPath = nil
            files = []; directories = []; nextCursor = nil; manifestRevision = nil; manifestError = nil
            workspaceDiff = nil; selectedDiffChanges = []; workspaceHistoryError = nil; workspaceHistoryNotice = nil
        }
        .onChange(of: client.workspaceSyncAvailable) { available in
            if available == true {
                Task { await loadManifest(reset: true) }
            } else {
                manifestGeneration += 1
                manifestLoading = false
                files = []; directories = []; nextCursor = nil; manifestRevision = nil
                appliedDirectoryPath = nil
                manifestError = nil
            }
        }
        .task(id: "\(selectedWorkspaceID):\(selectedWorkspace?.revision ?? -1):\(currentDirectoryPath)") {
            await loadManifest(reset: true)
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.item], allowsMultipleSelection: true,
                      onCompletion: { result in Task { await importFiles(result) } })
        .confirmationDialog("下载并核验文件？", isPresented: $confirmDownload, titleVisibility: .visible) {
            Button("下载并确认检查点") {
                guard let selectedDownload else { return }
                Task { await download(selectedDownload) }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text(selectedDownload.map { "\($0.path) · \(Self.fileSize($0.sizeBytes)) · SHA-256 \($0.sha256)" } ?? "")
        }
        .confirmationDialog("删除本机文件副本？", isPresented: $deleteLocalCopy, titleVisibility: .visible) {
            Button("删除本机副本", role: .destructive) {
                guard let selectedLocalFile else { return }
                do {
                    try client.removeLocalWorkspaceFile(workspaceID: selectedWorkspaceID, path: selectedLocalFile.path)
                } catch { errorMessage = error.localizedDescription }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text(selectedLocalFile?.path ?? "")
        }
        .confirmationDialog("删除云端 Workspace 文件？", isPresented: $confirmCloudDelete,
                            titleVisibility: .visible) {
            Button("删除并提交新检查点", role: .destructive) {
                guard let file = selectedCloudDelete, let revision = selectedCloudDeleteRevision else { return }
                selectedCloudDelete = nil
                selectedCloudDeleteRevision = nil
                Task { await performWorkspaceFileOperation(action: .delete, file: file,
                                                            targetPath: "", revision: revision) }
            }
            Button("取消", role: .cancel) {
                selectedCloudDelete = nil
                selectedCloudDeleteRevision = nil
            }
        } message: {
            if let file = selectedCloudDelete, let revision = selectedCloudDeleteRevision {
                Text("删除 \(file.path)，基于 Workspace v\(revision) 创建新检查点。旧版本仍可比较和恢复。")
            }
        }
        .sheet(item: $previewItem) { item in MordeWorkspaceQuickLook(url: item.url) }
        .alert(filePathOperation.map { Text("\($0.title) Workspace 文件") } ?? Text("文件操作失败"),
               isPresented: Binding(
                get: { filePathOperation != nil || (errorMessage != nil && isTransferring == false) },
                set: { presented in
                    if !presented {
                        filePathOperation = nil
                        filePathOperationFile = nil
                        filePathOperationRevision = nil
                        errorMessage = nil
                    }
                }
               ), actions: {
                if let action = filePathOperation {
                    TextField(action == .rename ? "新文件名" : "目标相对路径", text: $filePathOperationInput)
                    Button("取消", role: .cancel) {
                        filePathOperation = nil
                        filePathOperationFile = nil
                        filePathOperationRevision = nil
                    }
                    Button("确认") {
                        guard let file = filePathOperationFile,
                              let revision = filePathOperationRevision,
                              let targetPath = filePathOperationTarget else { return }
                        filePathOperation = nil
                        filePathOperationFile = nil
                        filePathOperationRevision = nil
                        Task { await performWorkspaceFileOperation(action: action, file: file,
                                                                    targetPath: targetPath, revision: revision) }
                    }
                    .disabled(filePathOperationTarget == nil || !canMutateWorkspaceFiles ||
                              filePathOperationRevision != manifestRevision)
                } else {
                    Button("确定") { errorMessage = nil }
                }
               }, message: {
                if let action = filePathOperation, let file = filePathOperationFile {
                    Text("原路径：\(file.path)。\(action == .rename ? "输入新文件名" : "输入目标相对路径")；服务端会按 v\(filePathOperationRevision ?? -1) 重新检查权限和并发写入。")
                } else {
                    Text(errorMessage ?? "")
                }
               })
    }

    @ViewBuilder
    private func fileRow(_ file: MordeWorkspaceFile) -> some View {
        let localURL = client.localWorkspaceFileURL(workspaceID: selectedWorkspaceID, path: file.path)
        let exists = localURL.map(MordeWorkspaceTransferSupport.isRegularFileWithoutFollowingSymlinks) ?? false
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "doc")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text(workspacePathName(file.path)).font(.headline)
                Text(Self.fileSize(file.sizeBytes))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Menu {
                if exists {
                    Section("本机副本") {
                        Button {
                            Task {
                                do { previewItem = MordeWorkspacePreviewItem(
                                    url: try await client.verifyLocalWorkspaceFile(
                                        workspaceID: selectedWorkspaceID, file: file)) }
                                catch { errorMessage = error.localizedDescription }
                            }
                        } label: {
                            Label("核验并预览", systemImage: "doc.text.magnifyingglass")
                        }
                        .disabled(isTransferring)
                        Button(role: .destructive) {
                            selectedLocalFile = file
                            deleteLocalCopy = true
                        } label: {
                            Label("删除本机副本", systemImage: "trash")
                        }
                        .disabled(isTransferring)
                    }
                } else {
                    Button {
                        selectedDownload = file
                        confirmDownload = true
                    } label: {
                        Label("下载并校验", systemImage: "arrow.down.to.line")
                    }
                    .disabled(isTransferring || client.workspaceSyncAvailable != true)
                }
                Section("云端文件") {
                    Button("重命名") { beginFilePathOperation(.rename, file: file) }
                        .disabled(!canMutateWorkspaceFiles)
                    Button("移动") { beginFilePathOperation(.move, file: file) }
                        .disabled(!canMutateWorkspaceFiles)
                    Button("删除云端文件", role: .destructive) {
                        selectedCloudDelete = file
                        selectedCloudDeleteRevision = manifestRevision
                        confirmCloudDelete = true
                    }
                    .disabled(!canMutateWorkspaceFiles)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("\(file.path) 的操作")
            .accessibilityHint("显示此文件在本机和 Workspace 云端的操作")
        }
        .padding(.vertical, 3)
    }

    @MainActor
    private func importFiles(_ result: Result<[URL], Error>) async {
        switch result {
        case .failure(let error):
            selectedFiles = []
            if !(error is CancellationError) { errorMessage = error.localizedDescription }
        case .success(let urls):
            guard !urls.isEmpty else { selectedFiles = []; return }
            let sources = urls.map { (url: $0, path: $0.lastPathComponent) }
            guard MordeWorkspaceTransferSupport.hasCaseInsensitiveUniquePaths(sources.map(\.path)) else {
                selectedFiles = []
                errorMessage = "文件名为空、路径不安全或存在大小写冲突。请分开选择并重命名。"
                return
            }
            do {
                let manifests = try await Task.detached(priority: .userInitiated) {
                    try sources.map { source in
                        try withMordeSecurityScope(source.url) {
                            try MordeWorkspaceTransferSupport.scan(url: source.url, path: source.path)
                        }
                    }
                }.value
                guard !Task.isCancelled else { return }
                selectedFiles = zip(sources.map(\.url), manifests).map {
                    MordeWorkspaceLocalSelection(url: $0.0, file: $0.1)
                }
                errorMessage = nil
            } catch {
                selectedFiles = []
                errorMessage = error.localizedDescription
            }
        }
    }

    @MainActor
    private func loadManifest(reset: Bool) async {
        guard client.workspaceSyncAvailable == true else {
            manifestGeneration += 1
            manifestLoading = false
            files = []; directories = []; nextCursor = nil; manifestRevision = nil
            appliedDirectoryPath = nil
            manifestError = nil
            return
        }
        guard let workspace = selectedWorkspace else {
            manifestGeneration += 1
            manifestLoading = false
            files = []; directories = []; nextCursor = nil; manifestRevision = nil
            appliedDirectoryPath = nil; manifestError = nil
            return
        }
        guard reset || !manifestLoading else { return }
        let directoryPath: String
        if reset {
            directoryPath = currentDirectoryPath
        } else {
            guard let appliedDirectoryPath, appliedDirectoryPath == currentDirectoryPath else { return }
            directoryPath = appliedDirectoryPath
        }
        let prefix: String?
        do {
            if !directoryPath.isEmpty { try MordeWorkspaceTransferSupport.validatePath(directoryPath) }
            prefix = try MordeWorkspaceTransferSupport.normalizedManifestPrefix(directoryPath)
        } catch {
            manifestError = error.localizedDescription
            return
        }
        if reset {
            files = []; directories = []; nextCursor = nil; manifestRevision = nil; manifestError = nil
            appliedDirectoryPath = directoryPath
        }
        manifestGeneration += 1
        let requestGeneration = manifestGeneration
        manifestLoading = true
        defer {
            if requestGeneration == manifestGeneration { manifestLoading = false }
        }
        do {
            let page = try await client.loadWorkspaceManifest(workspaceID: workspace.id,
                                                              revision: workspace.revision,
                                                              cursor: reset ? nil : nextCursor,
                                                              prefix: prefix)
            guard requestGeneration == manifestGeneration, !Task.isCancelled,
                  workspace.id == selectedWorkspaceID,
                  directoryPath == currentDirectoryPath,
                  workspace.revision == selectedWorkspace?.revision,
                  directoryPath == appliedDirectoryPath else { return }
            let combinedFiles = reset ? page.files : files + page.files
            let pageDirectories = page.directories.map(\.path).filter { $0 != "." }
            let combinedDirectories = Array(Set((reset ? [] : directories) + pageDirectories)).sorted()
            guard MordeWorkspaceTransferSupport.hasCaseInsensitiveUniquePaths(
                combinedFiles.map(\.path) + combinedDirectories) else {
                throw URLError(.cannotParseResponse)
            }
            files = combinedFiles
            directories = combinedDirectories
            manifestRevision = page.revision
            nextCursor = page.next_cursor
            manifestError = nil
        } catch {
            guard requestGeneration == manifestGeneration, !Task.isCancelled,
                  workspace.id == selectedWorkspaceID,
                  directoryPath == currentDirectoryPath,
                  workspace.revision == selectedWorkspace?.revision,
                  directoryPath == appliedDirectoryPath else { return }
            manifestError = error.localizedDescription
        }
    }

    @MainActor
    private func loadWorkspaceDiff() async {
        guard let workspace = selectedWorkspace, let fromRevision = Int64(historyFromRevision),
              fromRevision >= 0, fromRevision < Int64(workspace.revision) else {
            workspaceHistoryError = "请输入小于当前版本的有效来源版本号。"
            workspaceDiff = nil; selectedDiffChanges = []
            return
        }
        workspaceHistoryLoading = true
        defer { workspaceHistoryLoading = false }
        do {
            let diff = try await client.loadWorkspaceDiff(workspaceID: workspace.id,
                                                          fromRevision: fromRevision,
                                                          toRevision: Int64(workspace.revision))
            guard !Task.isCancelled, workspace.id == selectedWorkspaceID,
                  workspace.revision == selectedWorkspace?.revision else { return }
            workspaceDiff = diff; selectedDiffChanges = []
            workspaceHistoryError = nil; workspaceHistoryNotice = nil
        } catch {
            guard !Task.isCancelled else { return }
            workspaceDiff = nil; selectedDiffChanges = []
            workspaceHistoryError = "读取差异失败：\(error.localizedDescription)"
        }
    }

    @MainActor
    private func restoreWorkspaceChanges() async {
        guard let workspace = selectedWorkspace, let diff = workspaceDiff,
              diff.to_revision == Int64(workspace.revision), !selectedRestorePaths.isEmpty else { return }
        let paths = selectedRestorePaths
        workspaceHistoryLoading = true
        defer { workspaceHistoryLoading = false }
        do {
            let result = try await client.restoreWorkspace(
                workspaceID: workspace.id, targetRevision: diff.from_revision,
                expectedCurrentRevision: diff.to_revision, paths: paths,
                idempotencyKey: MordeWorkspaceTransferSupport.idempotencyKey(
                    [workspace.id, String(diff.from_revision), String(diff.to_revision)] + paths))
            guard !Task.isCancelled, workspace.id == selectedWorkspaceID else { return }
            selectedDiffChanges = []
            workspaceHistoryNotice = "已提交恢复，服务端确认新版本 v\(result.revision)。"
            workspaceHistoryError = nil
            await client.refreshWorkspaces()
            await loadManifest(reset: true)
        } catch {
            guard !Task.isCancelled else { return }
            workspaceHistoryError = "恢复结果未确认：\(error.localizedDescription)。可重试同一来源版本和路径；服务端会按幂等键返回原结果。"
        }
    }

    private func workspaceDiffActionTitle(_ action: String) -> String {
        switch action {
        case "added": return "新增"
        case "removed": return "删除"
        case "changed": return "修改"
        case "renamed": return "重命名"
        default: return action
        }
    }

    private func workspaceDiffStatusTitle(_ status: String) -> String {
        switch status {
        case "text": return "文本差异可查看"
        case "binary": return "二进制文件，不显示内容"
        case "too_large": return "文件较大，不显示内容"
        case "metadata_only": return "仅显示文件信息"
        default: return "不适用"
        }
    }

    @MainActor
    private func uploadSelection() async {
        guard let workspace = selectedWorkspace, !selectedFiles.isEmpty, !isTransferring else { return }
        isTransferring = true
        errorMessage = nil
        transferProgress = (0, selectedBytes)
        defer { isTransferring = false }
        do {
            _ = try await client.uploadWorkspaceFiles(
                workspaceID: workspace.id, baseRevision: workspace.revision, selections: selectedFiles) { done, total in
                    transferProgress = (done, total)
                }
            selectedFiles = []
            transferProgress = nil
            await loadManifest(reset: true)
        } catch {
            transferProgress = nil
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func download(_ file: MordeWorkspaceFile) async {
        guard let workspace = selectedWorkspace, !isTransferring else { return }
        selectedDownload = nil
        isTransferring = true
        errorMessage = nil
        transferProgress = (0, file.sizeBytes)
        defer { isTransferring = false }
        do {
            let url = try await client.downloadWorkspaceFile(workspaceID: workspace.id,
                                                            revision: workspace.revision, file: file) { done, total in
                transferProgress = (done, total)
            }
            previewItem = MordeWorkspacePreviewItem(url: url)
            transferProgress = nil
        } catch {
            transferProgress = nil
            errorMessage = error.localizedDescription
        }
    }

    private func beginFilePathOperation(_ action: MordeWorkspaceFileOperationAction, file: MordeWorkspaceFile) {
        guard canMutateWorkspaceFiles, let manifestRevision else { return }
        filePathOperation = action
        filePathOperationFile = file
        filePathOperationRevision = manifestRevision
        filePathOperationInput = action == .rename
            ? String(file.path.split(separator: "/").last ?? Substring(file.path))
            : file.path
    }

    @MainActor
    private func performWorkspaceFileOperation(action: MordeWorkspaceFileOperationAction, file: MordeWorkspaceFile,
                                               targetPath: String, revision: Int64) async {
        guard canMutateWorkspaceFiles, manifestRevision == revision,
              let workspace = selectedWorkspace else {
            errorMessage = "Workspace 文件清单已变化或当前版本已过期，请刷新后重试。"
            return
        }
        let workspaceID = workspace.id
        isTransferring = true
        errorMessage = nil
        defer { isTransferring = false }
        do {
            _ = try await client.applyWorkspaceFileOperation(
                workspaceID: workspaceID, action: action, sourcePath: file.path,
                targetPath: targetPath, expectedCurrentRevision: revision)
            await client.refreshWorkspaces()
            if selectedWorkspaceID == workspaceID { await loadManifest(reset: true) }
        } catch {
            await client.refreshWorkspaces()
            if selectedWorkspaceID == workspaceID { await loadManifest(reset: true) }
            errorMessage = "操作结果未确认：\(error.localizedDescription)。刷新文件清单；重试同一路径、版本和操作会复用幂等键。"
        }
    }

    private static func fileSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

private struct MordeWorkspaceQuickLook: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(url: url) }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(url: URL) { self.url = url }
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
    }
}

private struct MordeClientInstallationsSettingsView: View {
    @StateObject private var client = MordeClient.shared
    @State private var revokeTarget: MordeClientInstallation?
    @State private var confirmsRevoke = false
    @State private var relayConfirmationDevice: MordeDeviceInstallation?
    @State private var relayURL = ""

    var body: some View {
        List {
            Section("Device relay") {
                if client.hubAvailable == true {
                    TextField("HTTP or HTTPS link", text: $relayURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("morde.hub.open.url")
                } else {
                    Text("This Morde service has not confirmed Hub v1 support; device relay is unavailable.")
                        .foregroundStyle(.secondary)
                }
                Text("Online is advisory Hub presence. The target confirms the open request; no confirmation means the result is unknown.")
                    .font(.footnote).foregroundStyle(.secondary)
                switch client.devicesState {
                case .loading:
                    ProgressView("Loading devices…")
                case .failed(let message):
                    Text(message).foregroundStyle(.orange)
                    Button("Retry devices") { Task { await client.loadDevices() } }
                case .loaded:
                    if client.devices.isEmpty {
                        Text("No client devices are registered.").foregroundStyle(.secondary)
                    }
                    ForEach(client.devices) { device in deviceRelayRow(device) }
                }
                if let notice = client.hubRelayNotice {
                    Label(notice, systemImage: "checkmark.circle").foregroundStyle(.secondary)
                }
                if let error = client.hubRelayError {
                    Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
                }
                Text("Only an explicit open-link request is sent. This screen does not send files, screenshots, commands, or notifications.")
                    .font(.footnote).foregroundStyle(.secondary)
            }

            switch client.clientInstallationsState {
            case .loading:
                Section {
                    ProgressView("Loading client installations…")
                }
            case .failed(let message):
                Section {
                    Text(message).foregroundStyle(.orange)
                    Button("Retry") { Task { await client.loadClientInstallations() } }
                }
            case .loaded:
                if client.clientInstallations.isEmpty {
                    Section {
                        Text("No client installations are registered.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("Client installations") {
                        ForEach(client.clientInstallations) { installation in
                            installationRow(installation)
                        }
                    }
                    if !client.clientInstallations.contains(where: { $0.id != client.currentClientInstallationID }) {
                        Section {
                            Text("No other client installations.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if let notice = client.clientInstallationsNotice {
                Section {
                    Label(notice, systemImage: "checkmark.circle")
                        .foregroundStyle(.secondary)
                }
            }
            if let error = client.clientInstallationsActionError {
                Section {
                    Text(error).foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("Client installations")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await client.loadClientInstallations()
            await client.loadDevices()
        }
        .task {
            if client.signedIn, client.user == nil { await client.load() }
            await client.loadClientInstallations()
            await client.loadDevices()
        }
        .confirmationDialog("Revoke this installation?", isPresented: $confirmsRevoke,
                            titleVisibility: .visible) {
            Button("Revoke", role: .destructive) {
                guard let revokeTarget else { return }
                Task { await client.revokeClientInstallation(revokeTarget) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will end the installation’s active Morde sessions and revoke its credential.")
        }
        .alert("Authorize remote open?", isPresented: Binding(
            get: { relayConfirmationDevice != nil },
            set: { if !$0 { relayConfirmationDevice = nil } }
        )) {
            Button("Open link") {
                guard let device = relayConfirmationDevice else { return }
                relayConfirmationDevice = nil
                Task { await client.openURLOnDevice(device.id, input: relayURL) }
            }
            .accessibilityIdentifier("morde.hub.open.confirm")
            Button("Cancel", role: .cancel) { relayConfirmationDevice = nil }
                .accessibilityIdentifier("morde.hub.open.cancel")
        } message: {
            Text(relayConfirmationDevice.map {
                "Ask \($0.display_name) to open \(relayURL). The link is sent only after you confirm; success requires that device’s confirmation."
            } ?? "The target device and link could not be verified.")
        }
    }

    private var relayURLIsValid: Bool {
        guard let url = URL(string: relayURL) else { return false }
        return (try? MordeHubRelayPolicy.validateOpenURL(url)) != nil
    }

    private func deviceRelayRow(_ device: MordeDeviceInstallation) -> some View {
        let isCurrent = device.id == client.currentClientInstallationID
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(device.display_name).font(.headline)
                    Text("\(device.platform) · \(device.online ? "Hub presence online" : "Offline")\(isCurrent ? " · This device" : "")")
                        .font(.footnote).foregroundStyle(device.online ? .secondary : .tertiary)
                    if device.revoked {
                        Text("Installation revoked.").font(.caption).foregroundStyle(.secondary)
                            .accessibilityIdentifier("morde.hub.revokedDevice")
                    }
                }
                Spacer()
                if client.hubRelayWorkingID == device.id { ProgressView() }
            }
            if client.hubAvailable == true && !isCurrent && device.online && !device.revoked {
                Button("Open link on this device") {
                    relayConfirmationDevice = device
                }
                .accessibilityIdentifier("morde.hub.open.request")
                .disabled(!relayURLIsValid || client.hubRelayWorkingID != nil)
            }
        }
    }

    @ViewBuilder
    private func installationRow(_ installation: MordeClientInstallation) -> some View {
        let isCurrent = installation.id == client.currentClientInstallationID
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(installation.display_name).font(.headline)
                    Text(installation.id)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                Spacer(minLength: 8)
                if isCurrent {
                    Text("Current device")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                if installation.revoked {
                    Text("Installation revoked.").font(.footnote).foregroundStyle(.secondary)
                } else if isCurrent {
                    Text("This is the current device. To revoke it, sign out of this account.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if MordeClientInstallationPolicy.revokePath(
                    for: installation.id, currentInstallationID: client.currentClientInstallationID) != nil,
                   !installation.revoked {
                    if client.revokingClientInstallationID == installation.id {
                        ProgressView()
                    } else {
                        Button("Revoke", role: .destructive) {
                            revokeTarget = installation
                            confirmsRevoke = true
                        }
                        .disabled(client.revokingClientInstallationID != nil)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/// The main chat surface used by NanoMuse's four-tab shell. Task progress and controls stay
/// beside their conversation without adding another root tab.
public struct MordeConversationRoom: View {
    private let bottomOverlay: CGFloat
    public init(bottomOverlay: CGFloat = 0) { self.bottomOverlay = bottomOverlay }

    public var body: some View {
        MordeClientContainer(layout: .conversation, ownsLifecycle: true, bottomOverlay: bottomOverlay)
    }
}

// nanoMuse: expose the existing, ticket-backed Host flow from the four-tab Resource Library.
public struct MordeComputerRoom: View {
    public init() {}

    public var body: some View {
        MordeClientContainer(layout: .computers, ownsLifecycle: true)
    }
}

private enum MIFResourceSheetDestination: Identifiable, Equatable {
    case host(URL)
    case library

    var id: String {
        switch self {
        case .host(let url): return "host:\(url.absoluteString)"
        case .library: return "library"
        }
    }
}

/// The Morde resource room hosted inside nanoMuse's existing four-tab shell.
struct MIFResourcesRoot: View {
    private let chrome: NanoMuseRoomChrome?
    private let onMenu: (() -> Void)?
    private let onOpenHost: ((MIFResourcePageState.Host) -> Void)?
    @StateObject private var store = MIFResourcePageStore.shared
    @State private var workspaceFilesID: String?
    @State private var libraryPresented = false

    init(chrome: NanoMuseRoomChrome? = nil, onMenu: (() -> Void)? = nil,
         onOpenHost: ((MIFResourcePageState.Host) -> Void)? = nil) {
        self.chrome = chrome
        self.onMenu = onMenu
        self.onOpenHost = onOpenHost
    }

    private var workspaceNavigationPresented: Binding<Bool> {
        Binding(get: { workspaceFilesID != nil }, set: { if !$0 { workspaceFilesID = nil } })
    }

    private var sheetDestination: Binding<MIFResourceSheetDestination?> {
        Binding(
            get: {
                if let url = store.hostURL { return .host(url) }
                return libraryPresented ? .library : nil
            },
            set: { value in
                guard value == nil else { return }
                store.dismissHost()
                workspaceFilesID = nil
                libraryPresented = false
            })
    }

    var body: some View {
        MIFResourceRoom(chrome: chrome, onMenu: onMenu, state: store.state, actions: MIFResourcePageActions(
            refresh: { Task { await store.refresh() } },
            openLibrary: { libraryPresented = true },
            openHost: { host in
                if let onOpenHost { onOpenHost(host) }
                else { Task { await store.openHost(host.id) } }
            },
            refreshControl: { id in Task { await store.refreshControl(id) } },
            control: { id, action in Task { await store.control(id, action: action) } },
            openWorkspaceFiles: { workspaceFilesID = $0 }))
            .task(id: store.scopeKey) { await store.loadIfNeeded() }
            .navigationDestination(isPresented: workspaceNavigationPresented) {
                if let id = workspaceFilesID {
                    MordeWorkspaceFilesView(initialWorkspaceID: id)
                }
            }
            .sheet(item: sheetDestination) { destination in
                switch destination {
                case .host(let url):
                    MordeHostView(url: url)
                case .library:
                    NavigationStack {
                        MIFLibraryRoot(onMenu: onMenu, personalDataRoot: MordePersonalStorage.root)
                            .navigationTitle(AppLocalized("Library"))
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button { libraryPresented = false } label: {
                                        Text(AppLocalized("Done")).font(.body.weight(.medium))
                                    }
                                    .tint(NanoMuseTones.action)
                                }
                            }
                }
            }
        }
    }
}

private enum MordeRootLayout: Equatable {
    case full
    case conversation
    case computers
}

private struct MordeClientContainer: View {
    let layout: MordeRootLayout
    let ownsLifecycle: Bool
    var bottomOverlay: CGFloat = 0
    @StateObject private var client = MordeClient.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        MordeRoot(client: client, layout: layout, bottomOverlay: bottomOverlay)
            .task {
                guard ownsLifecycle else { return }
                client.refreshExpiredAuthorization()
                await client.load()
            }
            .task {
                guard ownsLifecycle else { return }
                while !Task.isCancelled {
                    let seconds = min(max(client.authorizationExpiryDelay() ?? 30, 0.05), 30)
                    try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                    if Task.isCancelled { break }
                    client.refreshExpiredAuthorization()
                }
            }
            .task(id: ownsLifecycle ? client.currentTask?.id : nil) {
                guard ownsLifecycle, layout != .computers else { return }
                await client.watchCurrentTask()
            }
            .nmOnChange(of: scenePhase) { phase in
                if ownsLifecycle, phase == .active {
                    Task {
                        client.refreshExpiredAuthorization()
                        await client.load()
                    }
                }
            }
    }
}

private enum MordeAuthField: Hashable {
    case username, password, confirmation
}

private struct MordeRoot: View {
    @ObservedObject var client: MordeClient
    @ObservedObject private var authorization = MordeShellAuthorization.shared
    @ObservedObject private var personal = NanoMuseMordePersonalContentStore.shared
    @ObservedObject private var conversationDrawer = MIFConversationDrawerStore.shared
    let layout: MordeRootLayout
    let bottomOverlay: CGFloat
    @StateObject private var taskSpeech = SpeechRecognitionManager()
    @State private var loginName = ""
    @State private var loginPassword = ""
    @State private var confirmationPassword = ""
    @State private var registrationMode = false
    @FocusState private var authFieldFocused: MordeAuthField?
    @State private var selectedTab = 0
    @State private var selectedDesignTab: MordeDesignTab = .chat
    @State private var selectedDesignRoute: MordeDesignRoute = .chat
    @State private var designNavigationPath: [MordeDesignRoute] = []
    @State private var drawerSearchText = ""
    // nanoMuse: Preserve a last-row appearance that precedes its page cursor.
    @State private var drawerPaginationPendingConversationID: String?
    @State private var approvalCount: Int?
    @State private var eventChainTaskID: String?
    @State private var confirmsSignOut = false
    @State private var hostToRestore: MordeHost?
    @State private var resourceSection = MordeResourceRoomSection.computers
    @State private var host = ""
    @State private var workspace = ""
    @State private var model = ""
    @State private var draft = ""
    @State private var draftConversationKey: String?
    @State private var conversationDrafts: [String: String] = [:]
    @State private var composerColumnHeight: CGFloat = 0
    @State private var taskOptionsPresented = false
    @FocusState private var taskDraftFocused: Bool
    @State private var taskSpeechStarting = false
    @State private var taskSpeechStartAttempt = UUID()
    @State private var showChatAttachmentImporter = false
    @State private var isUploadingChatAttachments = false
    @State private var pendingChatAttachments: [MordeChatAttachment] = []
    @State private var chatAttachmentDrafts: [String: [MordeChatAttachment]] = [:]
    @State private var chatAttachmentPreviewItem: MIFPersonalAttachmentPreviewItem?
    @State private var chatAttachmentPreviewDownload: MordePersonalAttachmentDownload?
    @State private var chatAttachmentPreviewTask: Task<Void, Never>?
    @State private var chatAttachmentPreviewRequestID: UUID?
#if DEBUG
    @State private var localChatAttachmentFixtureStarted = false
#endif
    private var selectedHost: MordeHost? { client.hosts.first(where: { $0.id == host }) }
    private var workspaceBindings: [MordeWorkspaceBinding] { client.workspaceBindings(for: host) }
    private var selectedBinding: MordeWorkspaceBinding? {
        workspaceBindings.first(where: { $0.workspace.id == workspace })
    }
    private var selectedHostReady: Bool { selectedHost.map(client.isReady) ?? false }
    private var targetUnavailable: Bool { client.targetIsUnavailable(hostID: host, workspaceID: workspace) }
    private var allowedTextModelIDs: Set<String> {
        Set(client.models.map(\.id))
    }
    private var selectedTextModelReady: Bool {
        guard client.defaultModelConfigured else { return false }
        return MordeTaskModelSelection.canSubmit(modelID: model, resourceState: client.resourceState(.models),
                                                 allowedModelIDs: allowedTextModelIDs)
    }
    private var activeConversationDraftKey: String? {
        guard let scope = client.taskPageScopeKey, let conversationID = client.currentConversation else { return nil }
        return "\(scope):\(conversationID)"
    }
    private func clearComposer() {
        taskSpeechStartAttempt = UUID()
        taskSpeechStarting = false
        if taskSpeech.state == .recording { taskSpeech.stopRecording() }
        taskSpeech.recognizedText = ""
        host = ""; workspace = ""; model = ""; draft = ""; selectedTab = 0
        draftConversationKey = nil
        conversationDrafts.removeAll()
        pendingChatAttachments = []
        chatAttachmentDrafts.removeAll()
        composerColumnHeight = 0
        taskOptionsPresented = false
    }

    private struct MordeChatAttachmentPreviewTarget: Equatable, Sendable {
        let objectID: String
        let attachmentID: String
        let name: String
        let mediaType: String
        let scopeKey: String
    }

    private func chatAttachmentPreviewTarget(_ attachmentID: String) -> MordeChatAttachmentPreviewTarget? {
        guard authorization.signedIn, personal.syncEnabled, !personal.isLoading, personal.error == nil,
              let scope = authorization.personalDataScopeKey,
              MordePersonalDataContract.isValidAttachmentID(attachmentID) else { return nil }
        for object in personal.values("library_item") {
            guard let body = try? object.decodeBody(NanoMuseMordeLibraryItemBody.self), body.isValid,
                  body.attachment_id == attachmentID,
                  let mediaType = MIFLibraryPreviewPolicy.normalizedPersonalAttachmentMediaType(body.mime) else {
                continue
            }
            return MordeChatAttachmentPreviewTarget(objectID: object.object_id, attachmentID: attachmentID,
                                                     name: body.name, mediaType: mediaType, scopeKey: scope)
        }
        return nil
    }

    private func chatAttachmentPreviewTargetIsCurrent(_ target: MordeChatAttachmentPreviewTarget) -> Bool {
        guard authorization.signedIn, authorization.personalDataScopeKey == target.scopeKey,
              personal.syncEnabled, !personal.isLoading, personal.error == nil else { return false }
        return personal.values("library_item").contains { object in
            guard object.object_id == target.objectID,
                  let body = try? object.decodeBody(NanoMuseMordeLibraryItemBody.self), body.isValid else { return false }
            return body.name == target.name && body.attachment_id == target.attachmentID &&
                MIFLibraryPreviewPolicy.normalizedPersonalAttachmentMediaType(body.mime) == target.mediaType
        }
    }

    private func previewChatAttachment(_ attachmentID: String) {
        clearChatAttachmentPreview()
        guard let target = chatAttachmentPreviewTarget(attachmentID) else {
            client.error = AppLocalized("Artifact details unavailable")
            return
        }
        let requestID = UUID()
        chatAttachmentPreviewRequestID = requestID
        chatAttachmentPreviewTask = Task { @MainActor in
            do {
                let downloaded = try await authorization.downloadPersonalAttachment(attachmentID: target.attachmentID)
                guard !Task.isCancelled,
                      chatAttachmentPreviewRequestID == requestID,
                      downloaded.attachmentID == target.attachmentID,
                      MIFLibraryPreviewPolicy.normalizedPersonalAttachmentMediaType(downloaded.mediaType) == target.mediaType,
                      chatAttachmentPreviewTargetIsCurrent(target) else {
                    MIFLibraryTemporaryFileCleanup.discard(downloaded.fileURL)
                    return
                }
                chatAttachmentPreviewDownload = downloaded
                chatAttachmentPreviewRequestID = nil
                chatAttachmentPreviewTask = nil
                chatAttachmentPreviewItem = MIFPersonalAttachmentPreviewItem(
                    fileURL: downloaded.fileURL, name: target.name, mediaType: target.mediaType)
            } catch {
                guard chatAttachmentPreviewRequestID == requestID else { return }
                chatAttachmentPreviewRequestID = nil
                chatAttachmentPreviewTask = nil
                client.error = AppLocalized("Artifact details unavailable")
            }
        }
    }

    private func clearChatAttachmentPreview() {
        chatAttachmentPreviewTask?.cancel()
        chatAttachmentPreviewTask = nil
        chatAttachmentPreviewRequestID = nil
        chatAttachmentPreviewItem = nil
        if let downloaded = chatAttachmentPreviewDownload {
            MIFLibraryTemporaryFileCleanup.discard(downloaded.fileURL)
            chatAttachmentPreviewDownload = nil
        }
    }

    private func chatAttachmentPreviewDismissed() {
        if let downloaded = chatAttachmentPreviewDownload {
            MIFLibraryTemporaryFileCleanup.discard(downloaded.fileURL)
            chatAttachmentPreviewDownload = nil
        }
    }

    private func selectDraftConversation(_ key: String?) {
        guard key != draftConversationKey else { return }
        if let draftConversationKey {
            conversationDrafts[draftConversationKey] = draft
            chatAttachmentDrafts[draftConversationKey] = pendingChatAttachments
        }
        taskDraftFocused = false
        draftConversationKey = key
        draft = key.flatMap { conversationDrafts[$0] } ?? ""
        pendingChatAttachments = key.flatMap { chatAttachmentDrafts[$0] } ?? []
    }
    private func saveConversationDraft() {
        if let draftConversationKey {
            conversationDrafts[draftConversationKey] = draft
            chatAttachmentDrafts[draftConversationKey] = pendingChatAttachments
        }
    }
#if DEBUG && !MORDE_STANDALONE
    private func seedLocalHistoryFixtureIfRequested() async {
        guard ProcessInfo.processInfo.arguments.contains(MordeAuthURLProtocol.localHistoryFixtureLaunchArgument) else { return }
        let store = ChatStore.shared
        let sessions = await store.listSessions()
        if !sessions.contains(where: { $0.source == "morde-local-history-fixture" }) {
            let session = await store.createSession(
                modelId: "local-fixture", title: "Local archived conversation", source: "morde-local-history-fixture")
            let now = Date()
            await store.appendMessage(RawMessage(
                id: UUID().uuidString, sessionId: session.id, role: .user,
                parts: [.text("Local archive message")], createdAt: now))
            await store.appendMessage(RawMessage(
                id: UUID().uuidString, sessionId: session.id, role: .assistant,
                parts: [.text("Local archive reply")], createdAt: now.addingTimeInterval(1)))
        }
        guard ProcessInfo.processInfo.arguments.contains(MordeAuthURLProtocol.historyImportFixtureLaunchArgument),
              !sessions.contains(where: { $0.source == "morde-local-history-import-fixture-v1" }) else { return }
        let importSession = await store.createSession(
            modelId: "local-fixture", title: "Local import fixture conversation",
            source: "morde-local-history-import-fixture-v1")
        let now = Date()
        await store.appendMessage(RawMessage(
            id: "local-import-user-1", sessionId: importSession.id, role: .user,
            parts: [.text("Local import message"), .mediaRef(MediaRef(
                id: "local-media-1", relativePath: "fixtures/private.png", mimeType: "image/png",
                originalFileName: "private.png"))], createdAt: now))
        await store.appendMessage(RawMessage(
            id: "local-import-assistant-1", sessionId: importSession.id, role: .assistant,
            parts: [.text("Local import reply"), .toolUse(ToolUse(
                toolUseId: "tool-1", name: "local_tool", input: "private tool input",
                description: nil, thoughtSignature: nil))],
            createdAt: now.addingTimeInterval(1), reasoningContent: "Private reasoning must stay on device"))
        await store.appendMessage(RawMessage(
            id: "local-import-tool-result-1", sessionId: importSession.id, role: .user,
            parts: [.toolResult(ToolResult(toolUseId: "tool-1", output: "Private tool output",
                success: true, mediaRef: nil, snapshot: nil, pageURL: nil, status: "success"))],
            createdAt: now.addingTimeInterval(2)))
    }
#endif
    private func appendTaskSpeechTranscript() {
        let transcript = taskSpeech.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        taskSpeech.recognizedText = ""
        guard !transcript.isEmpty else { return }
        let existing = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        draft = existing.isEmpty ? transcript : "\(existing)\n\(transcript)"
    }
    private func stopTaskSpeechInput() {
        taskSpeechStartAttempt = UUID()
        taskSpeechStarting = false
        if taskSpeech.state == .recording { taskSpeech.stopRecording() }
        appendTaskSpeechTranscript()
    }
    private func toggleTaskSpeechInput() {
        if taskSpeech.state == .recording {
            stopTaskSpeechInput()
            return
        }
        guard !taskSpeechStarting else { return }
        guard MordeTaskSpeechInputPolicy.onDeviceRequirement(
            forced: true, supported: taskSpeech.supportsOnDeviceRecognition
        ) != nil else {
            client.error = String(localized: "On-device speech recognition is unavailable for the selected language.")
            return
        }
        taskSpeechStarting = true
        let attempt = UUID()
        taskSpeechStartAttempt = attempt
        Task { @MainActor in
            defer {
                if taskSpeechStartAttempt == attempt { taskSpeechStarting = false }
            }
            guard await taskSpeech.requestPermissions() else {
                guard taskSpeechStartAttempt == attempt else { return }
                client.error = String(localized: "Voice input needs speech recognition and microphone access.")
                return
            }
            guard taskSpeechStartAttempt == attempt else { return }
            taskSpeech.recognizedText = ""
            do {
                try taskSpeech.startRecording(requiringOnDeviceRecognition: true)
            } catch {
                client.error = error.localizedDescription
            }
        }
    }
    private func notificationTitle(_ notice: MordeNotification) -> String {
        NSLocalizedString(MordeTaskStatusPresentation.notificationLocalizationKey(kind: notice.kind),
                         comment: "Task notification category")
    }
    private func openNotification(_ notice: MordeNotification) {
        Task { if await client.openNotification(notice) { selectedTab = 0 } }
    }
    private func handleNewConversationRequest(_ note: Notification) {
        guard layout == .conversation else { return }
        let shouldFocusComposer = note.userInfo?["focusComposer"] as? Bool == true
        Task {
            await client.startNewConversation()
            selectDraftConversation(activeConversationDraftKey)
            draft = ""
            saveConversationDraft()
            selectedTab = 0
            if shouldFocusComposer { taskDraftFocused = true }
        }
    }
    private func handleShellPrompt(_ note: Notification) {
        guard layout == .conversation,
              let text = note.userInfo?["text"] as? String,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        Task {
            if note.userInfo?["newConversation"] as? Bool == true { await client.startNewConversation() }
            selectDraftConversation(activeConversationDraftKey)
            // nanoMuse: Prompt notifications prefill the draft; the person still submits explicitly.
            draft = text
            saveConversationDraft()
            selectedTab = 0
        }
    }
    private func submitChatDraft(queueingTask: MordeTask? = nil) {
        guard queueingTask == nil ? canSendChatDraft : canEnqueueChatDraft else { return }
        let attachmentIDs = pendingChatAttachments.flatMap(\.allAttachmentIDs).sorted()
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = trimmed.isEmpty && !attachmentIDs.isEmpty ? "请读取并处理我附加的文件。" : draft
        let conversationID = client.currentConversation
        let draftKey = draftConversationKey
        guard conversationID != nil, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        Task { @MainActor in
            guard client.currentConversation == conversationID, draftConversationKey == draftKey else { return }
            if await client.send(text, host: host, workspace: workspace, model: model,
                                 attachmentIDs: attachmentIDs, queueingTask: queueingTask),
               client.currentConversation == conversationID, draftConversationKey == draftKey {
                draft = ""
                pendingChatAttachments = []
                saveConversationDraft()
            }
        }
    }
    private func submitOrQueueChatDraft() {
        if canEnqueueChatDraft, let task = currentConversationTask {
            submitChatDraft(queueingTask: task)
        } else {
            submitChatDraft()
        }
    }
    private func stopCurrentChatTask() {
        guard let task = currentConversationTask, ["queued", "running"].contains(task.status) else { return }
        Task { @MainActor in
            guard client.currentConversation == task.conversation_id, client.currentTask?.id == task.id else { return }
            _ = await client.act(["action": "cancel", "expected_status": task.status])
        }
    }
    private var currentConversationTask: MordeTask? {
        guard let task = client.currentTask,
              MordeConversationTaskState.belongs(taskConversationID: task.conversation_id,
                                                 toSelectedConversationID: client.currentConversation) else { return nil }
        return task
    }
    private var hasActiveConversationTask: Bool {
        guard let task = currentConversationTask else { return false }
        return ["queued", "running", "waiting_user", "pausing", "paused", "cancelling"].contains(task.status)
    }
    private var isGeneratingConversationTask: Bool {
        guard !client.busy else { return false }
        guard let task = currentConversationTask else { return false }
        return ["queued", "running"].contains(task.status)
    }
    private func handleTaskOptionsRequest() {
        guard layout != .computers else { return }
        taskOptionsPresented = true
    }
    private func handleChatAttachmentRequest() {
        guard layout != .computers, !isUploadingChatAttachments else { return }
        showChatAttachmentImporter = true
    }
    @MainActor
    private func importChatAttachments(_ result: Result<[URL], Error>) async {
        switch result {
        case .failure(let error):
            if !(error is CancellationError) { client.error = error.localizedDescription }
        case .success(let urls):
            guard !urls.isEmpty else { return }
            guard let conversationID = client.currentConversation else {
                client.error = "请先选择或新建一个云端会话，再添加附件。"
                return
            }
            let existingIDs = pendingChatAttachments.reduce(0) { $0 + $1.allAttachmentIDs.count }
            guard existingIDs + urls.count <= 16 else {
                client.error = "一条消息最多附加 16 项；PDF 会额外生成文本和最多 10 页预览。"
                return
            }
            isUploadingChatAttachments = true
            defer { isUploadingChatAttachments = false }
            let prepared: [MordePreparedChatAttachment]
            do {
                prepared = try await Task.detached(priority: .userInitiated) {
                    var items: [MordePreparedChatAttachment] = []
                    do {
                        for url in urls {
                            let item = try MordeChatAttachmentPreparation.prepare(url)
                            items.append(item)
                            guard existingIDs + items.reduce(0, { $0 + $1.files.count }) <= 16 else {
                                throw NSError(domain: "Morde", code: 413,
                                    userInfo: [NSLocalizedDescriptionKey: "图片与 PDF 处理结果合计最多附加 16 项；PDF 会额外生成文本和最多 10 页预览。"])
                            }
                        }
                        return items
                    } catch {
                        items.forEach { $0.discardTemporaryFiles() }
                        throw error
                    }
                }.value
            } catch {
                client.error = error.localizedDescription
                return
            }
            defer { prepared.forEach { $0.discardTemporaryFiles() } }
            for item in prepared where !Task.isCancelled {
                do {
                    var uploaded: [MordeChatAttachment] = []
                    for file in item.files {
                        uploaded.append(try await uploadChatAttachment(from: file.url, conversationID: conversationID))
                    }
                    guard let primary = uploaded.first else { continue }
                    let attachment = MordeChatAttachment(attachmentID: primary.attachmentID,
                        additionalAttachmentIDs: uploaded.dropFirst().map(\.attachmentID), name: item.name,
                        mediaType: primary.mediaType, sizeBytes: primary.sizeBytes)
                    guard client.currentConversation == conversationID else { return }
                    if !pendingChatAttachments.contains(where: { $0.attachmentID == attachment.attachmentID }) {
                        pendingChatAttachments.append(attachment)
                        saveConversationDraft()
                    }
                } catch {
                    client.error = error.localizedDescription
                    return
                }
            }
        }
    }
    @MainActor
    private func uploadChatAttachment(from sourceURL: URL, conversationID: String) async throws -> MordeChatAttachment {
        let authorization = MordeShellAuthorization.shared
        guard authorization.signedIn, let scope = authorization.personalDataScopeKey,
              client.currentConversation == conversationID else { throw URLError(.userAuthenticationRequired) }
        let personal = NanoMuseMordePersonalContentStore.shared
        await personal.refresh(root: MordePersonalStorage.root)
        guard authorization.personalDataScopeKey == scope, personal.syncEnabled else {
            throw NSError(domain: "Morde", code: 403,
                          userInfo: [NSLocalizedDescriptionKey: "请登录并启用个人同步后再添加聊天附件。"])
        }
        let name = sourceURL.lastPathComponent
        guard !name.isEmpty, name.unicodeScalars.count <= 255,
              !name.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains) else {
            throw NSError(domain: "Morde", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "附件文件名无效或过长。"])
        }
        let mediaType = UTType(filenameExtension: sourceURL.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
        guard ["image/jpeg", "application/pdf", "text/plain"].contains(mediaType) else {
            throw NSError(domain: "Morde", code: 415,
                          userInfo: [NSLocalizedDescriptionKey: "聊天附件处理后仅支持 JPEG、PDF 与 PDF 提取文本。"])
        }
        let digest = try await Task.detached(priority: .utility) {
            try withMordeSecurityScope(sourceURL) { try MordePersonalAttachmentHash.measure(fileURL: sourceURL) }
        }.value
        let quota = try await authorization.personalDataQuota()
        guard authorization.personalDataScopeKey == scope, digest.sizeBytes <= quota.max_attachment_bytes else {
            throw NSError(domain: "Morde", code: 413,
                          userInfo: [NSLocalizedDescriptionKey: "附件超过当前账号允许的上传大小。"])
        }
        let identity = SHA256.hash(data: Data((scope + "\u{0}" + name + "\u{0}" + digest.sha256).utf8))
            .map { String(format: "%02x", $0) }.joined()
        let objectID = "li_" + String(identity.prefix(40))
        let existing = personal.object("library_item", objectID)
        let baseRevision: Int64
        if let existing {
            guard let body = try? existing.decodeBody(NanoMuseMordeLibraryItemBody.self), body.isValid,
                  body.name == name, body.mime == mediaType, body.size_bytes == digest.sizeBytes else {
                throw NSError(domain: "Morde", code: 409,
                              userInfo: [NSLocalizedDescriptionKey: "此附件的文件信息与已有文件库记录冲突。"])
            }
            if let attachmentID = body.attachment_id {
                return MordeChatAttachment(attachmentID: attachmentID, additionalAttachmentIDs: [], name: name,
                                           mediaType: mediaType, sizeBytes: digest.sizeBytes)
            }
            baseRevision = existing.revision
        } else {
            let body = NanoMuseMordeLibraryItemBody(name: name,
                kind: UTType(mimeType: mediaType)?.conforms(to: .image) == true ? "media" : "artifact",
                mime: mediaType, size_bytes: digest.sizeBytes, attachment_id: nil)
            guard let revision = try await personal.replace("library_item", id: objectID, revision: 0,
                                                            body: body, root: MordePersonalStorage.root) else {
                throw NSError(domain: "Morde", code: 409,
                              userInfo: [NSLocalizedDescriptionKey: "文件库记录正在等待同步，请完成同步后重试。"])
            }
            baseRevision = revision
        }
        guard authorization.personalDataScopeKey == scope else { throw URLError(.userAuthenticationRequired) }
        let personalDataRoot = MordePersonalStorage.root
        let staged = try await Task.detached(priority: .utility) {
            try withMordeSecurityScope(sourceURL) {
                try NanoMuseMordePersonalAttachmentStaging.stage(sourceURL: sourceURL,
                    expectedSizeBytes: digest.sizeBytes, expectedSHA256: digest.sha256,
                    maxBytes: quota.max_attachment_bytes, root: personalDataRoot)
            }
        }.value
        defer { NanoMuseMordePersonalAttachmentStaging.discard(staged) }
        guard authorization.personalDataScopeKey == scope, client.currentConversation == conversationID else {
            throw URLError(.userAuthenticationRequired)
        }
        let receipt = try await authorization.uploadPersonalAttachment(objectID: objectID,
            baseRevision: baseRevision, fileURL: staged.fileURL, sizeBytes: staged.sizeBytes,
            sha256: staged.sha256, mediaType: mediaType, idempotencyKey: "chat-library-upload-\(objectID)")
        guard authorization.personalDataScopeKey == scope, client.currentConversation == conversationID,
              MordePersonalDataContract.isValidAttachmentID(receipt.attachment_id) else {
            throw URLError(.cannotParseResponse)
        }
        await personal.refresh(root: MordePersonalStorage.root)
        return MordeChatAttachment(attachmentID: receipt.attachment_id, additionalAttachmentIDs: [], name: name,
                                   mediaType: mediaType, sizeBytes: digest.sizeBytes)
    }
    private func conversationChanged(_ _: String?) {
        clearChatAttachmentPreview()
        selectDraftConversation(activeConversationDraftKey)
        startLocalChatAttachmentFixtureIfNeeded()
    }
    private func conversationScopeChanged(_ _: String?) {
        selectDraftConversation(activeConversationDraftKey)
    }
    private func announceTaskStatus(_ status: String?) {
        guard let status, UIAccessibility.isVoiceOverRunning else { return }
        UIAccessibility.post(notification: .announcement,
                             argument: String(format: NSLocalizedString(
                                "Task status: %@", comment: "VoiceOver announcement for task status changes"), status))
    }
    private func setErrorAlertPresented(_ presented: Bool) {
        guard !presented, let dismissedError = client.error else { return }
        Task { @MainActor [client, dismissedError] in
            if client.error == dismissedError { client.error = nil }
        }
    }
    private var errorAlertPresented: Binding<Bool> {
        Binding(get: { client.error != nil }, set: setErrorAlertPresented)
    }
    private var hostSheetItem: Binding<MordeHostURL?> {
        Binding(get: {
            guard layout == .computers else { return nil }
            return client.hostURL.map(MordeHostURL.init)
        }, set: { item in
            if item == nil { client.hostURL = nil }
        })
    }
    private func signedInChanged(_ signedIn: Bool) {
        if !signedIn {
            clearComposer()
            clearChatAttachmentPreview()
            selectedDesignTab = .chat
            selectedDesignRoute = .chat
            designNavigationPath = []
        }
        else { startLocalChatAttachmentFixtureIfNeeded() }
    }
#if DEBUG
    private func startLocalChatAttachmentFixtureIfNeeded() {
        let conversationID = ProcessInfo.processInfo.arguments.contains(MordeAuthURLProtocol.accountIsolationFixtureLaunchArgument)
            ? "c0000001" : "c1234567"
        guard ProcessInfo.processInfo.arguments.contains(MordeAuthURLProtocol.chatAttachmentFixtureLaunchArgument),
              MordeShellAuthorization.shared.signedIn, client.currentConversation == conversationID,
              !ProcessInfo.processInfo.arguments.contains(MordeAuthURLProtocol.accountIsolationFixtureLaunchArgument) ||
                client.user?.id == "u_accounta1",
              !localChatAttachmentFixtureStarted else { return }
        do {
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("morde-chat-fixture-\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let imageURL = directory.appendingPathComponent("fixture-image.png")
            let image = UIGraphicsImageRenderer(size: CGSize(width: 64, height: 64)).image { context in
                UIColor.systemOrange.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
            }
            guard let imageData = image.pngData() else {
                throw NSError(domain: "Morde", code: 500,
                              userInfo: [NSLocalizedDescriptionKey: "Unable to generate the local image fixture."])
            }
            let inputURLs: [URL]
            if ProcessInfo.processInfo.arguments.contains(MordeAuthURLProtocol.chatAttachmentOverflowFixtureLaunchArgument) {
                var overflowURLs = try (0..<2).map { index in
                    let url = directory.appendingPathComponent("overflow-\(index).png")
                    try imageData.write(to: url)
                    return url
                }
                for index in 0..<5 {
                    let url = directory.appendingPathComponent("overflow-\(index).pdf")
                    let pdf = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 320, height: 200)).pdfData { context in
                        context.beginPage()
                        ("Morde PDF overflow fixture \(index)" as NSString).draw(at: CGPoint(x: 24, y: 32),
                            withAttributes: [.font: UIFont.systemFont(ofSize: 18)])
                    }
                    try pdf.write(to: url)
                    overflowURLs.append(url)
                }
                inputURLs = overflowURLs
            } else {
                try imageData.write(to: imageURL)
                let pdfURL = directory.appendingPathComponent("fixture.pdf")
                let pdf = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 320, height: 200)).pdfData { context in
                    context.beginPage()
                    ("Morde PDF fixture text" as NSString).draw(at: CGPoint(x: 24, y: 32),
                        withAttributes: [.font: UIFont.systemFont(ofSize: 18)])
                }
                try pdf.write(to: pdfURL)
                inputURLs = [imageURL, pdfURL]
            }
            localChatAttachmentFixtureStarted = true
            Task {
                await importChatAttachments(.success(inputURLs))
                try? FileManager.default.removeItem(at: directory)
            }
        } catch {
            client.error = error.localizedDescription
        }
    }
#else
    private func startLocalChatAttachmentFixtureIfNeeded() {}
#endif
    private func userIDChanged(_ _: String?) { clearComposer() }
    private func hostsChanged(_ state: MordeResourceLoadState?) {
        if state?.isLoaded != true { host = ""; workspace = "" }
    }
    private func workspacesChanged(_ state: MordeResourceLoadState?) {
        if state?.isLoaded != true { workspace = "" }
    }
    private func modelsChanged(_ state: MordeResourceLoadState?) {
        guard let state, state != .loading else { return }
        guard !MordeTaskModelSelection.canSubmit(modelID: model, resourceState: state,
                                                 allowedModelIDs: allowedTextModelIDs) else { return }
        model = client.defaultModelID ?? client.models.first?.id ?? ""
    }
    @ViewBuilder
    private func emptyResourceState(_ resource: MordeResource, itemCount: Int, emptyMessage: String) -> some View {
        let state = client.resourceState(resource)
        if let message = MordeResourcePresentation.emptyListMessage(
            resource: resource, state: state, itemCount: itemCount, emptyMessage: emptyMessage) {
            VStack(alignment: .leading, spacing: 6) {
                Text(message).font(.subheadline)
                    .foregroundStyle(state.isFailed ? Color.orange : Color.primary)
                if state.isFailed {
                    Button("重试读取") { Task { await client.load() } }
                }
            }
        }
    }
    private var conversationContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    if let failure = client.mainConversationLoadError {
                        Label(failure, systemImage: "exclamationmark.triangle")
                            .font(.footnote).foregroundStyle(.orange)
                        Button("重试读取") { Task { await client.load() } }
                    } else if client.currentConversation == nil {
                        VStack(spacing: 10) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 24)).foregroundStyle(NanoMuseTones.secondaryText)
                            Text("请从聊天抽屉选择或新建云端会话。")
                                .font(.subheadline).foregroundStyle(NanoMuseTones.secondaryText)
                        }
                        .frame(maxWidth: .infinity, minHeight: 150)
                    }
                    if client.currentConversation != nil {
                        let messageState = client.resourceState(.messages)
                        if let failure = messageState.failureMessage {
                            Text(failure).font(.subheadline).foregroundStyle(.orange)
                            Button("重试读取") { Task { await client.retryCurrentConversationMessages() } }
                                .accessibilityIdentifier("morde.chat.messages.retry")
                        } else if let emptyMessage = MordeResourcePresentation.emptyListMessage(
                            resource: .messages, state: messageState, itemCount: client.messages.count,
                            emptyMessage: "此对话暂无消息。") {
                            Text(emptyMessage).font(.subheadline)
                                .foregroundStyle(NanoMuseTones.secondaryText)
                        }
                        if let failure = client.messageHistoryError {
                            Text(failure).font(.footnote).foregroundStyle(.orange)
                            Button("重试读取") { Task { await client.loadEarlierMessages() } }
                                .accessibilityIdentifier("morde.chat.messages.retryEarlier")
                        } else if client.messageNextCursor != nil {
                            Button {
                                Task { await client.loadEarlierMessages() }
                            } label: {
                                HStack(spacing: 8) {
                                    if client.loadingEarlierMessages { ProgressView().controlSize(.small) }
                                    Text("Load earlier messages")
                                }
                            }
                            .disabled(client.loadingEarlierMessages)
                            .accessibilityIdentifier("morde.chat.messages.loadEarlier")
                        }
                        ForEach(client.messages) { message in
                            MIFMordeMessageBubble(message: message, onAttachmentPreview: previewChatAttachment)
                                .id(message.id)
                        }
                        if let task = client.currentTask,
                           MordeConversationTaskState.belongs(
                            taskConversationID: task.conversation_id,
                            toSelectedConversationID: client.currentConversation) {
                            conversationTaskCard(task)
                        }
                    }
                    Color.clear.frame(height: 1).id("morde.chat.latest")
                }
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, composerColumnHeight + bottomOverlay + 12)
            }
            .accessibilityIdentifier("morde.chat.transcript")
            .scrollDismissesKeyboard(.interactively)
            .background(ChatColors.background)
            .modifier(NanoMuseComposerHost(
                stack: AnyView(conversationComposerStack), popup: AnyView(EmptyView()),
                overlay: bottomOverlay, columnHeight: $composerColumnHeight, fade: false))
            .onChange(of: client.messages.last?.id) { _ in
                withAnimation(.easeOut(duration: 0.18)) { proxy.scrollTo("morde.chat.latest", anchor: .bottom) }
            }
        }
        .background(ChatColors.background.ignoresSafeArea())
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(AppLocalized("Done")) { taskDraftFocused = false }
                    .accessibilityIdentifier("morde.chat.keyboardDone")
            }
        }
        .nmOnChange(of: taskSpeech.state) { state in
            if state == .idle { appendTaskSpeechTranscript() }
        }
        .onDisappear { stopTaskSpeechInput() }
        .sheet(isPresented: $taskOptionsPresented) {
            NavigationStack {
                taskOptionsContent
                    .navigationTitle(AppLocalized("Task options"))
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(AppLocalized("Done")) { taskOptionsPresented = false }
                                .accessibilityIdentifier("morde.chat.taskOptions.done")
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var conversationComposerStack: some View {
        VStack(spacing: 8) {
            if isUploadingChatAttachments || !pendingChatAttachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        if isUploadingChatAttachments {
                            ProgressView().controlSize(.small)
                            Text(AppLocalized("Uploading attachments…"))
                                .font(.caption).foregroundStyle(NanoMuseTones.secondaryText)
                        }
                        ForEach(pendingChatAttachments) { attachment in
                            Label(attachment.name, systemImage: "paperclip")
                                .font(.caption)
                                .lineLimit(1)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 6)
                                .background(NanoMuseTones.surface, in: Capsule())
                                .contextMenu {
                                    Button(role: .destructive) {
                                        pendingChatAttachments.removeAll { $0.attachmentID == attachment.attachmentID }
                                        saveConversationDraft()
                                    } label: {
                                        Label(AppLocalized("Remove attachment"), systemImage: "xmark")
                                    }
                                }
                        }
                    }
                }
                .frame(maxWidth: 680, alignment: .leading)
                .padding(.horizontal, 20)
                .accessibilityIdentifier("morde.chat.attachments.pending")
            }
            NanoMuseComposerPill(
                hasContent: !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    !pendingChatAttachments.isEmpty,
                isProcessing: isGeneratingConversationTask,
                canSend: canSendChatDraft,
                canEnqueue: canEnqueueChatDraft,
                showsAttachments: false,
                showsMicrophone: false,
                sendAccessibilityIdentifier: "morde.task.send",
                onCamera: {}, onPhotos: {}, onFile: {}, onPasteImage: { _ in },
                onCommands: {}, onMic: { toggleTaskSpeechInput() }, onSend: submitOrQueueChatDraft,
                onEnqueue: { if let task = currentConversationTask { submitChatDraft(queueingTask: task) } },
                onStop: stopCurrentChatTask
            ) {
                TextField(AppLocalized("Message"), text: $draft)
                    .focused($taskDraftFocused)
                    .textFieldStyle(.plain)
                    .submitLabel(.send)
                    .onSubmit { submitOrQueueChatDraft() }
                    .accessibilityIdentifier("morde.chat.composer")
            }
            .padding(4)
            .background(NanoMuseTones.bubble, in: Capsule())
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
            .padding(.horizontal, 16)
            .frame(maxWidth: 680)

            if !selectedTextModelReady {
                Text(client.resourceState(.models).isLoaded && !client.defaultModelConfigured
                     ? "An administrator must configure a usable default model before cloud tasks can be sent."
                     : "发送前请在聊天菜单中选择任务模型。")
                    .font(.caption)
                    .foregroundStyle(NanoMuseTones.secondaryText)
            } else if taskSpeech.state == .recording, !taskSpeech.recognizedText.isEmpty {
                Text(taskSpeech.recognizedText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("morde.task.voiceTranscript")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
    }

    private var canSendChatDraft: Bool {
        !client.busy && !isUploadingChatAttachments && !hasActiveConversationTask &&
            !taskSpeechStarting && taskSpeech.state != .recording &&
            (!draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !pendingChatAttachments.isEmpty) &&
            selectedTextModelReady && !targetUnavailable && client.taskAPIAvailable == true
    }

    private var canEnqueueChatDraft: Bool {
        guard let task = currentConversationTask,
              !client.busy, isGeneratingConversationTask,
              !isUploadingChatAttachments, pendingChatAttachments.isEmpty,
              !taskSpeechStarting, taskSpeech.state != .recording,
              !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              selectedTextModelReady, !targetUnavailable, client.taskAPIAvailable == true,
              task.model_id == model,
              task.host_id == (host.isEmpty ? nil : host),
              task.workspace_id == (workspace.isEmpty ? nil : workspace),
              task.workspace_id == nil || task.input_revision != nil else { return false }
        return true
    }

    private func conversationTaskCard(_ task: MordeTask) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(AppLocalized("Task"), systemImage: "checklist")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(task.statusLabel)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Text(task.current_step ?? task.result ?? task.objective)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            NavigationLink {
                MIFTaskDetailView(taskID: task.id)
            } label: {
                Label(AppLocalized("Open task details and activity"),
                      systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.subheadline.weight(.medium))
            }
            .accessibilityIdentifier("morde.taskDetail.open")
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NanoMuseTones.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityIdentifier("morde.chat.taskSummary")
    }

    private var taskOptionsContent: some View {
        Form {
            Section("目标电脑") {
                emptyResourceState(.hosts, itemCount: client.hosts.count,
                                   emptyMessage: "当前没有可访问的电脑。可以不选电脑提交文本任务。")
                emptyResourceState(.workspaces, itemCount: client.workspaces.count,
                                   emptyMessage: "当前没有可访问的 Workspace。")
                Picker("目标电脑", selection: Binding(get: { host }, set: { value in
                    host = value
                    let bindings = client.workspaceBindings(for: value)
                    workspace = bindings.count == 1 ? bindings[0].workspace.id : ""
                })) {
                    Text("无电脑目标").tag("")
                    if !host.isEmpty && selectedHost == nil { Text("所选 Host 状态待核验").tag(host) }
                    ForEach(client.hosts) { item in
                        Text("\(item.name.isEmpty ? item.id : item.name) · \(MordeTaskTargetPresentation.hostState(item.state)) · \(MordeTaskTargetPresentation.hostControlState(item.control_state))")
                            .tag(item.id)
                    }
                }
                if let selectedHost {
                    Text("电脑状态：\(MordeTaskTargetPresentation.hostState(selectedHost.state)) · \(MordeTaskTargetPresentation.hostControlState(selectedHost.control_state))")
                        .font(.footnote).foregroundStyle(selectedHostReady ? Color.secondary : Color.orange)
                    if !selectedHostReady {
                        Text("所选电脑尚未运行并交由 AI 控制。本条消息不会提交到该电脑。")
                            .font(.footnote).foregroundStyle(.orange)
                    }
                    if workspaceBindings.count == 1 {
                        Picker("唯一 Workspace", selection: $workspace) {
                            Text("选择唯一 Workspace").tag("")
                            if !workspace.isEmpty && selectedBinding == nil { Text("所选 Workspace 状态待核验").tag(workspace) }
                            ForEach(workspaceBindings, id: \.workspace.id) { binding in
                                Text("\(binding.workspace.name.isEmpty ? binding.workspace.id : binding.workspace.name) · v\(binding.workspace.revision) · \(client.isReady(binding) ? "已就绪" : "未就绪")")
                                    .tag(binding.workspace.id)
                                    .disabled(!client.isReady(binding))
                            }
                        }.disabled(!selectedHostReady || client.busy)
                    } else {
                        Text("电脑必须恰好绑定一个 Workspace。当前读取到 \(workspaceBindings.count) 个，不能提交任务。")
                            .font(.footnote).foregroundStyle(.orange)
                    }
                    if !workspace.isEmpty && selectedBinding == nil {
                        Text(client.resourceState(.workspaces).failureMessage.map {
                            "Workspace 列表未成功读取：\($0)，本条消息不会提交。"
                        } ?? "所选 Workspace 已不在当前电脑的可访问列表中，本条消息不会提交。")
                            .font(.footnote).foregroundStyle(.orange)
                    } else if let selectedBinding, !client.isReady(selectedBinding) {
                        Text("所选 Workspace 尚未完成应用或同步，本条消息不会提交。")
                            .font(.footnote).foregroundStyle(.orange)
                    } else if let selectedBinding {
                        Text("本条消息固定使用 Workspace v\(selectedBinding.workspace.revision)。")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                } else if !host.isEmpty {
                    Text(client.resourceState(.hosts).failureMessage.map {
                        "电脑列表未成功读取：\($0)，本条消息不会提交。"
                    } ?? (client.resourceState(.hosts).isLoaded
                          ? "所选 Host 已不在当前可访问列表中，本条消息不会提交。"
                          : "正在核验所选 Host，本条消息暂不可提交。"))
                        .font(.footnote).foregroundStyle(.orange)
                }
            }
            Section("模型") {
                Picker("模型", selection: $model) {
                    Text("选择模型").tag("")
                    ForEach(client.models.filter { $0.capabilities.text && $0.capabilities.tools }) { item in
                        Text("\(item.name) · \(String(localized: item.id == client.defaultModelID ? "Administrator default" : "Personal model"))")
                            .tag(item.id)
                    }
                }
                .accessibilityIdentifier("morde.task.model")
                emptyResourceState(.models, itemCount: client.models.count,
                                   emptyMessage: "当前没有可用的文本工具模型。")
                if client.resourceState(.models).isLoaded && !client.defaultModelConfigured {
                    Text("An administrator must configure a usable default model before cloud tasks can be sent.")
                        .font(.footnote).foregroundStyle(.orange)
                }
                Text("目标和模型只影响后续提交；已受理 Task 的目标及输入版本保持固定。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
    // nanoMuse: keep Host access as a nested destination; it is not a new root tab.
    private var computerContent: some View {
        List {
            Section("我的电脑") {
                emptyResourceState(.hosts, itemCount: client.hosts.count,
                                   emptyMessage: "当前没有可访问的电脑。")
                ForEach(client.hosts) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        Button { Task { await client.openHost(item.id) } } label: {
                            VStack(alignment: .leading) {
                                Text(item.name.isEmpty ? item.id : item.name)
                                Text("\(MordeTaskTargetPresentation.hostState(item.state)) · \(MordeTaskTargetPresentation.hostControlState(item.control_state))")
                                    .font(.caption)
                                if item.state == "running" && !client.canOpenHost(item) {
                                    Text("绑定状态未就绪；需恰好一个可用 Workspace 才能打开")
                                        .font(.caption).foregroundStyle(.orange)
                                }
                            }
                        }.disabled(!client.canOpenHost(item))
                        if let error = client.hostOpenErrors[item.id] {
                            Text(error).font(.caption).foregroundStyle(.orange)
                        }
                        if item.state == "stopped" {
                            if client.canRestoreHost(item) {
                                Button(client.hostRestoreInFlightID == item.id ? "正在恢复…" : "恢复电脑") {
                                    hostToRestore = item
                                }
                                .disabled(client.hostRestoreInFlightID != nil)
                            } else {
                                Text("恢复前需要恰好一个已就绪的 Workspace 绑定。")
                                    .font(.caption).foregroundStyle(.orange)
                            }
                        }
                        hostControlPanel(item)
                    }
                    .padding(.vertical, 6)
                }
            }
            Section("Shared") {
                emptyResourceState(.sharedHosts, itemCount: client.sharedHosts.count,
                                   emptyMessage: "当前没有可访问的共享电脑。")
                ForEach(client.sharedHosts) { item in
                    Button { Task { await client.openHost(item.id, shared: true) } } label: {
                        VStack(alignment: .leading) {
                            Text(item.name.isEmpty ? item.id : item.name)
                            Text("共享 · 只读观察 · \(MordeTaskTargetPresentation.hostState(item.state)) · \(item.permissions.joined(separator: ", "))")
                                .font(.caption)
                            Text("当前操作者与控制租约状态尚未提供；本入口不授予操作权。")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }.disabled(item.state != "running" || !item.permissions.contains("desktop:view"))
                    if let error = client.hostOpenErrors[item.id] {
                        Text(error).font(.caption).foregroundStyle(.orange)
                    }
                }
            }
        }
        .navigationTitle(layout == .computers ? Text("Morde · Computers") : Text("Computers"))
        .task(id: "\(client.user?.id ?? "")|\(client.hosts.map(\.id).joined(separator: ","))") {
            await client.refreshHostControls()
        }
        .refreshable { await client.refreshHostControls() }
        .confirmationDialog("恢复电脑？", isPresented: Binding(
            get: { hostToRestore != nil }, set: { if !$0 { hostToRestore = nil } }), titleVisibility: .visible) {
            if let host = hostToRestore {
                Button("恢复并保留 Workspace") {
                    Task { await client.restoreHost(host.id) }
                    hostToRestore = nil
                }
            }
            Button("取消", role: .cancel) { hostToRestore = nil }
        } message: {
            Text("恢复会保留当前电脑 ID、Workspace 和运行数据，并轮换运行凭据。只有服务端确认成功后，状态才会更新。")
        }
    }

    @ViewBuilder
    private func hostControlPanel(_ host: MordeHost) -> some View {
        if host.owner_id == nil || host.owner_id != client.user?.id {
            Text("所有者未确认；控制状态和操作保持关闭。")
                .font(.caption).foregroundStyle(.secondary)
        } else if let status = client.hostControlStatuses[host.id] {
            let currentUserID = client.user?.id
            let transitioning = status.active_transition != nil
            VStack(alignment: .leading, spacing: 6) {
                Text("控制：\(MordeTaskTargetPresentation.hostControlState(status.control_state)) · v\(status.control_version)")
                    .font(.caption)
                if let actorID = status.control_actor_user_id {
                    Text(actorID.isEmpty ? "当前操作者：无" : "当前操作者 ID：\(actorID)")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if status.control_lease_active == true {
                    Text("控制租约至：\(status.control_lease_expires_at ?? "时间未知")")
                        .font(.caption).foregroundStyle(.secondary)
                } else if status.control_lease_active == false {
                    Text("当前没有活动的用户控制租约。")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("租约状态未知；控制操作已禁用。")
                        .font(.caption).foregroundStyle(.orange)
                }
                if let transition = status.active_transition {
                    Text("交接：\(transition.action) · \(transition.phase)\(transition.failure_reason.map { " · \($0)" } ?? "")")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if let error = client.hostControlErrors[host.id] {
                    Text(error).font(.caption).foregroundStyle(.orange)
                }
                HStack {
                    Button("刷新状态") { Task { await client.loadHostControl(host.id) } }
                    Spacer()
                    if host.state == "running" && MordeHostControlPolicy.canTakeOver(
                        state: status.control_state, actorID: status.control_actor_user_id,
                        leaseActive: status.control_lease_active, transitioning: transitioning) {
                        Button("接管控制") { Task { await client.takeOverHostControl(host.id) } }
                    }
                    if host.state == "running" && MordeHostControlPolicy.canRelease(
                        state: status.control_state, actorID: status.control_actor_user_id,
                        currentUserID: currentUserID, leaseActive: status.control_lease_active,
                        transitioning: transitioning) {
                        Button("交还给 AI") { Task { await client.releaseHostControl(host.id) } }
                    }
                    if host.state == "running" && MordeHostControlPolicy.canRenew(
                        state: status.control_state, actorID: status.control_actor_user_id,
                        currentUserID: currentUserID, leaseActive: status.control_lease_active,
                        transitioning: transitioning) {
                        Button("续租 30 秒") { Task { await client.renewHostControlLease(host.id) } }
                    }
                    if client.hostControlActionInFlightFor == host.id { ProgressView().controlSize(.small) }
                }
                .buttonStyle(.borderless)
                .disabled(client.hostControlActionInFlightFor != nil)
            }
        } else {
            HStack {
                if let error = client.hostControlErrors[host.id] {
                    Text("控制状态未能读取：\(error)").font(.caption).foregroundStyle(.orange)
                } else {
                    Text("正在读取控制状态…").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("重试") { Task { await client.loadHostControl(host.id) } }
                    .buttonStyle(.borderless)
            }
        }
    }

    private func notificationRow(_ item: MordeNotification) -> some View {
        Button { openNotification(item) } label: {
            VStack(alignment: .leading) {
                HStack {
                    Text(notificationTitle(item))
                    Spacer()
                    Text(item.read_at == nil ? "未读" : "已读")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Text(item.displaySummary).font(.caption)
            }
        }
    }

    private var notificationTab: some View {
        NavigationStack {
            List {
                emptyResourceState(.notifications, itemCount: client.notifications.count,
                                   emptyMessage: "当前没有通知。")
                ForEach(client.notifications) { item in notificationRow(item) }
                if client.notificationNextCursor != nil {
                    Button(client.loadingMoreNotifications ? "正在读取…" : "读取更多通知") {
                        Task { await client.loadMoreNotifications() }
                    }
                    .disabled(client.loadingMoreNotifications)
                }
            }.navigationTitle("通知")
            Button("退出登录", role: .destructive) { confirmsSignOut = true }
                .disabled(client.busy)
        }.tabItem { Label("通知", systemImage: "bell") }.tag(3)
    }

    private var resourceContent: some View {
        TabView(selection: $resourceSection) {
            computerContent
                .tabItem { Label(MordeResourceRoomSection.computers.title,
                                 systemImage: MordeResourceRoomSection.computers.symbol) }
                .tag(MordeResourceRoomSection.computers)
            workspaceContent
                .tabItem { Label(MordeResourceRoomSection.workspaces.title,
                                 systemImage: MordeResourceRoomSection.workspaces.symbol) }
                .tag(MordeResourceRoomSection.workspaces)
            workspaceFilesContent
                .tabItem { Label(MordeResourceRoomSection.files.title,
                                 systemImage: MordeResourceRoomSection.files.symbol) }
                .tag(MordeResourceRoomSection.files)
        }
    }

    private var workspaceContent: some View {
        List {
            Section("当前账号可访问的 Workspace") {
                emptyResourceState(.workspaces, itemCount: client.workspaces.count,
                                   emptyMessage: "当前账号没有可访问的 Workspace。")
                ForEach(client.workspaces) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                        Text("版本 \(item.revision) · 任务提交时会重新核验电脑绑定状态")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Section {
                Text("默认电脑与 Workspace 选择尚未接入。此页只读账号资源列表；会话目标只影响之后提交的消息，不会更改已受理任务。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Workspace")
    }

    private var workspaceFilesContent: some View {
        MordeWorkspaceFilesView()
    }
    private var designDrawerSections: [MordeDesignDrawerSection] {
        let conversations = conversationDrawer.conversations.filter { !$0.isMain }
        let conversationMessage = conversationDrawer.error ??
            (conversationDrawer.hasLoaded ? (conversations.isEmpty ? "暂无旁聊" : nil) : "正在加载旁聊…")
        return [
            MordeDesignDrawerSection(id: "tabs", title: "选项卡", hint: "你可以长按来重新排序", items: [
                MordeDesignDrawerItem(id: "chat", title: "主要聊天", systemImage: "bubble.left.and.bubble.right",
                                      route: .chat, isSelected: selectedDesignRoute.primaryTab == .chat),
                MordeDesignDrawerItem(id: "tasks", title: "任务", systemImage: "checkmark.square",
                                      route: .tasks, isSelected: selectedDesignRoute.primaryTab == .tasks),
                MordeDesignDrawerItem(id: "approvals", title: "审批", systemImage: "checkmark.shield",
                                      route: .approvals, badge: approvalCount, isSelected: selectedDesignRoute.primaryTab == .approvals),
                MordeDesignDrawerItem(id: "eventChain", title: "事件链", systemImage: "clock.arrow.circlepath",
                                      route: .eventChain, isSelected: selectedDesignRoute == .eventChain),
                MordeDesignDrawerItem(id: "resources", title: "资源", systemImage: "square.grid.2x2",
                                      route: .resources, isSelected: selectedDesignRoute.primaryTab == .resources),
                MordeDesignDrawerItem(id: "library", title: "文件库", systemImage: "folder",
                                      route: .library, isSelected: selectedDesignRoute == .library),
                MordeDesignDrawerItem(id: "workItems", title: "工作项", systemImage: "checklist",
                                      route: .workItems, isSelected: selectedDesignRoute == .workItems),
                MordeDesignDrawerItem(id: "friends", title: "好友", systemImage: "person.2",
                                      route: .friends, isSelected: selectedDesignRoute == .friends),
            ]),
            MordeDesignDrawerSection(id: "conversations", title: "旁聊",
                                     items: conversations.map {
                MordeDesignDrawerItem(id: "conversation-\($0.id)", title: $0.title,
                                      systemImage: "bubble.left", route: .chatConversation($0.id),
                                      isSelected: conversationDrawer.currentID == $0.id)
            }, emptyMessage: conversationMessage),
            MordeDesignDrawerSection(id: "toolChats", items: [
                MordeDesignDrawerItem(id: "toolChats", title: "AI 工具会话", systemImage: "sparkles",
                                      route: .toolChats, isSelected: selectedDesignRoute == .toolChats)
            ]),
        ]
    }

    private var designNavigation: some View {
        MordeDesignNavigationShell(
            selectedRoute: selectedDesignRoute,
            selectedTab: selectedDesignTab,
            approvalCount: approvalCount,
            drawerSections: designDrawerSections,
            footer: MordeDesignDrawerFooter(settingsTitle: "设置", searchPlaceholder: "搜索", newChatTitle: "新聊天"),
            searchText: $drawerSearchText,
            onSelectTab: { tab in
                designNavigationPath = []
                selectedDesignTab = tab
                selectedDesignRoute = tab.route
            },
            onSelectRoute: selectDesignRoute,
            onSettings: { selectDesignRoute(.settings) },
            onNewChat: createDesignConversation,
            onOpenDrawer: {
                if conversationDrawer.error != nil || !conversationDrawer.hasLoaded {
                    Task { await conversationDrawer.retry() }
                }
            },
            onDrawerItemAppear: { route in
                guard case .chatConversation(let id) = route,
                      conversationDrawer.conversations.last(where: { !$0.isMain })?.id == id else { return }
                guard conversationDrawer.nextCursor != nil else {
                    drawerPaginationPendingConversationID = id
                    return
                }
                guard !conversationDrawer.loadingMore else { return }
                drawerPaginationPendingConversationID = nil
                Task { await conversationDrawer.loadMore() }
            }
        ) { route, openDrawer in
            NavigationStack(path: $designNavigationPath) {
                designRouteContent(route, onMenu: openDrawer)
                    .navigationDestination(for: MordeDesignRoute.self) { nestedRoute in
                        designRouteContent(nestedRoute, onMenu: openDrawer)
                    }
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
        .nmOnChange(of: conversationDrawer.nextCursor) { cursor in
            guard cursor != nil,
                  let pendingID = drawerPaginationPendingConversationID,
                  conversationDrawer.conversations.last(where: { !$0.isMain })?.id == pendingID,
                  !conversationDrawer.loadingMore else { return }
            drawerPaginationPendingConversationID = nil
            Task { await conversationDrawer.loadMore() }
        }
        .safeAreaInset(edge: .top) {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                if let notice = client.expiryNotice(at: context.date) {
                    Text(notice).font(.headline).frame(maxWidth: .infinity)
                        .padding().background(Color.orange.opacity(0.25))
                }
            }
        }
    }

    private func selectDesignRoute(_ route: MordeDesignRoute) {
        designNavigationPath = []
        eventChainTaskID = nil
        if case .chatConversation(let id) = route {
            selectedDesignTab = .chat
            selectedDesignRoute = .chat
            Task { await conversationDrawer.choose(id) }
            return
        }
        selectedDesignRoute = route
        if let tab = route.primaryTab { selectedDesignTab = tab }
    }

    private func openEventChain(taskID: String) {
        selectDesignRoute(.eventChain)
        eventChainTaskID = taskID
    }

    private func createDesignConversation() {
        Task { @MainActor in
            await client.startNewConversation()
            selectDraftConversation(activeConversationDraftKey)
            draft = ""
            saveConversationDraft()
            selectedDesignTab = .chat
            selectedDesignRoute = .chat
            designNavigationPath = []
            taskDraftFocused = true
        }
    }

    @ViewBuilder
    private func designRouteContent(_ route: MordeDesignRoute, onMenu: @escaping () -> Void) -> some View {
        switch route {
        case .chat, .chatConversation, .search:
            VStack(spacing: 0) {
                chatDesignHeader(onMenu: onMenu)
                conversationContent
            }
            .background(ChatColors.background.ignoresSafeArea())
        case .tasks:
            MIFTaskListRoom(onMenu: onMenu, onNewConversation: createDesignConversation)
        case .approvals:
            MIFApprovalInboxRoom(onConfirmedCount: { approvalCount = $0 }, onMenu: onMenu,
                                 onOpenEventChain: { openEventChain(taskID: $0) })
        case .eventChain:
            MIFTaskEventChainRoom(onMenu: onMenu, taskID: eventChainTaskID)
        case .resources:
            MIFResourcesRoot(onMenu: onMenu, onOpenHost: { host in
                selectDesignRoute(.computer(host.id, shared: host.scope == .sharedReadOnly))
            })
        case .library:
            MIFLibraryRoot(onMenu: onMenu, personalDataRoot: MordePersonalStorage.root)
        case .workItems:
            MIFWorkItemRoom(onMenu: onMenu)
        case .friends:
            MIFPlaceholderPage(destination: .friends, onMenu: onMenu)
        case .toolChats:
            MIFPlaceholderPage(destination: .toolChats, onBack: { selectDesignRoute(.chat) })
        case .settings:
            MordeDesignSettingsRoot(onBack: { selectDesignRoute(.chat) }, onOpen: { destination in
                selectDesignRoute(.settingsDetail(destination.rawValue))
            })
        case .settingsDetail(let rawValue):
            if let destination = MordeDesignSettingsDestination(rawValue: rawValue) {
                MordeDesignSettingsDetail(destination: destination, onBack: { selectDesignRoute(.settings) })
            } else {
                unavailableRoute("设置项不可用", symbol: "gearshape")
            }
        case .task(let id):
            MIFTaskDetailView(taskID: id)
        case .workspace(let id):
            MordeWorkspaceFilesView(initialWorkspaceID: id)
        case .computer(let id, let shared):
            MordeComputerDesignRoom(client: client, hostID: id, shared: shared,
                                    onClose: { selectDesignRoute(.resources) })
        case .file:
            unavailableRoute("文件预览不可用", symbol: "doc")
        }
    }

    private func unavailableRoute(_ title: String, symbol: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: symbol).font(.title2).foregroundStyle(.secondary)
            Text(title).font(.body).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NanoMuseTones.canvas.ignoresSafeArea())
    }

    private func chatDesignHeader(onMenu: @escaping () -> Void) -> some View {
        HStack {
            NanoMuseRoundButton(symbol: "line.3.horizontal", label: "菜单", size: 38,
                                accessibilityIdentifier: "morde.nav.menu", action: onMenu)
            Spacer()
            VStack(spacing: 2) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(NanoMuseTones.ink)
                    .frame(width: 42, height: 42)
                    .background(NanoMuseTones.fill, in: Circle())
                Text(client.currentTask?.statusLabel ?? "就绪")
                    .font(.caption2)
                    .foregroundStyle(NanoMuseTones.secondaryText)
                    .lineLimit(1)
            }
            Spacer()
            Color.clear.frame(width: 40, height: 40)
                .contentShape(Rectangle())
                .contextMenu {
                    Button { handleTaskOptionsRequest() } label: {
                        Label(AppLocalized("Task options"), systemImage: "slider.horizontal.3")
                    }
                    .accessibilityIdentifier("morde.chat.action.taskOptions")
                    Button { toggleTaskSpeechInput() } label: {
                        Label(AppLocalized("Voice input"), systemImage: "mic")
                    }
                    .accessibilityIdentifier("morde.chat.action.voiceInput")
                    Button { handleChatAttachmentRequest() } label: {
                        Label(AppLocalized("Add attachment"), systemImage: "paperclip")
                    }
                    .accessibilityIdentifier("morde.chat.action.attachments")
                }
                .accessibilityElement()
                .accessibilityLabel(AppLocalized("Chat actions"))
                .accessibilityHint(AppLocalized("Long press to open chat actions"))
                .accessibilityIdentifier("morde.chat.actions")
        }
        // nanoMuse: The Morde chat header uses the design's 22pt side inset.
        .padding(.horizontal, 22)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }
    private var rootContent: some View {
        Group {
            if !client.signedIn {
                Form {
                    if let message = client.registrationMessage {
                        Section(String(localized: "Registration submitted")) {
                            Text(message).accessibilityIdentifier("morde.registration.pending")
                        }
                    }
                    Section(AppLocalized(registrationMode ? "Create account" : "Sign in")) {
                        TextField(String(localized: "Username"), text: $loginName)
                            .textInputAutocapitalization(.never)
                            .textContentType(.username)
                            .focused($authFieldFocused, equals: .username)
                            .accessibilityIdentifier("morde.auth.username")
                        SecureField(String(localized: "Password"), text: $loginPassword)
                            .textContentType(registrationMode ? .newPassword : .password)
                            .focused($authFieldFocused, equals: .password)
                            .accessibilityIdentifier("morde.auth.password")
                        if registrationMode {
                            SecureField(String(localized: "Confirm password"), text: $confirmationPassword)
                                .textContentType(.newPassword)
                                .focused($authFieldFocused, equals: .confirmation)
                                .accessibilityIdentifier("morde.auth.confirmPassword")
                        }
                        Button(AppLocalized(registrationMode ? "Create account" : "Sign in")) {
                            // nanoMuse: Release the auth form responder before the signed-in shell replaces it.
                            authFieldFocused = nil
                            let password = loginPassword
                            if registrationMode {
                                guard password == confirmationPassword else {
                                    loginPassword = ""
                                    confirmationPassword = ""
                                    client.error = String(localized: "Passwords do not match.")
                                    return
                                }
                                loginPassword = ""
                                confirmationPassword = ""
                                Task { await client.register(name: loginName, password: password) }
                            } else {
                                loginPassword = ""
                                Task { await client.login(name: loginName, password: password) }
                            }
                        }
                        .accessibilityIdentifier("morde.auth.submit")
                        .disabled(client.busy ||
                                  MordeRegistrationPayload.make(name: loginName, password: loginPassword) == nil)
                        Button(AppLocalized(registrationMode
                            ? "Already have an account? Sign in"
                            : "New to Morde? Create account")) {
                            registrationMode.toggle()
                            loginPassword = ""
                            confirmationPassword = ""
                            client.registrationMessage = nil
                            client.error = nil
                        }
                        .disabled(client.busy)
                    }
                }
            } else if layout == .conversation {
                conversationContent
                    .safeAreaInset(edge: .top) {
                        TimelineView(.periodic(from: .now, by: 60)) { context in
                            if let notice = client.expiryNotice(at: context.date) {
                                Text(notice).font(.headline).frame(maxWidth: .infinity)
                                    .padding().background(Color.orange.opacity(0.25))
                            }
                        }
                    }
            } else if layout == .computers {
                resourceContent
            } else {
                designNavigation
            }
        }
    }

    private var rootWithShellNotifications: some View {
        rootContent
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("morde.shellNewConversation")),
                   perform: handleNewConversationRequest)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("morde.shellPrompt")), perform: handleShellPrompt)
        .onReceive(NotificationCenter.default.publisher(for: .mordeShellTaskOptions)) { _ in handleTaskOptionsRequest() }
        .onReceive(NotificationCenter.default.publisher(for: .mordeShellVoiceInput)) { _ in toggleTaskSpeechInput() }
        .onReceive(NotificationCenter.default.publisher(for: .mordeShellAttachmentOptions)) { _ in handleChatAttachmentRequest() }
        .onReceive(NotificationCenter.default.publisher(for: .mordePersonalConflictResolved)) { note in
            guard let resolved = note.object as? NanoMuseMordePersonalConflictResolved,
                  resolved.source == .personalData,
                  resolved.scopeKey == authorization.personalDataScopeKey else { return }
            Task { await personal.refresh(root: MordePersonalStorage.root) }
        }
        .fileImporter(isPresented: $showChatAttachmentImporter, allowedContentTypes: [.image, .pdf], allowsMultipleSelection: true) { result in
            Task { await importChatAttachments(result) }
        }
    }

    private var rootWithStateObservers: some View {
        rootWithShellNotifications
        .nmOnChange(of: client.signedIn, perform: signedInChanged)
        .nmOnChange(of: authorization.personalDataScopeKey) { _ in clearChatAttachmentPreview() }
        .nmOnChange(of: personal.syncEnabled) { enabled in
            if !enabled { clearChatAttachmentPreview() }
        }
        .nmOnChange(of: personal.isLoading) { loading in
            if loading { clearChatAttachmentPreview() }
        }
        .nmOnChange(of: personal.error) { error in
            if error != nil { clearChatAttachmentPreview() }
        }
        .nmOnChange(of: client.currentTask?.statusLabel, perform: announceTaskStatus)
        .nmOnChange(of: client.user?.id, perform: userIDChanged)
        .nmOnChange(of: client.currentConversation, perform: conversationChanged)
        .nmOnChange(of: client.taskPageScopeKey, perform: conversationScopeChanged)
        .nmOnChange(of: draft) { _ in saveConversationDraft() }
        .nmOnChange(of: client.resourceStates[.hosts], perform: hostsChanged)
        .nmOnChange(of: client.resourceStates[.workspaces], perform: workspacesChanged)
        .nmOnChange(of: client.resourceStates[.models], perform: modelsChanged)
        .onAppear(perform: startLocalChatAttachmentFixtureIfNeeded)
    }

    private var rootWithErrorAlert: some View {
        rootWithStateObservers
        .alert("请求失败", isPresented: errorAlertPresented) {
            Button("确定", action: { setErrorAlertPresented(false) })
        } message: { Text(client.error ?? "") }
    }

    private var rootWithSignOutDialog: some View {
        rootWithErrorAlert
        .confirmationDialog("退出 Morde 账户？", isPresented: $confirmsSignOut, titleVisibility: .visible) {
            Button("退出登录", role: .destructive) {
                Task { await client.signOut() }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("这只会退出本机当前的 Morde 客户端会话。")
        }
    }

    private var rootWithHostSheet: some View {
        rootWithSignOutDialog
        .sheet(item: hostSheetItem) { item in
            MordeHostView(url: item.url)
        }
        .sheet(item: $chatAttachmentPreviewItem, onDismiss: chatAttachmentPreviewDismissed) { item in
            MIFPersonalAttachmentPreview(item: item, onClose: { chatAttachmentPreviewItem = nil })
        }
    }

    var body: some View {
#if DEBUG && !MORDE_STANDALONE
        rootWithHostSheet.task {
            await seedLocalHistoryFixtureIfRequested()
        }
#else
        rootWithHostSheet
#endif
    }
}

private enum MordeDesignSettingsDestination: String, CaseIterable, Identifiable {
    case account, connectors, devices, credentials, permissions, approvalRules, notifications, appearance, about

    var id: String { rawValue }
    var title: String {
        switch self {
        case .account: "账号"
        case .connectors: "连接器"
        case .devices: "设备"
        case .credentials: "安全凭证"
        case .permissions: "权限"
        case .approvalRules: "审批规则"
        case .notifications: "通知"
        case .appearance: "外观"
        case .about: "关于"
        }
    }
}

private struct MordeDesignSettingsRoot: View {
    @ObservedObject private var client = MordeClient.shared
    @ObservedObject private var execution = MIFExecutionControlStore.shared
    @State private var confirmsStop = false
    let onBack: () -> Void
    let onOpen: (MordeDesignSettingsDestination) -> Void

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        return version.map { "Morde \($0)" } ?? "Morde"
    }

    var body: some View {
        VStack(spacing: 0) {
            NanoMuseTopBar(title: "设置", onBack: onBack)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    sectionTitle("账号与连接", top: 8)
                    settingRow(.account, value: client.user?.name)
                    settingRow(.connectors)
                    settingRow(.devices)
                    settingRow(.credentials)

                    sectionTitle("权限与审批")
                    settingRow(.permissions)
                    settingRow(.approvalRules)
                    Button {
                        if execution.state == "disabled" {
                            Task { await execution.enable() }
                        } else {
                            confirmsStop = true
                        }
                    } label: {
                        HStack {
                            Text(execution.state == "disabled" ? "重新启用全部任务" : "急停全部任务")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.red)
                            Spacer()
                            if execution.isBusy { ProgressView().controlSize(.small) }
                        }
                        .padding(.vertical, 13)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!execution.isSignedIn || execution.isLoading || execution.isBusy || execution.state == nil)
                    .accessibilityIdentifier("morde.settings.executionControl")

                    sectionTitle("通用")
                    settingRow(.notifications)
                    settingRow(.appearance)
                    settingRow(.about, value: appVersion)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 20)
            }
            .accessibilityIdentifier("morde.settings.list")
        }
        .background(NanoMuseTones.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .tint(NanoMuseTones.action)
        .task { await execution.refresh() }
        .confirmationDialog("急停全部云端任务？", isPresented: $confirmsStop, titleVisibility: .visible) {
            Button("急停全部任务", role: .destructive) {
                Task { await execution.stopAll() }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("急停会停止当前账号下的云端任务。状态由服务端确认后更新。")
        }
    }

    private func sectionTitle(_ title: String, top: CGFloat = 24) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(NanoMuseTones.ink)
            .padding(.top, top)
            .padding(.bottom, 2)
    }

    private func settingRow(_ item: MordeDesignSettingsDestination, value: String? = nil) -> some View {
        Button { onOpen(item) } label: {
            HStack(spacing: 10) {
                Text(item.title).font(.system(size: 16, weight: .semibold)).foregroundStyle(NanoMuseTones.ink)
                Spacer(minLength: 8)
                if let value, !value.isEmpty {
                    Text(value).font(.system(size: 14, weight: .medium)).foregroundStyle(.tertiary).lineLimit(1)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("morde.settings.row.\(item.rawValue)")
    }
}

private struct MordeDesignSettingsDetail: View {
    let destination: MordeDesignSettingsDestination
    let onBack: () -> Void

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        return version.map { "Morde \($0)" } ?? "Morde"
    }

    var body: some View {
        VStack(spacing: 0) {
            NanoMuseTopBar(title: destination.title, onBack: onBack)
            detailContent
        }
        .background(NanoMuseTones.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private var detailContent: some View {
        switch destination {
        case .account:
            MordeAccountSettingsView()
        case .devices:
            MordeClientInstallationsSettingsView()
        case .credentials:
            MordePortalSettingsView(page: .apiKeys)
        case .about:
            VStack(alignment: .leading, spacing: 10) {
                Text(appVersion).font(.headline)
                Text("Morde iOS") .font(.subheadline).foregroundStyle(.secondary)
                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        case .connectors, .permissions, .approvalRules, .notifications, .appearance:
            Text("暂未实现")
                .font(.body)
                .foregroundStyle(NanoMuseTones.secondaryText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("morde.settings.unavailable.\(destination.rawValue)")
        }
    }
}

private struct MIFMordeMessageBubble: View {
    @ObservedObject private var personal = NanoMuseMordePersonalContentStore.shared
    let message: MordeClientMessage
    let onAttachmentPreview: (String) -> Void

    private var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack(alignment: .bottom) {
            if isUser { Spacer(minLength: 52) }
            VStack(alignment: .leading, spacing: 6) {
                if !isUser {
                    Text("morde")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Text(message.content)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                ForEach(message.attachment_ids ?? [], id: \.self) { attachmentID in
                    let body = attachmentBody(attachmentID)
                    let name = body?.name ?? String(attachmentID.suffix(8))
                    if !name.hasPrefix("morde-解析-") {
                        if canPreviewAttachment(attachmentID, body: body) {
                            Button { onAttachmentPreview(attachmentID) } label: {
                                attachmentLabel(name, attachmentID: attachmentID)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("morde.chat.message.attachment.\(attachmentID)")
                        } else {
                            attachmentLabel(name, attachmentID: attachmentID)
                        }
                    }
                }
                if isUser, message.task_id != nil {
                    Text(MordeMessageDeliveryPresentation.label(message.delivery_status))
                        .font(.caption)
                        .foregroundStyle(message.delivery_status == "applied" ? Color.secondary : Color.orange)
                }
                if message.status == "streaming" {
                    Text("正在生成…")
                        .font(.footnote).foregroundStyle(.secondary)
                } else if message.status == "interrupted" {
                    Text("回复中断，以下为已恢复内容")
                        .font(.footnote).foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: 340, alignment: .leading)
            .background(isUser ? NanoMuseTones.bubble : NanoMuseTones.agentPill,
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            if !isUser { Spacer(minLength: 52) }
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("morde.chat.message.\(message.id)")
    }

    private func attachmentBody(_ attachmentID: String) -> NanoMuseMordeLibraryItemBody? {
        for object in personal.values("library_item") {
            guard let body = try? object.decodeBody(NanoMuseMordeLibraryItemBody.self),
                  body.isValid, body.attachment_id == attachmentID else { continue }
            return body
        }
        return nil
    }

    private func canPreviewAttachment(_ attachmentID: String,
                                      body: NanoMuseMordeLibraryItemBody?) -> Bool {
        MordeShellAuthorization.shared.signedIn && personal.syncEnabled &&
            !personal.isLoading && personal.error == nil &&
            MordePersonalDataContract.isValidAttachmentID(attachmentID) &&
            body?.attachment_id == attachmentID &&
            MIFLibraryPreviewPolicy.normalizedPersonalAttachmentMediaType(body?.mime) != nil
    }

    private func attachmentLabel(_ name: String, attachmentID: String) -> some View {
        Label(name, systemImage: "paperclip")
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .accessibilityIdentifier("morde.chat.message.attachment.\(attachmentID)")
    }
}

private struct MordeProjectsRoom: View {
    @ObservedObject var client: MordeClient
    @State private var projectName = ""
    @State private var projectDescription = ""
    @State private var inviteUserID = ""
    @State private var inviteRole = "member"
    @State private var resourceKind = "host"
    @State private var resourceID = ""
    @State private var ownerTransferUserID = ""
    @State private var memberToRemove: MordeProjectMember?
    @State private var confirmsOwnerTransfer = false
    @State private var confirmsMemberRemoval = false
    @State private var workItemTitle = ""
    @State private var workItemDescription = ""
    @State private var blockingWorkItemID: String?
    @State private var blockedReason = ""
    @State private var budgetCurrency = "USD"
    @State private var budgetLimitMicros = ""
    @State private var projectConversationTitle = ""
    @State private var projectConversationDraft = ""
    @State private var projectConversationAnswer = ""
    @State private var projectConversationModelID = ""
    @State private var projectConversationHostID = ""
    @State private var projectConversationWorkspaceID = ""
    @State private var workItemDeliveryConfirmation: MordeProjectWorkItem?

    private var selectedProject: MordeProject? {
        client.projects.first(where: { $0.id == client.selectedProjectID })
    }
    private var selectedProjectConversation: MordeProjectConversation? {
        guard let projectID = selectedProject?.id, let conversationID = client.selectedProjectConversationID else { return nil }
        return client.projectConversations.first { $0.id == conversationID && $0.project_id == projectID }
    }
    private var selectedProjectConversationTask: MordeTask? {
        guard let conversation = selectedProjectConversation,
              let task = client.projectConversationTask, task.conversation_id == conversation.id else { return nil }
        return task
    }
    private var canManageProjectConversationTask: Bool {
        selectedProjectConversation.map {
            MordeProjectPolicy.isOwner(ownerID: $0.owner_id, currentUserID: client.user?.id)
        } == true
    }
    private var selectedProjectDeliveryBinding: MordeWorkspaceBinding? {
        guard !projectConversationHostID.isEmpty, !projectConversationWorkspaceID.isEmpty else { return nil }
        return client.workspaceBindings(for: projectConversationHostID)
            .first { $0.workspace.id == projectConversationWorkspaceID && client.isReady($0) }
    }
    private var isOwner: Bool {
        selectedProject.map { MordeProjectPolicy.isOwner(ownerID: $0.owner_id, currentUserID: client.user?.id) } == true
    }
    private var transferCandidates: [MordeProjectMember] {
        client.projectMembers.filter { $0.role != "owner" && $0.user_id != client.user?.id }
    }
    private var canManageWorkItems: Bool {
        client.projectMembers.first(where: { $0.project_id == selectedProject?.id && $0.user_id == client.user?.id })
            .map { MordeProjectPolicy.canManageWorkItems(role: $0.role) } == true
    }
    private var projectConversationModels: [MordeModel] {
        client.models.filter { $0.capabilities.text && $0.capabilities.tools }
    }
    private var projectConversationTargetUnavailable: Bool {
        client.targetIsUnavailable(hostID: projectConversationHostID, workspaceID: projectConversationWorkspaceID)
    }

    var body: some View {
        List {
            Section("收到的邀请") {
                if let failure = client.projectInvitationsState.failureMessage {
                    Text("邀请列表读取失败：\(failure)").font(.footnote).foregroundStyle(.orange)
                    Button("重试读取") { Task { await client.loadProjects() } }
                } else if client.projectInvitations.isEmpty && client.projectInvitationsState.isLoaded {
                    Text("当前没有待接受的项目邀请。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                ForEach(client.projectInvitations) { invitation in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("项目 \(invitation.project_id)").font(.headline)
                        Text("邀请人 \(invitation.inviter_id) · 权限：\(roleLabel(invitation.role))")
                            .font(.footnote).foregroundStyle(.secondary)
                        Button("接受邀请") { Task { await client.acceptProjectInvitation(invitation) } }
                            .disabled(client.projectActionInFlight)
                    }
                }
            }
            Section("项目") {
                if let failure = client.projectsState.failureMessage {
                    Text("项目列表读取失败：\(failure)").font(.footnote).foregroundStyle(.orange)
                    Button("重试读取") { Task { await client.loadProjects() } }
                } else if client.projects.isEmpty && client.projectsState.isLoaded {
                    Text("当前账号尚未加入项目。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if !client.projectsState.isLoaded && !client.projectsState.isFailed {
                    ProgressView("正在读取项目…")
                }
                ForEach(client.projects) { project in projectRow(project) }
            }
            Section("新建项目") {
                TextField("项目名称", text: $projectName)
                TextField("说明（可选）", text: $projectDescription, axis: .vertical)
                Button("创建项目") {
                    Task {
                        if await client.createProject(name: projectName, description: projectDescription) {
                            projectName = ""; projectDescription = ""
                        }
                    }
                }
                .disabled(client.projectActionInFlight || projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let project = selectedProject {
                Section("共享范围") {
                    Text("加入项目不会自动共享个人主会话或记忆。电脑和 Workspace 关联只记录资源，不复制文件，也不授予项目成员访问权限。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("项目共享会话") {
                    if let error = client.projectConversationError {
                        Text(error).font(.footnote).foregroundStyle(.orange)
                    }
                    if client.projectBudgetExecutionAvailable != true {
                        Text("当前服务未声明项目会话执行能力；不会提交项目任务。")
                            .font(.footnote).foregroundStyle(.secondary)
                    } else {
                        if let failure = client.projectConversationsState.failureMessage {
                            Text("会话列表读取失败：\(failure)").font(.footnote).foregroundStyle(.orange)
                            Button("重试读取") { Task { await client.loadProjectConversations(project.id) } }
                        } else if !client.projectConversationsState.isLoaded {
                            ProgressView("正在读取项目会话…")
                        } else if client.projectConversations.isEmpty {
                            Text("当前项目还没有共享会话。")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                        ForEach(client.projectConversations) { projectConversationRow($0) }
                        if canManageWorkItems {
                            TextField("共享会话标题（可选）", text: $projectConversationTitle)
                            Button("创建共享会话") {
                                Task {
                                    if await client.createProjectConversation(projectID: project.id,
                                                                              title: projectConversationTitle) {
                                        projectConversationTitle = ""
                                    }
                                }
                            }
                            .disabled(client.projectActionInFlight || projectConversationTitle.unicodeScalars.count > 120)
                        } else {
                            Text("只读成员可以查看共享会话，不能创建或发送消息。")
                                .font(.footnote).foregroundStyle(.secondary)
                        }

                        if let conversation = selectedProjectConversation {
                            projectConversationTranscript(project, conversation: conversation)
                        }
                    }
                }
                Section("项目成员") {
                    Text(isOwner ? "你是项目负责人。" : "你是项目成员；仅负责人可管理成员和资源关联。")
                        .font(.footnote).foregroundStyle(.secondary)
                    if let failure = client.projectDetailState.failureMessage {
                        Text("项目详情读取失败：\(failure)").font(.footnote).foregroundStyle(.orange)
                        Button("重试读取") { Task { await client.selectProject(project.id) } }
                    } else if !client.projectDetailState.isLoaded {
                        ProgressView("正在读取成员和资源…")
                    }
                    ForEach(client.projectMembers) { member in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(member.user_id)
                                Text(roleLabel(member.role)).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if isOwner && member.role != "owner" {
                                Menu("管理") {
                                    Button(member.role == "member" ? "改为只读" : "设为成员") {
                                        Task {
                                            await client.updateProjectMember(
                                                projectID: project.id, member: member,
                                                role: member.role == "member" ? "viewer" : "member")
                                        }
                                    }
                                    Button("移除成员", role: .destructive) {
                                        memberToRemove = member; confirmsMemberRemoval = true
                                    }
                                }
                                .disabled(client.projectActionInFlight)
                            }
                        }
                    }
                }

                Section("工作项") {
                    if let failure = client.projectWorkItemsState.failureMessage {
                        Text("工作项读取失败：\(failure)").font(.footnote).foregroundStyle(.orange)
                        Button("重试读取") { Task { await client.loadProjectExecution(project.id) } }
                    } else if !client.projectWorkItemsState.isLoaded {
                        ProgressView("正在读取工作项…")
                    } else if client.projectWorkItems.isEmpty {
                        Text("还没有项目工作项。")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    ForEach(client.projectWorkItems) { projectWorkItemRow($0, projectID: project.id) }
                    if canManageWorkItems {
                        TextField("新工作项", text: $workItemTitle)
                        TextField("说明（可选）", text: $workItemDescription, axis: .vertical)
                        Button("创建工作项") {
                            Task {
                                if await client.createProjectWorkItem(projectID: project.id, title: workItemTitle,
                                                                      description: workItemDescription) {
                                    workItemTitle = ""; workItemDescription = ""
                                }
                            }
                        }
                        .disabled(client.projectActionInFlight || workItemTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    } else {
                        Text("只读成员可以查看工作项；创建和变更由负责人或项目成员执行。")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }

                Section("项目预算与费用") {
                    if client.projectBudgetExecutionAvailable != true {
                        Text("当前服务未声明项目预算执行能力，暂不显示费用状态。")
                            .font(.footnote).foregroundStyle(.secondary)
                    } else if let failure = client.projectBudgetState.failureMessage {
                        Text("预算读取失败：\(failure)").font(.footnote).foregroundStyle(.orange)
                        Button("重试读取") { Task { await client.loadProjectExecution(project.id) } }
                    } else if !client.projectBudgetState.isLoaded {
                        ProgressView("正在读取预算和费用…")
                    } else if let budget = client.projectBudget {
                        if budget.configured {
                            LabeledContent("预算上限", value: formatMicros(budget.limit_micros, currency: budget.currency))
                            LabeledContent("已结算", value: formatMicros(budget.spent_micros, currency: budget.currency))
                            LabeledContent("已预留", value: formatMicros(budget.reserved_micros, currency: budget.currency))
                            if budget.has_unknown {
                                Text("有费用结果待核对；预留金额仍保留，不能当作已结算费用。")
                                    .font(.footnote).foregroundStyle(.orange)
                            }
                        } else {
                            Text("项目尚未配置预算；当前没有费用额度可供执行。")
                                .font(.footnote).foregroundStyle(.orange)
                        }
                        if isOwner {
                            TextField("币种（三位大写代码）", text: $budgetCurrency)
                                .textInputAutocapitalization(.characters).autocorrectionDisabled()
                            TextField("预算微单位（1,000,000 = 1 单位）", text: $budgetLimitMicros)
                                .keyboardType(.numberPad)
                            Button(budget.configured ? "更新项目预算" : "配置项目预算") {
                                guard let limit = Int64(budgetLimitMicros) else {
                                    client.projectActionError = "预算需填写正整数微单位，不要输入逗号或小数点。"
                                    return
                                }
                                Task {
                                    if await client.setProjectBudget(projectID: project.id, currency: budgetCurrency,
                                                                    limitMicros: limit) {
                                        budgetLimitMicros = String(limit)
                                    }
                                }
                            }
                            .disabled(client.projectActionInFlight || Int64(budgetLimitMicros) == nil)
                        }
                        ForEach(client.projectBudgetLedger.prefix(10)) { entry in
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(entry.model_id) · \(entry.status) · \(entry.actor_id)")
                                    .font(.footnote)
                                Text("预留 \(formatMicros(entry.reserved_micros, currency: entry.currency))" +
                                     (entry.actual_micros.map { " · 实际 \(formatMicros($0, currency: entry.currency))" } ?? ""))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if isOwner {
                    Section("邀请成员") {
                        TextField("已有账号的 User ID", text: $inviteUserID)
                            .textInputAutocapitalization(.never)
                        Picker("加入后权限", selection: $inviteRole) {
                            Text("成员").tag("member")
                            Text("只读").tag("viewer")
                        }
                        Button("创建邀请") {
                            Task {
                                if await client.inviteProjectMember(projectID: project.id, userID: inviteUserID, role: inviteRole) {
                                    inviteUserID = ""
                                }
                            }
                        }
                        .disabled(client.projectActionInFlight || inviteUserID.isEmpty)
                        if let invitations = client.recentProjectInvitations[project.id], !invitations.isEmpty {
                            Text("服务端只提供当前账号收到的邀请列表；刚创建的邀请可在本机当前会话中撤销。")
                                .font(.footnote).foregroundStyle(.secondary)
                            ForEach(invitations) { invitation in
                                HStack {
                                    Text("\(invitation.invitee_id) · \(roleLabel(invitation.role))")
                                    Spacer()
                                    Button("撤销") { Task { await client.revokeProjectInvitation(invitation) } }
                                        .disabled(client.projectActionInFlight)
                                }
                            }
                        }
                    }
                    Section("负责人交接") {
                        if transferCandidates.isEmpty {
                            Text("需要先有一位已接受邀请的成员，才能转移负责人。")
                                .font(.footnote).foregroundStyle(.secondary)
                        } else {
                            Picker("交接给", selection: $ownerTransferUserID) {
                                Text("选择成员").tag("")
                                ForEach(transferCandidates) { member in Text(member.user_id).tag(member.user_id) }
                            }
                            Button("转移项目负责人", role: .destructive) { confirmsOwnerTransfer = true }
                                .disabled(client.projectActionInFlight || ownerTransferUserID.isEmpty)
                        }
                    }
                }

                Section("关联的电脑与 Workspace") {
                    Text("关联只记录项目资源，不会授予其他项目成员访问 Host 或 Workspace 的权限。")
                        .font(.footnote).foregroundStyle(.secondary)
                    if client.projectResources.isEmpty && client.projectDetailState.isLoaded {
                        Text("没有当前账号可见的关联资源。")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    ForEach(client.projectResources) { resource in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(resourceTitle(resource))
                                Text(resource.kind == "host" ? "电脑状态：\(hostState(resource.resource_id))" : "仅显示已授权的 Workspace")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if isOwner {
                                Button("移除") { Task { await client.removeProjectResource(resource) } }
                                    .disabled(client.projectActionInFlight)
                            }
                        }
                    }
                    if isOwner {
                        Picker("资源类型", selection: $resourceKind) {
                            Text("电脑").tag("host")
                            Text("Workspace").tag("workspace")
                        }
                        Picker("可访问资源", selection: $resourceID) {
                            Text("选择资源").tag("")
                            if resourceKind == "host" {
                                ForEach(client.hosts) { host in Text(host.name.isEmpty ? host.id : host.name).tag(host.id) }
                            } else {
                                ForEach(client.workspaces) { workspace in Text(workspace.name).tag(workspace.id) }
                            }
                        }
                        Button("关联资源") {
                            Task { await client.addProjectResource(projectID: project.id, kind: resourceKind, resourceID: resourceID) }
                        }
                        .disabled(client.projectActionInFlight || resourceID.isEmpty)
                        Text("当前服务未开放 Workspace 复制或移交；资源关联不代表副本，也不会授予成员访问权限。")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            if let notice = client.projectNotice {
                Section { Text(notice).font(.footnote).foregroundStyle(.secondary) }
            }
            if let failure = client.projectActionError {
                Section { Text(failure).font(.footnote).foregroundStyle(.orange) }
            }
        }
        .navigationTitle("项目")
        .refreshable { await client.loadProjects() }
        .task(id: client.signedIn) { if client.signedIn { await client.loadProjects() } }
        .onChange(of: client.selectedProjectID) { _ in
            ownerTransferUserID = ""; resourceID = ""; memberToRemove = nil
            workItemDeliveryConfirmation = nil
            workItemTitle = ""; workItemDescription = ""; blockingWorkItemID = nil; blockedReason = ""
            budgetCurrency = "USD"; budgetLimitMicros = ""
            projectConversationTitle = ""; projectConversationDraft = ""; projectConversationModelID = ""
            projectConversationAnswer = ""
            projectConversationHostID = ""; projectConversationWorkspaceID = ""
            client.projectActionError = nil; client.projectNotice = nil
            client.projectConversationError = nil
        }
        .onChange(of: client.selectedProjectConversationID) { _ in
            projectConversationDraft = ""; projectConversationAnswer = ""
        }
        .onChange(of: client.projectBudgetExecutionAvailable) { available in
            guard available == true, let projectID = client.selectedProjectID else { return }
            Task {
                await client.loadProjectExecution(projectID)
                await client.loadProjectConversations(projectID)
            }
        }
        .onChange(of: projectConversationHostID) { hostID in
            let bindings = client.workspaceBindings(for: hostID)
            projectConversationWorkspaceID = bindings.count == 1 && bindings.first.map({ client.isReady($0) }) == true
                ? bindings[0].workspace.id : ""
        }
        .onChange(of: client.projectBudget?.version) { _ in
            guard let budget = client.projectBudget, budget.configured else { return }
            budgetCurrency = budget.currency
            budgetLimitMicros = String(budget.limit_micros)
        }
        .onChange(of: resourceKind) { _ in resourceID = "" }
        .confirmationDialog("转移项目负责人？", isPresented: $confirmsOwnerTransfer, titleVisibility: .visible) {
            if let project = selectedProject, !ownerTransferUserID.isEmpty {
                Button("转移给 \(ownerTransferUserID)", role: .destructive) {
                    Task { await client.transferProjectOwner(projectID: project.id, to: ownerTransferUserID) }
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("项目所有权会立即转给这位已加入的成员，你将失去负责人权限。")
        }
        .confirmationDialog("移除项目成员？", isPresented: $confirmsMemberRemoval, titleVisibility: .visible) {
            if let project = selectedProject, let member = memberToRemove {
                Button("移除 \(member.user_id)", role: .destructive) {
                    Task { await client.removeProjectMember(projectID: project.id, member: member) }
                }
            }
            Button("取消", role: .cancel) { memberToRemove = nil }
        } message: {
            Text("移除后，该成员对项目的访问会被撤销。")
        }
        .confirmationDialog("确认登记项目交付？", isPresented: Binding(
            get: { workItemDeliveryConfirmation != nil },
            set: { if !$0 { workItemDeliveryConfirmation = nil } }
        ), titleVisibility: .visible) {
            if let project = selectedProject, let item = workItemDeliveryConfirmation,
               let task = selectedProjectConversationTask, let binding = selectedProjectDeliveryBinding {
                Button("登记已保存版本 v\(binding.workspace.revision)") {
                    Task {
                        if await client.recordProjectWorkItemDelivery(
                            projectID: project.id, item: item, taskID: task.id,
                            hostID: projectConversationHostID, workspaceID: binding.workspace.id) {
                            workItemDeliveryConfirmation = nil
                        }
                    }
                }
                .disabled(client.projectActionInFlight)
            }
            Button("取消", role: .cancel) { workItemDeliveryConfirmation = nil }
        } message: {
            if let item = workItemDeliveryConfirmation, let task = selectedProjectConversationTask,
               let binding = selectedProjectDeliveryBinding {
                Text("\(item.title) · Task \(task.id) · \(binding.workspace.name) v\(binding.workspace.revision)。服务端会核验已保存产物；这里只提交版本元数据，不传送文件。")
            } else {
                Text("当前项目会话或 Workspace 已变化，请重新选择。")
            }
        }
    }

    private func roleLabel(_ role: String) -> String {
        switch role {
        case "owner": return "负责人"
        case "member": return "成员"
        case "viewer": return "只读"
        default: return "未知权限"
        }
    }

    private func workItemStateLabel(_ state: String) -> String {
        switch state {
        case "open": return "待处理"
        case "blocked": return "阻塞"
        case "delivered": return "已交付"
        default: return "状态未知"
        }
    }

    private func projectConversationRow(_ conversation: MordeProjectConversation) -> some View {
        Button { Task { await client.selectProjectConversation(conversation.id) } } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(conversation.title.isEmpty ? "新共享会话" : conversation.title)
                Text("创建者 \(conversation.owner_id) · \(conversation.id)")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(client.selectedProjectConversationID == conversation.id
                           ? Color.accentColor.opacity(0.12) : nil)
    }

    private func projectWorkItemRow(_ item: MordeProjectWorkItem, projectID: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.title).font(.headline)
                Spacer()
                Text(workItemStateLabel(item.state)).font(.caption).foregroundStyle(.secondary)
            }
            Text("\(item.assignee_id.map { "负责人 \($0)" } ?? "待认领") · v\(item.version) · 关联任务 \(item.task_ids.count) 项")
                .font(.caption).foregroundStyle(.secondary)
            if !item.description.isEmpty { Text(item.description).font(.footnote) }
            if !item.blocked_reason.isEmpty {
                Text("阻塞原因：\(item.blocked_reason)").font(.footnote).foregroundStyle(.orange)
            }
            if let delivery = item.delivery {
                Text("已记录交付：Task \(delivery.task_id) · Workspace \(delivery.workspace_id) · v\(delivery.revision)")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            if canManageWorkItems, let task = selectedProjectConversationTask {
                if MordeProjectPolicy.canLinkTask(role: client.projectMembers.first(where: {
                    $0.project_id == projectID && $0.user_id == client.user?.id
                })?.role, state: item.state, taskID: task.id, taskIDs: item.task_ids) {
                    Button("关联当前 Task \(task.id)") {
                        Task { await client.linkProjectWorkItemTask(projectID: projectID, item: item, taskID: task.id) }
                    }
                    .disabled(client.projectActionInFlight)
                }
                if item.state == "open", let binding = selectedProjectDeliveryBinding,
                   MordeProjectPolicy.canRecordDelivery(
                    role: client.projectMembers.first(where: { $0.project_id == projectID && $0.user_id == client.user?.id })?.role,
                    state: item.state, taskID: task.id, taskIDs: item.task_ids,
                    workspaceID: binding.workspace.id, revision: Int64(binding.workspace.revision)) {
                    Button("登记当前 Workspace 版本交付") { workItemDeliveryConfirmation = item }
                        .disabled(client.projectActionInFlight)
                }
            }
            if canManageWorkItems && item.state == "open" {
                if blockingWorkItemID == item.id {
                    TextField("阻塞原因", text: $blockedReason, axis: .vertical)
                    Button("确认阻塞") {
                        Task {
                            if await client.setProjectWorkItemBlocked(projectID: projectID, item: item, reason: blockedReason) {
                                blockedReason = ""; blockingWorkItemID = nil
                            }
                        }
                    }
                    .disabled(client.projectActionInFlight || blockedReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } else {
                    Button("标记阻塞") { blockingWorkItemID = item.id }
                        .disabled(client.projectActionInFlight)
                }
            } else if canManageWorkItems && item.state == "blocked" {
                Button("解除阻塞") { Task { await client.resumeProjectWorkItem(projectID: projectID, item: item) } }
                    .disabled(client.projectActionInFlight)
            }
        }
        .padding(.vertical, 3)
    }

    private func projectConversationTranscript(_ project: MordeProject,
                                               conversation: MordeProjectConversation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(conversation.title.isEmpty ? "新共享会话" : conversation.title).font(.headline)
                Spacer()
                Button("刷新") {
                    Task { await client.loadProjectConversationMessages(projectID: project.id,
                                                                        conversationID: conversation.id) }
                }
            }
            if let failure = client.projectConversationMessagesState.failureMessage {
                Text("消息读取失败：\(failure)").font(.footnote).foregroundStyle(.orange)
            } else if !client.projectConversationMessagesState.isLoaded {
                ProgressView("正在读取消息…")
            } else if client.projectConversationMessages.isEmpty {
                Text("这条共享会话还没有消息。").font(.footnote).foregroundStyle(.secondary)
            }
            ForEach(client.projectConversationMessages) { projectConversationMessageRow($0) }
            if let task = client.projectConversationTask, task.conversation_id == conversation.id {
                projectConversationTaskStatus(task)
            }
            projectConversationComposer(projectID: project.id, conversationID: conversation.id)
        }
    }

    private func projectConversationMessageRow(_ message: MordeProjectConversationMessage) -> some View {
        VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
            Text(message.role == "user" ? message.actor_id : "AI 回复")
                .font(.caption).foregroundStyle(.secondary)
            Text(message.content).textSelection(.enabled)
            if message.role == "user" {
                Text(MordeMessageDeliveryPresentation.label(message.delivery_status))
                    .font(.caption).foregroundStyle(message.delivery_status == "applied" ? Color.secondary : Color.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == "user" ? .trailing : .leading)
    }

    private func projectConversationTaskStatus(_ task: MordeTask) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Task：\(task.statusLabel)").font(.footnote)
            if let step = task.current_step, !step.isEmpty { Text(step).font(.caption).foregroundStyle(.secondary) }
            if let result = task.result, !result.isEmpty { Text(result).font(.footnote) }
            if let pending = task.pending_request { projectConversationApprovalControls(task, pending: pending) }
            if let clarification = task.clarification_request {
                projectConversationClarificationControls(task, clarification: clarification)
            }
            if canManageProjectConversationTask {
                Button("刷新 Task 状态") { Task { await client.refreshProjectConversationTask() } }
            } else {
                Text("仅共享会话创建者可以刷新 Task 状态和处理审批。")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func projectConversationApprovalControls(_ task: MordeTask, pending: MordeTask.Pending) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(pending.title).font(.headline)
            Text(pending.content)
            Text(pending.impact).font(.footnote).foregroundStyle(.secondary)
            if pending.media_preview_operation_id != nil {
                MordeTaskMediaPreviewControls(
                    client: client, task: task, pending: pending,
                    canRespond: canManageProjectConversationTask, busy: client.projectActionInFlight,
                    isPendingCurrent: {
                        client.projectConversationTask?.id == task.id &&
                            client.projectConversationTask?.pending_request?.id == pending.id &&
                            client.projectConversationTask?.pending_request?.version == pending.version &&
                            client.projectConversationTask?.pending_request?.media_preview_operation_id == pending.media_preview_operation_id
                    },
                    onDecision: { decision in
                        await client.respondToProjectConversationApproval(
                            taskID: task.id, approvalID: pending.id, version: pending.version, decision: decision)
                    })
            } else if canManageProjectConversationTask {
                HStack {
                    Button("批准") {
                        Task {
                            await client.respondToProjectConversationApproval(
                                taskID: task.id, approvalID: pending.id, version: pending.version, decision: "approve")
                        }
                    }
                    Button("拒绝", role: .destructive) {
                        Task {
                            await client.respondToProjectConversationApproval(
                                taskID: task.id, approvalID: pending.id, version: pending.version, decision: "reject")
                        }
                    }
                }
                .disabled(client.projectActionInFlight)
            }
        }
    }

    private func projectConversationClarificationControls(
        _ task: MordeTask, clarification: MordeTask.Clarification
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(clarification.question)
            if canManageProjectConversationTask {
                TextField("补充信息", text: $projectConversationAnswer, axis: .vertical)
                Button("提交补充信息") {
                    Task {
                        if await client.answerProjectConversationClarification(
                            taskID: task.id, clarificationID: clarification.id,
                            version: clarification.version, answer: projectConversationAnswer) {
                            projectConversationAnswer = ""
                        }
                    }
                }
                .disabled(client.projectActionInFlight ||
                          !MordeTaskResponsePolicy.hasValidAnswer(projectConversationAnswer))
            }
        }
    }

    @ViewBuilder
    private func projectConversationComposer(projectID: String, conversationID: String) -> some View {
        if canManageWorkItems {
            Picker("模型", selection: $projectConversationModelID) {
                Text("选择模型").tag("")
                ForEach(projectConversationModels) { model in Text(model.name).tag(model.id) }
            }
            Picker("电脑（可选）", selection: $projectConversationHostID) {
                Text("云端运行").tag("")
                ForEach(client.hosts.filter { $0.owner_id == client.user?.id && client.canOpenHost($0) }) { host in
                    Text(host.name.isEmpty ? host.id : host.name).tag(host.id)
                }
            }
            if !projectConversationHostID.isEmpty {
                Picker("Workspace", selection: $projectConversationWorkspaceID) {
                    Text("选择 Workspace").tag("")
                    ForEach(client.workspaceBindings(for: projectConversationHostID).filter { client.isReady($0) }, id: \.workspace.id) { binding in
                        Text(projectWorkspaceOptionLabel(binding)).tag(binding.workspace.id)
                    }
                }
            }
            TextField("发送项目消息", text: $projectConversationDraft, axis: .vertical)
            Button("发送并创建/继续 Task") {
                Task {
                    if await client.appendProjectConversationMessage(
                        projectID: projectID, conversationID: conversationID,
                        content: projectConversationDraft, modelID: projectConversationModelID,
                        hostID: projectConversationHostID, workspaceID: projectConversationWorkspaceID) {
                        projectConversationDraft = ""
                    }
                }
            }
            .disabled(client.projectActionInFlight || projectConversationDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                      projectConversationModelID.isEmpty || projectConversationTargetUnavailable ||
                      !projectConversationModels.contains(where: { $0.id == projectConversationModelID }))
            Text("项目消息由当前账号提交；电脑和 Workspace 必须属于当前账号并已就绪。没有附加或传送文件。")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func projectWorkspaceOptionLabel(_ binding: MordeWorkspaceBinding) -> String {
        let revision = binding.workspace.revision
        return "\(binding.workspace.name) · v\(revision)"
    }

    private func projectRow(_ project: MordeProject) -> some View {
        let role = project.owner_id == client.user?.id ? "负责人" : "项目成员"
        let summary = "\(project.id) · \(role) · v\(project.version)"
        return Button { Task { await client.selectProject(project.id) } } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name).font(.headline)
                Text(summary).font(.caption).foregroundStyle(.secondary)
                if !project.description.isEmpty { Text(project.description).font(.footnote) }
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(client.selectedProjectID == project.id ? Color.accentColor.opacity(0.12) : nil)
    }

    private func formatMicros(_ micros: Int64, currency: String) -> String {
        let value = Decimal(micros) / Decimal(1_000_000)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 6
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(currency) \(micros) µ"
    }

    private func hostState(_ id: String) -> String {
        if let host = client.hosts.first(where: { $0.id == id }) { return MordeTaskTargetPresentation.hostState(host.state) }
        if let host = client.sharedHosts.first(where: { $0.id == id }) { return "共享 · \(MordeTaskTargetPresentation.hostState(host.state))" }
        return "当前账号无独立可见状态"
    }

    private func resourceTitle(_ resource: MordeProjectResource) -> String {
        if resource.kind == "host" {
            return client.hosts.first(where: { $0.id == resource.resource_id })?.name ?? resource.resource_id
        }
        return client.workspaces.first(where: { $0.id == resource.resource_id })?.name ?? resource.resource_id
    }
}

private struct MordeComputerDesignRoom: View {
    @ObservedObject var client: MordeClient
    let hostID: String
    let shared: Bool
    let onClose: () -> Void
    @State private var pageLoadState: MordeHostPageLoadState = .loading

    private var hostName: String {
        let name = shared
            ? client.sharedHosts.first(where: { $0.id == hostID })?.name
            : client.hosts.first(where: { $0.id == hostID })?.name
        return name ?? hostID
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                NanoMuseRoundButton(symbol: "xmark", label: "关闭云电脑", size: 40,
                                    accessibilityIdentifier: "morde.computer.close", action: onClose)
                VStack(alignment: .leading, spacing: 2) {
                    Text(hostName).font(.headline).lineLimit(1)
                    Text("云电脑").font(.caption).foregroundStyle(NanoMuseTones.secondaryText)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Group {
                if let url = client.hostURL {
                    ZStack {
                        MordeHostView(url: url) { pageLoadState = $0 }
                            .accessibilityIdentifier("morde.computer.webview")
                        if pageLoadState == .loading {
                            ProgressView("正在加载云电脑…")
                                .padding(16)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .accessibilityIdentifier("morde.computer.pageLoading")
                        } else if pageLoadState == .failed {
                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle")
                                Text("云电脑页面加载失败，请关闭后重试。")
                                    .multilineTextAlignment(.center)
                                    .accessibilityIdentifier("morde.computer.pageLoadFailure")
                            }
                            .padding(16)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                } else if let error = client.hostOpenErrors[hostID] {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                        Text(error).multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ProgressView("正在连接云电脑…")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.black.ignoresSafeArea())
        .task(id: "\(hostID):\(shared)") {
            pageLoadState = .loading
            client.hostURL = nil
            await client.openHost(hostID, shared: shared)
            if Task.isCancelled { client.hostURL = nil }
        }
        .onDisappear { client.hostURL = nil }
    }
}

private struct MordeHostURL: Identifiable { let url: URL; var id: String { url.absoluteString } }
private enum MordeHostPageLoadState: Equatable {
    case loading
    case loaded
    case failed
}

private struct MordeHostView: UIViewRepresentable {
    let url: URL
    var onPageLoadStateChange: ((MordeHostPageLoadState) -> Void)? = nil

    func makeUIView(context: Context) -> WKWebView {
        let web = WKWebView(frame: .zero)
        web.navigationDelegate = context.coordinator
        web.load(URLRequest(url: url))
        return web
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.onPageLoadStateChange = onPageLoadStateChange
    }
    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.stopLoading()
        coordinator.cancelDownloads()
        uiView.navigationDelegate = nil
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(origin: url, onPageLoadStateChange: onPageLoadStateChange)
    }
    final class Coordinator: NSObject, WKNavigationDelegate, WKDownloadDelegate {
        let origin: URL
        var onPageLoadStateChange: ((MordeHostPageLoadState) -> Void)?
        private var activeDownloads: [ObjectIdentifier: WKDownload] = [:]
        private var downloadDestinations: [ObjectIdentifier: URL] = [:]
        private var downloadPartials: [ObjectIdentifier: URL] = [:]

        init(origin: URL, onPageLoadStateChange: ((MordeHostPageLoadState) -> Void)?) {
            self.origin = origin
            self.onPageLoadStateChange = onPageLoadStateChange
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            onPageLoadStateChange?(.loading)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            onPageLoadStateChange?(.loaded)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
            onPageLoadStateChange?(.failed)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            onPageLoadStateChange?(.failed)
        }

        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if action.shouldPerformDownload {
                let allowed = isAllowedMordeHostDownload(
                    requestURL: action.request.url,
                    sourceURL: action.sourceFrame.request.url,
                    sourceIsMainFrame: action.sourceFrame.isMainFrame,
                    relativeTo: origin)
                decisionHandler(allowed ? .download : .cancel)
                return
            }
            decisionHandler(isAllowedMordeHostNavigation(action.request.url, relativeTo: origin) ? .allow : .cancel)
        }

        func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
            download.delegate = self
            activeDownloads[ObjectIdentifier(download)] = download
        }

        func download(_ download: WKDownload, willPerformHTTPRedirection response: HTTPURLResponse,
                      newRequest request: URLRequest,
                      decisionHandler: @escaping (WKDownload.RedirectPolicy) -> Void) {
            decisionHandler(isAllowedMordeHostNavigation(request.url, relativeTo: origin) ? .allow : .cancel)
        }

        func download(_ download: WKDownload, decideDestinationUsing response: URLResponse,
                      suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
            let key = ObjectIdentifier(download)
            do {
                let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let directory = documents.appendingPathComponent("Morde Host Downloads", isDirectory: true)
                if MordeWorkspaceTransferSupport.pathEntryExists(directory),
                   !MordeWorkspaceTransferSupport.isDirectoryWithoutFollowingSymlinks(directory) {
                    throw MordeWorkspaceTransferError.invalidPath
                }
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                let reserved = Set(downloadDestinations.values.map(\.lastPathComponent))
                guard let destination = mordeHostDownloadDestination(
                    suggestedFilename: suggestedFilename,
                    directory: directory,
                    reservedFilenames: reserved,
                    fileExists: { MordeWorkspaceTransferSupport.pathEntryExists($0) }) else {
                    activeDownloads.removeValue(forKey: key)
                    completionHandler(nil)
                    return
                }
                var partial: URL
                repeat {
                    partial = directory.appendingPathComponent(".morde-\(UUID().uuidString).part")
                } while MordeWorkspaceTransferSupport.pathEntryExists(partial)
                downloadDestinations[key] = destination
                downloadPartials[key] = partial
                completionHandler(partial)
            } catch {
                activeDownloads.removeValue(forKey: key)
                completionHandler(nil)
            }
        }

        func downloadDidFinish(_ download: WKDownload) {
            let key = ObjectIdentifier(download)
            activeDownloads.removeValue(forKey: key)
            let partial = downloadPartials.removeValue(forKey: key)
            let destination = downloadDestinations.removeValue(forKey: key)
            guard let partial, let destination,
                  promoteMordeHostDownload(from: partial, to: destination) else {
                if let partial { try? FileManager.default.removeItem(at: partial) }
                return
            }
        }

        func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
            let key = ObjectIdentifier(download)
            activeDownloads.removeValue(forKey: key)
            downloadDestinations.removeValue(forKey: key)
            if let partial = downloadPartials.removeValue(forKey: key) {
                try? FileManager.default.removeItem(at: partial)
            }
        }

        func cancelDownloads() {
            let downloads = Array(activeDownloads.values)
            let partials = Array(downloadPartials.values)
            activeDownloads.removeAll()
            downloadDestinations.removeAll()
            downloadPartials.removeAll()
            for download in downloads { download.cancel { _ in } }
            for partial in partials { try? FileManager.default.removeItem(at: partial) }
        }
    }
}
