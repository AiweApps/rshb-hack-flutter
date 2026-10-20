package com.aiweapps.winescan.domain.scan.model

import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonTransformingSerializer

/** The catalogue uses dishes:null for unknown metadata; other malformed values remain errors. */
internal object WineDishListSerializer : JsonTransformingSerializer<List<WineDish>>(
    ListSerializer(WineDish.serializer()),
) {
    override fun transformDeserialize(element: JsonElement): JsonElement =
        if (element == JsonNull) JsonArray(emptyList()) else element
}
