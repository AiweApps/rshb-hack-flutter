package com.aiweapps.winescan.components.scan.result.model

import com.aiweapps.core.components.model.BaseScreenState
import com.aiweapps.core.components.model.ScreenState
import com.aiweapps.core.error.AppError
import com.aiweapps.winescan.components.common.model.WineFacts
import com.aiweapps.winescan.domain.scan.model.BottleBox
import com.aiweapps.winescan.domain.scan.model.BottlePhoto
import com.aiweapps.winescan.domain.scan.model.RecognitionView
import com.aiweapps.winescan.domain.scan.model.RecognizedBottle
import com.aiweapps.winescan.domain.scan.model.ReferenceAccess
import com.aiweapps.winescan.domain.scan.model.ScanFailure
import com.aiweapps.winescan.domain.scan.model.ScanGeometryProgress
import com.aiweapps.winescan.domain.scan.model.WineCard

/** What the result panel shows for the current photo. */
enum class ResultPhase { RECOGNIZING, WAITING_RETRY, FAILED, ANSWER }

/** Why the app is waiting before retrying by itself. */
enum class RetryReason { BUSY, TOO_MANY }

/** Once per answer, the same short tips the web shows under «Result». */
sealed class ScanResultToast {
    data object RoiFound : ScanResultToast()
    data object RoiEmpty : ScanResultToast()
    data class ManyBottles(val count: Int) : ScanResultToast()
    data object AddedToCompare : ScanResultToast()
    data object AlreadyInCompare : ScanResultToast()
    data object CompareFull : ScanResultToast()
    data object AddToCompareFailed : ScanResultToast()
    data object RemovedFromCompare : ScanResultToast()
    data object RemoveFromCompareFailed : ScanResultToast()
}

data class ScanResultState(
    /** `Loading` until the photo (or the stored scan) is at hand; `Error` only when a stored scan is gone. */
    override val screenState: ScreenState = ScreenState.Loading,
    val photoPath: String = "",
    /** Opened from the history: the answer is shown, not requested, and re-scans are not stored. */
    val isStored: Boolean = false,
    /**
     * Opened for a frame drawn on another result: the answer is for that frame only, there
     * is no all-bottles answer to go back to, and nothing is stored in the history.
     */
    val isFramed: Boolean = false,
    /**
     * The answer is being written to the history, which moves the photo under its own name:
     * nothing may open on the photo's old path meanwhile.
     */
    val isSavingHistory: Boolean = false,
    val phase: ResultPhase = ResultPhase.RECOGNIZING,
    /** The request in flight (or the one that failed) was for a frame. */
    val isRoiRequest: Boolean = false,
    /** The answer on screen. */
    val view: RecognitionView? = null,
    /** Transient boxes for this request; not a partial wine answer and never persisted. */
    val geometryProgress: ScanGeometryProgress? = null,
    /**
     * The bottle on screen; `null` is the all-bottles overview. An automatic answer with
     * several bottles opens on [RecognitionView.bestBottle], the «All» chip stays available.
     */
    val selectedInstanceId: String? = null,
    /** Frame of the request in flight or the one that failed. */
    val pendingRoi: BottleBox? = null,
    val retryAttempt: Int = 0,
    val retrySecondsLeft: Int = 0,
    val retryReason: RetryReason = RetryReason.BUSY,
    val failure: ScanFailure? = null,
    val referenceAccess: ReferenceAccess? = null,
    val historyId: Long? = null,
    val techRows: List<TechRow> = emptyList(),
    /** Slugs of the wines in the comparison set, so a card shows whether it is already there. */
    val compareSlugs: Set<String> = emptySet(),
    /** Colour, sugar, temperature and pairings of every card on screen, by slug; absent while loading. */
    val facts: Map<String, WineFacts> = emptyMap(),
    val isFactsLoading: Boolean = false,
    /** A failed source load is retryable, not a successful catalogue entry without facts. */
    val factsErrors: Map<String, AppError> = emptyMap(),
    val toast: ScanResultToast? = null,
) : BaseScreenState {

    val compareCount: Int get() = compareSlugs.size

    /**
     * The «Compare · N» pill is the way on after adding a bottle from here, so it needs
     * bottles on screen and a set to go to.
     */
    val canOpenCompare: Boolean
        get() = hasAnswer && view?.bottles?.isNotEmpty() == true && compareSlugs.isNotEmpty()

    fun isInCompare(card: WineCard): Boolean = card.slug in compareSlugs

    val selectedBottle: RecognizedBottle? get() = view?.bottleById(selectedInstanceId)

    /** The card the toolbar compares the selected bottle with. */
    val selectedCard: WineCard? get() = selectedBottle?.best

    val hasAnswer: Boolean get() = phase == ResultPhase.ANSWER && view != null

    /** Comparing needs a bottle with a match on screen. */
    val canCompare: Boolean get() = hasAnswer && selectedCard != null

    /**
     * A frame needs the photo's frame size, which an answer brings, no request in flight,
     * and the photo settled on its path.
     */
    val canDrawFrame: Boolean
        get() = frame != null && photoPath.isNotBlank() && !isSavingHistory &&
            phase != ResultPhase.RECOGNIZING && phase != ResultPhase.WAITING_RETRY

    /**
     * The bottle chip that wears the crown: set only when the best bottle of an automatic
     * multi-bottle answer is unambiguous — see [RecognitionView.winnerInstanceId].
     */
    val winnerInstanceId: String? get() = view?.winnerInstanceId

    /**
     * «Recognise only this bottle» in «More»: a bottle of an automatic answer with several
     * bottles is selected and the service gave it a box to ask for.
     */
    val canRescanBottle: Boolean
        get() {
            val view = view ?: return false
            return hasAnswer && !isSavingHistory && !view.isExplicitRoi && view.bottles.size > 1 &&
                selectedBottle?.selectRoiBox != null
        }

    /** The frame every box refers to, once an answer told us. */
    val frame: List<Int>? get() = view?.frame

    internal fun bottlePhoto(instanceId: String): BottlePhoto? {
        val view = view ?: return null
        val bottle = view.bottleById(instanceId) ?: return null
        return BottlePhoto(
            photoPath = photoPath,
            crop = view.cropOf(bottle),
            frame = view.frame,
            bottleNumber = bottle.number,
            scanId = historyId,
        )
    }
}
