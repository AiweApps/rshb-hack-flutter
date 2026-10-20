package com.aiweapps.core.components.base

import com.arkivanov.decompose.ComponentContext
import com.arkivanov.decompose.value.MutableValue
import com.arkivanov.decompose.value.Value
import kotlinx.coroutines.Dispatchers
import kotlin.coroutines.CoroutineContext
import com.aiweapps.core.components.model.BaseScreenState
import kotlinx.atomicfu.locks.SynchronizedObject
import kotlinx.atomicfu.locks.synchronized
import kotlinx.serialization.KSerializer

/**
 * Holds the screen state and, optionally, restores it after process death.
 *
 * Pass [stateSerializer] to opt in to restoration: the state is then written through the
 * component's `stateKeeper` when the system asks to save, and read back the next time the
 * component is created. Opting in makes two demands on the state class:
 *
 * - it is `@Serializable`;
 * - anything that only makes sense inside the current process — in-flight flags, mapped UI
 *   projections — is `@Transient` and recomputed after restore.
 *
 * Leaving [stateSerializer] as `null` keeps the old behaviour: the state lives and dies
 * with the process. That is the right choice for a screen that reloads from scratch anyway.
 */
abstract class BaseStatefulComponent<S : BaseScreenState>(
    componentContext: ComponentContext,
    initialState: S,
    stateSerializer: KSerializer<S>? = null,
    mainContext: CoroutineContext = Dispatchers.Main.immediate
) : BaseComponent(componentContext, mainContext) {

    private val lock = SynchronizedObject()

    private val _state = MutableValue(
        stateSerializer?.let { stateKeeper.consume(key = STATE_KEY, strategy = it) } ?: initialState
    )
    open val state: Value<S> = _state

    protected val currentState: S get() = _state.value

    /**
     * True when this instance started from a state that was saved before the process died,
     * rather than from [initialState]. A component uses it to decide whether it still needs
     * to load anything.
     */
    protected val isRestored: Boolean =
        stateSerializer != null && _state.value !== initialState

    init {
        if (stateSerializer != null) {
            stateKeeper.register(key = STATE_KEY, strategy = stateSerializer) { _state.value }
        }
    }

    protected fun updateState(block: S.() -> S) {
        synchronized(lock) {
            _state.value = block(_state.value)
        }
    }

    protected fun updateState(newState: S) {
        synchronized(lock) {
            _state.value = newState
        }
    }

    private companion object {
        /**
         * Every component owns its own `StateKeeper`, so a single constant cannot collide
         * with another component's entry.
         */
        const val STATE_KEY = "component_state"
    }
}
