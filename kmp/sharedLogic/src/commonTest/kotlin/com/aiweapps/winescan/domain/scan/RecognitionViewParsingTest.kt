package com.aiweapps.winescan.domain.scan

import com.aiweapps.winescan.domain.scan.model.EmptyAnswer
import com.aiweapps.winescan.domain.scan.model.RecognitionView
import com.aiweapps.winescan.domain.scan.model.ScanDecision
import com.aiweapps.winescan.domain.scan.model.ScanMode
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlinx.serialization.json.Json

/**
 * The answer is parsed straight into the domain model, so the thing worth pinning down is
 * what happens when the backend says something this version does not know: an unknown
 * decision, a box that is not four numbers, a field that is missing. None of it may fail
 * the whole answer — the web UI survives all three, and the stored history has to as well.
 */
class RecognitionViewParsingTest {

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        encodeDefaults = true
        explicitNulls = false
    }

    @Test
    fun unknownDecisionAndModeFallBackInsteadOfFailing() {
        val view = json.decodeFromString<RecognitionView>(
            """{"decision":"something_new","mode":"weird","bottle_count":0}"""
        )

        assertEquals(ScanDecision.OTHER, view.decisionKind)
        assertEquals(ScanMode.UNKNOWN, view.modeKind)
        assertEquals("something_new", view.decision, "the raw value survives for the JSON export")
    }

    @Test
    fun malformedBoxBecomesNoBox() {
        val view = json.decodeFromString<RecognitionView>(
            """{"decision":"uncertain","mode":"automatic","roi":[1,2,3],
               "bottles":[{"number":1,"instance_id":"a","geometry":"nope"}]}"""
        )

        assertNull(view.roiBox)
        assertNull(view.bottles.single().geometryBox)
    }

    @Test
    fun boxReadsIntegersAndDecimals() {
        val view = json.decodeFromString<RecognitionView>(
            """{"decision":"uncertain","mode":"explicit_roi","roi":[10,20.5,300,400]}"""
        )

        val roi = assertNotNull(view.roiBox)
        assertEquals(10.0, roi.x1)
        assertEquals(20.5, roi.y1)
        assertEquals(listOf(10, 21, 300, 400), roi.toList(), "target_roi is sent in whole pixels")
    }

    @Test
    fun frameFallsBackToImageSize() {
        val view = json.decodeFromString<RecognitionView>(
            """{"decision":"uncertain","mode":"automatic","image":{"size":[640,480]}}"""
        )

        assertEquals(listOf(640, 480), view.frame)
    }

    @Test
    fun emptyAnswerDistinguishesFrameAndVerdict() {
        val roiNoTarget = json.decodeFromString<RecognitionView>(
            """{"decision":"no_target","mode":"explicit_roi"}"""
        )
        val autoOther = json.decodeFromString<RecognitionView>(
            """{"decision":"insufficient_evidence","mode":"automatic"}"""
        )

        assertEquals(EmptyAnswer.ROI_NO_TARGET, roiNoTarget.emptyAnswer)
        assertEquals(EmptyAnswer.AUTO, autoOther.emptyAnswer)
    }

    @Test
    fun roundTripKeepsWireNames() {
        val source = """{"decision":"uncertain","mode":"automatic","bottle_count":1,""" +
            """"bottles":[{"number":1,"instance_id":"a","best":{"slug":"s","title":"T","page_url":"u"}}]}"""

        val encoded = json.encodeToString(json.decodeFromString<RecognitionView>(source))

        val reparsed = json.decodeFromString<RecognitionView>(encoded)
        assertEquals("u", reparsed.bottles.single().best?.pageUrl)
        assertEquals(1, reparsed.bottleCount)
    }
}
