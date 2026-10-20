package com.aiweapps.core.storage

import android.content.Context
import android.content.SharedPreferences
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.core.content.edit
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.IOException
import java.security.GeneralSecurityException
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

actual class SecureStorageProvider(private val context: Context) {

    actual fun create(name: String): SecureStorage =
        KeystoreSecureStorage(
            preferences = context.getSharedPreferences(name, Context.MODE_PRIVATE),
            keyAlias = KEY_ALIAS_PREFIX + name,
        )

    private companion object {
        const val KEY_ALIAS_PREFIX = "com.aiweapps.core.storage."
    }
}

/**
 * Stores values encrypted with an AES/GCM key that never leaves the Android Keystore.
 * Only the ciphertext (prefixed with the GCM IV) is kept in [SharedPreferences].
 */
private class KeystoreSecureStorage(
    private val preferences: SharedPreferences,
    private val keyAlias: String,
) : SecureStorage {

    @Volatile
    private var cachedKey: SecretKey? = null

    override suspend fun getString(key: String): String? = withContext(Dispatchers.IO) {
        val stored = preferences.getString(key, null) ?: return@withContext null
        try {
            val blob = Base64.decode(stored, Base64.NO_WRAP)
            if (blob.size <= IV_SIZE_BYTES) {
                dropEntry(key)
                return@withContext null
            }
            val iv = blob.copyOfRange(0, IV_SIZE_BYTES)
            val cipherText = blob.copyOfRange(IV_SIZE_BYTES, blob.size)
            val cipher = Cipher.getInstance(TRANSFORMATION).apply {
                init(Cipher.DECRYPT_MODE, secretKey(), GCMParameterSpec(TAG_LENGTH_BITS, iv))
            }
            cipher.doFinal(cipherText).decodeToString()
        } catch (_: GeneralSecurityException) {
            // The key may have been invalidated (e.g. the user changed the screen lock) or the
            // blob tampered with. The value is unrecoverable, so drop it instead of crashing.
            cachedKey = null
            dropEntry(key)
            null
        } catch (_: IOException) {
            // KeyStore.load() reports a corrupted or unreadable keystore as an IOException,
            // which is not a GeneralSecurityException. Same unrecoverable situation.
            cachedKey = null
            dropEntry(key)
            null
        } catch (_: IllegalArgumentException) {
            // Corrupted Base64 payload.
            dropEntry(key)
            null
        }
    }

    override suspend fun putString(key: String, value: String) = withContext(Dispatchers.IO) {
        try {
            val cipher = Cipher.getInstance(TRANSFORMATION).apply {
                init(Cipher.ENCRYPT_MODE, secretKey())
            }
            // GCM generates the IV itself, so it has to be persisted next to the ciphertext.
            val blob = cipher.iv + cipher.doFinal(value.encodeToByteArray())
            preferences.edit { putString(key, Base64.encodeToString(blob, Base64.NO_WRAP)) }
        } catch (_: GeneralSecurityException) {
            // Deliberate trade-off, mirroring getString: writing goes through the same
            // Keystore that can refuse to hand out the key, and SecureStorage has no error
            // channel to report it through. Letting the exception escape would crash the app
            // from whatever coroutine triggered the write (a login, for instance), while
            // degrading quietly only costs the user the persisted session — they sign in
            // again. The key cache and the stale entry are dropped so the next attempt
            // starts from a clean slate instead of reusing a key that no longer works.
            cachedKey = null
            dropEntry(key)
        } catch (_: IOException) {
            // KeyStore.load() signals a corrupted or unreadable keystore with an IOException,
            // which is not a GeneralSecurityException — the reason this used to crash.
            cachedKey = null
            dropEntry(key)
        }
    }

    override suspend fun remove(key: String) = withContext(Dispatchers.IO) {
        dropEntry(key)
    }

    override suspend fun clear() = withContext(Dispatchers.IO) {
        preferences.edit { clear() }
    }

    private fun dropEntry(key: String) {
        preferences.edit { remove(key) }
    }

    private fun secretKey(): SecretKey {
        cachedKey?.let { return it }
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        val existing = (keyStore.getEntry(keyAlias, null) as? KeyStore.SecretKeyEntry)?.secretKey
        val key = existing ?: generateKey()
        cachedKey = key
        return key
    }

    private fun generateKey(): SecretKey {
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)
        generator.init(
            KeyGenParameterSpec.Builder(
                keyAlias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(KEY_SIZE_BITS)
                .build()
        )
        return generator.generateKey()
    }

    private companion object {
        const val ANDROID_KEYSTORE = "AndroidKeyStore"
        const val TRANSFORMATION = "AES/GCM/NoPadding"
        const val KEY_SIZE_BITS = 256
        const val TAG_LENGTH_BITS = 128
        const val IV_SIZE_BYTES = 12
    }
}
