package com.aiweapps.winescan.assistant.components

import com.aiweapps.winescan.components.AppIcons

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.assistant.model.AssistantState
import com.aiweapps.winescan.domain.assistant.model.AssistantLocationSource
import com.aiweapps.winescan.domain.assistant.model.AssistantPhase
import com.aiweapps.winescan.domain.assistant.model.AssistantStore
import com.aiweapps.winescan.domain.assistant.model.AssistantUiError
import com.aiweapps.winescan.retail.RetailSessionStatus
import java.text.DateFormat
import java.time.Instant
import java.util.Date
import kotlinx.coroutines.flow.StateFlow

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AssistantStoreSheet(
    state: AssistantState,
    sessionStatus: StateFlow<RetailSessionStatus>?,
    locationUnavailable: Boolean,
    onDismiss: () -> Unit,
    onLocationRequested: () -> Unit,
    onAddressEntered: (String) -> Unit,
    onStoreSelected: (Int) -> Unit,
    onSearchProducts: (String) -> Unit,
    onOpenStore: () -> Unit,
) {
    var address by remember(state.location?.address) { mutableStateOf(state.location?.address.orEmpty()) }
    var query by remember { mutableStateOf("") }
    val status = sessionStatus?.collectAsState()?.value ?: RetailSessionStatus.NotOpened
    val selected = state.selectedStore
    val stores = (listOfNotNull(state.suggestedStore) + state.availableStores).distinctBy { it.id }
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState) {
        Column(
            modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState())
                .navigationBarsPadding().padding(horizontal = 20.dp).padding(bottom = 16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text(stringResource(R.string.assistant_store_title), style = MaterialTheme.typography.titleLarge,
                    modifier = Modifier.weight(1f))
                IconButton(onClick = onDismiss) {
                    Icon(AppIcons.Close, contentDescription = stringResource(R.string.common_close))
                }
            }
            Text(stringResource(R.string.assistant_store_reason), style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant)

            if (selected != null) SelectedStoreSummary(selected, status, onOpenStore)

            SheetSection(R.string.assistant_v2_store_location_title)
            state.location?.let { location ->
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    Icon(AppIcons.Location, contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant)
                    Column(Modifier.weight(1f)) {
                        Text(location.address, style = MaterialTheme.typography.bodyMedium)
                        Text(stringResource(if (location.source == AssistantLocationSource.GPS)
                            R.string.assistant_location_gps else R.string.assistant_location_entered),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }
            TextButton(onClick = onLocationRequested) {
                Icon(AppIcons.Location, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(8.dp))
                Text(stringResource(R.string.assistant_location_action))
            }
            if (locationUnavailable) Text(stringResource(R.string.assistant_location_unavailable),
                style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.error)
            OutlinedTextField(
                value = address,
                onValueChange = { address = it },
                label = { Text(stringResource(R.string.assistant_store_address)) },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                trailingIcon = {
                    IconButton(onClick = { onAddressEntered(address) }, enabled = address.isNotBlank()) {
                        Icon(AppIcons.Search, contentDescription = stringResource(R.string.assistant_v2_store_find))
                    }
                },
            )

            if (stores.isNotEmpty()) {
                SheetSection(R.string.assistant_v2_store_list_title)
                stores.forEachIndexed { index, store ->
                    if (index > 0) HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.6f))
                    StoreChoice(store, selected?.id == store.id, state.suggestedStore?.id == store.id,
                        state.location?.source, enabled = state.phase == AssistantPhase.IDLE, onStoreSelected)
                }
            }
            if (state.phase == AssistantPhase.SEARCHING_STORE) {
                Text(stringResource(R.string.assistant_store_searching), style = MaterialTheme.typography.bodySmall)
                LinearProgressIndicator(Modifier.fillMaxWidth())
            }
            state.errorCode?.takeIf { it == AssistantUiError.STORE_UNAVAILABLE ||
                it == AssistantUiError.RETAIL_SEARCH_FAILED || it == AssistantUiError.RETAIL_ACCESS_REQUIRED }?.let { error ->
                Text(stringResource(error.textRes()), style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error)
            }

            if (selected != null && status == RetailSessionStatus.Ready) {
                SheetSection(R.string.assistant_store_search)
                OutlinedTextField(
                    value = query,
                    onValueChange = { query = it },
                    label = { Text(stringResource(R.string.assistant_store_search_hint)) },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    trailingIcon = {
                        IconButton(onClick = { onSearchProducts(query) }, enabled = query.isNotBlank()) {
                            Icon(AppIcons.Search, contentDescription = stringResource(R.string.assistant_store_search))
                        }
                    },
                )
            }
            Text(stringResource(R.string.assistant_store_no_delivery), style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun SelectedStoreSummary(store: AssistantStore, status: RetailSessionStatus, onOpenStore: () -> Unit) {
    Surface(shape = RoundedCornerShape(16.dp), color = MaterialTheme.colorScheme.surfaceContainerLow,
        modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Icon(AppIcons.Store, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                Column(Modifier.weight(1f)) {
                    Text(store.name, style = MaterialTheme.typography.titleSmall)
                    Text(store.address, style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            val checked = store.checkedAt?.let { checkedAt ->
                remember(checkedAt) {
                    runCatching {
                        DateFormat.getDateTimeInstance(DateFormat.SHORT, DateFormat.SHORT)
                            .format(Date.from(Instant.parse(checkedAt)))
                    }.getOrNull()
                }
            }
            Text(
                listOfNotNull(
                    stringResource(if (status == RetailSessionStatus.Ready) R.string.assistant_store_session_ready
                        else R.string.assistant_store_session_needed),
                    checked?.let { stringResource(R.string.assistant_store_checked, it) },
                ).joinToString(" · "),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            if (status != RetailSessionStatus.Ready) Button(onClick = onOpenStore, modifier = Modifier.fillMaxWidth()) {
                Text(stringResource(R.string.assistant_open_store), maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
    }
}

@Composable
private fun SheetSection(label: Int) {
    Text(stringResource(label), style = MaterialTheme.typography.titleSmall,
        modifier = Modifier.padding(top = 8.dp))
}

@Composable
private fun StoreChoice(store: AssistantStore, selected: Boolean, suggested: Boolean,
    locationSource: AssistantLocationSource?, enabled: Boolean, onStoreSelected: (Int) -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp).clip(RoundedCornerShape(12.dp))
            .selectable(selected = selected, enabled = enabled, role = Role.RadioButton) { onStoreSelected(store.id) }
            .padding(vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        RadioButton(selected = selected, onClick = null, enabled = enabled)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(store.name, style = MaterialTheme.typography.bodyLarge)
            Text(store.address, style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
            val hint = listOfNotNull(
                when {
                    selected -> stringResource(R.string.assistant_store_selected)
                    suggested -> stringResource(if (locationSource == AssistantLocationSource.GPS)
                        R.string.assistant_store_suggested else R.string.assistant_store_address_suggested)
                    else -> null
                },
                store.distanceMetres?.let { distanceLabel(it) },
            )
            if (hint.isNotEmpty()) Text(hint.joinToString(" · "), style = MaterialTheme.typography.labelMedium,
                color = if (selected || suggested) MaterialTheme.colorScheme.primary
                    else MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
