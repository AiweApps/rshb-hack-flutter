package com.aiweapps.winescan.compare.components

import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.FactPlaceholder
import com.aiweapps.winescan.components.colorText
import com.aiweapps.winescan.components.sugarText
import com.aiweapps.winescan.components.temperatureText
import com.aiweapps.winescan.domain.compare.model.CompareAttribute
import com.aiweapps.winescan.domain.compare.model.CompareValue
import com.aiweapps.winescan.uikit.theme.AppDesign

@Composable
internal fun CompareAttribute.label(): String = stringResource(
    when (this) {
        CompareAttribute.COLOR -> R.string.result_attr_color
        CompareAttribute.SUGAR -> R.string.result_attr_sugar
        CompareAttribute.ALCOHOL -> R.string.compare_attr_alcohol
        CompareAttribute.GRAPES -> R.string.result_attr_grapes
        CompareAttribute.REGION -> R.string.result_attr_region
        CompareAttribute.PAIRINGS -> R.string.result_pairings
        CompareAttribute.TEMPERATURE -> R.string.result_attr_serving
    },
)

/**
 * One table cell. Pairings every wine lists are drawn in the brand colour and a medium
 * weight; a value still loading is a placeholder and a missing one says «No data» in the
 * muted colour.
 */
@Composable
internal fun CompareCell(value: CompareValue, modifier: Modifier = Modifier) {
    val ink = MaterialTheme.colorScheme.onSurface
    val style = MaterialTheme.typography.bodyLarge
    when (value) {
        is CompareValue.Text -> Text(value.value, style = style, color = ink, modifier = modifier)
        is CompareValue.Color -> FactText(colorText(value.color, value.isSparkling), modifier)
        is CompareValue.Sugar -> FactText(sugarText(value.sugar), modifier)
        is CompareValue.Temperature -> FactText(temperatureText(value.range), modifier)
        CompareValue.Pending -> FactPlaceholder(modifier = modifier)
        CompareValue.None -> MutedText(stringResource(R.string.common_no_data), modifier)
        is CompareValue.Pairings -> if (value.dishes.isEmpty()) {
            MutedText(stringResource(R.string.result_pairings_none), modifier)
        } else {
            val hit = SpanStyle(color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Medium)
            Text(
                text = buildAnnotatedString {
                    value.dishes.forEachIndexed { index, dish ->
                        if (index > 0) append(", ")
                        if (dish.id in value.sharedIds) withStyle(hit) { append(dish.label) } else append(dish.label)
                    }
                },
                style = style,
                color = ink,
                modifier = modifier.padding(end = 4.dp),
            )
        }
    }
}

/** A value whose localised text may be unknown, which reads as «No data». */
@Composable
private fun FactText(text: String?, modifier: Modifier) {
    if (text == null) {
        MutedText(stringResource(R.string.common_no_data), modifier)
    } else {
        Text(text, style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurface, modifier = modifier)
    }
}

@Composable
private fun MutedText(text: String, modifier: Modifier) {
    Text(text = text, style = MaterialTheme.typography.bodyLarge, color = AppDesign.colors.muted, modifier = modifier)
}
