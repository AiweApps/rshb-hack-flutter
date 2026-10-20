package com.aiweapps.winescan.assistant.components

import com.aiweapps.winescan.components.AppIcons

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import com.aiweapps.winescan.R
import com.aiweapps.winescan.WineScanApp
import com.aiweapps.winescan.activity.MainActivity
import com.aiweapps.winescan.components.assistant.AssistantComponent
import com.aiweapps.winescan.components.assistant.model.AssistantState
import com.aiweapps.winescan.domain.assistant.model.AssistantDinner
import com.aiweapps.winescan.domain.assistant.model.AssistantMessage
import com.aiweapps.winescan.domain.assistant.model.AssistantMessageKind
import com.aiweapps.winescan.domain.assistant.model.AssistantPhase
import com.aiweapps.winescan.domain.assistant.model.AssistantPhoto
import com.aiweapps.winescan.domain.assistant.model.AssistantProduct
import com.aiweapps.winescan.domain.assistant.model.AssistantStore
import com.aiweapps.winescan.domain.assistant.model.AssistantUiError
import com.aiweapps.winescan.domain.assistant.model.AssistantWine
import java.io.File
import java.text.NumberFormat
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.Locale

private const val ANSWER_COLLAPSED_LINES = 3
private const val CARD_INTRO_COLLAPSED_LINES = 3
private const val PAIRINGS_COLLAPSED_LINES = 2
private const val COMPARISON_ROW_PAIRINGS = 3
private const val VISIBLE_WINES = 2
private const val VISIBLE_SEARCH_PRODUCTS = 3

@Composable
fun AssistantAttachmentStrip(photos: List<AssistantPhoto>, onRemove: (String) -> Unit,
    onOpen: (List<AssistantPhoto>, Int) -> Unit) {
    LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        itemsIndexed(photos, key = { _, photo -> photo.id }) { index, photo ->
            Card(shape = RoundedCornerShape(12.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box {
                        AsyncImage(
                            model = File(photo.path),
                            contentDescription = photo.name,
                            modifier = Modifier.size(54.dp).clickable { onOpen(photos, index) },
                            contentScale = ContentScale.Crop,
                        )
                        if (photos.size > 1) PhotoNumber(index + 1, Modifier.align(Alignment.TopStart))
                    }
                    IconButton(onClick = { onRemove(photo.id) }, modifier = Modifier.size(48.dp)) {
                        Icon(AppIcons.Close, contentDescription = stringResource(R.string.assistant_remove_photo))
                    }
                }
            }
        }
    }
}

@Composable
fun AssistantMessageCard(message: AssistantMessage, state: AssistantState, component: AssistantComponent,
    timeline: AssistantTimelineIndex, onOpenPhoto: (List<AssistantPhoto>, Int) -> Unit) {
    when (timeline.version(message.id)) {
        MessageVersion.PREVIOUS -> PreviousVersion(message) {
            MessageBody(message, state, component, timeline, onOpenPhoto, isCurrentVersion = false)
        }
        MessageVersion.CURRENT -> MessageBody(message, state, component, timeline, onOpenPhoto, isCurrentVersion = true)
        MessageVersion.SINGLE -> MessageBody(message, state, component, timeline, onOpenPhoto, isCurrentVersion = false)
    }
}

@Composable
private fun MessageBody(message: AssistantMessage, state: AssistantState, component: AssistantComponent,
    timeline: AssistantTimelineIndex, onOpenPhoto: (List<AssistantPhoto>, Int) -> Unit, isCurrentVersion: Boolean) {
    when (message.kind) {
        AssistantMessageKind.LOCATION_REQUEST -> LocationRequestCard(message, component)
        AssistantMessageKind.STORE_CANDIDATES -> StoreCandidatesCard(message, state, component)
        AssistantMessageKind.STORE_SELECTED -> StoreSelectedCard(message, state, component)
        AssistantMessageKind.USER_TEXT, AssistantMessageKind.USER_PHOTOS -> UserBubble(message, onOpenPhoto)
        AssistantMessageKind.WINE_RESULTS -> WineResults(message, state, component, timeline, onOpenPhoto)
        AssistantMessageKind.DINNER_OPTIONS -> Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            AssistantText(message.id, message.text, timeline.knownLinks, CARD_INTRO_COLLAPSED_LINES)
            message.dinners.forEach { dinner -> DinnerCard(dinner, state, component) }
            SourceNote(message.source, message.checkedAt)
        }
        AssistantMessageKind.PRODUCTS -> ProductListCard(message, state, component, timeline, isCurrentVersion)
        AssistantMessageKind.ERROR -> ErrorCard(message, state, component, onOpenPhoto)
        AssistantMessageKind.ASSISTANT_TEXT, AssistantMessageKind.STATUS -> AssistantText(
            message.id, message.errorCode?.let { stringResource(it.textRes()) } ?: message.text,
            timeline.knownLinks, if (message.id == state.messages.lastOrNull {
                it.kind == AssistantMessageKind.ASSISTANT_TEXT
            }?.id) Int.MAX_VALUE else ANSWER_COLLAPSED_LINES,
        )
    }
}

@Composable
private fun PreviousVersion(message: AssistantMessage, content: @Composable () -> Unit) {
    var expanded by rememberSaveable(message.id) { mutableStateOf(false) }
    val label = when {
        message.kind == AssistantMessageKind.ERROR -> R.string.assistant_previous_notice
        message.kind == AssistantMessageKind.DINNER_OPTIONS -> R.string.assistant_v2_previous_dinners
        message.replacementForProductId != null -> R.string.assistant_v2_previous_candidates
        message.kind == AssistantMessageKind.PRODUCTS -> R.string.assistant_v2_previous_list
        else -> R.string.assistant_v2_previous_store
    }
    val summary = when (message.kind) {
        AssistantMessageKind.DINNER_OPTIONS -> message.dinners.joinToString(" · ") { it.title }
        AssistantMessageKind.PRODUCTS -> message.displayTotalKopeks?.let(::money)
            ?: message.products.firstOrNull()?.title
        else -> message.stores.firstOrNull()?.name
    }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Surface(
            onClick = { expanded = !expanded },
            shape = RoundedCornerShape(16.dp),
            color = MaterialTheme.colorScheme.surfaceContainerLow,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Row(
                Modifier.heightIn(min = 48.dp).padding(horizontal = 14.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Icon(AppIcons.History, contentDescription = null, modifier = Modifier.size(20.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant)
                Column(Modifier.weight(1f)) {
                    Text(stringResource(label), style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                    summary?.takeIf { it.isNotBlank() }?.let {
                        Text(it, style = MaterialTheme.typography.bodySmall, maxLines = 1,
                            overflow = TextOverflow.Ellipsis, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
                Icon(
                    if (expanded) AppIcons.ChevronUp else AppIcons.ChevronDown,
                    contentDescription = stringResource(if (expanded) R.string.assistant_ux_less else R.string.assistant_v2_show),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
        if (expanded) content()
    }
}

@Composable
private fun AssistantText(messageId: String, text: String, knownLinks: Set<String>, collapsedLines: Int) {
    if (text.isBlank()) return
    var expanded by rememberSaveable(messageId) { mutableStateOf(false) }
    var overflows by remember(text) { mutableStateOf(false) }
    val compact = remember(text, knownLinks) { compactAssistantText(text, knownLinks) }
    Column(Modifier.fillMaxWidth().padding(horizontal = 2.dp)) {
        Text(
            if (expanded) text else compact,
            style = MaterialTheme.typography.bodyLarge,
            maxLines = if (expanded) Int.MAX_VALUE else collapsedLines,
            overflow = TextOverflow.Ellipsis,
            onTextLayout = { if (!expanded) overflows = it.hasVisualOverflow },
        )
        if (expanded || overflows || compact != text) {
            TextButton(onClick = { expanded = !expanded }) {
                Text(stringResource(if (expanded) R.string.assistant_ux_less else R.string.assistant_v2_more_text))
            }
        }
    }
}

@Composable
private fun ChatCard(content: @Composable ColumnScope.() -> Unit) {
    Surface(
        shape = RoundedCornerShape(20.dp),
        color = MaterialTheme.colorScheme.surface,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.6f)),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp), content = content)
    }
}

@Composable
private fun LocationRequestCard(message: AssistantMessage, component: AssistantComponent) {
    var address by rememberSaveable(message.id) { mutableStateOf("") }
    var showAddress by rememberSaveable(message.id) { mutableStateOf(false) }
    ChatCard {
        if (message.text == "store_context_changed") Text(stringResource(R.string.assistant_store_context_changed),
            style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(stringResource(R.string.assistant_location_card), style = MaterialTheme.typography.titleMedium)
        Button(onClick = component::onLocationRequested) {
            Icon(AppIcons.Location, contentDescription = null, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(8.dp))
            Text(stringResource(R.string.assistant_locate_me))
        }
        if (!showAddress) TextButton(onClick = { showAddress = true }) {
            Text(stringResource(R.string.assistant_location_manual))
        } else OutlinedTextField(
            value = address,
            onValueChange = { address = it },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
            shape = RoundedCornerShape(16.dp),
            label = { Text(stringResource(R.string.assistant_store_address)) },
            trailingIcon = {
                IconButton(onClick = { component.onAddressEntered(address) }, enabled = address.isNotBlank()) {
                    Icon(AppIcons.Search, contentDescription = stringResource(R.string.assistant_v2_store_find))
                }
            },
        )
    }
}

@Composable
private fun StoreCandidatesCard(message: AssistantMessage, state: AssistantState, component: AssistantComponent) {
    ChatCard {
        Text(stringResource(if (state.selectedStore == null) R.string.assistant_choose_store
            else R.string.assistant_store_options), style = MaterialTheme.typography.titleMedium)
        if (message.stores.isEmpty()) Text(stringResource(R.string.assistant_no_store))
        message.stores.forEachIndexed { index, store ->
            if (index > 0) HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.6f))
            StoreRow(store, selected = state.selectedStore?.id == store.id,
                enabled = state.phase == AssistantPhase.IDLE) { component.onStoreSelected(store.id) }
        }
    }
}

@Composable
private fun StoreRow(store: AssistantStore, selected: Boolean, enabled: Boolean, onSelect: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().heightIn(min = 56.dp).clip(RoundedCornerShape(12.dp))
            .clickable(enabled = enabled && !selected, role = Role.Button, onClick = onSelect).padding(vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Icon(AppIcons.Store, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(store.name, style = MaterialTheme.typography.titleSmall, maxLines = 2, overflow = TextOverflow.Ellipsis)
            Text(store.address, style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 2, overflow = TextOverflow.Ellipsis)
            store.distanceMetres?.let {
                Text(distanceLabel(it), style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        if (selected) Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(AppIcons.CheckCircle, contentDescription = null, modifier = Modifier.size(22.dp),
                tint = MaterialTheme.colorScheme.primary)
            Text(stringResource(R.string.assistant_store_is_selected), style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.primary)
        } else Text(stringResource(R.string.assistant_v2_store_choose), style = MaterialTheme.typography.labelLarge,
            color = if (enabled) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun StoreSelectedCard(message: AssistantMessage, state: AssistantState, component: AssistantComponent) {
    if (message.stores.none { it.id == state.selectedStore?.id }) {
        PastStoreNote(message.stores)
        return
    }
    ChatCard {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Icon(AppIcons.CheckCircle, contentDescription = null, modifier = Modifier.size(20.dp),
                tint = MaterialTheme.colorScheme.primary)
            Text(stringResource(R.string.assistant_store_confirmed), style = MaterialTheme.typography.titleMedium)
        }
        message.stores.forEach { store ->
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(store.name, style = MaterialTheme.typography.titleSmall)
                Text(store.address, style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        Text(stringResource(R.string.assistant_store_selection_saved),
            style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            TextButton(onClick = component::onLocationCardRequested) {
                Text(stringResource(R.string.assistant_change_store))
            }
        }
    }
}

@Composable
private fun PastStoreNote(stores: List<AssistantStore>) {
    if (stores.isEmpty()) return
    Column(Modifier.fillMaxWidth().padding(horizontal = 2.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(stringResource(R.string.assistant_v3_previous_store), style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
        stores.forEach { store ->
            Text(listOf(store.name, store.address).filter { it.isNotBlank() }.joinToString(" · "),
                style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun ErrorCard(message: AssistantMessage, state: AssistantState, component: AssistantComponent,
    onOpenPhoto: (List<AssistantPhoto>, Int) -> Unit) {
    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer)) {
        Column(Modifier.fillMaxWidth().padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Icon(AppIcons.Error, contentDescription = null,
                    tint = MaterialTheme.colorScheme.onErrorContainer)
                Text(message.errorCode?.let { stringResource(it.textRes()) } ?: message.text,
                    modifier = Modifier.weight(1f), color = MaterialTheme.colorScheme.onErrorContainer)
            }
            if (message.photos.isNotEmpty()) PhotoThumbnails(message.photos, onOpenPhoto)
            if (message.id in state.retryableMessageIds) {
                if (message.errorCode == AssistantUiError.RETAIL_ACCESS_REQUIRED) {
                    val activity = LocalContext.current as? MainActivity
                    TextButton(onClick = { activity?.openRetailStore() }) {
                        Text(stringResource(R.string.assistant_open_store))
                    }
                    TextButton(onClick = { component.onMessageRetryClicked(message.id) },
                        enabled = state.phase == AssistantPhase.IDLE) {
                        Text(stringResource(R.string.assistant_retry_after_access))
                    }
                } else TextButton(onClick = { component.onMessageRetryClicked(message.id) },
                    enabled = state.phase == AssistantPhase.IDLE) {
                    Text(stringResource(R.string.assistant_retry))
                }
            }
        }
    }
}

@Composable
private fun UserBubble(message: AssistantMessage, onOpenPhoto: (List<AssistantPhoto>, Int) -> Unit) {
    Column(horizontalAlignment = Alignment.End, modifier = Modifier.fillMaxWidth().padding(start = 40.dp)) {
        Surface(
            color = MaterialTheme.colorScheme.primaryContainer,
            shape = RoundedCornerShape(20.dp),
            modifier = Modifier.widthIn(max = 340.dp),
        ) {
            Column(Modifier.padding(horizontal = 14.dp, vertical = 10.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                if (message.photos.isNotEmpty()) PhotoThumbnails(message.photos, onOpenPhoto)
                if (message.text.isNotBlank()) Text(message.text, style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onPrimaryContainer)
            }
        }
    }
}

@Composable
private fun PhotoThumbnails(photos: List<AssistantPhoto>, onOpenPhoto: (List<AssistantPhoto>, Int) -> Unit) {
    LazyRow(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
        itemsIndexed(photos, key = { _, photo -> photo.id }) { index, photo ->
            Box {
                AsyncImage(model = File(photo.path), contentDescription = photo.name,
                    modifier = Modifier.size(88.dp).clip(RoundedCornerShape(12.dp))
                        .clickable { onOpenPhoto(photos, index) },
                    contentScale = ContentScale.Crop)
                if (photos.size > 1) PhotoNumber(index + 1, Modifier.align(Alignment.TopStart).padding(4.dp))
            }
        }
    }
}

@Composable
private fun PhotoNumber(number: Int, modifier: Modifier) {
    Box(
        modifier.sizeIn(minWidth = 20.dp, minHeight = 20.dp)
            .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.9f), CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Text(number.toString(), style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurface)
    }
}

@Composable
private fun WineResults(message: AssistantMessage, state: AssistantState, component: AssistantComponent,
    timeline: AssistantTimelineIndex, onOpenPhoto: (List<AssistantPhoto>, Int) -> Unit) {
    if (message.comparisonContext) {
        ComparisonContextWines(message, state, component, timeline, onOpenPhoto)
        return
    }
    val allUncertain = message.wines.isNotEmpty() && message.wines.all { it.uncertain }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            stringResource(
                if (allUncertain) R.string.assistant_v3_uncertain_all else R.string.assistant_scan_disclaimer,
            ),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        var expanded by rememberSaveable(message.id) { mutableStateOf(false) }
        val visibleWines = if (expanded) message.wines else message.wines.take(VISIBLE_WINES)
        visibleWines.forEach { wine ->
            key(wine.photoId, wine.instanceId, wine.slug) {
                WineResultCard(wine, state, component, timeline, onOpenPhoto, showUncertainty = !allUncertain)
            }
        }
        if (message.wines.size > VISIBLE_WINES) TextButton(onClick = { expanded = !expanded }) {
            Text(if (expanded) stringResource(R.string.assistant_ux_less) else
                stringResource(R.string.assistant_ux_show_wines, message.wines.size - VISIBLE_WINES))
            Icon(if (expanded) AppIcons.ChevronUp else AppIcons.ChevronDown, contentDescription = null,
                modifier = Modifier.padding(start = 4.dp).size(18.dp))
        }
    }
}

// Wines already attached from Compare are a context summary, not new detection choices.
@Composable
private fun ComparisonContextWines(message: AssistantMessage, state: AssistantState, component: AssistantComponent,
    timeline: AssistantTimelineIndex, onOpenPhoto: (List<AssistantPhoto>, Int) -> Unit) {
    var showCards by rememberSaveable(message.id) { mutableStateOf(false) }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Surface(
            shape = RoundedCornerShape(20.dp),
            color = MaterialTheme.colorScheme.surfaceContainerLow,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Column(Modifier.padding(start = 14.dp, top = 12.dp, end = 14.dp, bottom = 4.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Icon(AppIcons.Compare, contentDescription = null, modifier = Modifier.size(18.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text(stringResource(R.string.assistant_v3_from_comparison),
                        style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                message.wines.forEach { wine ->
                    key(wine.photoId, wine.instanceId, wine.slug) { ComparisonContextRow(wine, state) }
                }
                TextButton(onClick = { showCards = !showCards },
                    contentPadding = PaddingValues(horizontal = 0.dp, vertical = 8.dp)) {
                    Text(stringResource(
                        if (showCards) R.string.assistant_v3_hide_cards else R.string.assistant_v3_show_cards,
                    ))
                    Icon(if (showCards) AppIcons.ChevronUp else AppIcons.ChevronDown, contentDescription = null,
                        modifier = Modifier.padding(start = 4.dp).size(18.dp))
                }
            }
        }
        if (showCards) message.wines.forEach { wine ->
            key(wine.photoId, wine.instanceId, wine.slug) {
                WineResultCard(wine, state, component, timeline, onOpenPhoto, showUncertainty = false)
            }
        }
        Text(stringResource(R.string.assistant_scan_disclaimer), style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun ComparisonContextRow(wine: AssistantWine, state: AssistantState) {
    val pairings = winePairings(wine).take(COMPARISON_ROW_PAIRINGS)
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.Top) {
        Box(
            Modifier.size(width = 32.dp, height = 48.dp).clip(RoundedCornerShape(6.dp))
                .background(MaterialTheme.colorScheme.surface),
            contentAlignment = Alignment.Center,
        ) {
            AsyncImage(
                model = state.referenceAccess?.resolve(wine.reference),
                contentDescription = stringResource(R.string.assistant_reference),
                modifier = Modifier.padding(2.dp),
                contentScale = ContentScale.Fit,
            )
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(wineDisplayTitle(wine), style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
            wine.producer?.takeIf { it.isNotBlank() }?.let {
                Text(it, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            if (pairings.isNotEmpty()) Text(
                stringResource(R.string.assistant_v3_pairs_with, pairings.joinToString(", ")),
                style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
    }
}

private fun wineDisplayTitle(wine: AssistantWine): String {
    val producer = wine.producer?.takeIf { it.isNotBlank() } ?: return wine.title
    if (!wine.title.endsWith(producer, ignoreCase = true)) return wine.title
    return wine.title.dropLast(producer.length).trim().trimEnd('·', '-', '—').trim().ifBlank { wine.title }
}

private fun winePairings(wine: AssistantWine): List<String> =
    (wine.foodPairings + wine.dishes.map { it.name }).filter { it.isNotBlank() }.distinctBy { it.lowercase() }

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun WineResultCard(wine: AssistantWine, state: AssistantState, component: AssistantComponent,
    timeline: AssistantTimelineIndex, onOpenPhoto: (List<AssistantPhoto>, Int) -> Unit, showUncertainty: Boolean) {
    val saved = state.savedWines.any {
        it.slug == wine.slug && it.photoId == wine.photoId && it.instanceId == wine.instanceId
    }
    val chosen = state.selectedWine?.let {
        it.slug == wine.slug && it.photoId == wine.photoId && it.instanceId == wine.instanceId
    } == true
    val displayTitle = wineDisplayTitle(wine)
    val metadata = listOfNotNull(wine.producer, wine.category, wine.region).filter { it.isNotBlank() }
    val pairings = remember(wine.foodPairings, wine.dishes) { winePairings(wine) }
    Surface(
        shape = RoundedCornerShape(20.dp),
        color = MaterialTheme.colorScheme.surface,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.6f)),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(Modifier.padding(start = 12.dp, top = 12.dp, end = 4.dp, bottom = 6.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.Top) {
                Column(horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Box(
                        Modifier.size(width = 56.dp, height = 76.dp).clip(RoundedCornerShape(10.dp))
                            .background(MaterialTheme.colorScheme.surfaceContainerLow),
                        contentAlignment = Alignment.Center,
                    ) {
                        AsyncImage(
                            model = state.referenceAccess?.resolve(wine.reference),
                            contentDescription = stringResource(R.string.assistant_reference),
                            modifier = Modifier.padding(4.dp),
                            contentScale = ContentScale.Fit,
                        )
                    }
                }
                Column(Modifier.weight(1f).padding(top = 2.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(displayTitle, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                    if (metadata.isNotEmpty()) Text(metadata.joinToString(" · "),
                        style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    if (showUncertainty && wine.uncertain) Text(stringResource(R.string.assistant_wine_uncertain),
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                IconButton(onClick = {
                    component.onWineInstanceFavoriteClicked(wine.photoId, wine.instanceId, wine.slug)
                }) {
                    Icon(
                        if (saved) AppIcons.FavoriteFilled else AppIcons.Favorite,
                        contentDescription = stringResource(
                            if (saved) R.string.assistant_unsave_wine else R.string.assistant_save_wine,
                        ),
                        tint = if (saved) MaterialTheme.colorScheme.primary
                            else MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
            WineAbout(wine, pairings, component::onLinkClicked)
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                wine.photoPath?.let { path ->
                    val album = timeline.albumFor(wine.photoId)
                    val position = album?.indexOfFirst { it.id == wine.photoId }?.takeIf { it >= 0 }
                    val photoNumber = if (album != null && album.size > 1 && position != null) position + 1 else null
                    SourcePhotoThumb(path, photoNumber) {
                        if (album != null && position != null) onOpenPhoto(album, position)
                        else onOpenPhoto(
                            listOf(AssistantPhoto(wine.photoId ?: path, path, path.substringAfterLast('/'))), 0,
                        )
                    }
                }
                val dinnerPrompt = stringResource(R.string.assistant_wine_dinner_prompt)
                val onSelect = { component.onWineDinnerRequested(wine.photoId, wine.instanceId, wine.slug, dinnerPrompt) }
                val actionPadding = PaddingValues(horizontal = 14.dp, vertical = 8.dp)
                // The source photo keeps its target. Text actions wrap as a group on
                // narrow phones instead of squeezing the wine action to a few letters.
                FlowRow(Modifier.weight(1f), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    if (chosen) FilledTonalButton(onClick = onSelect, contentPadding = actionPadding,
                        modifier = Modifier.heightIn(min = 48.dp)) {
                        Icon(AppIcons.CheckCircle, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(6.dp))
                        Text(stringResource(R.string.assistant_wine_dinner_action))
                    } else OutlinedButton(onClick = onSelect, contentPadding = actionPadding,
                        modifier = Modifier.heightIn(min = 48.dp)) {
                        Text(stringResource(R.string.assistant_wine_dinner_action), textAlign = TextAlign.Center)
                    }
                    TextButton(onClick = {
                        component.onWineInstanceCompareClicked(wine.photoId, wine.instanceId, wine.slug)
                    }, enabled = state.compareBusyKey == null,
                        modifier = Modifier.heightIn(min = 48.dp),
                        contentPadding = PaddingValues(horizontal = 8.dp, vertical = 8.dp)) {
                        Text(stringResource(if (wine.slug in state.compareSlugs) R.string.action_in_compare
                            else R.string.tab_compare_short))
                    }
                }
            }
        }
    }
}

@Composable
private fun WineAbout(wine: AssistantWine, pairings: List<String>, onOpenCatalogue: (String) -> Unit) {
    val description = wine.description?.takeIf { it.isNotBlank() }
    var expanded by rememberSaveable(wine.slug, wine.photoId, wine.instanceId) { mutableStateOf(false) }
    var pairingsOverflow by remember(pairings) { mutableStateOf(false) }
    if (pairings.isEmpty() && description == null && wine.pageUrl == null) return
    val pairingsText = pairings.takeIf { it.isNotEmpty() }
        ?.let { stringResource(R.string.assistant_v3_pairs_with, it.joinToString(", ")) }
    Column(Modifier.fillMaxWidth().padding(end = 8.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            if (pairingsText != null) Text(
                pairingsText,
                style = MaterialTheme.typography.bodyMedium,
                maxLines = if (expanded) Int.MAX_VALUE else PAIRINGS_COLLAPSED_LINES,
                overflow = TextOverflow.Ellipsis,
                onTextLayout = { if (!expanded) pairingsOverflow = it.hasVisualOverflow },
                modifier = Modifier.weight(1f),
            )
            if (pairingsText != null && (description != null || wine.pageUrl != null || expanded || pairingsOverflow)) {
                IconButton(onClick = { expanded = !expanded }) {
                    Icon(if (expanded) AppIcons.ChevronUp else AppIcons.ChevronDown,
                        contentDescription = stringResource(
                            if (expanded) R.string.assistant_ux_less else R.string.assistant_v3_about_wine,
                        ), modifier = Modifier.size(20.dp))
                }
            } else if (pairingsText == null && (description != null || wine.pageUrl != null)) {
                TextButton(onClick = { expanded = !expanded }, contentPadding = PaddingValues(horizontal = 0.dp)) {
                    Text(stringResource(if (expanded) R.string.assistant_ux_less else R.string.assistant_v3_about_wine))
                    Icon(if (expanded) AppIcons.ChevronUp else AppIcons.ChevronDown, contentDescription = null,
                        modifier = Modifier.padding(start = 4.dp).size(16.dp))
                }
            }
        }
        if (expanded && description != null) Text(description, style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
        if (expanded) wine.pageUrl?.let { url ->
            TextButton(onClick = { onOpenCatalogue(url) }, contentPadding = PaddingValues(horizontal = 0.dp)) {
                Text(stringResource(R.string.assistant_v2_catalog))
                Spacer(Modifier.width(4.dp))
                Icon(AppIcons.External, contentDescription = null, modifier = Modifier.size(16.dp))
            }
        }
    }
}

@Composable
private fun SourcePhotoThumb(path: String, photoNumber: Int?, onOpen: () -> Unit) {
    val label = photoNumber?.let { stringResource(R.string.assistant_v2_your_photo_number, it) }
        ?: stringResource(R.string.assistant_v2_your_photo)
    Box(
        Modifier.size(48.dp).clip(RoundedCornerShape(10.dp))
            .clickable(onClickLabel = label, role = Role.Image, onClick = onOpen),
    ) {
        AsyncImage(model = File(path), contentDescription = label, modifier = Modifier.size(48.dp),
            contentScale = ContentScale.Crop)
        photoNumber?.let { PhotoNumber(it, Modifier.align(Alignment.TopStart).padding(2.dp)) }
    }
}

@Composable
private fun DinnerCard(dinner: AssistantDinner, state: AssistantState, component: AssistantComponent) {
    val selected = dinner.remoteOptionId != null && state.messages.asReversed().firstOrNull {
        it.selectedDinnerOptionId != null
    }?.selectedDinnerOptionId == dinner.remoteOptionId
    var expanded by rememberSaveable(dinner.id) { mutableStateOf(false) }
    var explanationOverflows by remember(dinner.explanation) { mutableStateOf(false) }
    ChatCard {
        Text(dinner.title, style = MaterialTheme.typography.titleMedium)
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            dinner.preparationMinutes?.let { Text(stringResource(R.string.assistant_dinner_minutes, it),
                style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant) }
            Text(dinner.displayTotalKopeks?.let(::money) ?: stringResource(R.string.assistant_product_unknown_total),
                style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        Text(dinner.explanation, style = MaterialTheme.typography.bodyMedium,
            maxLines = if (expanded) Int.MAX_VALUE else 2, overflow = TextOverflow.Ellipsis,
            onTextLayout = { if (!expanded) explanationOverflows = it.hasVisualOverflow })
        if (expanded || explanationOverflows) TextButton(onClick = { expanded = !expanded }) {
            Text(stringResource(if (expanded) R.string.assistant_ux_less else R.string.assistant_ux_dinner_details))
        }
        dinner.caveat?.let { Text(it, style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant) }
        if (selected) Row(Modifier.heightIn(min = 40.dp), verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Icon(AppIcons.CheckCircle, contentDescription = null, modifier = Modifier.size(20.dp),
                tint = MaterialTheme.colorScheme.primary)
            Text(stringResource(R.string.assistant_v2_dinner_chosen), style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.primary)
        } else TextButton(onClick = { component.onDinnerSelected(dinner.id) },
            contentPadding = PaddingValues(horizontal = 0.dp, vertical = 8.dp),
            modifier = Modifier.heightIn(min = 48.dp),
            enabled = state.phase == AssistantPhase.IDLE) {
            Text(stringResource(R.string.assistant_dinner_choose))
            Icon(AppIcons.Forward, contentDescription = null, modifier = Modifier.padding(start = 8.dp).size(18.dp))
        }
    }
}

@Composable
private fun SourceNote(source: String?, checkedAt: String?) {
    source ?: return
    val label = when (source) {
        "live_catalog", "perekrestok_webview" -> stringResource(R.string.assistant_source_live)
        "session_context" -> stringResource(R.string.assistant_source_session)
        else -> stringResource(R.string.assistant_source_snapshot)
    }
    val checked = checkedAt?.takeIf { source == "saved_snapshot" }
        ?.let { stringResource(R.string.assistant_snapshot_checked_at, formatCheckedAt(it)) }
    Text(listOfNotNull(label, checked).joinToString(" · "), style = MaterialTheme.typography.bodySmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant)
}

@Composable
private fun ProductListCard(message: AssistantMessage, state: AssistantState, component: AssistantComponent,
    timeline: AssistantTimelineIndex, isCurrentVersion: Boolean) {
    var expanded by rememberSaveable(message.id) { mutableStateOf(false) }
    val shoppingList = message.sourceMessageId != null && message.replacementForProductId == null
    val visibleProducts = if (shoppingList || expanded) message.products else message.products.take(VISIBLE_SEARCH_PRODUCTS)
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        AssistantText(message.id, message.text, timeline.knownLinks, CARD_INTRO_COLLAPSED_LINES)
        Surface(
            shape = RoundedCornerShape(20.dp),
            color = MaterialTheme.colorScheme.surface,
            border = BorderStroke(1.dp, if (isCurrentVersion) MaterialTheme.colorScheme.primary.copy(alpha = 0.5f)
                else MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.6f)),
            modifier = Modifier.fillMaxWidth(),
        ) {
            Column(Modifier.padding(horizontal = 16.dp, vertical = 12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(stringResource(when {
                    isCurrentVersion -> R.string.assistant_v2_current_list
                    message.replacementForProductId != null -> R.string.assistant_v2_replacement_title
                    shoppingList -> R.string.assistant_v2_list_title
                    else -> R.string.assistant_ux_catalog_title
                }), style = MaterialTheme.typography.titleSmall,
                    color = if (isCurrentVersion) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface)
                message.displayTotalKopeks?.let {
                    Text(stringResource(R.string.assistant_total, money(it)), style = MaterialTheme.typography.titleMedium,
                        modifier = Modifier.padding(top = 4.dp))
                } ?: if (shoppingList) {
                    Text(stringResource(R.string.assistant_product_unknown_total), style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                } else Unit
                SourceNote(message.source, message.checkedAt)
                if (message.products.isEmpty()) Text(stringResource(R.string.assistant_no_products),
                    style = MaterialTheme.typography.bodyMedium)
                visibleProducts.forEachIndexed { index, product ->
                    if (index > 0) HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.6f))
                    ProductRow(
                        product, component,
                        messageId = message.id,
                        originalProductId = message.replacementForProductId,
                        canUse = state.phase == AssistantPhase.IDLE && (message.id == state.activeBasketMessageId ||
                            message.id == state.activeReplacementMessageId),
                        replacementCandidate = message.replacementForProductId != null,
                        shoppingList = shoppingList,
                    )
                }
                if (!shoppingList && message.products.size > VISIBLE_SEARCH_PRODUCTS) TextButton(
                    onClick = { expanded = !expanded }, modifier = Modifier.fillMaxWidth()) {
                    Text(if (expanded) stringResource(R.string.assistant_ux_less) else
                        stringResource(R.string.assistant_ux_show_products, message.products.size))
                    Icon(if (expanded) AppIcons.ChevronUp else AppIcons.ChevronDown, contentDescription = null)
                }

            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun ProductRow(
    product: AssistantProduct,
    component: AssistantComponent,
    messageId: String,
    originalProductId: String?,
    canUse: Boolean,
    replacementCandidate: Boolean,
    shoppingList: Boolean,
) {
    if (!shoppingList && !replacementCandidate) {
        ProductCandidateRow(product, component)
        return
    }
    val onProductAction: (String) -> Unit = { id ->
        if (replacementCandidate) component.onReplacementCandidateChosen(messageId, originalProductId.orEmpty(), id)
        else component.onProductReplacementRequestedFrom(messageId, id)
    }
    var details by rememberSaveable(product.id, product.quantity) { mutableStateOf(false) }
    val secondaryColor = MaterialTheme.colorScheme.onSurfaceVariant
    val hasDetails = product.url != null || (shoppingList &&
        (product.unitPriceKopeks != null || product.recipeQuantity != null))
    Column(Modifier.fillMaxWidth().padding(top = 8.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.Top) {
            ProductThumbnail(product)
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(product.title, style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium)
                // Keep the actual purchase facts together; secondary controls do not
                // consume a separate row beside each value or compete with the price.
                FlowRow(horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text((if (shoppingList) product.displayLineTotalKopeks else product.unitPriceKopeks)?.let {
                        if (shoppingList) money(it) else unitPriceLabel(product, it)
                    } ?: stringResource(if (shoppingList) R.string.assistant_product_unknown_total
                        else R.string.assistant_product_unknown_price),
                        style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                    if (shoppingList) Text(purchaseQuantityLabel(product),
                        style = MaterialTheme.typography.bodySmall, color = secondaryColor)
                    product.availability?.let {
                        Text(availabilityLabel(it), style = MaterialTheme.typography.bodySmall,
                            color = secondaryColor)
                    }
                }
            }
        }
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween) {
            TextButton(onClick = { onProductAction(product.id) }, enabled = canUse,
                contentPadding = PaddingValues(horizontal = 0.dp, vertical = 8.dp),
                modifier = Modifier.heightIn(min = 48.dp)) {
                Text(stringResource(if (replacementCandidate) R.string.assistant_product_choose_replacement
                    else R.string.assistant_product_replace))
            }
            if (hasDetails) TextButton(
                onClick = { details = !details },
                colors = ButtonDefaults.textButtonColors(contentColor = secondaryColor),
                modifier = Modifier.heightIn(min = 48.dp),
            ) {
                Text(stringResource(if (details) R.string.assistant_ux_less else R.string.assistant_v2_details))
                Icon(if (details) AppIcons.ChevronUp else AppIcons.ChevronDown, contentDescription = null,
                    modifier = Modifier.padding(start = 4.dp).size(18.dp))
            }
        }
        if (details) Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            if (shoppingList) {
                product.unitPriceKopeks?.let {
                    Text(unitPriceLabel(product, it), style = MaterialTheme.typography.bodySmall, color = secondaryColor)
                }
                product.recipeQuantity?.let {
                    Text(stringResource(R.string.assistant_product_recipe_quantity, it),
                        style = MaterialTheme.typography.bodySmall, color = secondaryColor)
                }
            }
            product.url?.let { url ->
                TextButton(onClick = { component.onLinkClicked(url) },
                    colors = ButtonDefaults.textButtonColors(contentColor = secondaryColor),
                    contentPadding = PaddingValues(horizontal = 0.dp, vertical = 8.dp),
                    modifier = Modifier.heightIn(min = 48.dp)) {
                    Text(stringResource(R.string.assistant_product_open))
                    Icon(AppIcons.External, contentDescription = null,
                        modifier = Modifier.padding(start = 6.dp).size(18.dp))
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun ProductCandidateRow(product: AssistantProduct, component: AssistantComponent) {
    Row(Modifier.fillMaxWidth().padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        ProductThumbnail(product)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(product.title, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
            FlowRow(horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(product.unitPriceKopeks?.let { unitPriceLabel(product, it) }
                    ?: stringResource(R.string.assistant_product_unknown_price),
                    style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
                product.availability?.let {
                    Text(availabilityLabel(it), style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
        product.url?.let { url ->
            IconButton(onClick = { component.onLinkClicked(url) }) {
                Icon(AppIcons.External,
                    contentDescription = stringResource(R.string.assistant_product_open),
                    modifier = Modifier.size(18.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

@Composable
private fun ProductThumbnail(product: AssistantProduct) {
    val url = product.imageUrl ?: return
    var failed by remember(url) { mutableStateOf(false) }
    if (failed) return
    val loader = (LocalContext.current.applicationContext as WineScanApp).publicImageLoader
    AsyncImage(
        model = url,
        imageLoader = loader,
        // The adjacent title names the product; the photo is supplementary.
        contentDescription = null,
        modifier = Modifier.size(48.dp).clip(RoundedCornerShape(10.dp))
            .background(MaterialTheme.colorScheme.surfaceContainerLow).padding(3.dp),
        contentScale = ContentScale.Fit,
        onError = { failed = true },
    )
}

@Composable
internal fun distanceLabel(metres: Double): String = if (metres < 1000) {
    stringResource(R.string.assistant_v2_distance_m, metres.toInt())
} else {
    val km = NumberFormat.getNumberInstance(Locale.getDefault()).apply { maximumFractionDigits = 1 }.format(metres / 1000)
    stringResource(R.string.assistant_v2_distance_km, km)
}

@Composable
private fun availabilityLabel(value: String): String = stringResource(when (value) {
    "many" -> R.string.assistant_availability_many
    "few" -> R.string.assistant_availability_few
    "none" -> R.string.assistant_availability_none
    else -> R.string.assistant_availability_unknown
})

private fun money(kopeks: Long): String = NumberFormat.getNumberInstance(Locale.getDefault()).apply {
    minimumFractionDigits = 2
    maximumFractionDigits = 2
}.format(kopeks / 100.0) + " ₽"

private fun formatCheckedAt(value: String): String = runCatching {
    DateTimeFormatter.ofLocalizedDateTime(FormatStyle.SHORT)
        .withLocale(Locale.getDefault()).withZone(ZoneId.systemDefault())
        .format(Instant.parse(value))
}.getOrElse { value.substringBefore('T') }

@Composable
private fun purchaseQuantityLabel(product: AssistantProduct): String {
    if (!product.hasKnownPurchaseQuantity) return stringResource(R.string.assistant_product_unknown_quantity)
    val quantity = NumberFormat.getNumberInstance().apply { maximumFractionDigits = 6 }
        .format(product.purchaseLotQuantity)
    return stringResource(R.string.assistant_product_purchase_lot, product.quantity, quantity,
        product.purchaseLotUnit.orEmpty())
}

@Composable
private fun unitPriceLabel(product: AssistantProduct, kopeks: Long): String = when (product.priceBasis) {
    "piece" -> stringResource(R.string.assistant_product_price_piece, money(kopeks))
    "weight" -> stringResource(R.string.assistant_product_price_kg, money(kopeks))
    else -> stringResource(R.string.assistant_product_price_unknown_basis, money(kopeks))
}
