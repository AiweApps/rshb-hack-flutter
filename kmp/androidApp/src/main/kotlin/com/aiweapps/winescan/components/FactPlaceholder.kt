package com.aiweapps.winescan.components

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

private const val PULSE_MILLIS = 800
private const val PULSE_FROM = 0.35f
private const val PULSE_TO = 0.8f

/** A pulsing bar standing in for a value that is still loading, so it is not mistaken for «No data». */
@Composable
fun FactPlaceholder(modifier: Modifier = Modifier, width: Dp = 72.dp, height: Dp = 16.dp) {
    val pulse by rememberInfiniteTransition(label = "fact-placeholder").animateFloat(
        initialValue = PULSE_FROM,
        targetValue = PULSE_TO,
        animationSpec = infiniteRepeatable(tween(PULSE_MILLIS), RepeatMode.Reverse),
        label = "fact-placeholder-alpha",
    )
    Box(
        modifier
            .width(width)
            .height(height)
            .alpha(pulse)
            .background(MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(4.dp)),
    )
}
