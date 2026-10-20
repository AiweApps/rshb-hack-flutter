package com.aiweapps.core.components.model

import com.aiweapps.core.error.AppError
import kotlinx.serialization.Serializable

@Serializable
sealed class ScreenState {
    @Serializable
    data object Loading : ScreenState()

    @Serializable
    data object Content : ScreenState()

    @Serializable
    data class Error(val error: AppError) : ScreenState()
}
