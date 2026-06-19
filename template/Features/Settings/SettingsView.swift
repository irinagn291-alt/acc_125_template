import SwiftUI
import Alamofire

struct SettingsView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue
    @AppStorage("unitSystem") private var unitSystem = UnitSystem.metric.rawValue
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var confirmReset = false

    var body: some View {
        List {
            Section("Profile") {
                NavigationLink { ProfileEditView() } label: { Label("Profile", systemImage: AppIcons.profile) }
                NavigationLink { NutritionTargetsView() } label: { Label("Nutrition Targets", systemImage: AppIcons.nutrition) }
            }
            Section("Sections") {
                NavigationLink { AnalyticsView() } label: { Label("Analytics", systemImage: AppIcons.analytics) }
                NavigationLink { ProgramsListView() } label: { Label("Training Programs", systemImage: AppIcons.programs) }
                NavigationLink { BodyMeasurementsView() } label: { Label("Body Measurements", systemImage: AppIcons.body) }
                NavigationLink { GoalsView() } label: { Label("Goals", systemImage: AppIcons.goals) }
            }
            Section("Preferences") {
                Picker(selection: $appearanceMode) {
                    ForEach(AppearanceMode.allCases) { Text($0.displayName).tag($0.rawValue) }
                } label: { Label("Appearance", systemImage: "paintbrush.fill") }
                Picker(selection: $unitSystem) {
                    ForEach(UnitSystem.allCases) { Text($0.displayName).tag($0.rawValue) }
                } label: { Label("Units", systemImage: "ruler.fill") }
            }
            Section("Data") {
                NavigationLink { DataExportView() } label: { Label("Data Export", systemImage: AppIcons.export) }
                NavigationLink { DataImportView() } label: { Label("Data Import", systemImage: AppIcons.importIcon) }
                Button { URLCache.shared.removeAllCachedResponses() } label: { Label("Clear API Cache", systemImage: "trash.slash") }
            }
            Section("About") {
                NavigationLink { ContactUsView() } label: { Label("Contact Us", systemImage: "envelope.fill") }
                NavigationLink { PrivacyView() } label: { Label("Privacy", systemImage: AppIcons.privacy) }
                NavigationLink { AboutView() } label: { Label("About App", systemImage: "info.circle.fill") }
            }
            Section {
                Button(role: .destructive) { confirmReset = true } label: { Label("Reset All Data", systemImage: "exclamationmark.arrow.circlepath") }
            }
        }
        .scrollContentBackground(.hidden).background(AppColor.background)
        .navigationTitle("Settings")
        .confirmationDialog("Reset All Data?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset Everything", role: .destructive) {
                try? environment.exportImportService.resetAll()
                hasCompletedOnboarding = false
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This permanently deletes all local data on this device.") }
    }
}

struct ProfileEditView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var age = ""
    @State private var height = ""
    @State private var weight = ""
    @State private var targetWeight = ""
    @State private var level: DifficultyLevel = .beginner
    @State private var profile: UserProfile?

    var body: some View {
        Form {
            Section("Profile") {
                TextField("Name", text: $name)
                HStack { Text("Age"); Spacer(); TextField("—", text: $age).keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(maxWidth: 80) }
                HStack { Text("Height (cm)"); Spacer(); TextField("—", text: $height).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(maxWidth: 80) }
                HStack { Text("Current Weight (kg)"); Spacer(); TextField("—", text: $weight).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(maxWidth: 80) }
                HStack { Text("Target Weight (kg)"); Spacer(); TextField("—", text: $targetWeight).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(maxWidth: 80) }
                Picker("Training Level", selection: $level) { ForEach(DifficultyLevel.allCases) { Text($0.displayName).tag($0) } }
            }
        }
        .scrollContentBackground(.hidden).background(AppColor.background)
        .navigationTitle("Profile")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } } }
        .onAppear(perform: load)
    }

    private func load() {
        let p = environment.currentProfile() ?? UserProfile()
        profile = p
        name = p.name; age = p.age.map(String.init) ?? ""; height = p.heightCm.map { String($0) } ?? ""
        weight = p.currentWeightKg.map { String($0) } ?? ""; targetWeight = p.targetWeightKg.map { String($0) } ?? ""; level = p.trainingLevel
    }

    private func save() {
        let p = profile ?? UserProfile()
        p.name = name; p.age = Int(age); p.heightCm = Double(height); p.currentWeightKg = Double(weight)
        p.targetWeightKg = Double(targetWeight); p.trainingLevel = level
        try? environment.profileRepository.saveProfile(p)
        HapticsManager.success(); dismiss()
    }
}

struct NutritionTargetsView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @State private var calories = ""
    @State private var protein = ""
    @State private var fat = ""
    @State private var carbs = ""
    @State private var water = ""
    @State private var profile: UserProfile?

    var body: some View {
        Form {
            Section("Daily Targets") {
                field("Calories", $calories); field("Protein (g)", $protein); field("Fat (g)", $fat); field("Carbs (g)", $carbs); field("Water (ml)", $water)
            }
        }
        .scrollContentBackground(.hidden).background(AppColor.background)
        .navigationTitle("Nutrition Targets")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } } }
        .onAppear(perform: load)
    }

    private func field(_ t: String, _ b: Binding<String>) -> some View {
        HStack { Text(t); Spacer(); TextField("0", text: b).keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(maxWidth: 100) }
    }

    private func load() {
        let p = environment.currentProfile() ?? UserProfile()
        profile = p
        calories = String(Int(p.dailyCaloriesGoal)); protein = String(Int(p.proteinGoalGrams))
        fat = String(Int(p.fatGoalGrams)); carbs = String(Int(p.carbsGoalGrams)); water = String(p.waterGoalMl)
    }

    private func save() {
        let p = profile ?? UserProfile()
        p.dailyCaloriesGoal = Double(calories) ?? p.dailyCaloriesGoal
        p.proteinGoalGrams = Double(protein) ?? p.proteinGoalGrams
        p.fatGoalGrams = Double(fat) ?? p.fatGoalGrams
        p.carbsGoalGrams = Double(carbs) ?? p.carbsGoalGrams
        p.waterGoalMl = Int(water) ?? p.waterGoalMl
        try? environment.profileRepository.saveProfile(p)
        HapticsManager.success(); dismiss()
    }
}

struct ContactUsView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            WebContentView(url: "https://solar-stride-fitneiko.pro/contact-us")
        }
        .preferredColorScheme(.dark)
        .navigationTitle("Contact Us")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyView: View {
    private let lines = [
        "Your data is stored locally on this device.",
        "The app does not require an account.",
        "The app does not use HealthKit.",
        "The app does not use notifications.",
        "The app does not use camera access.",
        "The app does not track you.",
        "The app does not use third-party analytics SDKs.",
        "The app does not send your workouts, meals, body measurements, goals, or notes to any private server.",
        "OpenFoodFacts is used only when you search for food by text.",
        "OpenLibrary is used only when you search for books by text.",
        "You can export or delete your data at any time."
    ]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                ForEach(lines, id: \.self) { line in
                    HStack(alignment: .top, spacing: AppSpacing.sm) {
                        Image(systemName: "checkmark.shield.fill").foregroundStyle(AppColor.primary)
                        Text(line).font(AppTypography.body).foregroundStyle(AppColor.textPrimary)
                    }
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
        .navigationTitle("Privacy")
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "figure.run.circle.fill").font(.system(size: 72)).foregroundStyle(AppColor.primary)
                Text("SolarStride").font(AppTypography.title1).foregroundStyle(AppColor.textPrimary)
                Text("A private offline-first fitness planner. No account. No tracking. No ads. Your fitness data stays on your device.")
                    .font(AppTypography.body).foregroundStyle(AppColor.textSecondary).multilineTextAlignment(.center)
                AppCard {
                    Text("SolarStride is an offline training companion for strength planning, programs, nutrition, and progress analytics. It does not provide medical advice. Consult a qualified professional before making major changes to your training or nutrition.")
                        .font(AppTypography.caption).foregroundStyle(AppColor.textMuted)
                }
                Text("Version 1.0").font(AppTypography.caption).foregroundStyle(AppColor.textMuted)
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColor.background)
        .navigationTitle("About App")
    }
}
