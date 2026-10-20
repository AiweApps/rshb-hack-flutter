import SharedLogic

/// The verdict as the user reads it. `uncertain` (the normal «found» case) and anything
/// unrecognised have no label.
enum DecisionLabel {
    static func text(for decision: ScanDecision) -> String? {
        if decision == ScanDecision.unknown { return String(localized: "decision_unknown") }
        if decision == ScanDecision.insufficientEvidence { return String(localized: "decision_insufficient") }
        if decision == ScanDecision.ambiguousTarget { return String(localized: "decision_ambiguous") }
        if decision == ScanDecision.noTarget { return String(localized: "decision_no_target") }
        return nil
    }
}
