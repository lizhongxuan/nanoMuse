import XCTest
@testable import Minis

final class MordeTaskSpeechInputPolicyTests: XCTestCase {
    func testTaskDictationFailsClosedWhenOnDeviceRecognitionIsUnsupported() {
        XCTAssertNil(MordeTaskSpeechInputPolicy.onDeviceRequirement(forced: true, supported: false))
        XCTAssertEqual(MordeTaskSpeechInputPolicy.onDeviceRequirement(forced: true, supported: true), true)
    }

    func testExistingVoiceInputStillPrefersOnDeviceWhenAvailable() {
        XCTAssertEqual(MordeTaskSpeechInputPolicy.onDeviceRequirement(forced: false, supported: true), true)
        XCTAssertEqual(MordeTaskSpeechInputPolicy.onDeviceRequirement(forced: false, supported: false), false)
    }
}
