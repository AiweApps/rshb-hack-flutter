package com.aiweapps.winescan.domain.scan.model

import com.aiweapps.winescan.config.LinkConstants
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * One catalogue card as the recognition API returns it (`Catalog.card()`).
 *
 * Keeps the wire names on purpose: the history stores the answer as the API sent it and
 * «Share JSON» exports it unchanged, so the domain model and the transport format are the
 * same object here. [title] is always present (the slug when the name is unknown);
 * everything else may be missing from the catalogue row.
 */
@Serializable
data class WineCard(
    val slug: String,
    val title: String,
    @SerialName("in_catalog") val inCatalog: Boolean = true,
    val name: String? = null,
    val producer: String? = null,
    val category: String? = null,
    val region: String? = null,
    val grapes: String? = null,
    @SerialName("page_url") val pageUrl: String? = null,
    @SerialName("page_source") val pageSource: String? = null,
    @SerialName("page_in_site_snapshot") val pageInSiteSnapshot: Boolean? = null,
    /** Relative path of the reference thumbnail (`/api/reference/<slug>.jpg`). */
    val reference: String? = null,
    /**
     * Source catalogue facts, never sent by the recognition API: the comparison and the
     * assistant fill them through `WineCatalogRepository.enrich`, and stored answers and
     * «Share JSON» keep the card as the API sent it. Colour, sugar, temperature and
     * pairings shown as facts come from `GastronomyRepository`, which reads the same catalogue.
     */
    val description: String? = null,
    @Serializable(with = WineDishListSerializer::class)
    val dishes: List<WineDish> = emptyList(),
    val color: String? = null,
    val sugar: String? = null,
    @SerialName("food_pairings") val foodPairings: List<String>? = null,
    @SerialName("serving_temperature") val servingTemperature: String? = null,
    /** Alcohol percentage exactly as the source catalogue publishes it. */
    val alcohol: Double? = null,
) {
    /** Catalogue product name, or the recognition title without its exact producer suffix. */
    val presentationTitle: String get() = catalogPresentationTitle(name, title, producer)

    /** Invalid catalogue percentages stay unknown, with one rule for detail and comparison. */
    val validAlcohol: Double? get() = alcohol?.takeIf { it.isFinite() && it in 0.0..MAX_ALCOHOL }

    /** Pairings as the catalogue lists them, blanks dropped; `null` when the card has none. */
    val pairings: List<String>?
        get() = foodPairings?.map { it.trim() }?.filter { it.isNotEmpty() }?.takeIf { it.isNotEmpty() }

    /** Only catalogue pages are offered as a link, the same rule as the web UI. */
    val catalogueUrl: String?
        get() = pageUrl?.takeIf { it.startsWith(LinkConstants.VINO_SVOE_WINES_PREFIX) }

    /** "category · region · grapes", skipping what is missing. */
    val metaLine: String
        get() = listOfNotNull(category, region, grapes).filter { it.isNotEmpty() }.joinToString(" · ")
}

private const val MAX_ALCOHOL = 100.0

/** An illustrated food category from the source catalogue, without generated pictures. */
@Serializable
data class WineDish(val name: String, @SerialName("image_url") val imageUrl: String? = null)

/** One presentation rule for recognition, history and catalogue product titles. */
internal fun catalogPresentationTitle(name: String?, title: String, producer: String?): String {
    val value = name?.trim()?.takeIf { it.isNotEmpty() } ?: title.trim()
    val suffix = producer?.trim()?.takeIf { it.isNotEmpty() } ?: return value
    if (!value.endsWith(suffix, ignoreCase = true)) return value
    val boundary = value.getOrNull(value.length - suffix.length - 1)
    if (boundary != null && !boundary.isWhitespace() && boundary !in "·—–,-:()") return value
    return value.dropLast(suffix.length).trimEnd(' ', '·', '—', '–', ',', '-', ':', '(')
        .takeIf { it.isNotEmpty() } ?: value
}
