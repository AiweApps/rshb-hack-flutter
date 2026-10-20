package com.aiweapps.core.components.base

import com.arkivanov.decompose.ComponentContext
import com.arkivanov.essenty.lifecycle.coroutines.coroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlin.coroutines.CoroutineContext

abstract class BaseComponent(
    componentContext: ComponentContext,
    mainContext: CoroutineContext = Dispatchers.Main.immediate
) : ComponentContext by componentContext {

    protected val scope = coroutineScope(mainContext + SupervisorJob())
}
