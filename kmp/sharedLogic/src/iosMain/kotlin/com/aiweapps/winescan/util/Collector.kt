package com.aiweapps.winescan.util

import com.arkivanov.decompose.Cancellation
import com.arkivanov.decompose.value.Value

class Collector<T : Any>(
    private val value: Value<T>,
    private val block: (T) -> Unit
) {
    private var cancellation: Cancellation? = null

    val current: T get() = value.value

    fun start() {
        cancellation = value.subscribe(block)
    }

    fun stop() {
        cancellation?.cancel()
        cancellation = null
    }
}
