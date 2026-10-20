package com.aiweapps.winescan.domain.history.model

import com.aiweapps.winescan.domain.scan.model.RecognitionView
import kotlinx.datetime.LocalDate
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import kotlinx.serialization.Serializable
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/** A stored scan as the app uses it: the photo and the full answer. */
data class ScanRecord(
    val id: Long,
    val createdAtMillis: Long,
    val photoPath: String,
    val view: RecognitionView,
)

/** A row of the history list: what the list needs and nothing heavier. */
@Serializable
data class ScanHistoryItem(
    val id: Long,
    val createdAtMillis: Long,
    val photoPath: String,
    val bestTitle: String?,
    val bestProducer: String?,
    /** The best card's slug: how a row knows whether that wine is already in the comparison. */
    val bestSlug: String?,
    val bestReference: String?,
    val bottleCount: Int,
) {
    val presentationTitle: String? get() = bestTitle?.let {
        com.aiweapps.winescan.domain.scan.model.catalogPresentationTitle(null, it, bestProducer)
    }
}

/** The scans of one calendar day, newest first, for a sectioned list. */
@Serializable
data class HistoryDaySection(
    val day: LocalDate,
    val items: List<ScanHistoryItem>,
) {
    companion object {
        /** Groups [items] (already sorted newest first) by calendar day in [timeZone]. */
        @OptIn(ExperimentalTime::class)
        fun group(items: List<ScanHistoryItem>, timeZone: TimeZone): List<HistoryDaySection> {
            val sections = mutableListOf<HistoryDaySection>()
            for (item in items) {
                val day = Instant.fromEpochMilliseconds(item.createdAtMillis).toLocalDateTime(timeZone).date
                val last = sections.lastOrNull()
                if (last != null && last.day == day) {
                    sections[sections.lastIndex] = last.copy(items = last.items + item)
                } else {
                    sections += HistoryDaySection(day = day, items = listOf(item))
                }
            }
            return sections
        }
    }
}
