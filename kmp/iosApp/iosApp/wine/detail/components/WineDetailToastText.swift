import SharedLogic

/// The notice for a wine screen toast, from its kind. The comparison notices are the
/// result screen's.
enum WineDetailToastText {
    static func message(for toast: WineDetailToast?) -> String? {
        guard let toast else { return nil }
        if toast is WineDetailToast.AddedToCompare { return String(localized: "notice_compare_added") }
        if toast is WineDetailToast.AlreadyInCompare { return String(localized: "notice_compare_already") }
        if toast is WineDetailToast.CompareFull { return String(localized: "notice_compare_full") }
        if toast is WineDetailToast.AddToCompareFailed { return String(localized: "notice_compare_failed") }
        if toast is WineDetailToast.RemovedFromCompare { return String(localized: "notice_compare_removed") }
        if toast is WineDetailToast.RemoveFromCompareFailed { return String(localized: "notice_compare_remove_failed") }
        return nil
    }
}
