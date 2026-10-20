package com.aiweapps.winescan.components.scan.result.sheets

import com.arkivanov.decompose.ComponentContext
import com.arkivanov.decompose.value.MutableValue
import com.arkivanov.decompose.value.Value
import com.arkivanov.essenty.lifecycle.doOnDestroy
import com.aiweapps.winescan.domain.scan.model.BottleBox
import com.aiweapps.winescan.domain.scan.model.RecognitionView

/**
 * «Choose a frame», shown full screen: the photo to draw on; a drawn frame is at once
 * adjustable, and «Scan» hands it back, which opens a new result for that frame. The frame
 * being drawn is gesture state of the screen; only the committed [DrawFrameState.draft]
 * lives here and only the final frame reaches the result.
 */
interface DrawFrameComponent {

    val photoPath: String

    /** EXIF-oriented frame size from the answer; the UI falls back to the decoded size. */
    val frame: List<Int>?

    /**
     * The answer's boxes, drawn for orientation only; `null` when there is none to show,
     * e.g. after the screen was restored.
     */
    val view: RecognitionView?

    val state: Value<DrawFrameState>

    /**
     * The decoded photo's size, for when [frame] is missing: drafts are then checked against
     * it as well. Ignored once a size is known.
     */
    fun onImageSizeResolved(width: Int, height: Int)

    /** A draft outside the photo is clamped to it; a draft with nothing left is ignored. */
    fun onDraftChanged(box: BottleBox)

    fun onCancelClicked()

    /** Does nothing until a frame is drawn, and only once. */
    fun onScanClicked()

    fun interface Factory {
        fun create(
            componentContext: ComponentContext,
            photoPath: String,
            frame: List<Int>?,
            view: RecognitionView?,
            onFrameDrawn: (BottleBox) -> Unit,
            onCancel: () -> Unit,
        ): DrawFrameComponent
    }
}

data class DrawFrameState(
    val draft: BottleBox? = null,
)

/**
 * The draft is a single value that is not a screen state, so a plain [MutableValue] is
 * enough; there are no coroutines and no base class to take.
 */
internal class DefaultDrawFrameComponent(
    componentContext: ComponentContext,
    override val photoPath: String,
    override val frame: List<Int>?,
    override val view: RecognitionView?,
    private val onFrameDrawn: (BottleBox) -> Unit,
    private val onCancel: () -> Unit,
) : DrawFrameComponent, ComponentContext by componentContext {

    private val _state = MutableValue(DrawFrameState())
    override val state: Value<DrawFrameState> = _state

    private var resolvedFrame: List<Int>? = validFrame(frame)

    // A second tap on «Scan» or «✕» while the screen animates away must not act twice.
    private var isFinished = false

    init {
        lifecycle.doOnDestroy { isFinished = true }
    }

    override fun onImageSizeResolved(width: Int, height: Int) {
        if (isFinished || resolvedFrame != null) return
        resolvedFrame = validFrame(listOf(width, height))
    }

    override fun onDraftChanged(box: BottleBox) {
        if (isFinished) return
        val checked = validatedFrameRoi(box, resolvedFrame) ?: return
        _state.value = DrawFrameState(draft = checked)
    }

    override fun onCancelClicked() {
        if (isFinished) return
        isFinished = true
        onCancel()
    }

    override fun onScanClicked() {
        if (isFinished) return
        val draft = _state.value.draft?.let { validatedFrameRoi(it, resolvedFrame) } ?: return
        isFinished = true
        onFrameDrawn(draft)
    }
}

/** A frame size the boxes can be checked against: two positive sides, else `null`. */
internal fun validFrame(frame: List<Int>?): List<Int>? =
    frame?.takeIf { it.size == 2 && it.all { side -> side > 0 } }

/**
 * [box] in whole pixels, as the request sends it, clamped to [frame] when it is known;
 * `null` for a box with a non-finite side or nothing left after clamping and rounding.
 */
internal fun validatedFrameRoi(box: BottleBox, frame: List<Int>?): BottleBox? {
    if (!listOf(box.x1, box.y1, box.x2, box.y2).all { it.isFinite() }) return null
    val size = validFrame(frame)
    val clamped = if (size == null) box else box.clampTo(size[0].toDouble(), size[1].toDouble())
    val pixels = clamped.toList()
    if (pixels[0] < 0 || pixels[1] < 0 || pixels[2] <= pixels[0] || pixels[3] <= pixels[1]) return null
    return BottleBox(pixels[0].toDouble(), pixels[1].toDouble(), pixels[2].toDouble(), pixels[3].toDouble())
}
