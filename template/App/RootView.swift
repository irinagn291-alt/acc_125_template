import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                SolarStrideDashboardView()
            }
            .tabItem { Label("Dashboard", systemImage: AppIcons.today) }

            NavigationStack {
                WorkoutListView()
            }
            .tabItem { Label("Train", systemImage: AppIcons.workouts) }

            NavigationStack {
                ProgramsListView()
            }
            .tabItem { Label("Programs", systemImage: AppIcons.programs) }

            NavigationStack {
                NutritionDayView()
            }
            .tabItem { Label("Fuel", systemImage: AppIcons.nutrition) }

            NavigationStack {
                LibraryView()
            }
            .tabItem { Label("Library", systemImage: AppIcons.library) }
        }
    }
}
