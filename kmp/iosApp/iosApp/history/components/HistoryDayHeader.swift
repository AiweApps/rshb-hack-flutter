import SwiftUI
import SharedLogic

/// Section title: «Today», «Yesterday», or the date in the current locale.
struct HistoryDayHeader: View {
    let day: Kotlinx_datetimeLocalDate

    var body: some View {
        Text(title)
    }

    private var title: String {
        guard let date = Calendar.current.date(
            from: DateComponents(year: Int(day.year), month: Int(day.monthNumber), day: Int(day.day))
        ) else {
            return ""
        }
        if Calendar.current.isDateInToday(date) {
            return String(localized: "history_today")
        }
        if Calendar.current.isDateInYesterday(date) {
            return String(localized: "history_yesterday")
        }
        return date.formatted(.dateTime.day().month(.wide).year())
    }
}
