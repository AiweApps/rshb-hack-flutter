package com.aiweapps.winescan.components.onboarding.model

import com.aiweapps.core.components.model.BaseScreenState
import com.aiweapps.core.components.model.ScreenState

data class OnboardingState(
    override val screenState: ScreenState = ScreenState.Content,
    val pageIndex: Int = 0,
    val pageCount: Int = PAGE_COUNT,
    /**
     * The page the pager should display. Updated together with [pageIndex] for both
     * button navigation and swipes; native programmatic selection need not call back.
     */
    val targetPage: Int = 0,
) : BaseScreenState {

    val isLastPage: Boolean get() = pageIndex >= pageCount - 1

    companion object {
        const val PAGE_COUNT = 3
    }
}
