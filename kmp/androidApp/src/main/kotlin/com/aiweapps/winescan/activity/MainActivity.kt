package com.aiweapps.winescan.activity

import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.view.Gravity
import android.widget.FrameLayout
import androidx.activity.SystemBarStyle
import androidx.activity.OnBackPressedCallback
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.compose.ui.platform.ComposeView
import com.arkivanov.decompose.retainedComponent
import com.aiweapps.winescan.di.AppGraph
import com.aiweapps.winescan.root.RootContent
import com.aiweapps.winescan.retail.PerekrestokWebViewAdapter
import com.aiweapps.winescan.retail.AndroidRetailGateway
import com.aiweapps.winescan.retail.RetailCloseButton
import com.aiweapps.winescan.retail.RetailBridgeClient
import org.koin.android.ext.android.getKoin

/**
 * AppCompat rather than ComponentActivity on purpose: the per-app language
 * (`AppCompatDelegate.setApplicationLocales`) is applied by AppCompat on API < 33.
 */
class MainActivity : AppCompatActivity() {
    lateinit var retailAdapter: PerekrestokWebViewAdapter
        private set
    private lateinit var retailOverlay: FrameLayout
    private lateinit var retailBridge: RetailBridgeClient
    private var appDarkBars = false
    private var appBarBackground = android.graphics.Color.TRANSPARENT

    /** App-selected theme can differ from the Android system theme. */
    fun updateAppSystemBars(isDark: Boolean, background: Int) {
        appDarkBars = isDark
        appBarBackground = background
        applySystemBars()
    }

    private fun applySystemBars() {
        val retailerVisible = ::retailOverlay.isInitialized && retailOverlay.visibility == View.VISIBLE
        val dark = appDarkBars && !retailerVisible
        val background = if (retailerVisible) android.graphics.Color.WHITE else appBarBackground
        enableEdgeToEdge(
            statusBarStyle = if (dark) SystemBarStyle.dark(android.graphics.Color.TRANSPARENT)
                else SystemBarStyle.light(android.graphics.Color.TRANSPARENT, android.graphics.Color.TRANSPARENT),
            navigationBarStyle = if (dark) SystemBarStyle.dark(background)
                else SystemBarStyle.light(background, background),
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        // From API 35 the system draws the app edge to edge regardless; calling this keeps
        // the same behaviour on older versions instead of two layouts to reason about.
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        retailAdapter = PerekrestokWebViewAdapter(this)
        retailBridge = RetailBridgeClient(this, retailAdapter, getKoin().get(),
            getKoin().get<com.aiweapps.winescan.config.AppConfig>().assistantBaseUrl ?: "https://wines.aiweapps.com/assistant/")
        getKoin().get<AndroidRetailGateway>().attach(retailAdapter)

        val appGraph = getKoin().get<AppGraph>()
        val root = retainedComponent { componentContext ->
            appGraph.root.rootFactory.create(componentContext = componentContext)
        }

        setContent {
            RootContent(root)
        }

        // The retailer WebView stays attached while the user returns to chat. View.GONE was
        // verified with the original on-device prototype; detaching it could suspend JS.
        val content = findViewById<ViewGroup>(android.R.id.content)
        retailOverlay = FrameLayout(this)
        retailOverlay.addView(
            retailAdapter.webView,
            ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT),
        )
        val closeButton = ComposeView(this).apply {
            setContent { RetailCloseButton(onClose = ::hideRetailStore) }
        }
        val density = resources.displayMetrics.density
        retailOverlay.addView(closeButton, FrameLayout.LayoutParams(
            (56 * density).toInt(), (56 * density).toInt(), Gravity.TOP or Gravity.END,
        ).apply {
            topMargin = (48 * density).toInt()
            marginEnd = (12 * density).toInt()
        })
        retailOverlay.visibility = View.GONE
        content.addView(retailOverlay, ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT,
        ))
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(false) {
            override fun handleOnBackPressed() {
                if (retailAdapter.webView.canGoBack()) retailAdapter.webView.goBack()
                else hideRetailStore()
            }
        }.also { retailBackCallback = it })
    }

    private lateinit var retailBackCallback: OnBackPressedCallback

    /** Call only from an explicit user action that opens the retailer site. */
    fun openRetailStore() {
        retailAdapter.openStore()
        retailOverlay.visibility = View.VISIBLE
        applySystemBars()
        retailBackCallback.isEnabled = true
    }

    fun hideRetailStore() {
        retailOverlay.visibility = View.GONE
        applySystemBars()
        retailBackCallback.isEnabled = false
    }

    override fun onResume() {
        super.onResume()
        retailAdapter.onResume()
        retailBridge.start()
    }

    override fun onPause() {
        retailBridge.stop()
        retailAdapter.onPause()
        super.onPause()
    }

    override fun onDestroy() {
        retailBridge.close()
        getKoin().get<AndroidRetailGateway>().detach(retailAdapter)
        retailAdapter.close()
        super.onDestroy()
    }
}
