package com.aiweapps.winescan.wine.detail

import androidx.compose.runtime.Composable
import androidx.compose.ui.tooling.preview.Preview
import com.aiweapps.winescan.components.wine.detail.WineDetailComponent
import com.aiweapps.winescan.components.common.model.WineFacts
import com.aiweapps.winescan.components.wine.detail.model.WineDetailState
import com.aiweapps.winescan.domain.gastronomy.model.DishLabel
import com.aiweapps.winescan.domain.gastronomy.model.ServingTemperature
import com.aiweapps.winescan.domain.gastronomy.model.WineColor
import com.aiweapps.winescan.domain.gastronomy.model.WineSugar
import com.aiweapps.winescan.domain.scan.model.BottlePhoto
import com.aiweapps.winescan.domain.scan.model.WineCard
import com.aiweapps.winescan.uikit.theme.AppTheme
import com.arkivanov.decompose.router.slot.ChildSlot
import com.arkivanov.decompose.value.MutableValue
import com.arkivanov.decompose.value.Value

private val PreviewCard = WineCard(
    slug = "tamara-2023",
    title = "Тамара Красное сухое",
    producer = "Усадьба Дивноморское",
    category = "Красное сухое",
    region = "Краснодарский край",
    grapes = "Саперави, Каберне Совиньон",
    pageUrl = "https://vino.svoe.ru/wines/tamara-2023",
    reference = "/api/reference/tamara-2023.jpg",
)

private val PreviewFacts = WineFacts(
    color = WineColor.RED,
    isSparkling = false,
    sugar = WineSugar.DRY,
    servingTemperature = ServingTemperature(minC = 16, maxC = 18),
    pairings = listOf(
        DishLabel("steak", "Стейк"),
        DishLabel("hard-cheese", "Твёрдые сыры"),
        DishLabel("braised-lamb", "Тушёная баранина"),
    ),
    sourceUrl = null,
)

private val PreviewBottle = BottlePhoto(photoPath = "", crop = null, frame = null, bottleNumber = 1, scanId = 1L)

private class PreviewWineDetailComponent(initial: WineDetailState) : WineDetailComponent {
    override val state: Value<WineDetailState> = MutableValue(initial)
    override val modalSlot: Value<ChildSlot<*, WineDetailComponent.Modal>> =
        MutableValue(ChildSlot<Nothing, WineDetailComponent.Modal>())

    override fun onBackClicked() = Unit
    override fun onCatalogueLinkClicked(url: String) = Unit
    override fun onCompareWithPhotoClicked() = Unit
    override fun onAddToCompareClicked() = Unit
    override fun onRemoveFromCompareClicked() = Unit
    override fun onModalDismissed() = Unit
    override fun onToastConsumed() = Unit
}

@Composable
private fun WineDetailPreview(state: WineDetailState, isDark: Boolean = false) {
    AppTheme(isDark = isDark) { WineDetailContent(PreviewWineDetailComponent(state)) }
}

@Preview(name = "With bottle photo", showBackground = true, widthDp = 412, heightDp = 1100)
@Composable
private fun WineDetailWithBottlePreview() =
    WineDetailPreview(WineDetailState(card = PreviewCard, bottle = PreviewBottle, facts = PreviewFacts))

@Preview(name = "In the comparison", showBackground = true, widthDp = 412, heightDp = 1100)
@Composable
private fun WineDetailInCompareDarkPreview() =
    WineDetailPreview(
        WineDetailState(
            card = PreviewCard,
            bottle = PreviewBottle,
            facts = PreviewFacts,
            isInCompare = true,
            compareCount = 2,
        ),
        isDark = true,
    )

@Preview(name = "No photo, sparse card", showBackground = true, widthDp = 412, heightDp = 1100)
@Composable
private fun WineDetailNoPhotoPreview() =
    WineDetailPreview(
        WineDetailState(
            card = WineCard(slug = "bare", title = "Безымянное вино", reference = null),
            bottle = null,
            facts = WineFacts.NO_DATA,
        ),
    )
