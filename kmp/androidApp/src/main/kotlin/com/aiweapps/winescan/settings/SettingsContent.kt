package com.aiweapps.winescan.settings

import com.aiweapps.winescan.components.AppIcons

import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.IconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.aiweapps.core.components.model.ScreenState
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.ErrorState
import com.aiweapps.winescan.components.LoadingState
import com.aiweapps.winescan.components.ServiceStatusPill
import com.aiweapps.winescan.components.ToastEffect
import com.aiweapps.winescan.components.settings.SettingsComponent
import com.aiweapps.winescan.components.settings.model.SettingsState
import com.aiweapps.winescan.components.settings.model.SettingsToast
import com.aiweapps.winescan.settings.components.SettingsModals
import com.aiweapps.winescan.settings.components.SettingsRow
import com.aiweapps.winescan.settings.components.SettingsSection
import com.aiweapps.winescan.settings.components.labelRes
import com.aiweapps.winescan.settings.components.languageLabel
import com.arkivanov.decompose.extensions.compose.subscribeAsState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsContent(component: SettingsComponent, onBack: (() -> Unit)? = null) {
    val state by component.state.subscribeAsState()
    val modalSlot by component.modalSlot.subscribeAsState()
    val snackbarHost = remember { SnackbarHostState() }
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior()

    ToastEffect(
        message = when (state.toast) {
            SettingsToast.HISTORY_CLEARED -> stringResource(R.string.history_cleared)
            SettingsToast.HISTORY_CLEAR_FAILED -> stringResource(R.string.history_clear_failed)
            null -> null
        },
        host = snackbarHost,
        onConsumed = component::onToastConsumed,
    )

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text(stringResource(R.string.settings_title)) },
                navigationIcon = {
                    onBack?.let { back ->
                        IconButton(onClick = back) {
                            Icon(AppIcons.Back, contentDescription = stringResource(R.string.common_back))
                        }
                    }
                },
                scrollBehavior = scrollBehavior,
            )
        },
        snackbarHost = { SnackbarHost(snackbarHost) },
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            when (val screenState = state.screenState) {
                is ScreenState.Loading -> LoadingState()
                is ScreenState.Error -> ErrorState(error = screenState.error)
                is ScreenState.Content -> SettingsList(state, component)
            }
        }
    }

    SettingsModals(modal = modalSlot.child?.instance, onDismissRequest = component::onModalDismissed)
}

@Composable
private fun SettingsList(state: SettingsState, component: SettingsComponent) {
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
        SettingsSection(stringResource(R.string.settings_appearance)) {
            SettingsRow(
                icon = AppIcons.Palette,
                title = stringResource(R.string.settings_theme),
                value = stringResource(state.themeMode.labelRes()),
                onClick = component::onThemeClicked,
            )
            SettingsRow(
                icon = AppIcons.Language,
                title = stringResource(R.string.settings_language),
                value = languageLabel(state.languageCode),
                onClick = component::onLanguageClicked,
            )
        }
        state.scannerBackend?.let { com.aiweapps.winescan.local.ScannerBackendSection(it, component) }
        SettingsSection(stringResource(R.string.settings_service)) {
            SettingsRow(
                icon = AppIcons.Cloud,
                title = stringResource(R.string.settings_service),
                value = state.catalogCards?.let {
                    pluralStringResource(R.plurals.settings_catalog_size, it, it)
                },
                onClick = component::onStatusClicked,
                trailing = {
                    ServiceStatusPill(state = state.serviceState, onClick = component::onStatusClicked)
                },
            )
        }
        SettingsSection(stringResource(R.string.settings_help)) {
            SettingsRow(
                icon = AppIcons.School,
                title = stringResource(R.string.settings_show_onboarding),
                onClick = component::onShowOnboardingClicked,
            )
            SettingsRow(
                icon = AppIcons.Info,
                title = stringResource(R.string.settings_about),
                onClick = component::onAboutClicked,
            )
            SettingsRow(
                icon = AppIcons.External,
                title = stringResource(R.string.settings_open_site),
                onClick = component::onOpenSiteClicked,
            )
        }
        AlcoholWarningFooter()
        SettingsSection(stringResource(R.string.settings_data)) {
            SettingsRow(
                icon = AppIcons.Delete,
                title = stringResource(R.string.history_clear),
                onClick = component::onClearHistoryClicked,
                enabled = !state.isClearingHistory,
                tint = MaterialTheme.colorScheme.error,
                titleColor = MaterialTheme.colorScheme.error,
            )
        }
        HorizontalDivider(Modifier.padding(top = 24.dp), color = MaterialTheme.colorScheme.outlineVariant)
        Text(
            text = stringResource(R.string.settings_version, state.appVersion, state.appBuild),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(vertical = 24.dp),
        )
    }
}

/**
 * The health warning and the age mark every alcohol-related app carries, under «Help»
 * mid-screen rather than under the version where nobody scrolls.
 */
@Composable
private fun AlcoholWarningFooter() {
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(
            text = stringResource(R.string.settings_alcohol_warning),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.weight(1f),
        )
        Text(
            text = stringResource(R.string.settings_age_limit),
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier
                .border(1.dp, MaterialTheme.colorScheme.outline, CircleShape)
                .padding(horizontal = 10.dp, vertical = 3.dp),
        )
    }
}
