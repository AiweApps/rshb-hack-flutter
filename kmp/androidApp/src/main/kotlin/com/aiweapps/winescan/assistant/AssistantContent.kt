package com.aiweapps.winescan.assistant

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.speech.RecognizerIntent
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.scrollBy
import androidx.compose.foundation.interaction.DragInteraction
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.isImeVisible
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DrawerValue
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalDrawerSheet
import androidx.compose.material3.ModalNavigationDrawer
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberDrawerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.input.nestedscroll.NestedScrollConnection
import androidx.compose.ui.input.nestedscroll.NestedScrollSource
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.aiweapps.core.components.model.ScreenState
import com.aiweapps.winescan.R
import com.aiweapps.winescan.activity.MainActivity
import com.aiweapps.winescan.assistant.components.AssistantAttachmentStrip
import com.aiweapps.winescan.assistant.components.AssistantMessageCard
import com.aiweapps.winescan.assistant.components.AssistantPhotoViewer
import com.aiweapps.winescan.assistant.components.AssistantStoreSheet
import com.aiweapps.winescan.assistant.components.AssistantTimelineIndex
import com.aiweapps.winescan.assistant.components.LocationPermissionEffect
import com.aiweapps.winescan.assistant.components.textRes
import com.aiweapps.winescan.components.AppIcons
import com.aiweapps.winescan.components.ErrorState
import com.aiweapps.winescan.components.LoadingState
import com.aiweapps.winescan.components.ToastEffect
import com.aiweapps.winescan.components.assistant.AssistantComponent
import com.aiweapps.winescan.components.assistant.model.AssistantCompareNotice
import com.aiweapps.winescan.components.assistant.model.AssistantState
import com.aiweapps.winescan.domain.assistant.model.AssistantMessage
import com.aiweapps.winescan.domain.assistant.model.AssistantMessageKind
import com.aiweapps.winescan.domain.assistant.model.AssistantPhase
import com.aiweapps.winescan.domain.assistant.model.AssistantPhoto
import com.aiweapps.winescan.domain.assistant.model.AssistantUiError
import com.aiweapps.winescan.platform.rememberPhotoPreparer
import com.arkivanov.decompose.extensions.compose.subscribeAsState
import java.io.File
import java.util.Locale
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

private const val MAX_PENDING_PHOTOS = 5
private val FOLLOWED_PHASES = setOf(
    AssistantPhase.SEARCHING_STORE, AssistantPhase.REPLACING_PRODUCT, AssistantPhase.SELECTING_DINNER,
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AssistantContent(
    component: AssistantComponent,
    onOpenScanHistory: () -> Unit = {},
    onOpenSettings: () -> Unit = {},
) {
    val state by component.state.subscribeAsState()
    val activity = LocalContext.current as? MainActivity
    val focusManager = LocalFocusManager.current
    val drawerState = rememberDrawerState(DrawerValue.Closed)
    val scope = rememberCoroutineScope()
    val snackbar = remember { SnackbarHostState() }
    ToastEffect(
        message = when (state.compareNotice) {
            AssistantCompareNotice.SOURCE_UNAVAILABLE -> stringResource(R.string.assistant_compare_source_unavailable)
            AssistantCompareNotice.FAILED -> stringResource(R.string.notice_add_to_compare_failed)
            null -> null
        },
        host = snackbar,
        onConsumed = component::onCompareNoticeConsumed,
    )
    val preparer = rememberPhotoPreparer()
    var showAccountSheet by remember { mutableStateOf(false) }
    var showStoreSheet by remember { mutableStateOf(false) }
    var viewerPhotos by remember { mutableStateOf(emptyList<AssistantPhoto>()) }
    var viewerIndex by remember { mutableStateOf(0) }
    val openPhoto: (List<AssistantPhoto>, Int) -> Unit = { photos, index ->
        viewerPhotos = photos
        viewerIndex = index
    }
    var locationUnavailable by remember { mutableStateOf(false) }
    var isPreparingPhotos by remember { mutableStateOf(false) }
    var pickerConversationId by remember { mutableStateOf<String?>(null) }
    var composerFocused by remember { mutableStateOf(false) }
    val timelineListState = rememberSaveable(state.conversationId, saver = LazyListState.Saver) { LazyListState() }
    var jumpRequestTicket by remember(state.conversationId) { mutableIntStateOf(0) }
    val photoFailure = stringResource(R.string.assistant_photo_failed)
    val voiceUnavailable = stringResource(R.string.assistant_voice_unavailable)
    val voicePrompt = stringResource(R.string.assistant_voice_prompt)

    val voiceLauncher = rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            val recognized = result.data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
                ?.firstOrNull()?.trim().orEmpty()
            if (recognized.isNotEmpty()) {
                component.onDraftChanged(listOf(state.draft.trim(), recognized)
                    .filter { it.isNotEmpty() }.joinToString(" "))
            }
        }
    }

    val picker = rememberLauncherForActivityResult(
        ActivityResultContracts.PickMultipleVisualMedia(MAX_PENDING_PHOTOS),
    ) { uris ->
        val conversationId = pickerConversationId
        if (uris.isEmpty() || conversationId == null) {
            pickerConversationId = null
            return@rememberLauncherForActivityResult
        }
        isPreparingPhotos = true
        scope.launch {
            try {
                val current = component.state.value
                val room = (MAX_PENDING_PHOTOS - current.attachments.size - current.pendingAttachments).coerceAtLeast(0)
                uris.take(room).forEach { uri ->
                    if (component.state.value.conversationId != conversationId) return@forEach
                    val path = preparer.prepare(uri)
                    if (path == null) snackbar.showSnackbar(photoFailure)
                    else if (component.state.value.conversationId == conversationId) component.onAttachmentPicked(path)
                    else File(path).delete()
                }
            } finally {
                isPreparingPhotos = false
                pickerConversationId = null
            }
        }
    }

    LocationPermissionEffect(
        ticket = state.locationRequestTicket,
        onResolved = { latitude, longitude, address ->
            locationUnavailable = false
            component.onLocationResolved(latitude, longitude, address)
        },
        onUnavailable = { locationUnavailable = true },
    )

    BackHandler(enabled = drawerState.isOpen) {
        scope.launch { drawerState.close() }
    }

    ModalNavigationDrawer(
        drawerState = drawerState,
        drawerContent = {
            AssistantDrawer(
                state = state,
                onNewConversation = {
                    focusManager.clearFocus()
                    component.onNewConversationClicked()
                    scope.launch { drawerState.close() }
                },
                onConversation = { id ->
                    focusManager.clearFocus()
                    component.onConversationSelected(id)
                    scope.launch { drawerState.close() }
                },
                onSavedWine = { photoId, instanceId, slug ->
                    component.onWineInstanceSelected(photoId, instanceId, slug)
                    scope.launch { drawerState.close() }
                },
                onStore = {
                    showStoreSheet = true
                    scope.launch { drawerState.close() }
                },
                onHistory = { scope.launch { drawerState.close(); onOpenScanHistory() } },
                onSettings = { scope.launch { drawerState.close(); onOpenSettings() } },
            )
        },
    ) {
        Scaffold(
            contentWindowInsets = WindowInsets(0, 0, 0, 0),
            topBar = {
                CenterAlignedTopAppBar(
                    colors = TopAppBarDefaults.centerAlignedTopAppBarColors(containerColor = MaterialTheme.colorScheme.background),
                    title = { AssistantHeaderTitle(state.selectedStore?.name) { showStoreSheet = true } },
                    navigationIcon = {
                        IconButton(onClick = {
                            focusManager.clearFocus()
                            scope.launch { drawerState.open() }
                        }) {
                            Icon(AppIcons.Menu, contentDescription = stringResource(R.string.assistant_menu))
                        }
                    },
                    actions = {
                        if (timelineListState.canScrollForward && state.messages.isNotEmpty()) {
                            JumpToLatest { jumpRequestTicket += 1 }
                        }
                        IconButton(onClick = {
                            focusManager.clearFocus()
                            component.onNewConversationClicked()
                        }) {
                            Icon(AppIcons.NewChat, contentDescription = stringResource(R.string.assistant_new_chat))
                        }
                    },
                )
            },
            bottomBar = {
                if (state.screenState is ScreenState.Content) {
                    AssistantComposer(
                        state = state,
                        isPreparingPhotos = isPreparingPhotos,
                        onTextChanged = component::onDraftChanged,
                        onFocusChanged = { composerFocused = it },
                        onRemovePhoto = component::onRemoveAttachment,
                        onOpenPhoto = openPhoto,
                        onAddPhotos = {
                            pickerConversationId = component.onPhotoSelectionStarted()
                            if (pickerConversationId != null) picker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                        },
                        onSend = { if (!isPreparingPhotos) component.onSendClicked() },
                        onDictate = {
                            try {
                                voiceLauncher.launch(Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                                    putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault().toLanguageTag())
                                    putExtra(RecognizerIntent.EXTRA_PROMPT, voicePrompt)
                                    putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
                                })
                            } catch (_: ActivityNotFoundException) {
                                scope.launch { snackbar.showSnackbar(voiceUnavailable) }
                            }
                        },
                    )
                }
            },
            snackbarHost = { SnackbarHost(snackbar) },
        ) { padding ->
            Box(Modifier.fillMaxSize().padding(padding)) {
                when (val screen = state.screenState) {
                    is ScreenState.Loading -> LoadingState()
                    is ScreenState.Error -> ErrorState(error = screen.error, onRetry = component::onRetryClicked)
                    is ScreenState.Content -> AssistantTimeline(
                        state = state,
                        listState = timelineListState,
                        jumpRequestTicket = jumpRequestTicket,
                        component = component,
                        locationUnavailable = locationUnavailable,
                        composerFocused = composerFocused,
                        canAddPhotos = !isPreparingPhotos && state.pendingAttachments == 0 &&
                            state.attachments.size < MAX_PENDING_PHOTOS,
                        onAddPhotos = {
                            if (!isPreparingPhotos && component.state.value.pendingAttachments == 0) {
                                pickerConversationId = component.onPhotoSelectionStarted()
                                if (pickerConversationId != null) picker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                            }
                        },
                        onOpenPhoto = openPhoto,
                    )
                }
            }
        }
    }

    LaunchedEffect(state.accountRequestTicket) { if (state.accountRequestTicket > 0) showAccountSheet = true }
    LaunchedEffect(state.accountError) { if (state.accountError && state.account == null) showAccountSheet = true }
    if (showAccountSheet) com.aiweapps.winescan.assistant.components.AssistantAccountSheet(state, component) { showAccountSheet = false }
    if (showStoreSheet) {
        AssistantStoreSheet(
            state = state,
            sessionStatus = activity?.retailAdapter?.status,
            locationUnavailable = locationUnavailable,
            onDismiss = { showStoreSheet = false },
            onLocationRequested = {
                locationUnavailable = false
                component.onLocationRequested()
            },
            onAddressEntered = component::onAddressEntered,
            onStoreSelected = component::onStoreSelected,
            onSearchProducts = { query ->
                showStoreSheet = false
                component.onSearchProductsRequested(query)
            },
            onOpenStore = {
                showStoreSheet = false
                activity?.openRetailStore()
            },
        )
    }
    if (viewerPhotos.isNotEmpty()) {
        AssistantPhotoViewer(viewerPhotos, viewerIndex) { viewerPhotos = emptyList() }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun AssistantTimeline(state: AssistantState, listState: LazyListState,
    jumpRequestTicket: Int, component: AssistantComponent,
    locationUnavailable: Boolean, composerFocused: Boolean, canAddPhotos: Boolean, onAddPhotos: () -> Unit,
    onOpenPhoto: (List<AssistantPhoto>, Int) -> Unit) {
    val timeline = remember(state.messages) { AssistantTimelineIndex(state.messages) }
    val leadingItems = (if (locationUnavailable) 1 else 0) + (if (state.messages.isEmpty()) 1 else 0)
    val itemCount = leadingItems + state.messages.size + (if (state.phase == AssistantPhase.IDLE) 0 else 1) +
        (if (state.errorCode != null) 1 else 0) + 1
    val wasAtBottom = !listState.canScrollForward
    val latestUserIndex = state.messages.indexOfLast {
        it.kind == AssistantMessageKind.USER_TEXT || it.kind == AssistantMessageKind.USER_PHOTOS
    }
    val latestUserMessageId = state.messages.getOrNull(latestUserIndex)?.id
    // Only a send or an explicit card action may move the reader; passive replies raise the jump control.
    var observedUserMessageId by remember(state.conversationId) { mutableStateOf(latestUserMessageId) }
    var followFrom by remember(state.conversationId) { mutableStateOf<Int?>(null) }
    var seenCount by remember(state.conversationId) { mutableIntStateOf(state.messages.size) }
    // While pinned, any growth below the viewport (late measurement, keyboard, composer) keeps the tail visible.
    var pinnedToEnd by remember(state.conversationId) { mutableStateOf(false) }
    val imeVisible = WindowInsets.isImeVisible
    val comparisonContextIndex = state.messages.lastIndex
        .takeIf { state.messages.lastOrNull()?.isComparisonContext() == true }
    LaunchedEffect(state.conversationId) {
        if (state.messages.isNotEmpty() && listState.firstVisibleItemIndex == 0 &&
            listState.firstVisibleItemScrollOffset == 0) {
            if (comparisonContextIndex != null && !(composerFocused && imeVisible)) {
                listState.scrollToItem(leadingItems + comparisonContextIndex)
            } else {
                pinnedToEnd = true
                listState.scrollToEnd()
            }
        }
    }
    LaunchedEffect(state.conversationId, listState, composerFocused, imeVisible) {
        if (composerFocused && imeVisible) {
            // Editing always reveals the latest content, including the third imported
            // wine. Pin the tail as a multiline draft reduces the list viewport further.
            pinnedToEnd = true
            listState.scrollToEnd()
        }
    }
    LaunchedEffect(listState) {
        listState.interactionSource.interactions.collect { if (it is DragInteraction.Start) pinnedToEnd = false }
    }
    LaunchedEffect(listState, pinnedToEnd) {
        if (pinnedToEnd) snapshotFlow { listState.canScrollForward }.collect { if (it) listState.scrollToEnd() }
    }
    LaunchedEffect(listState) {
        // The keyboard shrinks the viewport from the bottom; a reader at the end stays pinned to the latest item.
        var lastHeight = 0
        var lastAtEnd = true
        snapshotFlow { listState.layoutInfo.viewportSize.height to listState.canScrollForward }
            .collect { (height, canScrollForward) ->
                if (lastHeight > height && lastAtEnd) {
                    listState.scrollBy((lastHeight - height).toFloat())
                } else {
                    lastAtEnd = !canScrollForward
                }
                lastHeight = height
            }
    }
    LaunchedEffect(state.phase) {
        if (state.phase in FOLLOWED_PHASES) {
            pinnedToEnd = false
            followFrom = state.messages.size
            // These phases start from an explicit card/store action. Show its working
            // state immediately, including when the action came from old history.
            listState.scrollToItem(itemCount - 1)
        } else if (state.phase != AssistantPhase.IDLE && wasAtBottom) {
            listState.animateScrollToItem(itemCount - 1)
        }
    }
    LaunchedEffect(state.errorCode, locationUnavailable) {
        when {
            locationUnavailable -> listState.scrollToItem(0)
            state.errorCode != null && followFrom != null -> {
                followFrom = null
                listState.reveal(itemCount - 2)
            }
            state.errorCode != null && wasAtBottom -> listState.animateScrollToItem(itemCount - 1)
        }
    }
    LaunchedEffect(state.messages.size, latestUserMessageId) {
        val size = state.messages.size
        val previous = seenCount
        val grew = size > previous
        seenCount = size
        val follow = followFrom
        when {
            // An import from Compare starts at the top of its summary so every attached wine is read before sending.
            grew && comparisonContextIndex != null && !composerFocused -> {
                observedUserMessageId = latestUserMessageId
                followFrom = null
                pinnedToEnd = false
                listState.scrollToItem(leadingItems + comparisonContextIndex)
            }
            grew && size - previous > 1 && previous == 0 -> {
                observedUserMessageId = latestUserMessageId
                pinnedToEnd = true
                listState.scrollToEnd()
            }
            latestUserMessageId != null && latestUserMessageId != observedUserMessageId -> {
                pinnedToEnd = false
                observedUserMessageId = latestUserMessageId
                followFrom = latestUserIndex + 1
                listState.scrollToItem(leadingItems + latestUserIndex)
            }
            grew && follow != null -> {
                followFrom = null
                listState.reveal(leadingItems + follow.coerceAtMost(size - 1))
            }
            grew && wasAtBottom -> listState.animateScrollToItem(itemCount - 1)
        }
    }
    // The header owns the action; the timeline consumes a conversation-scoped event.
    // A conversation change cancels an old animation instead of scrolling the new list.
    LaunchedEffect(state.conversationId, listState, jumpRequestTicket) {
        if (jumpRequestTicket > 0) {
            listState.animateScrollToItem((listState.layoutInfo.totalItemsCount - 1).coerceAtLeast(0))
            pinnedToEnd = true
        }
    }
    Box(Modifier.fillMaxSize()) {
        LazyColumn(
            modifier = Modifier.fillMaxSize().dismissesKeyboard(),
            state = listState,
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            if (locationUnavailable) item(key = "location_unavailable") {
                Text(stringResource(R.string.assistant_location_unavailable), color = MaterialTheme.colorScheme.error)
            }
            if (state.messages.isEmpty()) item(key = "welcome") {
                AssistantWelcome(component, canAddPhotos, onAddPhotos)
            }
            items(state.messages, key = { it.id }) { message ->
                AssistantMessageCard(message, state, component, timeline, onOpenPhoto)
            }
            if (state.phase != AssistantPhase.IDLE) item(key = "progress") { AssistantProgress(state.phase) }
            state.errorCode?.let { error ->
                item(key = "error") { TimelineError(error, component) }
            }
            item(key = "end") { Spacer(Modifier.height(8.dp)) }
        }
    }
}

private fun AssistantMessage.isComparisonContext() =
    kind == AssistantMessageKind.WINE_RESULTS && comparisonContext

private suspend fun LazyListState.scrollToEnd() {
    scrollToItem((layoutInfo.totalItemsCount - 1).coerceAtLeast(0))
}

private suspend fun LazyListState.reveal(index: Int) {
    snapshotFlow { layoutInfo.totalItemsCount }.first { it > index }
    val item = layoutInfo.visibleItemsInfo.firstOrNull { it.index == index }
    val readableLimit = layoutInfo.viewportStartOffset +
        (layoutInfo.viewportEndOffset - layoutInfo.viewportStartOffset) * 2 / 3
    if (item == null || item.offset < layoutInfo.viewportStartOffset || item.offset > readableLimit) {
        animateScrollToItem(index)
    }
}

@Composable
private fun JumpToLatest(onClick: () -> Unit) {
    IconButton(onClick = onClick) {
        Icon(
            imageVector = AppIcons.ChevronDown,
            contentDescription = stringResource(R.string.assistant_v2_jump_latest),
        )
    }
}

@Composable
private fun TimelineError(error: AssistantUiError, component: AssistantComponent) {
    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer)) {
        Column(Modifier.fillMaxWidth().padding(16.dp)) {
            Text(stringResource(error.textRes()), color = MaterialTheme.colorScheme.onErrorContainer)
            if (error == AssistantUiError.RETAIL_ACCESS_REQUIRED) {
                val activity = LocalContext.current as? MainActivity
                TextButton(onClick = { activity?.openRetailStore() }) { Text(stringResource(R.string.assistant_open_store)) }
                TextButton(onClick = component::onRetryClicked) { Text(stringResource(R.string.assistant_retry_after_access)) }
            } else if (error != AssistantUiError.DINNER_SELECTION_STALE) {
                TextButton(onClick = component::onRetryClicked) {
                    Text(stringResource(R.string.assistant_retry))
                }
            }
        }
    }
}

@Composable
private fun AssistantHeaderTitle(storeName: String?, onStore: () -> Unit) {
    val storeLabel = stringResource(R.string.assistant_store_title)
    val modifier = if (storeName == null) Modifier else Modifier.clip(RoundedCornerShape(12.dp))
        .clickable(onClickLabel = storeLabel, role = Role.Button, onClick = onStore)
    Column(
        modifier.widthIn(max = 260.dp).heightIn(min = 48.dp).padding(horizontal = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(stringResource(R.string.assistant_title), style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
        storeName?.let {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                Icon(AppIcons.Store, contentDescription = null, modifier = Modifier.size(14.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(it, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f, fill = false))
                Icon(AppIcons.ChevronDown, contentDescription = null, modifier = Modifier.size(16.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

@Composable
private fun AssistantWelcome(component: AssistantComponent, canAddPhotos: Boolean, onAddPhotos: () -> Unit) {
    val dinnerPrompt = stringResource(R.string.assistant_v3_plan_dinner_prompt)
    Column(
        modifier = Modifier.fillMaxWidth().padding(top = 16.dp, bottom = 8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(stringResource(R.string.assistant_v3_welcome_title), style = MaterialTheme.typography.titleLarge)
        Text(stringResource(R.string.assistant_v3_welcome_body), style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
        Column(Modifier.padding(top = 8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            WelcomePrompt(AppIcons.Photos, R.string.assistant_v3_find_wine, canAddPhotos, onAddPhotos)
            WelcomePrompt(AppIcons.Dinner, R.string.assistant_v3_plan_dinner, true) {
                component.onDraftChanged(dinnerPrompt)
            }
        }
    }
}

@Composable
private fun WelcomePrompt(icon: androidx.compose.ui.graphics.vector.ImageVector, label: Int,
    enabled: Boolean, onClick: () -> Unit) {
    Surface(onClick = onClick, enabled = enabled, shape = RoundedCornerShape(24.dp),
        color = MaterialTheme.colorScheme.surface,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.7f))) {
        Row(Modifier.heightIn(min = 48.dp).padding(horizontal = 16.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(20.dp))
            Text(stringResource(label), style = MaterialTheme.typography.labelLarge)
        }
    }
}

@Composable
private fun AssistantProgress(phase: AssistantPhase) {
    val label = when (phase) {
        AssistantPhase.IDLE -> return
        AssistantPhase.RECOGNIZING -> R.string.assistant_recognizing
        AssistantPhase.THINKING -> R.string.assistant_thinking
        AssistantPhase.SEARCHING_STORE -> R.string.assistant_store_searching
        AssistantPhase.REPLACING_PRODUCT -> R.string.assistant_replacing
        AssistantPhase.SELECTING_DINNER -> R.string.assistant_selecting_dinner
    }
    Row(Modifier.fillMaxWidth().padding(vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        CircularProgressIndicator(modifier = Modifier.size(18.dp), strokeWidth = 2.dp,
            color = MaterialTheme.colorScheme.primary)
        Text(stringResource(label), style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun AssistantComposer(
    state: AssistantState,
    isPreparingPhotos: Boolean,
    onTextChanged: (String) -> Unit,
    onFocusChanged: (Boolean) -> Unit,
    onRemovePhoto: (String) -> Unit,
    onOpenPhoto: (List<AssistantPhoto>, Int) -> Unit,
    onAddPhotos: () -> Unit,
    onSend: () -> Unit,
    onDictate: () -> Unit,
) {
    Column(
        // MainContent already consumed the nav bar (or tab bar) height, so this adds only the keyboard's remainder.
        modifier = Modifier.fillMaxWidth().background(MaterialTheme.colorScheme.background)
            .imePadding().padding(horizontal = 12.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        if (isPreparingPhotos || state.pendingAttachments > 0) {
            Text(stringResource(R.string.assistant_preparing_photos),
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
            LinearProgressIndicator(Modifier.fillMaxWidth())
        }
        if (state.attachments.isNotEmpty()) AssistantAttachmentStrip(state.attachments, onRemovePhoto, onOpenPhoto)
        Surface(shape = RoundedCornerShape(28.dp), color = MaterialTheme.colorScheme.surface,
            border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.7f)),
            shadowElevation = 1.dp) {
            Row(Modifier.fillMaxWidth().padding(4.dp), verticalAlignment = Alignment.Bottom) {
                IconButton(onClick = onAddPhotos, enabled = !isPreparingPhotos && state.pendingAttachments == 0 &&
                    state.attachments.size < MAX_PENDING_PHOTOS) {
                    Icon(AppIcons.Add, contentDescription = stringResource(R.string.assistant_add_photos))
                }
                androidx.compose.foundation.text.BasicTextField(
                    value = state.draft, onValueChange = onTextChanged,
                    textStyle = MaterialTheme.typography.bodyLarge.copy(color = MaterialTheme.colorScheme.onSurface),
                    modifier = Modifier.weight(1f).padding(vertical = 14.dp, horizontal = 2.dp)
                        .onFocusChanged { onFocusChanged(it.isFocused) },
                    maxLines = 5,
                    cursorBrush = androidx.compose.ui.graphics.SolidColor(MaterialTheme.colorScheme.primary),
                    decorationBox = { field ->
                        Box {
                            if (state.draft.isEmpty()) Text(stringResource(R.string.assistant_input_hint),
                                style = MaterialTheme.typography.bodyLarge,
                                color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 1,
                                overflow = TextOverflow.Ellipsis)
                            field()
                        }
                    },
                )
                IconButton(onClick = onDictate) {
                    Icon(AppIcons.Mic, contentDescription = stringResource(R.string.assistant_voice_input),
                        modifier = Modifier.size(22.dp))
                }
                FilledIconButton(onClick = onSend, enabled = state.canSend && !isPreparingPhotos,
                    modifier = Modifier.size(48.dp)) {
                    Icon(AppIcons.Send, contentDescription = stringResource(R.string.assistant_send),
                        modifier = Modifier.size(20.dp))
                }
            }
        }
    }
}

@Composable
private fun AssistantDrawer(
    state: AssistantState,
    onNewConversation: () -> Unit,
    onConversation: (String) -> Unit,
    onSavedWine: (String?, String?, String) -> Unit,
    onStore: () -> Unit,
    onHistory: () -> Unit,
    onSettings: () -> Unit,
) {
    ModalDrawerSheet(
        modifier = Modifier.widthIn(max = 304.dp),
        drawerShape = RectangleShape,
    ) {
        Column(Modifier.fillMaxSize()) {
            Row(Modifier.fillMaxWidth().padding(start = 16.dp, end = 4.dp, top = 4.dp),
                verticalAlignment = Alignment.CenterVertically) {
                Text(stringResource(R.string.assistant_title), style = MaterialTheme.typography.titleMedium,
                    modifier = Modifier.weight(1f))
                IconButton(onClick = onNewConversation) {
                    Icon(AppIcons.NewChat, contentDescription = stringResource(R.string.assistant_new_chat))
                }
            }
            // Only conversation content scrolls. The three destinations below
            // remain fixed even when there are more conversations than fit here.
            LazyColumn(Modifier.weight(1f), contentPadding = PaddingValues(bottom = 4.dp)) {
                item(key = "conversations_heading") {
                    DrawerHeading(R.string.assistant_conversations)
                    if (state.conversations.isEmpty()) DrawerEmpty(R.string.assistant_no_conversations)
                }
                items(state.conversations, key = { "conversation_" + it.id }) { conversation ->
                    DrawerRow(
                        title = if (conversation.title.isBlank() || conversation.title == "Новый разговор")
                            stringResource(R.string.assistant_new_chat) else conversation.title,
                        selected = conversation.id == state.conversationId,
                        compact = true,
                        onClick = { onConversation(conversation.id) },
                    )
                }
                if (state.savedWines.isNotEmpty()) {
                    item(key = "saved_heading") {
                        HorizontalDivider(Modifier.padding(vertical = 8.dp))
                        DrawerHeading(R.string.assistant_saved_wines)
                    }
                    items(state.savedWines, key = { "wine_" + it.slug + it.photoId + it.instanceId }) { wine ->
                        DrawerRow(wine.title, wine.producer, singleLine = false, compact = true,
                            onClick = { onSavedWine(wine.photoId, wine.instanceId, wine.slug) })
                    }
                }
            }
            HorizontalDivider()
            Column(Modifier.padding(vertical = 4.dp)) {
                DrawerRow(state.selectedStore?.name ?: stringResource(R.string.assistant_v3_store_choose),
                    icon = AppIcons.Store, onClick = onStore)
                DrawerRow(stringResource(R.string.tab_history), icon = AppIcons.History, onClick = onHistory)
                DrawerRow(stringResource(R.string.tab_settings), icon = AppIcons.Settings, onClick = onSettings)
            }
        }
    }
}

@Composable
private fun DrawerHeading(label: Int) {
    Text(
        stringResource(label),
        style = MaterialTheme.typography.labelLarge,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp),
    )
}

@Composable
private fun DrawerEmpty(label: Int) {
    Text(
        stringResource(label),
        style = MaterialTheme.typography.bodySmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp),
    )
}

@Composable
private fun DrawerRow(
    title: String,
    subtitle: String? = null,
    icon: androidx.compose.ui.graphics.vector.ImageVector? = null,
    selected: Boolean = false,
    singleLine: Boolean = true,
    compact: Boolean = false,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp)
            .clip(RectangleShape)
            .background(if (selected) MaterialTheme.colorScheme.secondaryContainer else Color.Transparent)
            .clickable(onClick = onClick).heightIn(min = 48.dp)
            .padding(horizontal = 8.dp, vertical = if (compact) 4.dp else 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        icon?.let {
            Icon(it, contentDescription = null, modifier = Modifier.size(20.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        Column(Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.bodyMedium,
                fontWeight = if (selected) FontWeight.Medium else FontWeight.Normal,
                color = if (selected) MaterialTheme.colorScheme.onSecondaryContainer
                    else MaterialTheme.colorScheme.onSurface,
                maxLines = if (singleLine) 1 else 2, overflow = TextOverflow.Ellipsis)
            subtitle?.takeIf { it.isNotBlank() }?.let {
                Text(it, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
    }
}

/**
 * The keyboard leaves with a tap on the chat or a drag through it, as in Messages. Taps on the
 * buttons and cards inside the messages still reach them: they consume the touch first.
 */
@Composable
private fun Modifier.dismissesKeyboard(): Modifier {
    val focusManager = LocalFocusManager.current
    val connection = remember(focusManager) {
        object : NestedScrollConnection {
            override fun onPreScroll(available: Offset, source: NestedScrollSource): Offset {
                if (source == NestedScrollSource.UserInput && available.y != 0f) focusManager.clearFocus()
                return Offset.Zero
            }
        }
    }
    return nestedScroll(connection).pointerInput(focusManager) {
        detectTapGestures { focusManager.clearFocus() }
    }
}
