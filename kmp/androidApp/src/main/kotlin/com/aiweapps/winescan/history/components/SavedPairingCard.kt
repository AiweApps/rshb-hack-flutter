package com.aiweapps.winescan.history.components

import com.aiweapps.winescan.components.AppIcons

import android.text.format.DateUtils
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.domain.pairing.model.SavedPairing
import com.aiweapps.winescan.uikit.theme.AppDesign

/** A dish choice the user kept: the dish, the wines that matched it, and when. Swipe left to delete. */
@Composable
fun SavedPairingCard(
    pairing: SavedPairing,
    dishLabel: String,
    onClick: () -> Unit,
    onDismissed: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val date = DateUtils.formatDateTime(context, pairing.createdAtMillis, DateUtils.FORMAT_SHOW_DATE or DateUtils.FORMAT_ABBREV_MONTH)

    DismissToDelete(onDismissed = onDismissed, shape = SavedCardShape, modifier = modifier) {
        Card(
            onClick = onClick,
            modifier = Modifier.fillMaxWidth(),
            shape = SavedCardShape,
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
        ) {
            Row(
                modifier = Modifier.padding(16.dp),
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(
                    imageVector = AppIcons.Dinner,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(24.dp),
                )
                Column(Modifier.weight(1f)) {
                    Text(dishLabel, style = MaterialTheme.typography.titleMedium)
                    Text(
                        text = pairing.wines.joinToString(", ") { it.title },
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                    )
                    Text(
                        text = date,
                        style = MaterialTheme.typography.labelSmall,
                        color = AppDesign.colors.muted,
                        modifier = Modifier.padding(top = 4.dp),
                    )
                }
            }
        }
    }
}
