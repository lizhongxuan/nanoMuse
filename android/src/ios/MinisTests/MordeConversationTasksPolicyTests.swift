import XCTest
@testable import Minis

final class MordeConversationTasksPolicyTests: XCTestCase {
    private func task(_ id: String, conversationID: String = "c1234567", sequence: Int? = 1) throws -> MordeTask {
        var value: [String: Any] = [
            "id": id, "conversation_id": conversationID, "objective": "Synthetic task",
            "status": "running", "updated_at": "2026-11-06T00:00:00Z"
        ]
        if let sequence { value["event_sequence"] = sequence }
        return try JSONDecoder().decode(MordeTask.self, from: JSONSerialization.data(withJSONObject: value))
    }

    func testIndependentTasksRemainScopedToConversation() throws {
        let first = try task("q1234567", sequence: 1)
        let second = try task("q2345678", sequence: 12)
        XCTAssertTrue(MordeConversationTasksPolicy.valid([first, second], conversationID: "c1234567"))
        XCTAssertFalse(MordeConversationTasksPolicy.valid([first, first], conversationID: "c1234567"))
        XCTAssertFalse(MordeConversationTasksPolicy.valid([first, try task("q2345678", conversationID: "c2345678")],
                                                           conversationID: "c1234567"))
    }

    func testTaskListRequiresNonnegativeEventCursor() throws {
        XCTAssertFalse(MordeConversationTasksPolicy.valid([try task("q1234567", sequence: nil)],
                                                           conversationID: "c1234567"))
        XCTAssertFalse(MordeConversationTasksPolicy.valid([try task("q1234567", sequence: -1)],
                                                           conversationID: "c1234567"))
    }

    func testRepliesFromParallelTasksStayWithTheirOwnTaskAndConversation() {
        let first = MordeClientMessage(id: "m1234567", conversation_id: "c1234567", task_id: "q1234567",
                                       role: "assistant", content: "First reply", status: "streaming")
        let second = MordeClientMessage(id: "m2345678", conversation_id: "c1234567", task_id: "q2345678",
                                        role: "assistant", content: "Second reply", status: "streaming")
        let firstUpdate = MordeClientMessage(id: first.id, conversation_id: "c1234567", task_id: "q1234567",
                                             role: "assistant", content: "First completed", status: "completed")
        let initial = MordeTaskSnapshotMessageMerge.merge([], snapshot: first, taskID: "q1234567", conversationID: "c1234567")
        let both = MordeTaskSnapshotMessageMerge.merge(initial, snapshot: second, taskID: "q2345678", conversationID: "c1234567")
        let updated = MordeTaskSnapshotMessageMerge.merge(both, snapshot: firstUpdate, taskID: "q1234567", conversationID: "c1234567")
        XCTAssertEqual(updated.map(\.content), ["First completed", "Second reply"])
        XCTAssertEqual(MordeTaskSnapshotMessageMerge.merge(updated, snapshot: second, taskID: "q1234567",
                                                            conversationID: "c1234567"), updated)
        XCTAssertEqual(MordeTaskSnapshotMessageMerge.merge(updated, snapshot: second, taskID: "q2345678",
                                                            conversationID: "c8765432"), updated)
    }
}
