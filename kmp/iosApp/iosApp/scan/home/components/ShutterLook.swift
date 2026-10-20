import SwiftUI
import SharedLogic

/// What the shutter shows about the service, as a plain Swift value: the views below take
/// this instead of the Kotlin `ShutterMood`, so they stay previewable without a component.
enum ShutterLook: CaseIterable {
    case checking, ready, busy, blocked, offline

    init(_ mood: ShutterMood) {
        if mood == ShutterMood.ready {
            self = .ready
        } else if mood == ShutterMood.busy {
            self = .busy
        } else if mood == ShutterMood.blocked {
            self = .blocked
        } else if mood == ShutterMood.offline {
            self = .offline
        } else {
            self = .checking
        }
    }

    /// A shot now would get no answer: the shutter refuses it.
    var isRefusing: Bool { self == .blocked || self == .offline }
}

/// What the hint over the shutter says, as a plain Swift value (see `ShutterLook`).
enum HintKind {
    case aim, status, queued

    init(_ hint: StatusHint) {
        if hint == StatusHint.status {
            self = .status
        } else if hint == StatusHint.queued {
            self = .queued
        } else {
            self = .aim
        }
    }
}

/// The words of the hint capsule: the resting text, and the status per mood.
enum StatusHintText {

    static var aim: String { String(localized: "scan_hint") }

    /// The text of the status layer. `queueAhead` is how many photos wait ahead (0 hides it).
    static func status(look: ShutterLook, hint: HintKind, queueAhead: Int) -> String {
        if hint == .queued {
            return queueAhead > 0
                ? L10n.format("scan_status_queued_ahead", Int32(queueAhead))
                : L10n.string("scan_status_queued")
        }
        switch look {
        case .checking: return L10n.string("scan_status_checking")
        case .ready: return aim
        case .busy:
            return queueAhead > 0
                ? L10n.format("scan_status_busy_queue", Int32(queueAhead))
                : L10n.string("scan_status_busy")
        case .blocked: return L10n.string("scan_status_blocked")
        case .offline: return L10n.string("scan_status_offline")
        }
    }

    /// The text that is on screen right now: also the accessibility label of the capsule.
    static func visible(look: ShutterLook, hint: HintKind, queueAhead: Int) -> String {
        hint == .aim ? aim : status(look: look, hint: hint, queueAhead: queueAhead)
    }
}
