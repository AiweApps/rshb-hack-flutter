package com.aiweapps.winescan.di.graph

import com.aiweapps.core.platform.PlatformLinks
import com.aiweapps.winescan.components.assistant.AssistantComponent
import com.aiweapps.winescan.components.assistant.DefaultAssistantComponent
import com.aiweapps.winescan.domain.assistant.repository.AssistantService
import com.aiweapps.winescan.domain.assistant.repository.AssistantLocalRepository
import com.aiweapps.winescan.domain.assistant.repository.RetailGateway
import com.aiweapps.winescan.domain.history.repository.ScanHistoryRepository
import com.aiweapps.winescan.domain.scan.repository.ScanRepository

class AssistantGraph(
    scanRepository: ScanRepository,
    historyRepository: ScanHistoryRepository,
    service: AssistantService,
    retailGateway: RetailGateway,
    accounts: com.aiweapps.winescan.domain.assistant.repository.AssistantAccountRepository,
    localRepository: AssistantLocalRepository,
    platformLinks: PlatformLinks,
    catalog: com.aiweapps.winescan.domain.catalog.repository.WineCatalogRepository,
    compareRepository: com.aiweapps.winescan.domain.compare.repository.CompareSetRepository,
) {
    val assistantFactory = AssistantComponent.Factory { context, onOpenCompare ->
        DefaultAssistantComponent(context, scanRepository, historyRepository, service, retailGateway, accounts, localRepository, platformLinks, catalog, compareRepository, onOpenCompare)
    }
}
