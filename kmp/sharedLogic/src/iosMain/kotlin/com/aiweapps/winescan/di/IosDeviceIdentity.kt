package com.aiweapps.winescan.di

import com.aiweapps.winescan.domain.assistant.repository.AssistantAccountRepository
import kotlinx.coroutines.CancellationException
import org.koin.mp.KoinPlatform

/** Native transport gets the same installation and account as chat. Never persisted or logged. */
data class IosDeviceIdentity(val subject: String, val token: String, val deviceId: String)

@Throws(CancellationException::class)
suspend fun currentIosDeviceIdentity(): IosDeviceIdentity? {
    val accounts = KoinPlatform.getKoin().get<AssistantAccountRepository>()
    return try {
        accounts.initialize()
        val account = accounts.account.value?.takeUnless { it.expired } ?: return null
        val credentials = accounts.credentials()
        if (accounts.account.value != account) null
        else IosDeviceIdentity(account.subject, credentials.token, credentials.deviceId)
    } catch (cancelled: CancellationException) {
        throw cancelled
    } catch (_: Exception) {
        null
    }
}

@Throws(CancellationException::class)
suspend fun expireIosDeviceIdentity(subject: String, token: String) {
    val accounts = KoinPlatform.getKoin().get<AssistantAccountRepository>()
    accounts.expireIfCurrent(subject, token)
}
