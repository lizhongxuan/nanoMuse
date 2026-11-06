import Foundation
import XCTest

@MainActor
final class IOS04CloudAcceptanceUITests: XCTestCase {
    func testPersonalDataSyncAndLibrary() throws {
        guard let account = ProcessInfo.processInfo.environment["MORDE_IOS04_TEST_USER"],
              let password = ProcessInfo.processInfo.environment["MORDE_IOS04_TEST_PASSWORD"],
              let serverAddress = ProcessInfo.processInfo.environment["MORDE_IOS04_TEST_SERVER"] else {
            throw XCTSkip("Set local IOS-04 test credentials in the test action environment.")
        }

        let app = XCUIApplication()
        app.launchArguments = ["-morde.server", serverAddress]
        app.launch()
        let accountField = app.textFields["morde.auth.username"]
        XCTAssertTrue(accountField.waitForExistence(timeout: 10))
        accountField.tap()
        accountField.typeText(account)

        let passwordField = app.secureTextFields["morde.auth.password"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5))
        passwordField.tap()
        passwordField.typeText(password)
        app.buttons["morde.auth.submit"].tap()
        let chatTab = app.buttons["morde.shell.tab.chat"]
        let tasksTab = app.buttons["morde.shell.tab.tasks"]
        let approvalsTab = app.buttons["morde.shell.tab.approvals"]
        let libraryTab = app.buttons["morde.shell.tab.resources"]
        XCTAssertTrue(chatTab.waitForExistence(timeout: 20))
        XCTAssertTrue(tasksTab.exists)
        XCTAssertTrue(approvalsTab.exists)
        XCTAssertTrue(libraryTab.exists)
        for room in ["feed", "ideas", "goals"] {
            XCTAssertFalse(app.buttons["morde.shell.tab.\(room)"].exists)
        }
        libraryTab.tap()
        let libraryAll = app.buttons["morde.library.source.all"]
        XCTAssertTrue(libraryAll.waitForExistence(timeout: 10))
        libraryAll.tap()
        let libraryMetadata = app.descendants(matching: .any)["morde.library.cloud.item.ios04acceptlibrary"]
        XCTAssertTrue(libraryMetadata.waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["morde.library.cloud.item.ios04acceptlibrary"].exists)
        XCTAssertTrue(text(app, "Metadata only", "仅元数据").exists)
        chatTab.tap()
        button(app, "More", "更多").tap()
        button(app, "Settings", "设置").tap()
        button(app, "Morde account", "Morde 账户").tap()
        XCTAssertTrue(app.staticTexts["Personal data quota"].waitForExistence(timeout: 10))
        XCTAssertTrue(button(app, "Refresh quota", "刷新额度").waitForExistence(timeout: 15))

        let syncToggle = app.switches.matching(
            NSPredicate(format: "label CONTAINS[c] 'Sync Morde personal data' OR label CONTAINS[c] '同步 Morde 个人数据'")
        ).firstMatch
        XCTAssertTrue(syncToggle.waitForExistence(timeout: 10))
        if syncToggle.value as? String == "1" {
            syncToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        }
        XCTAssertEqual(syncToggle.value as? String, "0")
        let pausedStatus = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS[c] 'Sync is paused' OR label CONTAINS[c] '暂停'")
        ).firstMatch
        XCTAssertTrue(pausedStatus.waitForExistence(timeout: 10))

        button(app, "Personal profile", "个人资料").tap()
        let displayName = app.textFields.matching(
            NSPredicate(format: "placeholderValue CONTAINS[c] 'Display name' OR placeholderValue CONTAINS[c] '显示名称'")
        ).firstMatch
        XCTAssertTrue(displayName.waitForExistence(timeout: 15))
        displayName.tap()
        if let currentName = displayName.value as? String, !currentName.isEmpty {
            displayName.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentName.count))
        }
        displayName.typeText("IOS04 Simulator")
        button(app, "Save", "保存").tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let pendingStatus = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'Pending' OR label CONTAINS[c] '待处理' OR label CONTAINS[c] '待同步'")
        ).firstMatch
        XCTAssertTrue(pendingStatus.waitForExistence(timeout: 10))
        XCTAssertEqual(syncToggle.value as? String, "0")
        XCTAssertTrue(pausedStatus.waitForExistence(timeout: 10))
        if syncToggle.value as? String != "1" {
            syncToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        }
        XCTAssertEqual(syncToggle.value as? String, "1")
        XCTAssertTrue(app.staticTexts["No pending personal-data changes."].waitForExistence(timeout: 20))
        button(app, "Personal profile", "个人资料").tap()
        XCTAssertTrue(app.textFields.matching(
            NSPredicate(format: "value == %@", "IOS04 Simulator")
        ).firstMatch.waitForExistence(timeout: 15))

        // The memory file is a separate personal-data object from the profile.
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let systemFiles = button(app, "System files", "系统文件")
        if !systemFiles.isHittable { app.scrollViews.firstMatch.swipeUp() }
        XCTAssertTrue(systemFiles.waitForExistence(timeout: 10))
        systemFiles.tap()
        XCTAssertFalse(app.staticTexts["feed-preferences.md"].exists)
        app.staticTexts["GLOBAL.md"].tap()
        button(app, "More", "更多").tap()
        button(app, "Edit", "编辑").tap()
        let memoryEditor = app.textViews.firstMatch
        XCTAssertTrue(memoryEditor.waitForExistence(timeout: 10))
        let memoryMarker = "IOS04 Simulator Memory \(UUID().uuidString)"
        memoryEditor.tap()
        memoryEditor.typeText("\n\(memoryMarker)")
        app.navigationBars.buttons.matching(
            NSPredicate(format: "label == 'Save' OR label == '保存'")
        ).firstMatch.tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        button(app, "Morde account", "Morde 账户").tap()
        XCTAssertTrue(app.staticTexts["No pending personal-data changes."].waitForExistence(timeout: 20))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let systemFilesAgain = button(app, "System files", "系统文件")
        if !systemFilesAgain.isHittable { app.scrollViews.firstMatch.swipeUp() }
        systemFilesAgain.tap()
        app.staticTexts["GLOBAL.md"].tap()
        let memoryCopy = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", memoryMarker)
        )
        XCTAssertTrue(memoryCopy.firstMatch.waitForExistence(timeout: 20), "The saved memory marker should round-trip from Morde.")

    }

    private func button(_ app: XCUIApplication, _ primary: String, _ alternate: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", primary, alternate)).firstMatch
    }

    private func text(_ app: XCUIApplication, _ primary: String, _ alternate: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label == %@ OR label == %@", primary, alternate)).firstMatch
    }
}
