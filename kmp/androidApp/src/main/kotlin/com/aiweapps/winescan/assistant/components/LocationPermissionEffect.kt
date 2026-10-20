package com.aiweapps.winescan.assistant.components

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Geocoder
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.CancellationSignal
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.ContextCompat
import kotlin.coroutines.resume
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import kotlinx.coroutines.launch
import java.util.Locale

/** Device location is only requested after the user taps the location button. */
@Composable
fun LocationPermissionEffect(
    ticket: Int,
    onResolved: (Double, Double, String) -> Unit,
    onUnavailable: () -> Unit,
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var handledTicket by remember { mutableIntStateOf(ticket) }
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { grants ->
        val precise = grants[Manifest.permission.ACCESS_FINE_LOCATION] == true
        val approximate = grants[Manifest.permission.ACCESS_COARSE_LOCATION] == true
        if (precise || approximate) scope.launch {
            val location = getLocation(context, precise)
            if (location == null) onUnavailable()
            else onResolved(location.latitude, location.longitude, addressFor(context, location))
        } else onUnavailable()
    }
    LaunchedEffect(ticket) {
        if (ticket != handledTicket) {
            handledTicket = ticket
            // A new conversation/account resets the counter; reset is not a GPS request.
            if (ticket <= 0) return@LaunchedEffect
            val precise = ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED
            val approximate = ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED
            if (precise || approximate) {
                val location = getLocation(context, precise)
                if (location == null) onUnavailable()
                else onResolved(location.latitude, location.longitude, addressFor(context, location))
            } else launcher.launch(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION))
        }
    }
}

private suspend fun getLocation(context: Context, precise: Boolean): Location? {
    val manager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
    val provider = when {
        precise && manager.isProviderEnabled(LocationManager.GPS_PROVIDER) -> LocationManager.GPS_PROVIDER
        manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER) -> LocationManager.NETWORK_PROVIDER
        manager.isProviderEnabled(LocationManager.PASSIVE_PROVIDER) -> LocationManager.PASSIVE_PROVIDER
        else -> return null
    }
    return try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val fresh = withTimeoutOrNull(10_000L) { suspendCancellableCoroutine<Location?> { continuation ->
                val cancellation = CancellationSignal()
                manager.getCurrentLocation(provider, cancellation, context.mainExecutor) { location ->
                    if (continuation.isActive) continuation.resume(location)
                }
                continuation.invokeOnCancellation { cancellation.cancel() }
            } }
            fresh ?: manager.getLastKnownLocation(provider)
                ?.takeIf { System.currentTimeMillis() - it.time < MAX_CACHED_LOCATION_AGE_MS }
        } else {
            manager.getLastKnownLocation(provider)
                ?.takeIf { System.currentTimeMillis() - it.time < MAX_CACHED_LOCATION_AGE_MS }
        }
    } catch (_: SecurityException) {
        null
    } catch (_: IllegalArgumentException) {
        null
    }
}

private suspend fun addressFor(context: Context, location: Location): String = withContext(Dispatchers.IO) {
    @Suppress("DEPRECATION")
    val result = try { Geocoder(context, Locale.getDefault()).getFromLocation(location.latitude, location.longitude, 1) }
    catch (_: Exception) { null }
    result?.firstOrNull()?.let { address ->
        listOfNotNull(address.locality, address.thoroughfare, address.subThoroughfare)
            .filter { it.isNotBlank() }.joinToString(", ")
    }?.takeIf { it.isNotBlank() }
        ?: String.format(Locale.getDefault(), "%.4f, %.4f", location.latitude, location.longitude)
}

private const val MAX_CACHED_LOCATION_AGE_MS = 10 * 60 * 1000L
