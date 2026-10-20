package com.aiweapps.winescan.data.history.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.aiweapps.winescan.domain.history.model.ScanHistoryItem

/**
 * One stored scan: the photo on disk, the answer as the API sent it, and a few columns
 * copied out of it so the list renders without parsing JSON.
 */
@Entity(tableName = "scan_history")
data class ScanHistoryEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val createdAt: Long,
    /** File name of the photo in the file store — a name, not a path: the container moves. */
    val photoName: String,
    /** The `view` object of the automatic answer, JSON-encoded. */
    val viewJson: String,
    val bestTitle: String?,
    val bestProducer: String?,
    val bestSlug: String?,
    /** Relative reference path of the best card, for the row thumbnail. */
    val bestReference: String?,
    val bottleCount: Int,
)

/** The row holds a file name; the repository supplies the resolved [photoPath]. */
fun ScanHistoryEntity.toItem(photoPath: String) = ScanHistoryItem(
    id = id,
    createdAtMillis = createdAt,
    photoPath = photoPath,
    bestTitle = bestTitle,
    bestProducer = bestProducer,
    bestSlug = bestSlug,
    bestReference = bestReference,
    bottleCount = bottleCount,
)
