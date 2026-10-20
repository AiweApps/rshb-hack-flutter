package com.aiweapps.winescan.domain.gastronomy.model

import com.aiweapps.winescan.config.GastronomyConfig
import kotlinx.serialization.Serializable

/** A dish category of the catalogue, with its name in every language the backend has. */
@Serializable
data class Dish(
    val id: String,
    /** ISO 639-1 code to label. */
    val labels: Map<String, String>,
) {
    /** The label in [language], else in the default language, else any; the id as the last resort. */
    fun labelIn(language: String): String =
        labels[language] ?: labels[GastronomyConfig.DEFAULT_LANGUAGE] ?: labels.values.firstOrNull() ?: id
}

/** A dish ready to show: its id for callbacks and its label in the current language. */
data class DishLabel(val id: String, val label: String)

/** The dish dictionary with lookups by id, in the backend's order. */
data class DishDictionary(val dishes: List<Dish>) {

    private val byId: Map<String, Dish> = dishes.associateBy { it.id }

    val isEmpty: Boolean get() = dishes.isEmpty()

    operator fun get(id: String): Dish? = byId[id]

    /** `null` stays «no data», empty stays «lists none»; unknown ids are dropped, and a list of
     * unknown ids only becomes «no data» — the app cannot name what it would show. */
    fun labels(ids: List<String>?, language: String): List<DishLabel>? {
        if (ids == null) return null
        if (ids.isEmpty()) return emptyList()
        val wanted = ids.toSet()
        return dishes.filter { it.id in wanted }
            .map { DishLabel(id = it.id, label = it.labelIn(language)) }
            .takeIf { it.isNotEmpty() }
    }

    /** The dishes [ids] refer to, for a snapshot that must render without the dictionary. */
    fun subset(ids: Collection<String>): List<Dish> = dishes.filter { it.id in ids }

    companion object {
        val EMPTY = DishDictionary(emptyList())
    }
}
