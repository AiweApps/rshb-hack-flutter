package com.aiweapps.winescan.di.graph

import com.aiweapps.winescan.components.common.ConfirmClearHistoryComponent
import com.aiweapps.winescan.components.common.DefaultConfirmClearHistoryComponent
import com.aiweapps.winescan.components.common.DefaultServiceDetailComponent
import com.aiweapps.winescan.components.common.ServiceDetailComponent

/** Sheets that more than one tab opens. */
class SharedGraph {

    val serviceDetailFactory = ServiceDetailComponent.Factory { componentContext, availability, onClose ->
        DefaultServiceDetailComponent(componentContext, availability, onClose)
    }

    val confirmClearHistoryFactory = ConfirmClearHistoryComponent.Factory { componentContext, onConfirm, onCancel ->
        DefaultConfirmClearHistoryComponent(componentContext, onConfirm, onCancel)
    }
}
