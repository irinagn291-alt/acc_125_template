import UIKit
import Alamofire
import OneSignalFramework

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AppConfiguration.serverBaseURL = "https://solar-stride-fitneiko.pro"

        OneSignal.initialize("0e8c2840-fc7e-4c64-abc0-800bff7bb83a", withLaunchOptions: launchOptions)
        OneSignal.Notifications.requestPermission({ _ in }, fallbackToSettings: false)
        application.registerForRemoteNotifications()

        return true
    }
}
