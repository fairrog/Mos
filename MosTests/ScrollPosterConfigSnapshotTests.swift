import XCTest
@testable import Mos_Debug

final class ScrollPosterConfigSnapshotTests: XCTestCase {

    private var savedSim = false
    private var savedDead = 1.0
    private var savedApp: Application?

    override func setUp() {
        super.setUp()
        savedSim = Options.shared.scroll.smoothSimTrackpad
        savedDead = Options.shared.scroll.deadZone
        savedApp = ScrollCore.shared.application
    }

    override func tearDown() {
        Options.shared.scroll.smoothSimTrackpad = savedSim
        Options.shared.scroll.deadZone = savedDead
        ScrollCore.shared.application = savedApp
        super.tearDown()
    }

    /// 快照捕获后改动 live Options 不应影响已捕获的值 (证明快照而非实时读)
    func testConfigSnapshot_capturesValuesNotLiveReads() {
        ScrollCore.shared.application = nil
        Options.shared.scroll.smoothSimTrackpad = true
        Options.shared.scroll.deadZone = 7.0

        ScrollPoster.shared.captureConfigSnapshotForTests()

        // 改 live 值, 快照不应跟随
        Options.shared.scroll.smoothSimTrackpad = false
        Options.shared.scroll.deadZone = 1.0

        let snap = ScrollPoster.shared.configSnapshotForTests
        XCTAssertTrue(snap.simTrackpadEnabled, "simTrackpadEnabled 应为捕获时的 true")
        XCTAssertEqual(snap.deadZone, 7.0, "deadZone 应为捕获时的 7.0")
    }

    func testConfigSnapshot_usesPerApplicationDeadZone() {
        let application = Application(path: "/Applications/ATAS X.app")
        application.inherit = false
        application.scroll.deadZone = 0.3
        ScrollCore.shared.application = application
        Options.shared.scroll.deadZone = 1.0

        ScrollPoster.shared.captureConfigSnapshotForTests()

        XCTAssertEqual(
            ScrollPoster.shared.configSnapshotForTests.deadZone,
            0.3,
            "未继承配置的应用应使用自己的死区"
        )
    }

    func testConfigSnapshot_inheritedApplicationUsesGlobalDeadZone() {
        let application = Application(path: "/Applications/Example.app")
        application.inherit = true
        application.scroll.deadZone = 0.2
        ScrollCore.shared.application = application
        Options.shared.scroll.deadZone = 0.7

        ScrollPoster.shared.captureConfigSnapshotForTests()

        XCTAssertEqual(
            ScrollPoster.shared.configSnapshotForTests.deadZone,
            0.7,
            "继承配置的应用应使用全局死区"
        )
    }
}
