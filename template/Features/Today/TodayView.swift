import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var network: NetworkMonitor

    @State private var summary: TodayDashboardSummary?
    @State private var insights: [String] = []
    @State private var showSettings = false
    @State private var activeSheet: TodaySheet?

    enum TodaySheet: Identifiable {
        case water, measurement, goal, meal
        var id: Int { hashValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                if !network.isConnected { OfflineBanner() }

                if let summary {
                    summaryCards(summary)
                    workoutCard(summary)
                    nutritionCard(summary)
                    waterCard(summary)
                    weeklyCard()
                    goalsCard(summary)
                    readingCard(summary)
                    if !insights.isEmpty { insightsCard }
                    quickActions
                } else {
                    LoadingStateView()
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
        .navigationTitle(greeting)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSettings = true } label: {
                    Image(systemName: AppIcons.settings)
                }
                .accessibilityLabel("Settings")
            }
        }
        .navigationDestination(isPresented: $showSettings) { SettingsView() }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .water: AddWaterSheet().onDisappear { reload() }
            case .measurement: MeasurementEditorView(measurement: nil).onDisappear { reload() }
            case .goal: GoalEditorView(goal: nil).onDisappear { reload() }
            case .meal: NavigationStack { NutritionDayView() }
            }
        }
        .onAppear(perform: reload)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private func summaryCards(_ s: TodayDashboardSummary) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(DateUtils.string(s.date, DateUtils.dayMonth))
                .font(AppTypography.captionMedium)
                .foregroundStyle(AppColor.textSecondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                MetricCard(title: "Calories", value: NumberFormatterUtils.int(s.caloriesConsumed), subtitle: "of \(NumberFormatterUtils.int(s.caloriesGoal)) kcal", color: AppColor.accent, icon: AppIcons.calories)
                MetricCard(title: "Protein", value: "\(NumberFormatterUtils.int(s.proteinConsumed)) g", subtitle: "of \(NumberFormatterUtils.int(s.proteinGoal)) g", color: AppColor.protein, icon: AppIcons.protein)
            }
        }
    }

    private func workoutCard(_ s: TodayDashboardSummary) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Label("Today's Workout", systemImage: AppIcons.workouts)
                    .font(AppTypography.captionMedium).foregroundStyle(AppColor.textSecondary)
                if let title = s.plannedWorkoutTitle {
                    Text(title).font(AppTypography.title3).foregroundStyle(AppColor.textPrimary)
                    NavigationLink { WorkoutListView() } label: {
                        Text("Open Workouts").font(.headline).frame(maxWidth: .infinity).frame(minHeight: 44)
                            .background(AppColor.primary).foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }
                } else {
                    Text("No workout planned").font(AppTypography.body).foregroundStyle(AppColor.textMuted)
                    NavigationLink { WorkoutListView() } label: {
                        Text("Plan Workout").font(.headline).frame(maxWidth: .infinity).frame(minHeight: 44)
                            .background(AppColor.elevatedSurface).foregroundStyle(AppColor.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }
                }
            }
        }
    }

    private func nutritionCard(_ s: TodayDashboardSummary) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Label("Nutrition", systemImage: AppIcons.nutrition)
                    .font(AppTypography.captionMedium).foregroundStyle(AppColor.textSecondary)
                let remaining = max(s.caloriesGoal - s.caloriesConsumed, 0)
                HStack {
                    ProgressRing(progress: s.caloriesGoal > 0 ? s.caloriesConsumed / s.caloriesGoal : 0, color: AppColor.accent)
                        .frame(width: 56, height: 56)
                    VStack(alignment: .leading) {
                        Text("\(NumberFormatterUtils.int(remaining)) kcal remaining")
                            .font(AppTypography.bodyMedium).foregroundStyle(AppColor.textPrimary)
                        Text("Goal \(NumberFormatterUtils.int(s.caloriesGoal)) kcal")
                            .font(AppTypography.caption).foregroundStyle(AppColor.textMuted)
                    }
                    Spacer()
                }
            }
        }
    }

    private func waterCard(_ s: TodayDashboardSummary) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Label("Water", systemImage: AppIcons.water)
                    .font(AppTypography.captionMedium).foregroundStyle(AppColor.textSecondary)
                Text("\(s.waterConsumedMl) ml / \(s.waterGoalMl) ml")
                    .font(AppTypography.title3).foregroundStyle(AppColor.textPrimary)
                HStack {
                    quickWater(250)
                    quickWater(500)
                }
            }
        }
    }

    private func quickWater(_ ml: Int) -> some View {
        Button {
            try? environment.nutritionRepository.addHydration(amountMl: ml, date: .now)
            HapticsManager.light(); reload()
        } label: {
            Text("+\(ml) ml").font(.headline).frame(maxWidth: .infinity).frame(minHeight: 44)
                .background(AppColor.secondary.opacity(0.18)).foregroundStyle(AppColor.secondary)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
    }

    private func weeklyCard() -> some View {
        let week = (try? environment.workoutRepository.fetchSessions(from: AnalyticsPeriod.week.range().start, to: AnalyticsPeriod.week.range().end)) ?? []
        let completed = week.filter { $0.status == .completed }
        let minutes = completed.reduce(0) { $0 + $1.durationSeconds } / 60
        return AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Label("Weekly Progress", systemImage: "calendar.badge.clock")
                    .font(AppTypography.captionMedium).foregroundStyle(AppColor.textSecondary)
                HStack {
                    statItem("\(completed.count)", "Workouts")
                    statItem(NumberFormatterUtils.durationMinutes(minutes), "Training time")
                }
            }
        }
    }

    private func goalsCard(_ s: TodayDashboardSummary) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Label("Goals", systemImage: AppIcons.goals)
                    .font(AppTypography.captionMedium).foregroundStyle(AppColor.textSecondary)
                HStack {
                    statItem("\(s.activeGoalsCount)", "Active")
                    statItem("\(s.completedGoalsCount)", "Completed")
                }
                NavigationLink { GoalsView() } label: {
                    Text("View Goals").font(.subheadline).foregroundStyle(AppColor.primary)
                }
            }
        }
    }

    private func readingCard(_ s: TodayDashboardSummary) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Label("Currently Reading", systemImage: AppIcons.library)
                    .font(AppTypography.captionMedium).foregroundStyle(AppColor.textSecondary)
                if let title = s.currentReadingBookTitle {
                    Text(title).font(AppTypography.bodyMedium).foregroundStyle(AppColor.textPrimary)
                } else {
                    Text("No book in progress").font(AppTypography.body).foregroundStyle(AppColor.textMuted)
                }
            }
        }
    }

    private var insightsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Label("Insights", systemImage: "lightbulb.fill")
                    .font(AppTypography.captionMedium).foregroundStyle(AppColor.textSecondary)
                ForEach(insights, id: \.self) { insight in
                    Text("• \(insight)").font(AppTypography.body).foregroundStyle(AppColor.textPrimary)
                }
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(title: "Quick Actions")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                NavigationLink { WorkoutListView() } label: { actionTile("Add Workout", AppIcons.workouts) }
                Button { activeSheet = .meal } label: { actionTile("Add Meal", AppIcons.nutrition) }
                Button { activeSheet = .water } label: { actionTile("Add Water", AppIcons.water) }
                Button { activeSheet = .measurement } label: { actionTile("Add Measurement", AppIcons.body) }
                Button { activeSheet = .goal } label: { actionTile("Add Goal", AppIcons.goals) }
                NavigationLink { LibrarySearchView() } label: { actionTile("Search Book", AppIcons.search) }
            }
        }
    }

    private func actionTile(_ title: String, _ icon: String) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon).font(.title2).foregroundStyle(AppColor.primary)
            Text(title).font(AppTypography.caption).foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    private func statItem(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading) {
            Text(value).font(AppTypography.title3).foregroundStyle(AppColor.textPrimary)
            Text(label).font(AppTypography.caption).foregroundStyle(AppColor.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func reload() {
        summary = try? environment.analyticsService.todaySummary(profile: environment.currentProfile())
        insights = (try? environment.analyticsService.localInsights()) ?? []
    }
}
