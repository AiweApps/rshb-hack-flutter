package com.aiweapps.winescan.domain.scan

import com.aiweapps.winescan.domain.scan.model.RecognitionView
import com.aiweapps.winescan.domain.scan.model.RecognizedBottle
import com.aiweapps.winescan.domain.scan.model.ScanMode
import com.aiweapps.winescan.domain.scan.model.WineCard
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class RecognitionViewBestBottleTest {

    @Test
    fun theBottleTheServiceNamesWinsOverEveryVerdict() {
        val view = view(
            bottle(1, "matched"),
            bottle(2, "uncertain"),
            primaryInstanceId = "b2",
        )

        assertEquals("b2", view.bestBottle()?.instanceId)
        assertEquals("b2", view.winnerInstanceId)
    }

    @Test
    fun aUniqueMatchedBottleIsTheBestAndTheWinner() {
        val view = view(bottle(1, "uncertain"), bottle(2, "unknown"), bottle(3, "matched"))

        assertEquals("b3", view.bestBottle()?.instanceId)
        assertEquals("b3", view.winnerInstanceId)
    }

    @Test
    fun aTieOpensTheLowestNumberButCrownsNobody() {
        // What `primary_basis = ambiguous_tie` looks like: no primary, two uncertain bottles.
        val view = view(bottle(2, "uncertain"), bottle(1, "uncertain"), primaryBasis = "ambiguous_tie")

        assertEquals("b1", view.bestBottle()?.instanceId)
        assertNull(view.winnerInstanceId, "on a tie the app must not pretend to know the winner")
    }

    @Test
    fun aBestCardBreaksATieOfVerdicts() {
        val view = view(bottle(1, "uncertain", hasBest = false), bottle(2, "uncertain"))

        assertEquals("b2", view.bestBottle()?.instanceId)
        assertEquals("b2", view.winnerInstanceId)
    }

    @Test
    fun aPrimaryThatIsNotAmongTheBottlesFallsBackToTheRanking() {
        val view = view(bottle(1, "uncertain"), bottle(2, "matched"), primaryInstanceId = "gone")

        assertEquals("b2", view.bestBottle()?.instanceId)
        assertEquals("b2", view.winnerInstanceId)
    }

    @Test
    fun onlyAnAutomaticAnswerWithSeveralBottlesHasAWinner() {
        val single = view(bottle(1, "matched"))
        val frame = view(bottle(1, "matched"), bottle(2, "uncertain"), mode = ScanMode.EXPLICIT_ROI)

        assertNull(single.winnerInstanceId, "one bottle needs no crown")
        assertNull(frame.winnerInstanceId, "a frame answer is single-target")
        assertNull(view().bestBottle())
    }

    private fun view(
        vararg bottles: RecognizedBottle,
        primaryInstanceId: String? = null,
        primaryBasis: String? = null,
        mode: ScanMode = ScanMode.AUTOMATIC,
    ) = RecognitionView(
        mode = mode.apiName,
        bottleCount = bottles.size,
        primaryInstanceId = primaryInstanceId,
        primaryBasis = primaryBasis,
        bottles = bottles.toList(),
    )

    private fun bottle(number: Int, decision: String, hasBest: Boolean = true) = RecognizedBottle(
        number = number,
        instanceId = "b$number",
        decision = decision,
        best = if (hasBest) WineCard(slug = "slug-$number", title = "Wine $number") else null,
    )
}
