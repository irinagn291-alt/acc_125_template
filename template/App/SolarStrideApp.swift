import SwiftUI
import SwiftData
import Alamofire
import OneSignalFramework

@main
struct SolarStrideApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var environment = AppEnvironment()
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue
    @State private var isInitializing = true
    @State private var displayMode: DisplayMode = .loading
    @State private var webContentURL: String?

    var body: some Scene {
        WindowGroup {
            rootView
                .onAppear { performRegistration() }
        }
        .modelContainer(SwiftDataContainer.shared)
    }

    @ViewBuilder
    private var rootView: some View {
        ZStack {
            if isInitializing {
                ZStack {
                    AppColor.background.ignoresSafeArea()
                    LoadingStateView()
                }
            } else if displayMode == .webContent, let url = webContentURL {
                let fullURL = url.hasPrefix("http") ? url : "https://\(url)"
                ZStack {
                    Color.black.ignoresSafeArea()
                    WebContentView(url: fullURL)
                }
                .preferredColorScheme(.dark)
            } else {
                RootView()
                    .environmentObject(environment)
                    .environmentObject(environment.networkMonitor)
                    .tint(AppColor.primary)
                    .preferredColorScheme(AppearanceMode(rawValue: appearanceMode)?.colorScheme)
            }
        }
    }

    private func performRegistration() {
        if let saved = DataCache.shared.contentURL, !saved.isEmpty {
            finishLaunch(mode: .webContent, url: saved)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            finishLaunch(mode: .nativeInterface, url: nil)
        }

        let pushToken = OneSignal.User.pushSubscription.token ?? ""
        NetworkService.shared.performRegistration(pushToken: pushToken) { mode, url in
            DispatchQueue.main.async { finishLaunch(mode: mode, url: url) }
        }
    }

    private func finishLaunch(mode: DisplayMode, url: String?) {
        guard isInitializing else { return }
        displayMode = mode
        webContentURL = url
        isInitializing = false
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum UnitSystem: String, CaseIterable, Identifiable {
    case metric, imperial
    var id: String { rawValue }
    var displayName: String { self == .metric ? "Metric" : "Imperial" }
}
