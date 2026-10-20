package com.aiweapps.core.storage

import kotlinx.cinterop.BetaInteropApi
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.alloc
import kotlinx.cinterop.convert
import kotlinx.cinterop.addressOf
import kotlinx.cinterop.memScoped
import kotlinx.cinterop.ptr
import kotlinx.cinterop.usePinned
import kotlinx.cinterop.value
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.withContext
import platform.CoreFoundation.CFDictionaryCreateMutable
import platform.CoreFoundation.CFDictionarySetValue
import platform.CoreFoundation.CFMutableDictionaryRef
import platform.CoreFoundation.CFRelease
import platform.CoreFoundation.CFStringRef
import platform.CoreFoundation.CFTypeRef
import platform.CoreFoundation.CFTypeRefVar
import platform.CoreFoundation.kCFAllocatorDefault
import platform.CoreFoundation.kCFBooleanTrue
import platform.CoreFoundation.kCFTypeDictionaryKeyCallBacks
import platform.CoreFoundation.kCFTypeDictionaryValueCallBacks
import platform.Foundation.CFBridgingRelease
import platform.Foundation.CFBridgingRetain
import platform.Foundation.NSData
import platform.Foundation.NSString
import platform.Foundation.NSUTF8StringEncoding
import platform.Foundation.create
import platform.darwin.OSStatus
import platform.Security.SecItemAdd
import platform.Security.SecItemCopyMatching
import platform.Security.SecItemDelete
import platform.Security.SecItemUpdate
import platform.Security.errSecDuplicateItem
import platform.Security.errSecItemNotFound
import platform.Security.errSecSuccess
import platform.Security.kSecAttrAccessible
import platform.Security.kSecAttrAccessibleAfterFirstUnlock
import platform.Security.kSecAttrAccount
import platform.Security.kSecAttrService
import platform.Security.kSecClass
import platform.Security.kSecClassGenericPassword
import platform.Security.kSecMatchLimit
import platform.Security.kSecMatchLimitOne
import platform.Security.kSecReturnData
import platform.Security.kSecValueData

actual class SecureStorageProvider {

    actual fun create(name: String): SecureStorage = KeychainSecureStorage(service = name)
}

/**
 * Keychain-backed storage. Every entry is a `kSecClassGenericPassword` item identified by
 * the storage name (`kSecAttrService`) plus the entry key (`kSecAttrAccount`).
 *
 * The Keychain reports failures through an `OSStatus` return value and [SecureStorage] has
 * no error channel to forward them to. So every mutation goes through a private helper that
 * turns that status into a success flag the caller acts on, rather than dropping it at the
 * call site: a failed write must never be indistinguishable from a stored value.
 */
@OptIn(ExperimentalForeignApi::class, BetaInteropApi::class)
private class KeychainSecureStorage(private val service: String) : SecureStorage {

    override suspend fun getString(key: String): String? = withContext(Dispatchers.IO) {
        memScoped {
            val result = alloc<CFTypeRefVar>()
            val query = itemQuery(
                account = key,
                kSecReturnData to kCFBooleanTrue,
                kSecMatchLimit to kSecMatchLimitOne,
            )
            val status = try {
                SecItemCopyMatching(query, result.ptr)
            } finally {
                CFRelease(query)
            }
            if (status != errSecSuccess) {
                null
            } else {
                // CFBridgingRelease takes ownership of the +1 reference returned by the query.
                (CFBridgingRelease(result.value) as? NSData)
                    ?.let { NSString.create(data = it, encoding = NSUTF8StringEncoding) }
                    ?.toString()
            }
        }
    }

    override suspend fun putString(key: String, value: String) {
        withContext(Dispatchers.IO) {
            if (!writeItem(account = key, value = value)) {
                // The Keychain refused the write and SecureStorage has no error channel to
                // report that through. It must not pass for a success either: drop whatever
                // is still stored under the key, so a later read returns null instead of the
                // outdated value this write was supposed to replace.
                deleteItem(account = key)
            }
        }
    }

    override suspend fun remove(key: String) {
        withContext(Dispatchers.IO) {
            deleteItem(account = key)
        }
    }

    override suspend fun clear() {
        withContext(Dispatchers.IO) {
            deleteService()
        }
    }

    /** Returns whether [value] ended up stored under [account]. */
    private fun writeItem(account: String, value: String): Boolean {
        // Kotlin values are bridged to their Foundation counterparts when passed as `id`.
        val cfData = CFBridgingRetain(value.toNSData())
        return try {
            val query = itemQuery(
                account = account,
                kSecValueData to cfData,
                kSecAttrAccessible to kSecAttrAccessibleAfterFirstUnlock,
            )
            val status = try {
                SecItemAdd(query, null)
            } finally {
                CFRelease(query)
            }
            when (status) {
                errSecSuccess -> true
                // Adding first and only updating on a reported duplicate keeps the write
                // atomic. Probing with SecItemCopyMatching beforehand would race with a
                // concurrent writer and turn into a swallowed errSecDuplicateItem.
                errSecDuplicateItem -> updateItem(account = account, cfData = cfData)
                else -> false
            }
        } finally {
            CFRelease(cfData)
        }
    }

    private fun updateItem(account: String, cfData: CFTypeRef?): Boolean {
        val query = itemQuery(account = account)
        val attributes = cfDictionaryOf(mapOf(kSecValueData to cfData))
        val status = try {
            SecItemUpdate(query, attributes)
        } finally {
            CFRelease(query)
            CFRelease(attributes)
        }
        return status == errSecSuccess
    }

    /** Returns whether nothing is stored under [account] once the call returns. */
    private fun deleteItem(account: String): Boolean {
        val query = itemQuery(account = account)
        val status = try {
            SecItemDelete(query)
        } finally {
            CFRelease(query)
        }
        return status.isDeleted()
    }

    /** Returns whether every entry of this storage is gone once the call returns. */
    private fun deleteService(): Boolean {
        val cfService = CFBridgingRetain(service)
        val query = try {
            cfDictionaryOf(
                mapOf(
                    kSecClass to kSecClassGenericPassword,
                    kSecAttrService to cfService,
                )
            )
        } finally {
            CFRelease(cfService)
        }
        val status = try {
            SecItemDelete(query)
        } finally {
            CFRelease(query)
        }
        return status.isDeleted()
    }

    /** Caller owns the returned dictionary and must `CFRelease` it. */
    private fun itemQuery(
        account: String,
        vararg extra: Pair<CFStringRef?, CFTypeRef?>,
    ): CFMutableDictionaryRef {
        val cfService = CFBridgingRetain(service)
        val cfAccount = CFBridgingRetain(account)
        return try {
            cfDictionaryOf(
                buildMap {
                    put(kSecClass, kSecClassGenericPassword)
                    put(kSecAttrService, cfService)
                    put(kSecAttrAccount, cfAccount)
                    putAll(extra)
                }
            )
        } finally {
            // The dictionary uses the standard CF callbacks, so it holds its own retain.
            CFRelease(cfService)
            CFRelease(cfAccount)
        }
    }
}

/**
 * Whether a `SecItemDelete` left the key empty. `errSecItemNotFound` means there was
 * nothing to delete in the first place, which is the outcome the caller asked for.
 */
private fun OSStatus.isDeleted(): Boolean =
    this == errSecSuccess || this == errSecItemNotFound

@OptIn(ExperimentalForeignApi::class, BetaInteropApi::class)
private fun String.toNSData(): NSData {
    val bytes = encodeToByteArray()
    if (bytes.isEmpty()) return NSData()
    return bytes.usePinned { pinned ->
        // `dataWithBytes:length:` copies, so the pinned array can be released right after.
        NSData.create(bytes = pinned.addressOf(0), length = bytes.size.convert())
    }
}

/** Caller owns the returned dictionary and must `CFRelease` it. */
@OptIn(ExperimentalForeignApi::class)
private fun cfDictionaryOf(entries: Map<CFStringRef?, CFTypeRef?>): CFMutableDictionaryRef {
    val dictionary = CFDictionaryCreateMutable(
        kCFAllocatorDefault,
        entries.size.convert(),
        kCFTypeDictionaryKeyCallBacks.ptr,
        kCFTypeDictionaryValueCallBacks.ptr,
    ) ?: error("Unable to allocate a CFMutableDictionary")
    entries.forEach { (key, value) -> CFDictionarySetValue(dictionary, key, value) }
    return dictionary
}
