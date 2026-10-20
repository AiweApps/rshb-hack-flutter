package com.aiweapps.winescan.onboarding.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.AppIcons

/** Product explanations, not recognition results: examples contain no wine identities or prices. */
@Composable
fun OnboardingPage(pageIndex: Int) {
    val title = when (pageIndex) {
        0 -> R.string.onboarding_story_scan_title
        1 -> R.string.onboarding_story_compare_title
        else -> R.string.onboarding_story_dinner_title
    }
    val body = when (pageIndex) {
        0 -> R.string.onboarding_story_scan_body
        1 -> R.string.onboarding_story_compare_body
        else -> R.string.onboarding_story_dinner_body
    }
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.TopCenter) {
        Column(Modifier.widthIn(max = 560.dp).fillMaxSize().verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp, vertical = 16.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
            when (pageIndex) {
                0 -> Image(painterResource(R.drawable.onboarding_evening), contentDescription = null,
                    contentScale = ContentScale.Fit,
                    modifier = Modifier.widthIn(max = 280.dp).fillMaxWidth().aspectRatio(4f / 5f).align(Alignment.CenterHorizontally).clip(RoundedCornerShape(24.dp)))
                1 -> CompareIllustration()
                else -> DinnerIllustration()
            }
            Text(stringResource(title), style = MaterialTheme.typography.headlineMedium)
            Text(stringResource(body), style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun CompareIllustration() {
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        ExampleLabel()
        Surface(shape = RoundedCornerShape(16.dp), color = MaterialTheme.colorScheme.surface,
            border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant)) {
            Column(Modifier.fillMaxWidth().padding(20.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(20.dp)) {
                    IllustrationWine(R.string.onboarding_wine_first, Modifier.weight(1f))
                    IllustrationWine(R.string.onboarding_wine_second, Modifier.weight(1f))
                }
                HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
                Text(stringResource(R.string.onboarding_compare_fields), style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

@Composable
private fun IllustrationWine(title: Int, modifier: Modifier) {
    Column(modifier, horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Icon(AppIcons.Wine, contentDescription = null, modifier = Modifier.size(72.dp),
            tint = MaterialTheme.colorScheme.primary)
        Text(stringResource(title), style = MaterialTheme.typography.titleSmall)
    }
}

@Composable
private fun DinnerIllustration() {
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        ExampleLabel()
        Surface(modifier = Modifier.align(Alignment.End).widthIn(max = 280.dp),
            shape = RoundedCornerShape(16.dp), color = MaterialTheme.colorScheme.surfaceContainerLow) {
            Text(stringResource(R.string.onboarding_dinner_message), style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.padding(16.dp))
        }
        Surface(shape = RoundedCornerShape(16.dp), color = MaterialTheme.colorScheme.surface,
            border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant)) {
            Row(Modifier.fillMaxWidth().padding(20.dp), horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically) {
                Icon(AppIcons.Dinner, contentDescription = null, modifier = Modifier.size(32.dp),
                    tint = MaterialTheme.colorScheme.primary)
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(stringResource(R.string.onboarding_dinner_options), style = MaterialTheme.typography.titleSmall)
                    Text(stringResource(R.string.onboarding_dinner_store), style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
}

@Composable
private fun ExampleLabel() {
    Text(stringResource(R.string.onboarding_example), style = MaterialTheme.typography.labelMedium,
        color = MaterialTheme.colorScheme.onSurfaceVariant)
}
