package com.aiweapps.winescan.di

import com.aiweapps.core.database.DatabaseBuilderProvider
import com.aiweapps.core.files.FileStoreProvider
import com.aiweapps.core.storage.KeyValueStorageProvider
import com.aiweapps.core.storage.SecureStorageProvider
import org.koin.core.module.Module
import org.koin.dsl.module

actual val platformModule: Module = module {
    single { DatabaseBuilderProvider(get()) }
    single { KeyValueStorageProvider(get()) }
    single { SecureStorageProvider(get()) }
    single { FileStoreProvider(get()) }
}
