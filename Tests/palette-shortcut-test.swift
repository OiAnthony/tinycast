import AppKit

enum PaletteMode: Equatable {
    case launcher
    case fileSearch
    case extensionCommand
}

@MainActor
final class AppSettings {
    var compactMode = false
}

@MainActor
final class AppIndex {
    func refresh() async {}
}

@MainActor
final class FileSearchSession {
    func search(_: String) {}
    func cancel() {}
}

@MainActor
final class PaletteState {
    var mode: PaletteMode = .launcher
    var query = ""
    var forceExpanded = false
    var summonCount = 0

    func prepare(mode: PaletteMode) {
        self.mode = mode
    }

    func push(mode: PaletteMode) {
        self.mode = mode
    }

    func summonFromShortcut(mode: PaletteMode) {
        self.mode = mode
        summonCount += 1
    }
}

@MainActor
final class PaletteWindowController {
    var isVisible = false
    var previousApp: NSRunningApplication?
    var hideCount = 0
    var showCount = 0

    func consumePreservedState() -> Bool { false }

    func show() {
        isVisible = true
        showCount += 1
    }

    func hide(restoreFocus _: Bool) {
        isVisible = false
        hideCount += 1
    }

    func popToRootNow() {}
    func applyCollapsed(_: Bool) {}
    func beginDrag() {}
    func endDrag() {}
}

@main
@MainActor
struct PaletteShortcutTests {
    static var failures = 0
    static var passes = 0

    static func expect(_ condition: Bool, _ message: String) {
        if condition {
            passes += 1
        } else {
            failures += 1
            print("FAIL: \(message)")
        }
    }

    static func main() {
        let palette = PaletteState()
        let window = PaletteWindowController()
        let coordinator = PaletteCoordinator(
            palette: palette,
            settings: AppSettings(),
            appIndex: AppIndex(),
            fileSearch: FileSearchSession(),
            windowController: window)

        palette.mode = .extensionCommand
        window.isVisible = true
        expect(
            !coordinator.summonFromShortcut(mode: .extensionCommand),
            "a repeated mode shortcut reports that it closed the palette")
        expect(
            window.hideCount == 1 && palette.summonCount == 0,
            "closing does not prepare or summon the mode again")

        expect(
            coordinator.summonFromShortcut(mode: .extensionCommand),
            "a hidden mode shortcut reports that it opened the palette")
        expect(
            window.showCount == 1 && palette.summonCount == 1,
            "opening summons the mode and shows the palette once")

        print("\(passes) passed, \(failures) failed")
        if failures > 0 { exit(1) }
    }
}
