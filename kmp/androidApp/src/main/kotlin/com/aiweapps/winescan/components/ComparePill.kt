package com.aiweapps.winescan.components

import com.aiweapps.winescan.components.AppIcons

import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import com.aiweapps.winescan.R

/** «Compare · N»: the way to the comparison from any screen that can add wines to it. */
@Composable
fun ComparePill(
    count: Int,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    ExtendedFloatingActionButton(
        onClick = onClick,
        modifier = modifier,
        icon = { Icon(AppIcons.Compare, contentDescription = null) },
        text = { Text(stringResource(R.string.compare_pill, count)) },
    )
}
