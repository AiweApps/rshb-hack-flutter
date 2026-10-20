package com.aiweapps.winescan.testutil

import com.arkivanov.decompose.DefaultComponentContext
import com.arkivanov.essenty.lifecycle.LifecycleRegistry
import com.arkivanov.essenty.lifecycle.destroy
import com.arkivanov.essenty.lifecycle.resume
import com.arkivanov.essenty.statekeeper.SerializableContainer
import com.arkivanov.essenty.statekeeper.StateKeeperDispatcher

/**
 * A component context a test can drive by hand: it starts the lifecycle, and it can save
 * and re-inject state the way the platform does when the process is killed and restored.
 *
 * Pass [savedState] from a previous context's [saveState] to reproduce process death —
 * that is the only way to prove restoration actually works, rather than assuming it does
 * because the code compiles.
 */
class TestComponentContext(savedState: SerializableContainer? = null) {

    private val lifecycle = LifecycleRegistry()
    private val stateKeeper = StateKeeperDispatcher(savedState)

    val componentContext: DefaultComponentContext =
        DefaultComponentContext(lifecycle = lifecycle, stateKeeper = stateKeeper)

    init {
        // Components start their work from a resumed lifecycle; a created-but-not-resumed
        // one would leave their coroutine scope inactive and every assertion vacuous.
        lifecycle.resume()
    }

    /** What the platform would hand back to the next process. */
    fun saveState(): SerializableContainer = stateKeeper.save()

    fun destroy() {
        lifecycle.destroy()
    }
}
