package com.aiweapps.winescan.pairing.components

import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.domain.gastronomy.model.DishLabel
import com.aiweapps.winescan.uikit.theme.AppTheme

private val PreviewDishes = listOf(
    DishLabel("steak", "Стейк"),
    DishLabel("hard-cheese", "Твёрдые сыры"),
    DishLabel("braised-lamb", "Тушёная баранина"),
    DishLabel("pasta", "Паста"),
)

@Preview(name = "Dishes", showBackground = true, widthDp = 412)
@Composable
private fun DishChipsPreview() = AppTheme(isDark = false) {
    DishChips(
        dishes = PreviewDishes,
        enabled = true,
        onSelected = {},
        onOtherDish = {},
        modifier = Modifier.padding(16.dp),
    )
}

@Preview(name = "Dishes, dark", showBackground = true, widthDp = 412)
@Composable
private fun DishChipsDarkPreview() = AppTheme(isDark = true) {
    DishChips(
        dishes = PreviewDishes,
        enabled = true,
        onSelected = {},
        onOtherDish = {},
        modifier = Modifier.padding(16.dp),
    )
}
