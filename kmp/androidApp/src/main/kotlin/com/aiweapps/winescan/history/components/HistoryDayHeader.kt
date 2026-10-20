package com.aiweapps.winescan.history.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import kotlinx.datetime.LocalDate as KotlinLocalDate

/** «Today», «Yesterday» or the date in the current language, over the scans of that day. */
@Composable
fun HistoryDayHeader(day: KotlinLocalDate) {
    val locale = LocalConfiguration.current.locales[0]
    val date = remember(day) { LocalDate.parse(day.toString()) }
    val today = remember { LocalDate.now() }
    val title = when (date) {
        today -> stringResource(R.string.history_today)
        today.minusDays(1) -> stringResource(R.string.history_yesterday)
        else -> remember(date, locale) {
            DateTimeFormatter.ofLocalizedDate(FormatStyle.LONG).withLocale(locale).format(date)
        }
    }
    Text(
        text = title,
        style = MaterialTheme.typography.titleSmall,
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.background)
            .padding(start = 16.dp, end = 16.dp, top = 16.dp, bottom = 4.dp),
    )
}
