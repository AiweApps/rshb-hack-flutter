package com.aiweapps.winescan.components

import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R

/** The «Svoe Vino» mark in its own colour, put before the «Open on Svoe Vino» texts. */
@Composable
fun SvoeVinoMark(modifier: Modifier = Modifier) {
    Icon(
        painter = painterResource(R.drawable.ic_svoe_vino_mark),
        contentDescription = null,
        tint = Color.Unspecified,
        modifier = modifier.size(18.dp),
    )
}
