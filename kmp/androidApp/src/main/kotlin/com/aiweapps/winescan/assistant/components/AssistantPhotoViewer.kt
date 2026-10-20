package com.aiweapps.winescan.assistant.components

import com.aiweapps.winescan.components.AppIcons

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import coil3.compose.AsyncImage
import com.aiweapps.winescan.R
import com.aiweapps.winescan.domain.assistant.model.AssistantPhoto
import com.aiweapps.winescan.scan.result.components.rememberZoomState
import com.aiweapps.winescan.scan.result.components.zoomGestures
import com.aiweapps.winescan.scan.result.components.zoomLayer
import java.io.File

@Composable
fun AssistantPhotoViewer(photos: List<AssistantPhoto>, initialIndex: Int, onDismiss: () -> Unit) {
    if (photos.isEmpty()) return
    val pager = rememberPagerState(initialPage = initialIndex.coerceIn(0, photos.lastIndex)) { photos.size }
    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Box(Modifier.fillMaxSize().background(Color.Black), contentAlignment = Alignment.Center) {
            HorizontalPager(state = pager, modifier = Modifier.fillMaxSize()) { page ->
                val zoom = rememberZoomState()
                Box(Modifier.fillMaxSize().clipToBounds().zoomGestures(zoom)) {
                    AsyncImage(
                        model = File(photos[page].path),
                        contentDescription = photos[page].name,
                        modifier = Modifier.fillMaxSize().zoomLayer(zoom),
                        contentScale = ContentScale.Fit,
                    )
                    TextButton(onClick = {
                        if (zoom.scale >= 4f) zoom.reset() else zoom.transform(2f, Offset.Zero)
                    }, modifier = Modifier.align(Alignment.TopStart).padding(12.dp)) {
                        Text("${zoom.scale.toInt()}×", color = Color.White)
                    }
                }
            }
            IconButton(onClick = onDismiss, modifier = Modifier.align(Alignment.TopEnd).padding(12.dp)) {
                Icon(AppIcons.Close, contentDescription = stringResource(R.string.assistant_close_photo),
                    tint = Color.White)
            }
            if (photos.size > 1) {
                Text(stringResource(R.string.assistant_photo_position, pager.currentPage + 1, photos.size),
                    modifier = Modifier.align(Alignment.BottomCenter).padding(18.dp), color = Color.White)
            }
        }
    }
}
