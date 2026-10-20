package com.aiweapps.winescan.settings.components

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.AppModalBottomSheet
import com.aiweapps.winescan.components.ConfirmClearDialog
import com.aiweapps.winescan.components.ServiceDetailSheet
import com.aiweapps.winescan.components.settings.SettingsComponent
import com.aiweapps.winescan.domain.theme.model.ThemeMode

/** Maps the settings modal slot onto sheets, and the one confirmation onto a dialog. */
@Composable
fun SettingsModals(
    modal: SettingsComponent.Modal?,
    onDismissRequest: () -> Unit,
) {
    AppModalBottomSheet(
        modal = modal?.takeUnless { it is SettingsComponent.Modal.ConfirmClear },
        onDismissRequest = onDismissRequest,
    ) { sheet ->
        when (sheet) {
            is SettingsComponent.Modal.ThemePicker -> ThemePickerSheet(sheet)
            is SettingsComponent.Modal.LanguagePicker -> LanguagePickerSheet(sheet)
            is SettingsComponent.Modal.ServiceDetail -> ServiceDetailSheet(sheet.component)
            is SettingsComponent.Modal.About -> AboutSheet(sheet.component)
            is SettingsComponent.Modal.ConfirmClear -> Unit
        }
    }
    if (modal is SettingsComponent.Modal.ConfirmClear) {
        ConfirmClearDialog(component = modal.component, onDismissRequest = onDismissRequest)
    }
}

@Composable
private fun ThemePickerSheet(modal: SettingsComponent.Modal.ThemePicker) {
    val picker = modal.component
    RadioOptionsSheet(
        title = stringResource(R.string.settings_theme),
        options = picker.options.map { RadioOption(it, stringResource(it.labelRes())) },
        selected = picker.current,
        onSelected = picker::onSelected,
    )
}

@Composable
private fun LanguagePickerSheet(modal: SettingsComponent.Modal.LanguagePicker) {
    val picker = modal.component
    RadioOptionsSheet(
        title = stringResource(R.string.settings_language),
        options = picker.codes.map { RadioOption(it, languageLabel(it)) },
        selected = picker.current,
        onSelected = picker::onSelected,
    )
}

fun ThemeMode.labelRes(): Int = when (this) {
    ThemeMode.System -> R.string.theme_system
    ThemeMode.Light -> R.string.theme_light
    ThemeMode.Dark -> R.string.theme_dark
}

@Composable
fun languageLabel(code: String): String = when (code) {
    "ru" -> stringResource(R.string.language_russian)
    "en" -> stringResource(R.string.language_english)
    else -> code
}
