import SwiftUI

struct MacroMotionTodayView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var network: NetworkMonitor

    @State private var summary: TodayDashboardSummary?
    @State private var activeSheet: HomeSheet?

    enum HomeSheet: Identifiable {
        case water, meal
        var id: Int { hashValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                if !network.isConnected { OfflineBanner() }
                if let summary {
                    nutritionHero(summary)
                    movementStrip(summary)
                    knowledgeCard(summary)
                } else {
                    LoadingStateView()
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
        .navigationTitle("MacroMotion")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { secondaryMenu }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .water: AddWaterSheet().onDisappear { reload() }
            case .meal: NavigationStack { NutritionDayView() }
            }
        }
        .onAppear(perform: reload)
    }

    private var secondaryMenu: some View {
        Menu {
            NavigationLink { CalendarView() } label: { Label("Calendar", systemImage: AppIcons.calendar) }
            NavigationLink { ProgramsListView() } label: { Label("Programs", systemImage: AppIcons.programs) }
            NavigationLink { BodyMeasurementsView() } label: { Label("Body", systemImage: AppIcons.body) }
            NavigationLink { GoalsView() } label: { Label("Goals", systemImage: AppIcons.goals) }
            NavigationLink { SettingsView() } label: { Label("Settings", systemImage: AppIcons.settings) }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }

    private func nutritionHero(_ s: TodayDashboardSummary) -> some View {
        AppCard {
            VStack(spacing: AppSpacing.md) {
                HStack {
                    ZStack {
                        ProgressRing(progress: s.caloriesGoal > 0 ? s.caloriesConsumed / s.caloriesGoal : 0, lineWidth: 12, color: AppColor.primary)
                            .frame(width: 120, height: 120)
                        VStack(spacing: 0) {
                            Text(NumberFormatterUtils.int(s.caloriesConsumed))
                                .font(AppTypography.metric).foregroundStyle(AppColor.textPrimary)
                            Text("of \(NumberFormatterUtils.int(s.caloriesGoal)) kcal")
                                .font(AppTypography.caption).foregroundStyle(AppColor.textMuted)
                        }
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        macroRow("Protein", "\(NumberFormatterUtils.int(s.proteinConsumed)) / \(NumberFormatterUtils.int(s.proteinGoal)) g", AppColor.protein)
                        macroRow("Water", "\(s.waterConsumedMl) / \(s.waterGoalMl) ml", AppColor.info)
                    }
                }
                HStack(spacing: AppSpacing.sm) {
                    Button { activeSheet = .meal } label: {
                        heroButton("Add Meal", AppIcons.nutrition, AppColor.primary)
                    }
                    Button { activeSheet = .water } label: {
                        heroButton("Add Water", AppIcons.water, AppColor.secondary)
                    }
                }
            }
        }
    }

    private func macroRow(_ title: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Circle().fill(color).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(AppTypography.caption).foregroundStyle(AppColor.textMuted)
                Text(value).font(AppTypography.bodyMedium).foregroundStyle(AppColor.textPrimary)
            }
        }
    }

    private func heroButton(_ title: String, _ icon: String, _ color: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity).frame(minHeight: 44)
            .background(color.opacity(0.2)).foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    private func movementStrip(_ s: TodayDashboardSummary) -> some View {
        let week = (try? environment.workoutRepository.fetchSessions(from: AnalyticsPeriod.week.range().start, to: AnalyticsPeriod.week.range().end)) ?? []
        let completed = week.filter { $0.status == .completed }
        let minutes = completed.reduce(0) { $0 + $1.durationSeconds } / 60
        return AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Label("Movement", systemImage: AppIcons.workouts)
                    .font(AppTypography.captionMedium).foregroundStyle(AppColor.textSecondary)
                HStack {
                    statItem(s.plannedWorkoutTitle == nil ? "Rest" : "Planned", "Today")
                    statItem("\(completed.count)", "Sessions")
                    statItem(NumberFormatterUtils.durationMinutes(minutes), "Minutes")
                }
                NavigationLink { WorkoutListView() } label: {
                    Text("Open Training").font(.subheadline).foregroundStyle(AppColor.primary)
                }
            }
        }
    }

    private func knowledgeCard(_ s: TodayDashboardSummary) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Label("Reading", systemImage: AppIcons.library)
                    .font(AppTypography.captionMedium).foregroundStyle(AppColor.textSecondary)
                Text(s.currentReadingBookTitle ?? "No book in progress")
                    .font(AppTypography.bodyMedium).foregroundStyle(AppColor.textPrimary)
            }
        }
    }

    private func statItem(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading) {
            Text(value).font(AppTypography.title3).foregroundStyle(AppColor.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(label).font(AppTypography.caption).foregroundStyle(AppColor.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func reload() {
        summary = try? environment.analyticsService.todaySummary(profile: environment.currentProfile())
    }
}
