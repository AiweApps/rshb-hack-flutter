package com.aiweapps.winescan.scan.result.components

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.aiweapps.winescan.R
import com.aiweapps.winescan.domain.scan.model.ScanDecision

/**
 * The verdict as the user reads it. `UNCERTAIN` (the normal "here are candidates" case) and
 * anything unrecognised have no label.
 */
@Composable
fun ScanDecision.label(): String? = when (this) {
    ScanDecision.UNKNOWN -> stringResource(R.string.decision_unknown)
    ScanDecision.INSUFFICIENT_EVIDENCE -> stringResource(R.string.decision_insufficient)
    ScanDecision.AMBIGUOUS_TARGET -> stringResource(R.string.decision_ambiguous)
    ScanDecision.NO_TARGET -> stringResource(R.string.decision_no_target)
    ScanDecision.UNCERTAIN, ScanDecision.MATCHED, ScanDecision.INVALID_IMAGE, ScanDecision.OTHER -> null
}
