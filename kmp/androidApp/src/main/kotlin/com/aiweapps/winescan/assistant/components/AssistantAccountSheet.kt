package com.aiweapps.winescan.assistant.components

import androidx.compose.runtime.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.assistant.AssistantComponent
import com.aiweapps.winescan.components.assistant.model.AssistantState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AssistantAccountSheet(state: AssistantState, component: AssistantComponent, onDismiss: () -> Unit) {
    var username by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var register by remember { mutableStateOf(false) }
    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(Modifier.fillMaxWidth().imePadding().verticalScroll(rememberScrollState()).padding(24.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(stringResource(R.string.assistant_account), style = MaterialTheme.typography.headlineSmall)
            Text(state.account?.username ?: stringResource(if (state.account == null) R.string.assistant_legacy_history else R.string.assistant_guest_account))
            if (state.account?.expired == true) Text(stringResource(R.string.assistant_account_expired), color = MaterialTheme.colorScheme.error)
            if (state.account?.username == null || state.account?.expired == true || register) {
                OutlinedTextField(username, { username = it }, label = { Text(stringResource(R.string.assistant_username)) }, singleLine = true)
                OutlinedTextField(password, { password = it }, label = { Text(stringResource(R.string.assistant_password)) }, singleLine = true,
                    visualTransformation = PasswordVisualTransformation())
                Button(onClick = { component.onAccountSubmit(username, password, register); password = "" },
                    enabled = !state.accountBusy && username.isNotBlank() && password.isNotBlank()) {
                    Text(stringResource(if (register) R.string.assistant_register else R.string.assistant_login))
                }
                TextButton(onClick = { register = !register }) {
                    Text(stringResource(if (register) R.string.assistant_login else R.string.assistant_register))
                }
            }
            if (state.account == null || state.account?.expired == true && state.account?.username == null) TextButton(onClick = { component.onAccountSubmit("", "", false) }, enabled = !state.accountBusy) {
                Text(stringResource(R.string.assistant_continue_guest))
            }
            else TextButton(onClick = component::onLogoutClicked, enabled = !state.accountBusy) {
                Text(stringResource(R.string.assistant_logout))
            }
            if (state.accountBusy) LinearProgressIndicator(Modifier.fillMaxWidth())
            if (state.accountError) Text(stringResource(R.string.assistant_account_failed), color = MaterialTheme.colorScheme.error)
            Spacer(Modifier.height(24.dp))
        }
    }
}
