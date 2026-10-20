package com.aiweapps.winescan.pairing.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.AppIcons
import com.aiweapps.winescan.components.PhotoCropImage
import com.aiweapps.winescan.domain.scan.model.BottleBox
import com.aiweapps.winescan.domain.scan.model.ReferenceAccess
import com.aiweapps.winescan.domain.scan.model.WineCard
import com.aiweapps.winescan.uikit.theme.AppDesign

/** Shared visual row for the initial roster and results; only real photos are used. */
@Composable
internal fun PairingWineRow(
    card: WineCard,
    photoPath: String?,
    crop: BottleBox?,
    frame: List<Int>?,
    referenceAccess: ReferenceAccess?,
    modifier: Modifier = Modifier,
    note: String? = null,
    isMatch: Boolean = false,
) {
    Row(modifier.fillMaxWidth().padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.Top) {
        val referenceUrl = referenceAccess?.resolve(card.reference)
        Box(Modifier.size(width = 40.dp, height = 56.dp).clip(RoundedCornerShape(8.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant)) {
            if (photoPath != null) {
                PhotoCropImage(photoPath = photoPath, crop = crop, frame = frame,
                    modifier = Modifier.matchParentSize(), contentScale = ContentScale.Fit)
            } else if (referenceUrl != null) {
                AsyncImage(model = referenceUrl, contentDescription = null,
                    modifier = Modifier.matchParentSize(), contentScale = ContentScale.Fit)
            } else {
                Icon(AppIcons.Wine, contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.align(Alignment.Center).size(24.dp))
            }
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(card.presentationTitle, style = MaterialTheme.typography.titleSmall)
            val subtitle = listOfNotNull(card.producer, card.category).filter { it.isNotBlank() }
            if (subtitle.isNotEmpty()) {
                Text(subtitle.joinToString(" · "), style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            if (note != null) {
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalAlignment = Alignment.Top, modifier = Modifier.padding(top = 4.dp)) {
                    if (isMatch) {
                        Icon(AppIcons.CheckCircle, contentDescription = stringResource(R.string.pairing_match_check),
                            tint = AppDesign.colors.ok, modifier = Modifier.size(18.dp))
                    }
                    Text(note, style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
}
