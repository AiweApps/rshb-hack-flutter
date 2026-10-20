package com.aiweapps.winescan.components

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.domain.scan.model.ServiceAvailability
import com.aiweapps.winescan.domain.scan.model.ServiceState
import com.aiweapps.winescan.uikit.theme.AppDesign

private const val PULSE_MIN_ALPHA = 0.35f
private const val PULSE_DURATION_MS = 900

/**
 * The service status as a small pill: a coloured dot and one word. The dot breathes while
 * the service can take a photo. [containerColor] lets it sit over the viewfinder.
 */
@Composable
fun ServiceStatusPill(
    state: ServiceState,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    containerColor: Color = MaterialTheme.colorScheme.surfaceVariant,
    contentColor: Color = MaterialTheme.colorScheme.onSurfaceVariant,
) {
    Surface(
        onClick = onClick,
        modifier = modifier.minimumInteractiveComponentSize(),
        shape = CircleShape,
        color = containerColor,
        contentColor = contentColor,
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            StatusDot(state.availability)
            Text(
                text = state.label(),
                style = MaterialTheme.typography.labelLarge,
                modifier = Modifier.padding(start = 8.dp),
            )
        }
    }
}

@Composable
fun StatusDot(availability: ServiceAvailability, modifier: Modifier = Modifier) {
    val pulse = rememberInfiniteTransition(label = "statusPulse")
    val animatedAlpha by pulse.animateFloat(
        initialValue = 1f,
        targetValue = PULSE_MIN_ALPHA,
        animationSpec = infiniteRepeatable(tween(PULSE_DURATION_MS), RepeatMode.Reverse),
        label = "statusPulseAlpha",
    )
    Box(
        modifier = modifier
            .size(10.dp)
            .alpha(if (availability.canRecognize) animatedAlpha else 1f)
            .background(availability.dotColor(), CircleShape),
    )
}

@Composable
private fun ServiceAvailability.dotColor(): Color = when (this) {
    ServiceAvailability.READY -> AppDesign.colors.ok
    ServiceAvailability.BUSY, ServiceAvailability.RATE_LIMITED -> AppDesign.colors.warn
    ServiceAvailability.DOWN,
    ServiceAvailability.UNAVAILABLE,
    ServiceAvailability.NO_ACCESS,
    ServiceAvailability.OFFLINE,
    -> AppDesign.colors.bad
    ServiceAvailability.DEV -> AppDesign.colors.gold
    ServiceAvailability.CHECKING -> AppDesign.colors.muted
}

@Composable
fun ServiceState.label(): String = when (availability) {
    ServiceAvailability.CHECKING -> stringResource(R.string.status_checking)
    ServiceAvailability.READY -> stringResource(R.string.status_ready)
    ServiceAvailability.BUSY ->
        if (waiting > 0) stringResource(R.string.status_busy_queue, waiting) else stringResource(R.string.status_busy)
    ServiceAvailability.DOWN -> stringResource(R.string.status_down)
    ServiceAvailability.UNAVAILABLE -> stringResource(R.string.status_unavailable)
    ServiceAvailability.NO_ACCESS -> stringResource(R.string.status_no_access)
    ServiceAvailability.RATE_LIMITED -> stringResource(R.string.status_rate_limited)
    ServiceAvailability.OFFLINE -> stringResource(R.string.status_offline)
    ServiceAvailability.DEV -> stringResource(R.string.status_dev)
}
