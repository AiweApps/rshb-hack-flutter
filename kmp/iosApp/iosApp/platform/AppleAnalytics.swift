import FirebaseAnalytics
import FirebaseCore
import SharedLogic

final class AppleAnalytics: AnalyticsTracker {

    func logEvent(name: String, params: [String: String]) {
        guard FirebaseApp.app() != nil else { return }
        Analytics.logEvent(name, parameters: params)
    }

    func logScreen(name: String) {
        guard FirebaseApp.app() != nil else { return }
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [AnalyticsParameterScreenName: name])
    }
}
