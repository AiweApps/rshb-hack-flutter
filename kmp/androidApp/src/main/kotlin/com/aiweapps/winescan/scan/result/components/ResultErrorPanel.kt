package com.aiweapps.winescan.scan.result.components

import com.aiweapps.winescan.components.AppIcons

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.domain.scan.model.ScanFailure
import com.aiweapps.winescan.domain.scan.model.ScanFailureKind

/** The failed request, in words, with «Retry» when it can help and «New scan». */
@Composable
fun ResultErrorPanel(
    failure: ScanFailure,
    onRetryClicked: () -> Unit,
    onNewScanClicked: () -> Unit,
) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(AppIcons.Error, contentDescription = null, tint = MaterialTheme.colorScheme.error)
            Text(
                text = failure.title(),
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.error,
                modifier = Modifier.padding(start = 12.dp),
            )
        }
        Text(text = stringResource(failure.kind.textRes()), style = MaterialTheme.typography.bodyLarge)
        Row(
            modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            if (failure.retryable) {
                Button(onClick = onRetryClicked, modifier = Modifier.weight(1f)) {
                    Text(stringResource(R.string.scan_error_retry))
                }
            }
            OutlinedButton(onClick = onNewScanClicked, modifier = Modifier.weight(1f)) {
                Text(stringResource(R.string.result_new_scan))
            }
        }
    }
}

@Composable
private fun ScanFailure.title(): String = when (kind) {
    ScanFailureKind.NO_ACCESS -> stringResource(R.string.scan_error_no_access)
    ScanFailureKind.TOO_LARGE -> stringResource(R.string.scan_error_too_large)
    ScanFailureKind.FORMAT -> stringResource(R.string.scan_error_format)
    ScanFailureKind.UNPROCESSED, ScanFailureKind.BAD_ROI -> stringResource(R.string.scan_error_unprocessed)
    ScanFailureKind.TOO_MANY -> stringResource(R.string.scan_error_too_many)
    ScanFailureKind.SERVICE -> stringResource(R.string.scan_error_service)
    ScanFailureKind.BUSY -> stringResource(R.string.scan_error_busy)
    ScanFailureKind.TIMEOUT -> stringResource(R.string.scan_error_timeout)
    ScanFailureKind.NO_RESPONSE, ScanFailureKind.OFFLINE -> stringResource(R.string.scan_error_no_response)
    ScanFailureKind.PHOTO_OPEN -> stringResource(R.string.scan_error_photo_open)
    ScanFailureKind.OTHER ->
        if (statusCode == null) {
            stringResource(R.string.scan_error_title_default)
        } else {
            stringResource(R.string.scan_error_code, statusCode!!)
        }
}

private fun ScanFailureKind.textRes(): Int = when (this) {
    ScanFailureKind.NO_ACCESS -> R.string.scan_error_text_no_access
    ScanFailureKind.TOO_LARGE -> R.string.scan_error_text_too_large
    ScanFailureKind.FORMAT -> R.string.scan_error_text_format
    ScanFailureKind.UNPROCESSED -> R.string.scan_error_text_unprocessed
    ScanFailureKind.BAD_ROI -> R.string.scan_error_text_bad_roi
    ScanFailureKind.TOO_MANY -> R.string.scan_error_text_too_many
    ScanFailureKind.SERVICE -> R.string.scan_error_text_service
    ScanFailureKind.BUSY -> R.string.scan_error_text_busy
    ScanFailureKind.TIMEOUT -> R.string.scan_error_text_timeout
    ScanFailureKind.OFFLINE, ScanFailureKind.NO_RESPONSE -> R.string.scan_error_text_offline
    ScanFailureKind.PHOTO_OPEN -> R.string.scan_error_text_photo_open
    ScanFailureKind.OTHER -> R.string.scan_error_text_default
}
