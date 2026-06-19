import SwiftUI

struct NutritionDayView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var network: NetworkMonitor

    @State private var date = Date.now
    @State private var meals: [Meal] = []
    @State private var summary = NutritionSummary.zero
    @State private var waterMl = 0
    @State private var showAddFood = false
    @State private var showWater = false

    private var profile: UserProfile? { environment.currentProfile() }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                if !network.isConnected { OfflineBanner() }
                dateSelector
                caloriesCard
                macroCard
                waterCard
                mealsSection
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
        .navigationTitle("Nutrition")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showAddFood = true } label: { Image(systemName: AppIcons.add) }.accessibilityLabel("Add Food") } }
        .sheet(isPresented: $showAddFood, onDismiss: reload) { AddFoodFlowView(date: date) }
        .sheet(isPresented: $showWater, onDismiss: reload) { AddWaterSheet(date: date) }
        .onAppear(perform: reload)
        .onChange(of: date) { _, _ in reload() }
    }

    private var dateSelector: some View {
        HStack {
            Button { shift(-1) } label: { Image(systemName: "chevron.left") }.frame(width: 44, height: 44)
            Spacer()
            Text(DateUtils.string(date, DateUtils.dayMonth)).font(AppTypography.bodyMedium).foregroundStyle(AppColor.textPrimary)
            Spacer()
            Button { shift(1) } label: { Image(systemName: "chevron.right") }.frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppSpacing.sm)
        .background(AppColor.surface).clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    private var caloriesCard: some View {
        let goal = profile?.dailyCaloriesGoal ?? 2200
        let remaining = max(goal - summary.calories, 0)
        return AppCard {
            HStack {
                ProgressRing(progress: goal > 0 ? summary.calories / goal : 0, color: AppColor.accent).frame(width: 64, height: 64)
                VStack(alignment: .leading) {
                    Text("\(NumberFormatterUtils.int(summary.calories)) / \(NumberFormatterUtils.int(goal)) kcal").font(AppTypography.title3).foregroundStyle(AppColor.textPrimary)
                    Text("\(NumberFormatterUtils.int(remaining)) kcal remaining").font(AppTypography.caption).foregroundStyle(AppColor.textMuted)
                }
                Spacer()
            }
        }
    }

    private var macroCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SectionHeader(title: "Macros")
                HStack {
                    macroItem("Protein", summary.protein, profile?.proteinGoalGrams, AppColor.protein)
                    macroItem("Fat", summary.fat, profile?.fatGoalGrams, AppColor.fat)
                    macroItem("Carbs", summary.carbs, profile?.carbsGoalGrams, AppColor.carbs)
                }
            }
        }
    }

    private func macroItem(_ name: String, _ value: Double, _ goal: Double?, _ color: Color) -> some View {
        VStack(spacing: AppSpacing.xs) {
            ProgressRing(progress: (goal ?? 0) > 0 ? value / goal! : 0, lineWidth: 6, color: color).frame(width: 44, height: 44)
            Text("\(NumberFormatterUtils.int(value)) g").font(AppTypography.captionMedium).foregroundStyle(AppColor.textPrimary)
            Text(name).font(AppTypography.caption).foregroundStyle(AppColor.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private var waterCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Label("Water", systemImage: AppIcons.water).font(AppTypography.captionMedium).foregroundStyle(AppColor.textSecondary)
                Text("\(waterMl) ml / \(profile?.waterGoalMl ?? 2500) ml").font(AppTypography.title3).foregroundStyle(AppColor.textPrimary)
                HStack {
                    waterButton(250); waterButton(500)
                    Button { showWater = true } label: {
                        Text("Custom").font(.headline).frame(maxWidth: .infinity).frame(minHeight: 44)
                            .background(AppColor.elevatedSurface).foregroundStyle(AppColor.textPrimary).clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }
                }
            }
        }
    }

    private func waterButton(_ ml: Int) -> some View {
        Button {
            try? environment.nutritionRepository.addHydration(amountMl: ml, date: date); HapticsManager.light(); reload()
        } label: {
            Text("+\(ml)").font(.headline).frame(maxWidth: .infinity).frame(minHeight: 44)
                .background(AppColor.secondary.opacity(0.18)).foregroundStyle(AppColor.secondary).clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
    }

    private var mealsSection: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack { SectionHeader(title: "Meals"); Spacer() }
            if meals.isEmpty {
                EmptyStateView(systemImage: AppIcons.nutrition, title: "No meals added", message: "Add your first meal to track calories and macros.", actionTitle: "Add Meal") { showAddFood = true }
            } else {
                ForEach(meals) { meal in
                    NavigationLink { MealDetailView(meal: meal) } label: { mealRow(meal) }
                }
            }
        }
    }

    private func mealRow(_ meal: Meal) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    Label(meal.type.displayName, systemImage: meal.type.icon).font(AppTypography.bodyMedium).foregroundStyle(AppColor.textPrimary)
                    Spacer()
                    Text("\(NumberFormatterUtils.int(meal.totalCalories)) kcal").font(AppTypography.caption).foregroundStyle(AppColor.textMuted)
                }
                ForEach(meal.items.prefix(4)) { item in
                    HStack {
                        Text(item.productName).font(AppTypography.caption).foregroundStyle(AppColor.textSecondary)
                        Spacer()
                        Text("\(NumberFormatterUtils.int(item.amountGrams)) g").font(AppTypography.caption).foregroundStyle(AppColor.textMuted)
                    }
                }
            }
        }
    }

    private func shift(_ v: Int) { date = Calendar.current.date(byAdding: .day, value: v, to: date) ?? date }

    private func reload() {
        meals = (try? environment.nutritionRepository.fetchMeals(for: date)) ?? []
        summary = environment.nutritionCalculation.summary(for: meals)
        waterMl = ((try? environment.nutritionRepository.fetchHydrationLogs(for: date)) ?? []).reduce(0) { $0 + $1.amountMl }
    }
}

struct AddWaterSheet: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    var date: Date = .now
    @State private var amount = "250"

    var body: some View {
        NavigationStack {
            Form {
                Section("Water Amount") {
                    TextField("ml", text: $amount).keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add Water")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let ml = Int(amount), ml > 0, ml <= 5000 {
                            try? environment.nutritionRepository.addHydration(amountMl: ml, date: date)
                            HapticsManager.success()
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}
