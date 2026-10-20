package com.aiweapps.winescan.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.common.ServiceDetailComponent
import com.aiweapps.winescan.domain.scan.model.ServiceAvailability
import com.aiweapps.winescan.domain.scan.model.ServiceState

/** «What does the pill mean right now»: the dot, the status, one sentence, a button. */
@Composable
fun ServiceDetailSheet(component: ServiceDetailComponent) {
    val availability = component.availability
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .navigationBarsPadding()
            .padding(horizontal = 24.dp)
            .padding(bottom = 16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            StatusDot(availability)
            Text(
                text = ServiceState(availability).label(),
                style = MaterialTheme.typography.titleLarge,
                modifier = Modifier.padding(start = 12.dp),
            )
        }
        Text(
            text = stringResource(availability.detailRes()),
            style = MaterialTheme.typography.bodyLarge,
        )
        Text(
            text = stringResource(R.string.status_auto_refresh),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Button(onClick = component::onCloseClicked, modifier = Modifier.fillMaxWidth()) {
            Text(stringResource(R.string.common_got_it))
        }
    }
}

private fun ServiceAvailability.detailRes(): Int = when (this) {
    ServiceAvailability.CHECKING, ServiceAvailability.READY -> R.string.status_ready_detail
    ServiceAvailability.BUSY -> R.string.status_busy_detail
    ServiceAvailability.DOWN -> R.string.status_down_detail
    ServiceAvailability.UNAVAILABLE -> R.string.status_unavailable_detail
    ServiceAvailability.NO_ACCESS -> R.string.status_no_access_detail
    ServiceAvailability.RATE_LIMITED -> R.string.status_rate_limited_detail
    ServiceAvailability.OFFLINE -> R.string.status_offline_detail
    ServiceAvailability.DEV -> R.string.status_dev_detail
}
