package com.aiweapps.winescan.data.assistant.remote

internal object AssistantRoutes {
    const val ME = "v1/me"
    const val STORE_SEARCH = "v1/stores/search"
    const val STORE_NEARBY = "v1/stores/nearby"
    const val GUEST_TOKEN = "auth/guest/token"
    const val REGISTER = "auth/register"
    const val LOGIN = "auth/token"
    const val LOGOUT = "auth/logout"
    fun confirmStore(id: String) = "${session(id)}/store"
    const val SESSIONS = "v1/sessions"
    fun session(id: String) = "$SESSIONS/$id"
    fun messages(id: String) = "${session(id)}/messages"
    fun selectDinner(id: String, sourceMessageId: String) =
        "${session(id)}/dinners/$sourceMessageId/select"
    fun replacementCandidates(id: String, sourceMessageId: String) =
        "${session(id)}/shopping/$sourceMessageId/candidates"
    fun replace(id: String, sourceMessageId: String) =
        "${session(id)}/shopping/$sourceMessageId/replace"
}
