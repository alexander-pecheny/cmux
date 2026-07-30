import XCTest
import AppKit

#if canImport(cmux_DEV)
@testable import cmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

@MainActor
final class GhosttyEnsureFocusWindowActivationTests: XCTestCase {
    func testAllowsActivationForActiveManager() {
        let activeManager = TabManager()
        let otherManager = TabManager()
        let targetWindow = NSWindow()
        let otherWindow = NSWindow()

        XCTAssertTrue(
            shouldAllowEnsureFocusWindowActivation(
                activeTabManager: activeManager,
                targetTabManager: activeManager,
                keyWindow: targetWindow,
                mainWindow: targetWindow,
                targetWindow: targetWindow
            )
        )
        XCTAssertFalse(
            shouldAllowEnsureFocusWindowActivation(
                activeTabManager: activeManager,
                targetTabManager: otherManager,
                keyWindow: otherWindow,
                mainWindow: otherWindow,
                targetWindow: targetWindow
            )
        )
    }

    func testAllowsActivationWhenAppHasNoKeyAndNoMainWindow() {
        let targetManager = TabManager()
        let targetWindow = NSWindow()

        XCTAssertTrue(
            shouldAllowEnsureFocusWindowActivation(
                activeTabManager: nil,
                targetTabManager: targetManager,
                keyWindow: nil,
                mainWindow: nil,
                targetWindow: targetWindow
            )
        )
        XCTAssertFalse(
            shouldAllowEnsureFocusWindowActivation(
                activeTabManager: nil,
                targetTabManager: targetManager,
                keyWindow: NSWindow(),
                mainWindow: nil,
                targetWindow: targetWindow
            )
        )
        XCTAssertFalse(
            shouldAllowEnsureFocusWindowActivation(
                activeTabManager: nil,
                targetTabManager: targetManager,
                keyWindow: nil,
                mainWindow: NSWindow(),
                targetWindow: targetWindow
            )
        )
    }
}

@MainActor
final class BuriedWindowActivationRecoveryTests: XCTestCase {
    private func snapshot(
        isMainTerminal: Bool = true,
        isVisible: Bool = true,
        isMiniaturized: Bool = false,
        isOnActiveSpace: Bool = true,
        isOnScreen: Bool = false,
        isMainWindow: Bool = false
    ) -> ActivationWindowSnapshot {
        ActivationWindowSnapshot(
            isMainTerminal: isMainTerminal,
            isVisible: isVisible,
            isMiniaturized: isMiniaturized,
            isOnActiveSpace: isOnActiveSpace,
            isOnScreen: isOnScreen,
            isMainWindow: isMainWindow
        )
    }

    func testRaisesBuriedMainWindow() {
        XCTAssertEqual(mainWindowToRaiseAfterActivation([snapshot()]), 0)
    }

    func testSkipsWhenAWindowIsAlreadyOnScreen() {
        XCTAssertNil(mainWindowToRaiseAfterActivation([snapshot(isOnScreen: true)]))
    }

    func testAnyVisibleCmuxWindowCountsAsOnScreen() {
        let windows = [
            snapshot(),
            snapshot(isMainTerminal: false, isOnScreen: true),
        ]
        XCTAssertNil(mainWindowToRaiseAfterActivation(windows))
    }

    func testPrefersTheMainWindowOverOtherBuriedWindows() {
        let windows = [
            snapshot(),
            snapshot(isMainWindow: true),
        ]
        XCTAssertEqual(mainWindowToRaiseAfterActivation(windows), 1)
    }

    func testPrefersTheActiveSpaceOverAnotherSpace() {
        let windows = [
            snapshot(isOnActiveSpace: false),
            snapshot(),
        ]
        XCTAssertEqual(mainWindowToRaiseAfterActivation(windows), 1)
    }

    func testIgnoresMiniaturizedAndNonTerminalWindows() {
        let windows = [
            snapshot(isVisible: false, isMiniaturized: true),
            snapshot(isMainTerminal: false),
        ]
        XCTAssertNil(mainWindowToRaiseAfterActivation(windows))
    }
}

@MainActor
final class CommandArrowSurfaceNavigationTests: XCTestCase {
    func testCommandOptionArrowsMoveBetweenSurfaces() {
        XCTAssertEqual(
            commandArrowSurfaceNavigationDelta(
                flags: [.command, .option], keyCode: 124, isEditingText: false
            ),
            1
        )
        XCTAssertEqual(
            commandArrowSurfaceNavigationDelta(
                flags: [.command, .option], keyCode: 123, isEditingText: false
            ),
            -1
        )
    }

    func testIgnoresTextEditing() {
        XCTAssertNil(
            commandArrowSurfaceNavigationDelta(
                flags: [.command, .option], keyCode: 123, isEditingText: true
            )
        )
    }

    func testIgnoresOtherKeysAndModifierCombinations() {
        XCTAssertNil(
            commandArrowSurfaceNavigationDelta(
                flags: [.command, .option], keyCode: 125, isEditingText: false
            )
        )
        XCTAssertNil(
            commandArrowSurfaceNavigationDelta(flags: [.command], keyCode: 123, isEditingText: false)
        )
        XCTAssertNil(
            commandArrowSurfaceNavigationDelta(
                flags: [.command, .option, .shift], keyCode: 123, isEditingText: false
            )
        )
        XCTAssertEqual(
            commandArrowSurfaceNavigationDelta(
                flags: [.command, .option, .function], keyCode: 124, isEditingText: false
            ),
            1
        )
    }
}

final class AppcastEligibilityTests: XCTestCase {
    func testOnlyShippedBundlesReceiveUpdates() {
        XCTAssertTrue(bundleIdentifierReceivesAppcastUpdates("com.cmuxterm.app", isUITest: false))
        XCTAssertTrue(bundleIdentifierReceivesAppcastUpdates("com.cmuxterm.app.nightly", isUITest: false))
        XCTAssertFalse(bundleIdentifierReceivesAppcastUpdates("com.cmuxterm.app.pecheny-fork", isUITest: false))
        XCTAssertFalse(bundleIdentifierReceivesAppcastUpdates("com.cmuxterm.app.debug.some-tag", isUITest: false))
        XCTAssertFalse(bundleIdentifierReceivesAppcastUpdates(nil, isUITest: false))
    }

    func testUITestsKeepTheUpdaterEnabled() {
        XCTAssertTrue(bundleIdentifierReceivesAppcastUpdates("com.cmuxterm.app.debug", isUITest: true))
    }
}
