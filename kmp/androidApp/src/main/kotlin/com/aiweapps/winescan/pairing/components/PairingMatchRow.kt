package com.aiweapps.winescan.pairing.components

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.aiweapps.winescan.domain.pairing.model.PairingMatch
import com.aiweapps.winescan.domain.scan.model.ReferenceAccess

/** A real wine with the catalogue verdict supplied by the shared pairing owner. */
@Composable
fun PairingMatchRow(
    match: PairingMatch,
    referenceAccess: ReferenceAccess?,
    explanation: String?,
    modifier: Modifier = Modifier,
    isMatch: Boolean = true,
) {
    PairingWineRow(card = match.card, photoPath = match.photoPath, crop = match.crop, frame = match.frame,
        referenceAccess = referenceAccess, note = explanation, isMatch = isMatch, modifier = modifier)
}
