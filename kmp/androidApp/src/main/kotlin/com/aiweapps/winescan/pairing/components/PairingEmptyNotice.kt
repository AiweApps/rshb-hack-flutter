package com.aiweapps.winescan.pairing.components

import com.aiweapps.winescan.components.AppIcons

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.uikit.theme.AppDesign

/** A centred icon, an optional title and a sentence: the «nothing to show» block of this screen. */
@Composable
fun PairingEmptyNotice(title: String?, text: String, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier.fillMaxWidth().padding(horizontal = 24.dp, vertical = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Icon(
            imageVector = AppIcons.Dinner,
            contentDescription = null,
            modifier = Modifier.size(40.dp),
            tint = AppDesign.colors.muted,
        )
        if (title != null) {
            Text(title, style = MaterialTheme.typography.titleLarge, textAlign = TextAlign.Center)
        }
        Text(
            text = text,
            style = MaterialTheme.typography.bodyMedium,
            color = AppDesign.colors.muted,
            textAlign = TextAlign.Center,
        )
    }
}
