package com.aiweapps.winescan.platform

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import org.koin.mp.KoinPlatform

/** The one place UI takes a platform helper from Koin: preparing a photo is not UI logic. */
@Composable
internal fun rememberPhotoPreparer(): PhotoPreparer = remember { KoinPlatform.getKoin().get<PhotoPreparer>() }
