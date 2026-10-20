package com.aiweapps.winescan.retail

import com.aiweapps.winescan.components.AppIcons

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.FilledTonalIconButton
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.aiweapps.winescan.R
import com.aiweapps.winescan.uikit.theme.AppTheme

@Composable
internal fun RetailCloseButton(onClose: () -> Unit) {
    AppTheme(isDark = isSystemInDarkTheme()) {
        FilledTonalIconButton(onClick = onClose) {
            Icon(AppIcons.Close, contentDescription = stringResource(R.string.common_close))
        }
    }
}
