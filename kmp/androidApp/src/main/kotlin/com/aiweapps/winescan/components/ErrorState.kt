package com.aiweapps.winescan.components

import com.aiweapps.winescan.components.AppIcons

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.aiweapps.core.error.AppError
import com.aiweapps.winescan.error.asText
import winescan.sharedui.generated.resources.Res
import winescan.sharedui.generated.resources.action_retry
import org.jetbrains.compose.resources.stringResource

/**
 * Full-screen error state shared by every screen that renders [AppError]. Keeps the
 * message, spacing, and retry affordance consistent instead of copy-pasting the same
 * `Box` + `Text` per screen.
 *
 * @param onRetry invoked when the user taps the retry button. When null, no retry action
 * is available (e.g. auth, where the retry is the login button itself) and the button is
 * not rendered.
 */
@Composable
fun ErrorState(
    error: AppError,
    modifier: Modifier = Modifier,
    onRetry: (() -> Unit)? = null,
) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Icon(
                imageVector = AppIcons.Error,
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = MaterialTheme.colorScheme.error,
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = error.asText(),
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.error,
                textAlign = TextAlign.Center,
            )

            if (onRetry != null) {
                Spacer(modifier = Modifier.height(24.dp))

                Button(onClick = onRetry) {
                    Text(text = stringResource(Res.string.action_retry))
                }
            }
        }
    }
}
