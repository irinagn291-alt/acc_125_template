import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject private var environment: AppEnvironment

    enum Tab: String, CaseIterable, Identifiable {
        case overview = "Overview", workouts = "Workouts", nutrition = "Nutrition", body = "Body", goals = "Goals", reading = "Reading"
        var id: String { rawValue }
    }

    @State private var tab: Tab = .overview
    @State private var period: AnalyticsPeriod = .month

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                Picker("Period", selection: $period) { ForEach(AnalyticsPeriod.allCases) { Text($0.displayName).tag($0) } }
                    .pickerStyle(.segmented)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Tab.allCases) { t in
                            Button { tab = t } label: {
                                Text(t.rawValue).font(AppTypography.captionMedium)
                                    .padding(.horizontal, AppSpacing.sm).padding(.vertical, AppSpacing.xs)
                                    .background(tab == t ? AppColor.primary : AppColor.surface)
                                    .foregroundStyle(tab == t ? .black : AppColor.textSecondary).clipShape(Capsule())
                            }
                        }
                    }
                }
                content
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
        .navigationTitle("Analytics")
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .overview: overview
        case .workouts: workouts
        case .nutrition: nutrition
        case .body: bodyTab
        case .goals: goals
        case .reading: reading
        }
    }

    private func grid<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm, content: content)
    }

    private var overview: some View {
        let w = (try? environment.analyticsService.workoutSummary(period: period))
        let g = (try? environment.analyticsService.goalSummary())
        let r = (try? environment.analyticsService.readingSummary(period: period))
        let b = (try? environment.analyticsService.bodySummary(period: period))
        return grid {
            MetricCard(title: "Workouts", value: "\(w?.sessionsCount ?? 0)", color: AppColor.primary, icon: AppIcons.workouts)
            MetricCard(title: "Training Time", value: NumberFormatterUtils.durationMinutes(w?.totalDurationMinutes ?? 0), color: AppColor.secondary, icon: "clock.fill")
            MetricCard(title: "Volume", value: NumberFormatterUtils.int(w?.totalVolume ?? 0), color: AppColor.info, icon: "scalemass")
            MetricCard(title: "Goals Done", value: "\(g?.completedGoalsCount ?? 0)", color: AppColor.success, icon: AppIcons.goals)
            MetricCard(title: "Books Done", value: "\(r?.completedBooksCount ?? 0)", color: AppColor.accent, icon: AppIcons.library)
            MetricCard(title: "Weight", value: b?.currentWeightKg.map { "\(NumberFormatterUtils.decimal($0)) kg" } ?? "—", color: AppColor.warning, icon: AppIcons.body)
        }
    }

    private var workouts: some View {
        let summary = try? environment.analyticsService.workoutSummary(period: period)
        let perDay = (try? environment.analyticsService.workoutsPerDay(period: period)) ?? []
        let volume = (try? environment.analyticsService.volumePoints(period: period)) ?? []
        return VStack(spacing: AppSpacing.md) {
            if let summary, summary.sessionsCount == 0 {
                EmptyStateView(systemImage: AppIcons.workouts, title: "No analytics yet", message: "Add workouts to see your progress.")
            } else {
                grid {
                    MetricCard(title: "Sessions", value: "\(summary?.sessionsCount ?? 0)", color: AppColor.primary, icon: AppIcons.workouts)
                    MetricCard(title: "Avg Duration", value: "\(Int(summary?.averageDurationMinutes ?? 0)) min", color: AppColor.secondary, icon: "clock")
                    MetricCard(title: "Completion", value: "\(Int((summary?.completionRate ?? 0) * 100))%", color: AppColor.success, icon: "checkmark")
                    MetricCard(title: "Avg RPE", value: summary?.averageRPE.map { NumberFormatterUtils.decimal($0) } ?? "—", color: AppColor.accent, icon: "gauge")
                }
                chartCard("Workouts per Week") {
                    Chart(perDay) { BarMark(x: .value("Date", $0.date, unit: .day), y: .value("Count", $0.count)).foregroundStyle(AppColor.primary) }
                }
                chartCard("Training Volume") {
                    Chart(volume) { LineMark(x: .value("Date", $0.date), y: .value("Volume", $0.volume)).foregroundStyle(AppColor.info) }
                }
            }
        }
    }

    private var nutrition: some View {
        let goal = environment.currentProfile()?.dailyCaloriesGoal ?? 2200
        let summary = try? environment.analyticsService.nutritionSummary(period: period, caloriesGoal: goal)
        let points = (try? environment.analyticsService.caloriesPoints(period: period, goal: goal)) ?? []
        return VStack(spacing: AppSpacing.md) {
            if points.isEmpty {
                EmptyStateView(systemImage: AppIcons.nutrition, title: "No analytics yet", message: "Add meals to see nutrition trends.")
            } else {
                grid {
                    MetricCard(title: "Avg Calories", value: NumberFormatterUtils.int(summary?.averageCalories ?? 0), color: AppColor.accent, icon: AppIcons.calories)
                    MetricCard(title: "Avg Protein", value: "\(NumberFormatterUtils.int(summary?.averageProtein ?? 0)) g", color: AppColor.protein, icon: AppIcons.protein)
                    MetricCard(title: "Avg Fat", value: "\(NumberFormatterUtils.int(summary?.averageFat ?? 0)) g", color: AppColor.fat, icon: AppIcons.fat)
                    MetricCard(title: "Target Hit", value: "\(Int((summary?.targetHitRate ?? 0) * 100))%", color: AppColor.success, icon: "target")
                }
                chartCard("Calories vs Goal") {
                    Chart(points) {
                        BarMark(x: .value("Date", $0.date, unit: .day), y: .value("Calories", $0.calories)).foregroundStyle(AppColor.accent)
                        RuleMark(y: .value("Goal", goal)).foregroundStyle(AppColor.textMuted).lineStyle(StrokeStyle(dash: [5]))
                    }
                }
            }
        }
    }

    private var bodyTab: some View {
        let summary = try? environment.analyticsService.bodySummary(period: period)
        let points = (try? environment.analyticsService.weightPoints(period: period)) ?? []
        return VStack(spacing: AppSpacing.md) {
            grid {
                MetricCard(title: "Current Weight", value: summary?.currentWeightKg.map { "\(NumberFormatterUtils.decimal($0)) kg" } ?? "—", color: AppColor.primary, icon: AppIcons.body)
                MetricCard(title: "Weight Change", value: summary?.weightChangeKg.map { "\(NumberFormatterUtils.decimal($0)) kg" } ?? "—", color: AppColor.secondary, icon: "arrow.up.arrow.down")
            }
            if points.count >= 2 {
                chartCard("Weight Trend") {
                    Chart(points) { LineMark(x: .value("Date", $0.date), y: .value("Weight", $0.weightKg)).foregroundStyle(AppColor.primary) }
                }
            } else {
                EmptyStateView(systemImage: AppIcons.body, title: "No analytics yet", message: "Add body measurements to see trends.")
            }
        }
    }

    private var goals: some View {
        let summary = try? environment.analyticsService.goalSummary()
        return grid {
            MetricCard(title: "Active", value: "\(summary?.activeGoalsCount ?? 0)", color: AppColor.primary, icon: AppIcons.goals)
            MetricCard(title: "Completed", value: "\(summary?.completedGoalsCount ?? 0)", color: AppColor.success, icon: "checkmark.circle")
            MetricCard(title: "Overdue", value: "\(summary?.overdueGoalsCount ?? 0)", color: AppColor.danger, icon: "exclamationmark")
            MetricCard(title: "Avg Progress", value: "\(Int((summary?.averageProgress ?? 0) * 100))%", color: AppColor.secondary, icon: "chart.bar")
        }
    }

    private var reading: some View {
        let summary = try? environment.analyticsService.readingSummary(period: period)
        return grid {
            MetricCard(title: "Saved Books", value: "\(summary?.savedBooksCount ?? 0)", color: AppColor.primary, icon: AppIcons.library)
            MetricCard(title: "Reading", value: "\(summary?.currentlyReadingCount ?? 0)", color: AppColor.secondary, icon: "book")
            MetricCard(title: "Completed", value: "\(summary?.completedBooksCount ?? 0)", color: AppColor.success, icon: "checkmark.circle")
            MetricCard(title: "Reading Time", value: NumberFormatterUtils.durationMinutes(summary?.totalReadingMinutes ?? 0), color: AppColor.accent, icon: "clock")
        }
    }

    private func chartCard<C: View>(_ title: String, @ViewBuilder _ chart: () -> C) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SectionHeader(title: title)
                chart().frame(height: 180)
            }
        }
    }
}
