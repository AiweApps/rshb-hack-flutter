import SharedLogic

/// The notice for a result toast, from its kind.
enum ResultToastText {
    static func message(for toast: ScanResultToast?) -> String? {
        guard let toast else { return nil }
        if toast is ScanResultToast.RoiFound { return String(localized: "notice_roi_found") }
        if toast is ScanResultToast.RoiEmpty { return String(localized: "notice_roi_empty") }
        if let many = toast as? ScanResultToast.ManyBottles {
            return L10n.format("notice_many_bottles", many.count)
        }
        if toast is ScanResultToast.AddedToCompare { return String(localized: "notice_compare_added") }
        if toast is ScanResultToast.AlreadyInCompare { return String(localized: "notice_compare_already") }
        if toast is ScanResultToast.CompareFull { return String(localized: "notice_compare_full") }
        if toast is ScanResultToast.AddToCompareFailed { return String(localized: "notice_compare_failed") }
        if toast is ScanResultToast.RemovedFromCompare { return String(localized: "notice_compare_removed") }
        if toast is ScanResultToast.RemoveFromCompareFailed { return String(localized: "notice_compare_remove_failed") }
        return nil
    }
}
