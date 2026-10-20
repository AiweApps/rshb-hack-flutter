package com.aiweapps.winescan.assistant.components

import com.aiweapps.winescan.domain.assistant.model.AssistantMessage
import com.aiweapps.winescan.domain.assistant.model.AssistantMessageKind
import com.aiweapps.winescan.domain.assistant.model.AssistantPhoto
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.Locale

enum class MessageVersion { SINGLE, CURRENT, PREVIOUS }

/** Presentation facts derived from message order; history itself is never rewritten. */
class AssistantTimelineIndex(messages: List<AssistantMessage>) {

    val knownLinks: Set<String> = messages.flatMap { message ->
        message.products.mapNotNull { it.url } + message.wines.mapNotNull { it.pageUrl } +
            message.dinners.flatMap { dinner -> dinner.products.mapNotNull { it.url } }
    }.map(::linkKey).toSet()

    private val versions: Map<String, MessageVersion> = versionsOf(messages)

    private val albums: Map<String, List<AssistantPhoto>> = buildMap {
        messages.forEach { message -> message.photos.forEach { put(it.id, message.photos) } }
    }

    fun version(messageId: String): MessageVersion = versions[messageId] ?: MessageVersion.SINGLE

    fun albumFor(photoId: String?): List<AssistantPhoto>? = photoId?.let(albums::get)

    private fun versionsOf(messages: List<AssistantMessage>): Map<String, MessageVersion> {
        val result = mutableMapOf<String, MessageVersion>()
        val baskets = messages.filter { it.isBasket() }
        baskets.forEachIndexed { index, message ->
            result[message.id] = when {
                index < baskets.lastIndex -> MessageVersion.PREVIOUS
                baskets.size > 1 -> MessageVersion.CURRENT
                else -> MessageVersion.SINGLE
            }
        }
        val searches = messages.filter {
            it.kind == AssistantMessageKind.PRODUCTS && !it.isBasket() && !it.isReplacementCandidates()
        }
        searches.dropLast(1).forEach { result[it.id] = MessageVersion.PREVIOUS }
        messages.forEachIndexed { index, message ->
            val later = messages.subList(index + 1, messages.size)
            val superseded = when {
                message.kind == AssistantMessageKind.ERROR -> later.any {
                    it.kind == AssistantMessageKind.USER_TEXT || it.kind == AssistantMessageKind.USER_PHOTOS
                }
                message.isReplacementCandidates() -> later.any { it.isBasket() || it.isReplacementCandidates() }
                message.kind == AssistantMessageKind.DINNER_OPTIONS ->
                    later.any { it.kind == AssistantMessageKind.DINNER_OPTIONS }
                message.isStoreStep() -> later.any { it.isStoreStep() }
                else -> false
            }
            if (superseded) result[message.id] = MessageVersion.PREVIOUS
        }
        return result
    }

    private fun AssistantMessage.isBasket() = kind == AssistantMessageKind.PRODUCTS &&
        sourceMessageId != null && replacementForProductId == null

    private fun AssistantMessage.isReplacementCandidates() = kind == AssistantMessageKind.PRODUCTS &&
        replacementForProductId != null

    private fun AssistantMessage.isStoreStep() = kind == AssistantMessageKind.LOCATION_REQUEST ||
        kind == AssistantMessageKind.STORE_CANDIDATES || kind == AssistantMessageKind.STORE_SELECTED
}

private val markdownLink = Regex("""\[([^\]]+)]\((https?://[^)\s]+)\)""")
private val bareUrl = Regex("""https?://[^\s)\]>»"]+""")
private val emptyBrackets = Regex("""\(\s*\)|\[\s*]""")
private val spaceBeforePunctuation = Regex("""[ \t]+([,.;:])""")
private val danglingDash = Regex("""[ \t]*[—–-][ \t]*$""", RegexOption.MULTILINE)
private val repeatedSpaces = Regex("""[ \t]{2,}""")
private val trailingSpaces = Regex("""[ \t]+\n""")
private val extraBlankLines = Regex("""\n{3,}""")
private val technicalStoreId = Regex(
    """[\[(](?:магазин|store(?:\s+id)?|store_id|sap)\s*[:=#№]?\s*\d+[\])]""",
    RegexOption.IGNORE_CASE,
)
private val isoTimestamp = Regex("""\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})""")
private val russianUtcTimestamp = Regex("""\d{2}\.\d{2}\.\d{4}\s+в\s+\d{2}:\d{2}\s+UTC\b""")

/** Hides only links that a card in this conversation already offers; the full text stays available. */
fun compactAssistantText(text: String, knownLinks: Set<String>): String {
    val withoutIds = russianUtcTimestamp.replace(technicalStoreId.replace(text, "")) { match ->
        runCatching {
            val instant = LocalDateTime.parse(match.value,
                DateTimeFormatter.ofPattern("dd.MM.yyyy 'в' HH:mm 'UTC'", Locale.ROOT))
                .toInstant(ZoneOffset.UTC)
            localTimeLabel(instant)
        }.getOrDefault(match.value)
    }
    val compactBase = isoTimestamp.replace(withoutIds) { match ->
        runCatching {
            localTimeLabel(Instant.parse(match.value))
        }.getOrDefault(match.value)
    }.replace(repeatedSpaces, " ").replace(spaceBeforePunctuation, "$1").trim()
    if (knownLinks.isEmpty() || !compactBase.contains("http")) return compactBase
    val unlinked = markdownLink.replace(compactBase) { match ->
        if (linkKey(match.groupValues[2]) in knownLinks) match.groupValues[1] else match.value
    }
    val withoutUrls = bareUrl.replace(unlinked) { match ->
        val core = match.value.trimEnd('.', ',', ';', ':', '!', '?')
        if (linkKey(core) in knownLinks) match.value.substring(core.length) else match.value
    }
    if (withoutUrls == text) return text
    return withoutUrls.replace(emptyBrackets, "")
        .replace(spaceBeforePunctuation, "$1")
        .replace(danglingDash, "")
        .replace(repeatedSpaces, " ")
        .replace(trailingSpaces, "\n")
        .replace(extraBlankLines, "\n\n")
        .trim()
}

private fun linkKey(url: String): String = url.substringBefore('#').substringBefore('?')
    .removePrefix("https://").removePrefix("http://").removePrefix("www.").trimEnd('/').lowercase()

private fun localTimeLabel(instant: Instant): String = DateTimeFormatter.ofLocalizedDateTime(FormatStyle.SHORT)
    .withLocale(Locale.getDefault()).withZone(ZoneId.systemDefault()).format(instant)
