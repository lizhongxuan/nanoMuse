import XCTest

final class IOS03SimulatorAcceptanceUITests: XCTestCase {
    func testLoginAndReadWorkspaceResources() throws {
        guard let account = ProcessInfo.processInfo.environment["MORDE_IOS03_TEST_USER"],
              let password = ProcessInfo.processInfo.environment["MORDE_IOS03_TEST_PASSWORD"],
              let serverAddress = ProcessInfo.processInfo.environment["MORDE_IOS03_TEST_SERVER"] else {
            throw XCTSkip("Set local IOS-03 test credentials in the test action environment.")
        }

        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        app.launchArguments = ["-morde.server", ""]
        app.launch()

        let server = app.textFields["https://morde.example"]
        XCTAssertTrue(server.waitForExistence(timeout: 10))
        server.tap()
        server.typeText(serverAddress)

        let accountField = app.textFields["账号"]
        accountField.tap()
        accountField.typeText(account)

        let passwordField = app.secureTextFields["密码"]
        passwordField.tap()
        passwordField.typeText(password)
        app.buttons["登录"].tap()

        let projects = app.tabBars.buttons["项目"]
        guard projects.waitForExistence(timeout: 15) else {
            let alert = app.alerts.firstMatch
            let message = alert.exists ? alert.staticTexts.allElementsBoundByIndex.last?.label ?? "alert" : "no alert"
            XCTFail("Sign-in did not reach the resource tabs: \(message)")
            return
        }
        projects.tap()
        XCTAssertTrue(app.staticTexts["IOS-03 本地合成验收 Workspace"].waitForExistence(timeout: 20))

        let computers = app.tabBars.buttons["电脑"]
        XCTAssertTrue(computers.exists)
        computers.tap()
        XCTAssertTrue(app.staticTexts["标准 1 核 2G"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["已停止 · AI 控制"].exists)
    }

    func testMordeDesignNavigationRoutes() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app, additionalArguments: ["-morde.localTaskPagesFixture", "-morde.localExecutionFixture"])
        let menu = app.buttons["morde.nav.menu"]
        for tab in ["chat", "tasks", "approvals", "resources"] {
            XCTAssertTrue(app.buttons["morde.nav.tab.\(tab)"].exists, "Missing \(tab) tab")
        }
        XCTAssertFalse(app.buttons["项目"].exists)
        XCTAssertFalse(app.buttons["通知"].exists)

        app.buttons["morde.nav.tab.tasks"].tap()
        XCTAssertTrue(app.buttons["morde.tasks.newTask"].waitForExistence(timeout: 15))
        menu.tap()
        XCTAssertTrue(app.buttons["morde.nav.drawer.eventChain"].waitForExistence(timeout: 5))
        app.buttons["morde.nav.drawer.eventChain"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["morde.eventChain.empty"].waitForExistence(timeout: 10) ||
                      app.descendants(matching: .any)["morde.eventChain.taskTitle"].waitForExistence(timeout: 10))

        menu.tap()
        app.buttons["morde.nav.drawer.friends"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["morde.placeholder.friends"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["morde.friends.add"].exists,
                       "Friend actions stay hidden until the feature is implemented.")
        menu.tap()
        app.buttons["morde.nav.drawer.toolChats"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["morde.placeholder.toolChats"].waitForExistence(timeout: 10))
        app.buttons["morde.toolChats.back"].tap()
        XCTAssertTrue(menu.waitForExistence(timeout: 5))

        menu.tap()
        let settings = app.buttons["设置"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.tap()
        for row in ["account", "connectors", "devices", "credentials", "permissions",
                    "approvalRules", "notifications", "appearance", "about"] {
            XCTAssertTrue(app.descendants(matching: .any)["morde.settings.row.\(row)"].waitForExistence(timeout: 5),
                          "Missing settings row \(row)")
        }
        XCTAssertTrue(app.buttons["morde.settings.executionControl"].exists)
    }

    func testMordeDrawerGeometrySearchAndConversationPagination() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app, additionalArguments: ["-morde.localTaskPagesFixture"])

        let menu = app.buttons["morde.nav.menu"]
        XCTAssertTrue(menu.waitForExistence(timeout: 10))
        XCTAssertEqual(menu.frame.minX, 22, accuracy: 1)
        XCTAssertEqual(menu.frame.width, 38, accuracy: 1)

        let tabFrames = ["chat", "tasks", "approvals", "resources"].map {
            app.buttons["morde.nav.tab.\($0)"].frame
        }
        XCTAssertEqual(tabFrames.map(\.width).max()! - tabFrames.map(\.width).min()!, 0, accuracy: 1)
        XCTAssertTrue(zip(tabFrames, tabFrames.dropFirst()).allSatisfy { $0.0.minX < $0.1.minX })

        menu.tap()
        let settings = app.buttons["morde.nav.drawer.settings"]
        let newChat = app.buttons["morde.nav.drawer.newChat"]
        let search = app.textFields["morde.nav.drawer.search"]
        let searchContainer = app.descendants(matching: .any)["morde.nav.drawer.search.container"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        XCTAssertTrue(newChat.exists)
        XCTAssertTrue(searchContainer.exists)
        XCTAssertEqual(settings.frame.width, 38, accuracy: 1)
        XCTAssertEqual(newChat.frame.width, 38, accuracy: 1)
        XCTAssertEqual(searchContainer.frame.height, 38, accuracy: 1)

        let firstPageConversation = app.buttons["morde.nav.drawer.conversation-c2345678"]
        XCTAssertTrue(firstPageConversation.waitForExistence(timeout: 10))
        let secondPageConversation = app.buttons["morde.nav.drawer.conversation-c3456789"]
        let drawerScroll = app.scrollViews["morde.nav.drawer.scroll"]
        XCTAssertTrue(drawerScroll.exists)
        for _ in 0..<5 where !secondPageConversation.exists {
            drawerScroll.swipeUp()
        }
        XCTAssertTrue(secondPageConversation.waitForExistence(timeout: 15),
                      "Opening the drawer should load the next conversation page when its last row appears.")
        XCTAssertFalse(app.buttons["项目"].exists)
        XCTAssertFalse(app.buttons["通知"].exists)

        search.tap()
        search.typeText("Needle")
        for _ in 0..<5 where !secondPageConversation.exists {
            drawerScroll.swipeUp()
        }
        XCTAssertTrue(secondPageConversation.waitForExistence(timeout: 5))
        XCTAssertFalse(firstPageConversation.exists, "Search should filter conversation rows as text changes.")
        search.typeText("\n")
        XCTAssertTrue(settings.exists, "Submitting the live filter must not dismiss the drawer.")
    }

    func testMordeTaskDetailShowsRealStepsWithoutBudget() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app, additionalArguments: ["-morde.localTaskPagesFixture"])
        app.buttons["morde.nav.tab.tasks"].tap()

        let task = app.buttons["morde.tasks.row.q0000001"]
        XCTAssertTrue(task.waitForExistence(timeout: 15))
        task.tap()

        XCTAssertTrue(app.staticTexts["morde.task.objective"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.descendants(matching: .any)["morde.task.step.s0000001"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["morde.task.action.pause"].exists)
        XCTAssertFalse(app.staticTexts["Private budget field"].exists)
    }

    func testMordeTaskListShowsConfirmedEmptyState() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app, additionalArguments: ["-morde.localTaskPagesEmptyFixture"])
        app.buttons["morde.nav.tab.tasks"].tap()

        let menu = app.buttons["morde.nav.menu"]
        let title = app.staticTexts["任务"]
        let newTask = app.buttons["morde.tasks.newTask"]
        XCTAssertTrue(menu.waitForExistence(timeout: 15))
        XCTAssertTrue(title.exists)
        XCTAssertTrue(newTask.exists)
        XCTAssertEqual(menu.frame.minX, 22, accuracy: 1)
        XCTAssertEqual(menu.frame.width, 38, accuracy: 1)
        XCTAssertEqual(title.frame.minX, menu.frame.maxX + 10, accuracy: 1)
        XCTAssertEqual(newTask.frame.maxX, app.frame.width - 22, accuracy: 1)
        XCTAssertTrue(app.descendants(matching: .any)["morde.tasks.empty"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "identifier CONTAINS %@", "morde.tasks.row.")).firstMatch.exists)
    }

    func testMordeTaskListContinuesAfterAnEmptyIntermediatePage() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app, additionalArguments: ["-morde.localTaskPagesEmptyIntermediateFixture"])
        app.buttons["morde.nav.tab.tasks"].tap()

        let taskList = app.scrollViews["morde.tasks.list"]
        XCTAssertTrue(taskList.waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["morde.tasks.empty"].exists)
        XCTAssertFalse(app.buttons["morde.tasks.loadMore"].exists)

        let nextPageTask = app.buttons["morde.tasks.row.q0000001"]
        for _ in 0..<10 where !nextPageTask.exists { taskList.swipeUp() }
        XCTAssertTrue(nextPageTask.waitForExistence(timeout: 15),
                      "An empty cursor page should continue automatically without adding a load-more button.")
    }

    func testMordeTaskListRecoversFromLoadFailureWithPullToRefresh() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app, additionalArguments: ["-morde.localTaskPagesRetryFixture"])
        app.buttons["morde.nav.tab.tasks"].tap()

        let loadError = app.descendants(matching: .any)["morde.tasks.loadError"]
        XCTAssertTrue(loadError.waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["morde.tasks.loadError.retry"].exists)
        let taskList = app.scrollViews["morde.tasks.list"]
        XCTAssertTrue(taskList.exists)
        let refreshStart = taskList.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.02))
        let refreshEnd = taskList.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75))
        refreshStart.press(forDuration: 0.1, thenDragTo: refreshEnd)
        XCTAssertTrue(app.descendants(matching: .any)["morde.tasks.empty"].waitForExistence(timeout: 20))
    }

    func testMordeEventChainShowsRealEmptyStateAndReturnsToChat() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app, additionalArguments: ["-morde.localTaskPagesEmptyFixture"])
        app.buttons["morde.nav.menu"].tap()
        app.buttons["morde.nav.drawer.eventChain"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["morde.eventChain.empty"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.staticTexts["morde.eventChain.taskTitle"].exists)
        XCTAssertFalse(app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "morde.eventChain.event.")).firstMatch.exists)

        app.buttons["morde.nav.tab.chat"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["morde.chat.actions"].waitForExistence(timeout: 10))
    }

    func testMordeEventChainRecoversExpiredCursorAndDeduplicatesEvents() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app, additionalArguments: [
            "-morde.localTaskPagesFixture",
            "-morde.localTaskPagesEventChainTimelineFixture",
        ])
        app.buttons["morde.nav.tab.approvals"].tap()

        let eventChain = app.buttons["mif.approval.timeline.q0000101"]
        XCTAssertTrue(eventChain.waitForExistence(timeout: 15))
        eventChain.tap()

        let taskTitle = app.staticTexts["morde.eventChain.taskTitle"]
        XCTAssertTrue(taskTitle.waitForExistence(timeout: 15))
        XCTAssertEqual(taskTitle.label, "Local task timeline fixture")
        let recoveredEvents = app.staticTexts.matching(NSPredicate(format: "label == %@", "Recovered event"))
        XCTAssertTrue(recoveredEvents.firstMatch.waitForExistence(timeout: 25))
        XCTAssertEqual(recoveredEvents.count, 1)
        XCTAssertFalse(app.staticTexts["Private budget field"].exists)
    }

    func testMordeApprovalInboxShowsOnlyConfirmedDecisions() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app, additionalArguments: [
            "-morde.localTaskPagesFixture",
            "-morde.localTaskPagesApprovalRefreshPendingFixture",
        ])
        app.buttons["morde.nav.tab.approvals"].tap()

        let count = app.staticTexts["mif.approval.count"]
        XCTAssertTrue(count.waitForExistence(timeout: 20))
        XCTAssertTrue(count.label.contains("1"), "The header should show the single confirmed approval")
        XCTAssertTrue(app.buttons["mif.approval.reject.q0000101:r0000001:1"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["mif.approval.approve.q0000101:r0000001:1"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["mif.approval.partial"].exists)
        let eventChain = app.buttons["mif.approval.timeline.q0000101"]
        XCTAssertEqual(eventChain.label, "看事件链 ›")
        let approve = app.buttons["mif.approval.approve.q0000101:r0000001:1"]
        approve.tap()
        let decisionSubmitted = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"),
                                                          object: approve)
        XCTAssertEqual(XCTWaiter.wait(for: [decisionSubmitted], timeout: 10), .completed,
                       "The accepted decision should replace the response buttons while task status refreshes.")
        XCTAssertTrue(eventChain.exists, "The event-chain link must remain available after a decision is submitted.")
        eventChain.tap()
        XCTAssertEqual(app.staticTexts["morde.eventChain.taskTitle"].waitForExistence(timeout: 15), true)
        XCTAssertEqual(app.staticTexts["morde.eventChain.taskTitle"].label, "Local approval fixture")
    }

    func testMordeApprovalCountIsHiddenWhenTaskDetailsArePartial() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app, additionalArguments: [
            "-morde.localTaskPagesFixture",
            "-morde.localTaskPagesApprovalPartialFixture",
        ])
        app.buttons["morde.nav.tab.approvals"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["mif.approval.partial"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.staticTexts["mif.approval.count"].exists,
                       "A partial task-detail read must not be presented as a confirmed count.")
        XCTAssertTrue(app.buttons["mif.approval.approve.q0000101:r0000001:1"].exists)
        XCTAssertFalse(app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "mif.approval.approve.q0000102:")
        ).firstMatch.exists)
    }

    func testMordeWorkItemsRouteShowsDesignFiltersAndCreateForm() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app, additionalArguments: ["-morde.localWorkItemFixture"])
        app.buttons["morde.nav.menu"].tap()

        let workItems = app.buttons["morde.nav.drawer.workItems"]
        XCTAssertTrue(workItems.waitForExistence(timeout: 10))
        workItems.tap()

        let projectPicker = app.buttons["morde.workItems.projectPicker"]
        XCTAssertTrue(projectPicker.waitForExistence(timeout: 10))
        projectPicker.tap()
        let project = app.buttons["morde.workItems.project.j0000001"]
        XCTAssertTrue(project.waitForExistence(timeout: 5))
        project.tap()

        for filter in ["all", "bug", "request", "unclaimed"] {
            XCTAssertTrue(app.buttons["morde.workItems.filter.\(filter)"].waitForExistence(timeout: 10),
                          "Missing \(filter) work item filter")
        }
        let create = app.buttons["morde.workItems.create.open"]
        XCTAssertTrue(create.waitForExistence(timeout: 15))
        XCTAssertTrue(waitForHittable(create))
        create.tap()

        XCTAssertTrue(app.textFields["morde.workItems.create.title"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["morde.workItems.create.category.bug"].exists)
        XCTAssertTrue(app.buttons["morde.workItems.create.category.request"].exists)
    }

    func testMordeWorkItemCreateFailureKeepsFormAndInput() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app, additionalArguments: [
            "-morde.localWorkItemFixture",
            "-morde.localWorkItemCreateFailureFixture",
        ])
        app.buttons["morde.nav.menu"].tap()
        app.buttons["morde.nav.drawer.workItems"].tap()

        let projectPicker = app.buttons["morde.workItems.projectPicker"]
        XCTAssertTrue(projectPicker.waitForExistence(timeout: 10))
        projectPicker.tap()
        app.buttons["morde.workItems.project.j0000001"].tap()
        let create = app.buttons["morde.workItems.create.open"]
        XCTAssertTrue(create.waitForExistence(timeout: 10))
        create.tap()

        let title = app.textFields["morde.workItems.create.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        title.tap()
        title.typeText("Keep this title after failure")
        let keyboardDone = app.buttons["morde.workItems.keyboardDone"]
        if keyboardDone.waitForExistence(timeout: 2) { keyboardDone.tap() }

        let submit = app.buttons["morde.workItems.create.submit"]
        XCTAssertTrue(waitForHittable(submit, timeout: 10))
        submit.tap()
        let error = app.staticTexts["morde.workItems.create.error"]
        XCTAssertTrue(error.waitForExistence(timeout: 15))
        XCTAssertTrue(app.textFields["morde.workItems.create.title"].exists,
                      "A failed create must leave the form open.")
        XCTAssertEqual(app.textFields["morde.workItems.create.title"].value as? String,
                       "Keep this title after failure")
    }

    func testMordeTaskListDropsLatePageAfterAccountSwitch() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app, additionalArguments: [
            "-morde.localAccountIsolationFixture",
            "-morde.localDelayedAccountResponseFixture",
        ], loginName: "account-a")
        app.buttons["morde.nav.tab.tasks"].tap()

        XCTAssertTrue(app.buttons["morde.tasks.row.q0000001"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.descendants(matching: .any)["morde.tasks.loadingMore"].waitForExistence(timeout: 10),
                      "Account A's second page should be in flight before switching accounts.")

        app.buttons["morde.nav.menu"].tap()
        app.buttons["morde.nav.drawer.settings"].tap()
        let drawerScrim = app.buttons["morde.nav.drawer.scrim"]
        let drawerClosed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"),
                                                     object: drawerScrim)
        XCTAssertEqual(XCTWaiter.wait(for: [drawerClosed], timeout: 5), .completed,
                       "Wait for the navigation drawer to close before tapping a settings row.")
        let accountSettings = app.buttons["morde.settings.row.account"]
        XCTAssertTrue(waitForHittable(accountSettings, timeout: 10),
                      "Wait until the settings route has finished opening before choosing the account page.")
        accountSettings.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        XCTAssertTrue(app.staticTexts["账号"].waitForExistence(timeout: 10),
                      "The account detail page should be visible before signing out.")
        let signOut = app.buttons["morde.account.signOut"]
        let bottomTab = app.buttons["morde.nav.tab.approvals"]
        let accountList = app.collectionViews.firstMatch.exists ? app.collectionViews.firstMatch :
            (app.tables.firstMatch.exists ? app.tables.firstMatch : app.scrollViews.firstMatch)
        XCTAssertTrue(accountList.waitForExistence(timeout: 5), "The account settings list should be scrollable.")
        for _ in 0..<8 where signOut.frame.maxY >= bottomTab.frame.minY {
            accountList.swipeUp()
        }
        XCTAssertTrue(signOut.isHittable, "The sign-out action should be visible after scrolling the account list.")
        XCTAssertLessThan(signOut.frame.maxY, bottomTab.frame.minY,
                          "The sign-out action must sit above the custom bottom navigation before tapping.")
        signOut.tap()
        let confirmSignOut = app.descendants(matching: .any)
            .matching(identifier: "morde.account.signOut.confirm").firstMatch
        XCTAssertTrue(confirmSignOut.waitForExistence(timeout: 5),
                      "The native sign-out confirmation should be visible.")
        confirmSignOut.tap()

        let username = app.textFields["morde.auth.username"]
        XCTAssertTrue(username.waitForExistence(timeout: 10))
        username.tap()
        username.typeText("account-b")
        let password = app.secureTextFields["morde.auth.password"]
        password.tap()
        password.typeText("local-password")
        app.buttons["morde.auth.submit"].tap()
        XCTAssertTrue(app.buttons["morde.nav.menu"].waitForExistence(timeout: 20))
        app.buttons["morde.nav.tab.tasks"].tap()
        XCTAssertTrue(app.buttons["morde.tasks.row.q0000002"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["morde.tasks.row.q0000001"].exists)

        // The fixture releases Account A's pending page after 12 seconds.
        let latePageReleased = expectation(description: "The delayed Account A page has been released")
        DispatchQueue.global().asyncAfter(deadline: .now() + 13) { latePageReleased.fulfill() }
        wait(for: [latePageReleased], timeout: 14)
        XCTAssertFalse(app.buttons["morde.tasks.row.q0000003"].exists,
                       "A late page from Account A must not appear in Account B's task list.")
        XCTAssertFalse(app.staticTexts["account-a-late-private-task"].exists)
    }

    func testMordeChatLongPressActionsOpenTaskOptionsAndImporter() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app)

        let actions = app.descendants(matching: .any)["morde.chat.actions"]
        XCTAssertTrue(actions.waitForExistence(timeout: 10))
        actions.press(forDuration: 1)
        let taskOptions = app.buttons["morde.chat.action.taskOptions"]
        XCTAssertTrue(taskOptions.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["morde.chat.action.voiceInput"].exists)
        XCTAssertTrue(app.buttons["morde.chat.action.attachments"].exists)
        taskOptions.tap()
        XCTAssertTrue(app.descendants(matching: .any)["morde.task.model"].waitForExistence(timeout: 10))
        app.buttons["morde.chat.taskOptions.done"].tap()

        actions.press(forDuration: 1)
        let addAttachment = app.buttons["morde.chat.action.attachments"]
        XCTAssertTrue(addAttachment.waitForExistence(timeout: 5))
        addAttachment.tap()
        let cancelEnglish = app.buttons["Cancel"]
        let cancelChinese = app.buttons["取消"]
        XCTAssertTrue(cancelEnglish.waitForExistence(timeout: 10) || cancelChinese.exists,
                      "The image/PDF document picker did not open")
    }

    func testMordeSettingsRoutesAndHonestUnavailableRows() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app)
        app.buttons["morde.nav.menu"].tap()
        app.buttons["设置"].tap()

        let back = app.buttons["返回"]
        let settingsTitle = app.staticTexts["设置"]
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        XCTAssertEqual(back.frame.minX, 22, accuracy: 1)
        XCTAssertEqual(back.frame.width, 38, accuracy: 1)
        XCTAssertEqual(settingsTitle.frame.minX, back.frame.maxX + 10, accuracy: 1)
        XCTAssertEqual(app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "morde.settings.row.")
        ).count, 9)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "已用")).firstMatch.exists)
        let accountRow = app.buttons["morde.settings.row.account"]
        XCTAssertTrue(accountRow.exists)
        XCTAssertEqual(accountRow.frame.minX, 22, accuracy: 1)
        XCTAssertEqual(accountRow.frame.width, app.frame.width - 44, accuracy: 1)
        XCTAssertEqual(accountRow.frame.height, 45, accuracy: 3)

        for row in ["connectors", "permissions", "approvalRules", "notifications", "appearance"] {
            let settingsRow = app.buttons["morde.settings.row.\(row)"]
            XCTAssertTrue(settingsRow.waitForExistence(timeout: 5))
            XCTAssertTrue(waitForHittable(settingsRow), "Settings row \(row) is covered by a transition")
            settingsRow.tap()
            XCTAssertTrue(app.staticTexts["暂未实现"].waitForExistence(timeout: 5),
                          "Settings row \(row) did not open its unavailable state")
            app.buttons["返回"].tap()
            XCTAssertTrue(settingsRow.waitForExistence(timeout: 5))
        }

        app.buttons["morde.settings.row.about"].tap()
        XCTAssertTrue(app.staticTexts["Morde iOS"].waitForExistence(timeout: 5))
    }

    func testMordeGlobalExecutionControlConfirmsAndCanBeReenabled() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app, additionalArguments: ["-morde.localExecutionFixture"])
        app.buttons["morde.nav.menu"].tap()
        app.buttons["设置"].tap()

        let execution = app.buttons["morde.settings.executionControl"]
        XCTAssertTrue(execution.waitForExistence(timeout: 10))
        let enabledLabel = NSPredicate(format: "label == %@ AND isEnabled == true", "急停全部任务")
        let enabled = XCTNSPredicateExpectation(predicate: enabledLabel, object: execution)
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 10), .completed)
        execution.tap()

        XCTAssertTrue(app.staticTexts["急停全部云端任务？"].waitForExistence(timeout: 5))
        let confirmations = app.buttons.matching(NSPredicate(format: "label == %@", "急停全部任务"))
        XCTAssertGreaterThan(confirmations.count, 1)
        confirmations.element(boundBy: confirmations.count - 1).tap()

        let reenableLabel = NSPredicate(format: "label == %@ AND isEnabled == true", "重新启用全部任务")
        let reenable = XCTNSPredicateExpectation(predicate: reenableLabel, object: execution)
        XCTAssertEqual(XCTWaiter.wait(for: [reenable], timeout: 20), .completed)
        execution.tap()
        let enabledAgain = XCTNSPredicateExpectation(predicate: enabledLabel, object: execution)
        XCTAssertEqual(XCTWaiter.wait(for: [enabledAgain], timeout: 10), .completed)
    }

    func testMordeResourceWorkspaceRouteBrowsesSyntheticManifest() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app, additionalArguments: ["-morde.localResourceAcceptanceFixture"])
        app.buttons["morde.nav.tab.resources"].tap()

        let workspace = app.buttons["morde.resources.workspace.open.w0000001"]
        XCTAssertTrue(workspace.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["morde.resources.host.open.h0000001"].exists)
        let addResource = app.buttons["morde.resources.add"]
        XCTAssertTrue(addResource.exists)
        XCTAssertTrue(addResource.isEnabled)
        addResource.tap()
        let addUnavailable = app.staticTexts["morde.resources.add.unavailable"]
        XCTAssertTrue(addUnavailable.waitForExistence(timeout: 5))
        XCTAssertFalse(app.alerts.firstMatch.exists,
                       "The prototype add action is transient feedback and must not add a dismissal button.")
        workspace.tap()

        let workspaceFiles = app.collectionViews["morde.workspace.files"]
        XCTAssertTrue(workspaceFiles.waitForExistence(timeout: 10))
        let workspaceTitle = app.descendants(matching: .any)["morde.workspace.title"]
        XCTAssertTrue(workspaceTitle.waitForExistence(timeout: 10))
        XCTAssertFalse(app.pickers["Workspace"].exists)
        XCTAssertFalse(app.buttons["选择文件"].exists)
        XCTAssertFalse(app.buttons["比较来源版本与当前版本"].exists)

        workspaceTitle.press(forDuration: 1)
        let uploadMenuItem = app.buttons["上传文件"]
        let historyMenuItem = app.buttons["版本比较与恢复"]
        XCTAssertTrue(uploadMenuItem.waitForExistence(timeout: 5))
        XCTAssertTrue(historyMenuItem.exists)
        uploadMenuItem.tap()
        XCTAssertTrue(app.buttons["选择文件"].waitForExistence(timeout: 5))
        app.buttons["完成"].tap()

        workspaceTitle.press(forDuration: 1)
        let openHistory = app.buttons["版本比较与恢复"]
        XCTAssertTrue(openHistory.waitForExistence(timeout: 5))
        openHistory.tap()
        XCTAssertTrue(app.textFields["恢复来源版本号"].waitForExistence(timeout: 5))
        app.buttons["完成"].tap()

        workspaceFiles.swipeUp()
        XCTAssertTrue(app.staticTexts["README.md"].waitForExistence(timeout: 10))
        app.buttons["morde.workspace.directory.docs"].tap()
        workspaceFiles.swipeUp()
        XCTAssertTrue(app.staticTexts["guide.md"].waitForExistence(timeout: 10))
        app.buttons["返回资源"].tap()
        XCTAssertTrue(app.buttons["morde.nav.tab.resources"].waitForExistence(timeout: 5))
    }

    func testMordeResourcePermissionMessageRequiresRunningSharedHost() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app, additionalArguments: ["-morde.localResourceAcceptanceFixture"])
        app.buttons["morde.nav.tab.resources"].tap()

        let runningWithoutPermission = app.descendants(matching: .any)["morde.resources.host.h0000009"]
        XCTAssertTrue(runningWithoutPermission.waitForExistence(timeout: 15))
        XCTAssertTrue(runningWithoutPermission.staticTexts["你没有权限查看此电脑。"].exists)

        let offlineWithoutPermission = app.descendants(matching: .any)["morde.resources.host.h0000010"]
        XCTAssertTrue(offlineWithoutPermission.waitForExistence(timeout: 15))
        XCTAssertFalse(offlineWithoutPermission.staticTexts["你没有权限查看此电脑。"].exists,
                       "An offline host should show its real state, not a permission failure.")
    }

    func testMordeResourcePreferenceFailureKeepsConfirmedEmptySections() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app, additionalArguments: [
            "-morde.localResourceConfirmedEmptyFixture",
            "-morde.localResourceDefaultHostPreferenceFailureFixture",
        ])
        app.buttons["morde.nav.tab.resources"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["morde.resources.empty.cloudComputers"]
            .waitForExistence(timeout: 15))
        XCTAssertTrue(app.descendants(matching: .any)["morde.resources.empty.workspaces"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["morde.resources.empty.cloudPhones"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["morde.resources.empty.aiTools"].exists)
        XCTAssertFalse(app.alerts["请求失败"].exists)
    }

    func testMordeComputerRouteAcceptsSyntheticTicketAndReturnsToResources() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app, additionalArguments: ["-morde.localResourceAcceptanceFixture"])
        app.buttons["morde.nav.tab.resources"].tap()

        let host = app.buttons["morde.resources.host.open.h0000001"]
        XCTAssertTrue(host.waitForExistence(timeout: 10))
        host.tap()

        XCTAssertTrue(app.buttons["morde.computer.close"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Running host"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["morde.computer.webview"].waitForExistence(timeout: 10))

        app.buttons["morde.computer.close"].tap()
        XCTAssertTrue(app.buttons["morde.nav.tab.resources"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["morde.resources.host.open.h0000001"].exists)

        let sharedHost = app.buttons["morde.resources.host.open.h0000008"]
        XCTAssertTrue(sharedHost.waitForExistence(timeout: 10))
        sharedHost.tap()
        XCTAssertTrue(app.staticTexts["Shared read-only host"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["morde.computer.webview"].waitForExistence(timeout: 10))
        app.buttons["morde.computer.close"].tap()
        XCTAssertTrue(app.buttons["morde.resources.host.open.h0000008"].waitForExistence(timeout: 5))
    }

    func testMordeComputerRouteReportsWebViewLoadFailure() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app, additionalArguments: ["-morde.localResourceAcceptanceFixture"])
        app.buttons["morde.nav.tab.resources"].tap()

        let host = app.buttons["morde.resources.host.open.h0000001"]
        XCTAssertTrue(host.waitForExistence(timeout: 10))
        host.tap()
        XCTAssertTrue(app.buttons["morde.computer.close"].waitForExistence(timeout: 10))

        let failure = app.staticTexts["morde.computer.pageLoadFailure"]
        XCTAssertTrue(failure.waitForExistence(timeout: 30),
                      "A failed Host WebView navigation should not leave a blank page.")
        app.buttons["morde.computer.close"].tap()
        XCTAssertTrue(app.buttons["morde.resources.host.open.h0000001"].waitForExistence(timeout: 5))
    }

    func testMordeChatComposerSubmitsFromKeyboardReturn() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app, additionalArguments: [
            "-morde.localTaskSSEFixture", "-morde.localTaskSequentialSendFixture",
        ])

        let composer = app.textFields["morde.chat.composer"]
        XCTAssertTrue(composer.waitForExistence(timeout: 15))
        composer.tap()
        composer.typeText("Keyboard submit fixture\n")

        XCTAssertTrue(app.descendants(matching: .any)["morde.chat.taskSummary"].waitForExistence(timeout: 20),
                      "The keyboard Return action should submit through the same guarded chat path.")
        XCTAssertTrue(app.staticTexts["Keyboard submit fixture"].exists)
    }

    func testMordeChatComposerQueuesFollowUpOnActiveTask() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app, additionalArguments: [
            "-morde.localTaskSSEFixture", "-morde.localTaskSequentialSendFixture", "-morde.localTaskQueueFixture",
        ])

        let composer = app.textFields["morde.chat.composer"]
        XCTAssertTrue(composer.waitForExistence(timeout: 15))
        composer.tap()
        composer.typeText("Queue this follow-up fixture")

        let enqueue = app.buttons["morde.chat.enqueueTask"]
        XCTAssertTrue(enqueue.waitForExistence(timeout: 15), "A matching running task should expose queue in the send position.")
        XCTAssertTrue(enqueue.isEnabled)
        enqueue.tap()

        XCTAssertTrue(app.staticTexts["Queue this follow-up fixture"].waitForExistence(timeout: 20),
                      "The accepted follow-up message should appear in the same conversation.")
        XCTAssertTrue(app.buttons["morde.chat.stopTask"].waitForExistence(timeout: 10),
                      "After the draft is accepted, the running task should return to its stop action.")
    }

    func testMordeFullLayoutUploadsAndSendsImageAndPDFFixture() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app, additionalArguments: ["-morde.localChatAttachmentFixture"])

        XCTAssertTrue(app.staticTexts["fixture-image.jpg"].waitForExistence(timeout: 40))
        XCTAssertTrue(app.staticTexts["fixture.pdf"].waitForExistence(timeout: 40))
        let send = app.buttons["morde.task.send"]
        XCTAssertTrue(send.waitForExistence(timeout: 10))
        let sendEnabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isEnabled == true"),
                                                    object: send)
        XCTAssertEqual(XCTWaiter.wait(for: [sendEnabled], timeout: 40), .completed)
        XCTAssertTrue(send.isEnabled)
        send.tap()
        XCTAssertTrue(app.descendants(matching: .any)["morde.chat.taskSummary"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.staticTexts["Synthetic attachment request accepted."].exists)

        let imageAttachment = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "fixture-image.jpg"))
            .firstMatch
        XCTAssertTrue(imageAttachment.waitForExistence(timeout: 10))
        imageAttachment.tap()
        XCTAssertTrue(app.descendants(matching: .any)["morde.attachment.preview.image"]
            .waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["Share"].exists)
        XCTAssertFalse(app.buttons["Save to Files"].exists)
        app.buttons["morde.attachment.preview.back"].tap()

        let pdfAttachment = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "fixture.pdf"))
            .firstMatch
        XCTAssertTrue(pdfAttachment.waitForExistence(timeout: 10))
        pdfAttachment.tap()
        XCTAssertTrue(app.descendants(matching: .any)["morde.attachment.preview.pdf"]
            .waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["Share"].exists)
        XCTAssertFalse(app.buttons["Save to Files"].exists)
        app.buttons["morde.attachment.preview.back"].tap()

        app.buttons["morde.nav.tab.resources"].tap()
        app.buttons["morde.nav.menu"].tap()
        app.buttons["morde.nav.drawer.library"].tap()
        let myUploads = app.buttons["morde.library.source.myUploads"]
        XCTAssertTrue(myUploads.waitForExistence(timeout: 15))
        myUploads.tap()
        let libraryImage = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "fixture-image.jpg")
        ).firstMatch
        XCTAssertTrue(libraryImage.waitForExistence(timeout: 15))
        libraryImage.tap()
        XCTAssertTrue(app.descendants(matching: .any)["morde.attachment.preview.image"]
            .waitForExistence(timeout: 15))
        app.buttons["morde.attachment.preview.back"].tap()
        XCTAssertTrue(myUploads.exists, "Returning from a preview should preserve the library source filter.")
    }

    func testMordeAttachmentDownloadFailureDoesNotOpenBlankPreview() {
        let app = XCUIApplication(bundleIdentifier: "io.morde.app")
        launchLocalChat(app, additionalArguments: [
            "-morde.localChatAttachmentFixture",
            "-morde.localChatAttachmentDownloadFailureFixture",
        ])

        XCTAssertTrue(app.staticTexts["fixture-image.jpg"].waitForExistence(timeout: 40))
        let send = app.buttons["morde.task.send"]
        let sendEnabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isEnabled == true"),
                                                    object: send)
        XCTAssertEqual(XCTWaiter.wait(for: [sendEnabled], timeout: 40), .completed)
        send.tap()
        XCTAssertTrue(app.staticTexts["Synthetic attachment request accepted."].waitForExistence(timeout: 30))

        let imageAttachment = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "fixture-image.jpg"))
            .firstMatch
        XCTAssertTrue(imageAttachment.waitForExistence(timeout: 10))
        imageAttachment.tap()
        let failure = app.alerts["请求失败"]
        XCTAssertTrue(failure.waitForExistence(timeout: 15))
        XCTAssertTrue(failure.buttons["确定"].exists, "A failed download should be reported to the user.")
        XCTAssertFalse(app.descendants(matching: .any)["morde.attachment.preview.image"].exists)
        failure.buttons["确定"].tap()
    }

    private func launchLocalChat(_ app: XCUIApplication, additionalArguments: [String] = [],
                                 loginName: String = "morde-design-test") {
        app.launchArguments = ["-morde.server", "", "-morde.localRegistrationStub",
                               "-morde.localRegistrationApproved", "-morde.localMainChatFixture"] + additionalArguments
        app.launch()
        let usernameField = app.textFields["morde.auth.username"]
        if usernameField.waitForExistence(timeout: 5) {
            usernameField.tap()
            usernameField.typeText(loginName)
            let password = app.secureTextFields["morde.auth.password"]
            password.tap()
            password.typeText("local-password")
            app.buttons["morde.auth.submit"].tap()
        }
        XCTAssertTrue(app.buttons["morde.nav.menu"].waitForExistence(timeout: 30),
                      "Local Morde app did not reach the chat route")
    }

    private func waitForHittable(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isHittable == true"),
                                                    object: element)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
