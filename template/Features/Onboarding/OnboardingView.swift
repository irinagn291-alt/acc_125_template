import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var step = 0

    @State private var selectedGoals: Set<String> = []
    @State private var trainingLevel: DifficultyLevel = .beginner
    @State private var age = ""
    @State private var height = ""
    @State private var currentWeight = ""
    @State private var targetWeight = ""
    @State private var activityLevel = "Moderate"
    @State private var calories = "2200"
    @State private var protein = "140"
    @State private var fat = "70"
    @State private var carbs = "250"
    @State private var water = "2500"

    private let goalOptions = ["Build muscle", "Lose weight", "Maintain fitness", "Improve strength", "Improve endurance", "Improve mobility", "Eat better", "Read more about training"]
    private let activities = ["Sedentary", "Light", "Moderate", "Active", "Very Active"]

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            VStack(spacing: 0) {
                ProgressView(value: Double(step + 1), total: 6)
                    .tint(AppColor.primary)
                    .padding()
                TabView(selection: $step) {
                    welcome.tag(0)
                    goals.tag(1)
                    level.tag(2)
                    bodyProfile.tag(3)
                    nutrition.tag(4)
                    finish.tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: step)
            }
        }
    }

    private func container<Content: View>(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title).font(AppTypography.title1).foregroundStyle(AppColor.textPrimary)
                    if let subtitle {
                        Text(subtitle).font(AppTypography.body).foregroundStyle(AppColor.textSecondary)
                    }
                }
                content()
            }
            .padding(AppSpacing.lg)
        }
    }

    private var welcome: some View {
        VStack {
            Spacer()
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "sun.max.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(AppColor.primary)
                Text("Plan your fitness life offline")
                    .font(AppTypography.title1)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColor.textPrimary)
                Text("Track workouts, nutrition, goals, body progress, and sports books without an account.")
                    .font(AppTypography.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(AppSpacing.lg)
            Spacer()
            PrimaryButton(title: "Get Started") { next() }.padding(AppSpacing.lg)
        }
    }

    private var goals: some View {
        VStack {
            container(title: "Choose your main goals", subtitle: "Select all that apply.") {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(goalOptions, id: \.self) { goal in
                        selectableRow(goal, isOn: selectedGoals.contains(goal)) {
                            if selectedGoals.contains(goal) { selectedGoals.remove(goal) } else { selectedGoals.insert(goal) }
                        }
                    }
                }
            }
            PrimaryButton(title: "Continue") { next() }.padding(AppSpacing.lg)
        }
    }

    private var level: some View {
        VStack {
            container(title: "Your training level") {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(DifficultyLevel.allCases) { lvl in
                        selectableRow(lvl.displayName, isOn: trainingLevel == lvl) { trainingLevel = lvl }
                    }
                }
            }
            PrimaryButton(title: "Continue") { next() }.padding(AppSpacing.lg)
        }
    }

    private var bodyProfile: some View {
        VStack {
            container(title: "Body profile", subtitle: "Used for local calculations only.") {
                VStack(spacing: AppSpacing.sm) {
                    field("Age", text: $age, keyboard: .numberPad)
                    field("Height (cm)", text: $height, keyboard: .decimalPad)
                    field("Current weight (kg)", text: $currentWeight, keyboard: .decimalPad)
                    field("Target weight (kg)", text: $targetWeight, keyboard: .decimalPad)
                    Menu {
                        ForEach(activities, id: \.self) { a in Button(a) { activityLevel = a } }
                    } label: {
                        HStack {
                            Text("Activity level").foregroundStyle(AppColor.textSecondary)
                            Spacer()
                            Text(activityLevel).foregroundStyle(AppColor.textPrimary)
                            Image(systemName: "chevron.up.chevron.down").foregroundStyle(AppColor.textMuted)
                        }
                        .padding().background(AppColor.surface).clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }
                }
            }
            PrimaryButton(title: "Continue") { next() }.padding(AppSpacing.lg)
        }
    }

    private var nutrition: some View {
        VStack {
            container(title: "Nutrition targets", subtitle: "You can change these later in Settings.") {
                VStack(spacing: AppSpacing.sm) {
                    field("Daily calories", text: $calories, keyboard: .numberPad)
                    field("Protein (g)", text: $protein, keyboard: .numberPad)
                    field("Fat (g)", text: $fat, keyboard: .numberPad)
                    field("Carbs (g)", text: $carbs, keyboard: .numberPad)
                    field("Water (ml)", text: $water, keyboard: .numberPad)
                }
            }
            PrimaryButton(title: "Continue") { next() }.padding(AppSpacing.lg)
        }
    }

    private var finish: some View {
        VStack {
            Spacer()
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "checkmark.seal.fill").font(.system(size: 80)).foregroundStyle(AppColor.primary)
                Text("You are ready").font(AppTypography.title1).foregroundStyle(AppColor.textPrimary)
                Text("Your data stays on your device. You can use the app offline anytime.")
                    .font(AppTypography.body).multilineTextAlignment(.center).foregroundStyle(AppColor.textSecondary)
            }
            .padding(AppSpacing.lg)
            Spacer()
            PrimaryButton(title: "Start Using App") { complete() }.padding(AppSpacing.lg)
        }
    }

    private func selectableRow(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).foregroundStyle(AppColor.textPrimary)
                Spacer()
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isOn ? AppColor.primary : AppColor.textMuted)
            }
            .padding()
            .frame(minHeight: AppSize.minTouchTarget)
            .background(isOn ? AppColor.primary.opacity(0.12) : AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
    }

    private func field(_ title: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        HStack {
            Text(title).foregroundStyle(AppColor.textSecondary)
            Spacer()
            TextField("", text: text)
                .keyboardType(keyboard)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(AppColor.textPrimary)
                .frame(maxWidth: 120)
        }
        .padding()
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    private func next() {
        withAnimation { step = min(step + 1, 5) }
    }

    private func complete() {
        let profile = UserProfile(
            age: Int(age),
            heightCm: Double(height),
            currentWeightKg: Double(currentWeight),
            targetWeightKg: Double(targetWeight),
            activityLevel: activityLevel.lowercased(),
            trainingLevel: trainingLevel,
            mainGoals: Array(selectedGoals),
            dailyCaloriesGoal: Double(calories) ?? 2200,
            proteinGoalGrams: Double(protein) ?? 140,
            fatGoalGrams: Double(fat) ?? 70,
            carbsGoalGrams: Double(carbs) ?? 250,
            waterGoalMl: Int(water) ?? 2500
        )
        try? environment.profileRepository.saveProfile(profile)
        HapticsManager.success()
        hasCompletedOnboarding = true
    }
}
