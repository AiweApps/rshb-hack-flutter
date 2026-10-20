package com.aiweapps.winescan.components.root

import com.arkivanov.decompose.ComponentContext
import com.arkivanov.decompose.router.stack.ChildStack
import com.arkivanov.decompose.router.stack.StackNavigation
import com.arkivanov.decompose.router.stack.childStack
import com.arkivanov.decompose.router.stack.pop
import com.arkivanov.decompose.router.stack.popWhile
import com.arkivanov.decompose.router.stack.push
import com.arkivanov.decompose.router.stack.pushNew
import com.arkivanov.decompose.router.stack.replaceAll
import com.arkivanov.decompose.value.MutableValue
import com.arkivanov.decompose.value.Value
import com.aiweapps.core.analytics.AnalyticsTracker
import com.aiweapps.core.components.base.BaseComponent
import com.aiweapps.winescan.components.common.trackScreen
import com.aiweapps.winescan.components.main.MainComponent
import com.aiweapps.winescan.components.pairing.DishPairingComponent
import com.aiweapps.winescan.components.onboarding.OnboardingComponent
import com.aiweapps.winescan.components.root.config.RootConfig
import com.aiweapps.winescan.components.scan.result.ScanResultComponent
import com.aiweapps.winescan.components.splash.SplashComponent
import com.aiweapps.winescan.components.wine.detail.WineDetailComponent
import com.aiweapps.winescan.config.AnalyticsScreens
import com.aiweapps.winescan.domain.pairing.model.PairingSource
import com.aiweapps.winescan.domain.scan.model.ScanTarget
import com.aiweapps.winescan.domain.theme.model.ThemeMode
import com.aiweapps.winescan.domain.theme.repository.ThemeRepository
import kotlinx.coroutines.launch

internal class DefaultRootComponent(
    componentContext: ComponentContext,
    private val splashFactory: SplashComponent.Factory,
    private val onboardingFactory: OnboardingComponent.Factory,
    private val mainFactory: MainComponent.Factory,
    private val scanResultFactory: ScanResultComponent.Factory,
    private val wineDetailFactory: WineDetailComponent.Factory,
    private val dishPairingFactory: DishPairingComponent.Factory,
    private val themeRepository: ThemeRepository,
    private val analytics: AnalyticsTracker,
) : RootComponent, BaseComponent(componentContext) {

    private val navigation = StackNavigation<RootConfig>()

    // Theme state is a single value rather than a BaseScreenState, so it stays a plain
    // MutableValue instead of going through BaseStatefulComponent.
    private val _themeMode = MutableValue(themeRepository.themeMode.value)
    override val themeMode: Value<ThemeMode> = _themeMode

    override val childStack: Value<ChildStack<*, RootComponent.Child>> =
        childStack(
            source = navigation,
            serializer = RootConfig.serializer(),
            initialConfiguration = RootConfig.Splash,
            handleBackButton = true,
            childFactory = ::createChild,
        )

    init {
        scope.launch {
            themeRepository.themeMode.collect { mode -> _themeMode.value = mode }
        }
    }

    private fun createChild(config: RootConfig, context: ComponentContext): RootComponent.Child {
        screenOf(config)?.let { context.trackScreen(analytics, it) }
        return when (config) {
            RootConfig.Splash -> RootComponent.Child.Splash(
                splashFactory.create(
                    componentContext = context,
                    onFinished = { isOnboardingDone ->
                        navigation.replaceAll(if (isOnboardingDone) RootConfig.Main else RootConfig.Onboarding)
                    },
                )
            )
            RootConfig.Onboarding -> RootComponent.Child.Onboarding(
                onboardingFactory.create(
                    componentContext = context,
                    onFinished = { navigation.replaceAll(RootConfig.Main) },
                )
            )
            RootConfig.Main -> RootComponent.Child.Main(
                mainFactory.create(
                    componentContext = context,
                    onOpenResult = ::openResult,
                    onOpenOnboarding = { navigation.replaceAll(RootConfig.Onboarding) },
                    onOpenPairing = ::openPairing,
                )
            )
            is RootConfig.ScanResult -> RootComponent.Child.ScanResult(
                scanResultFactory.create(
                    componentContext = context,
                    target = config.target,
                    onClose = { navigation.pop() },
                    onNewScan = { returnToTab(MainComponent.SCAN_TAB) },
                    onOpenCompare = { returnToTab(MainComponent.COMPARE_TAB) },
                    onOpenPairing = { openPairing(PairingSource.FromCompareSet) },
                    // pushNew: a double tap on a card must not stack the same wine twice.
                    onOpenWineDetail = { target -> navigation.pushNew(RootConfig.WineDetail(target)) },
                    // A result for a drawn frame goes over the one it was drawn on, so back
                    // returns there. pushNew: a double tap on «Scan» must not stack it twice;
                    // a different frame is a different config and stacks as it should.
                    onOpenFramedResult = { target -> navigation.pushNew(RootConfig.ScanResult(target)) },
                )
            )
            is RootConfig.WineDetail -> RootComponent.Child.WineDetail(
                wineDetailFactory.create(
                    componentContext = context,
                    target = config.target,
                    onClose = { navigation.pop() },
                )
            )
            is RootConfig.DishPairing -> RootComponent.Child.DishPairing(
                dishPairingFactory.create(
                    componentContext = context,
                    source = config.source,
                    onClose = { navigation.pop() },
                    onOpenScanner = { returnToTab(MainComponent.SCAN_TAB) },
                    onPlanDinner = { wines, prompt ->
                        navigation.popWhile(
                            predicate = { it != RootConfig.Main },
                            onComplete = {
                                val main = childStack.value.items.firstNotNullOfOrNull { it.instance as? RootComponent.Child.Main }
                                main?.component?.onComparisonRequested(wines, prompt)
                            },
                        )
                    },
                )
            )
        }
    }

    /** Splash and the tabs host are not screens of their own; the tabs report themselves. */
    private fun screenOf(config: RootConfig): String? = when (config) {
        RootConfig.Splash, RootConfig.Main -> null
        RootConfig.Onboarding -> AnalyticsScreens.ONBOARDING
        is RootConfig.ScanResult -> AnalyticsScreens.SCAN_RESULT
        is RootConfig.WineDetail -> AnalyticsScreens.WINE_DETAIL
        is RootConfig.DishPairing -> AnalyticsScreens.DISH_PAIRING
    }

    private fun openPairing(source: PairingSource) {
        navigation.push(RootConfig.DishPairing(source))
    }

    private fun openResult(target: ScanTarget) {
        navigation.push(RootConfig.ScanResult(target))
    }

    /**
     * «New scan» or «Compare» from a pushed screen: drop everything over the tabs and land
     * on that tab, whichever one it came from.
     */
    private fun returnToTab(tab: Int) {
        // The tab is chosen before Main comes back, or the one it left on is logged as a view.
        childStack.value.items
            .firstNotNullOfOrNull { it.instance as? RootComponent.Child.Main }
            ?.component
            ?.selectTab(tab)
        navigation.popWhile(predicate = { it != RootConfig.Main })
    }
}
