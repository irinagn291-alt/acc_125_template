import SwiftUI

struct SolarStrideDashboardView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var network: NetworkMonitor

    @State private var summary: TodayDashboardSummary?

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                if !network.isConnected { OfflineBanner() }
                if let summary {
                    solarHeader()
                    solarIndexCard(summary)
                    orbitActions
                    todayFocusCard(summary)
                    energyLanes(summary)
                    solarStreak
                    insightRow(summary)
                } else {
                    LoadingStateView()
                }
            }
            .padding(AppSpacing.md)
            .padding(.bottom, AppSpacing.xl)
        }
        .background {
            ZStack {
                AppColor.background
                RadialGradient(
                    colors: [AppColor.primary.opacity(0.14), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 320
                )
            }
            .ignoresSafeArea()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "sun.max.fill")
                        .foregroundStyle(AppColor.primary)
                    Text("SolarStride")
                        .font(AppTypography.title3)
                        .foregroundStyle(AppColor.textPrimary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) { secondaryMenu }
        }
        .onAppear(perform: reload)
    }

    private var secondaryMenu: some View {
        Menu {
            NavigationLink { CalendarView() } label: { Label("Calendar", systemImage: AppIcons.calendar) }
            NavigationLink { AnalyticsView() } label: { Label("Analytics", systemImage: AppIcons.analytics) }
            NavigationLink { BodyMeasurementsView() } label: { Label("Body", systemImage: AppIcons.body) }
            NavigationLink { GoalsView() } label: { Label("Goals", systemImage: AppIcons.goals) }
            NavigationLink { SettingsView() } label: { Label("Settings", systemImage: AppIcons.settings) }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundStyle(AppColor.primary)
        }
    }

    private func solarHeader() -> some View {
        let name = environment.currentProfile()?.name ?? "Athlete"
        return VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(greeting)
                .font(AppTypography.captionMedium)
                .foregroundStyle(AppColor.secondary)
            Text(name)
                .font(AppTypography.largeTitle)
                .foregroundStyle(AppColor.textPrimary)
            Text(DateUtils.string(.now, DateUtils.dayMonth))
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Night Session"
        }
    }

    private func solarIndexCard(_ s: TodayDashboardSummary) -> some View {
        let index = solarIndex(for: s)
        return HStack(spacing: AppSpacing.lg) {
            ZStack {
                Circle()
                    .stroke(AppColor.primary.opacity(0.15), lineWidth: 14)
                    .frame(width: 108, height: 108)
                Circle()
                    .trim(from: 0, to: index)
                    .stroke(
                        AngularGradient(
                            colors: [AppColor.secondary, AppColor.primary, AppColor.accent, AppColor.secondary],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 108, height: 108)
                VStack(spacing: 0) {
                    Text("\(Int(index * 100))")
                        .font(AppTypography.metric)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("INDEX")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textMuted)
                }
            }
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Solar Index")
                    .font(AppTypography.title3)
                    .foregroundStyle(AppColor.textPrimary)
                Text("Your daily balance of training, fuel, and hydration.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: AppSpacing.xs) {
                    indexPill("Train", s.completedWorkoutsCount > 0 ? 1 : 0, AppColor.accent)
                    indexPill("Fuel", progress(s.caloriesConsumed, s.caloriesGoal), AppColor.primary)
                    indexPill("Water", progress(Double(s.waterConsumedMl), Double(s.waterGoalMl)), AppColor.secondary)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .stroke(AppColor.primary.opacity(0.2), lineWidth: 1)
        )
    }

    private func indexPill(_ label: String, _ value: Double, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Capsule()
                .fill(color.opacity(0.25))
                .frame(width: 36, height: 4)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(color)
                        .frame(width: 36 * min(max(value, 0), 1))
                }
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColor.textMuted)
        }
    }

    private var orbitActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.md) {
                orbitLink("Train", AppIcons.workouts, AppColor.accent) { WorkoutListView() }
                orbitLink("Programs", AppIcons.programs, AppColor.secondary) { ProgramsListView() }
                orbitLink("Fuel", AppIcons.nutrition, AppColor.primary) { NutritionDayView() }
                orbitLink("Body", AppIcons.body, AppColor.secondary) { BodyMeasurementsView() }
                orbitLink("Library", AppIcons.library, AppColor.primary) { LibraryView() }
                orbitLink("Goals", AppIcons.goals, AppColor.accent) { GoalsView() }
            }
            .padding(.horizontal, 2)
        }
    }

    private func orbitLink<Destination: View>(
        _ title: String,
        _ icon: String,
        _ color: Color,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink(destination: destination) {
            VStack(spacing: AppSpacing.xs) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.18))
                        .frame(width: 58, height: 58)
                    Circle()
                        .stroke(color.opacity(0.45), lineWidth: 1.5)
                        .frame(width: 58, height: 58)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(color)
                }
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .frame(width: 72)
        }
        .buttonStyle(.plain)
    }

    private func todayFocusCard(_ s: TodayDashboardSummary) -> some View {
        NavigationLink { WorkoutListView() } label: {
            HStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("TODAY'S FOCUS")
                        .font(AppTypography.captionMedium)
                        .foregroundStyle(AppColor.onPrimary.opacity(0.75))
                    Text(s.plannedWorkoutTitle ?? "Build your session")
                        .font(AppTypography.title2)
                        .foregroundStyle(AppColor.onPrimary)
                        .multilineTextAlignment(.leading)
                    Text(s.completedWorkoutsCount > 0 ? "Session completed — great work!" : "Tap to start training")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.onPrimary.opacity(0.7))
                }
                Spacer(minLength: 0)
                Image(systemName: s.completedWorkoutsCount > 0 ? "checkmark.seal.fill" : AppIcons.workouts)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(AppColor.onPrimary.opacity(0.9))
            }
            .padding(AppSpacing.lg)
            .background(
                LinearGradient(
                    colors: [AppColor.secondary, AppColor.primary, AppColor.accent.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func energyLanes(_ s: TodayDashboardSummary) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Energy Lanes")
                .font(AppTypography.title3)
                .foregroundStyle(AppColor.textPrimary)
            energyLane("Calories", "\(NumberFormatterUtils.int(s.caloriesConsumed)) / \(NumberFormatterUtils.int(s.caloriesGoal)) kcal", progress(s.caloriesConsumed, s.caloriesGoal), AppColor.primary)
            energyLane("Protein", "\(NumberFormatterUtils.int(s.proteinConsumed)) / \(NumberFormatterUtils.int(s.proteinGoal)) g", progress(s.proteinConsumed, s.proteinGoal), AppColor.protein)
            energyLane("Water", "\(s.waterConsumedMl) / \(s.waterGoalMl) ml", progress(Double(s.waterConsumedMl), Double(s.waterGoalMl)), AppColor.secondary)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
    }

    private func energyLane(_ title: String, _ value: String, _ amount: Double, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            HStack {
                Text(title)
                    .font(AppTypography.captionMedium)
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
                Text(value)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textMuted)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.15))
                    Capsule()
                        .fill(LinearGradient(colors: [color.opacity(0.7), color], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * min(max(amount, 0), 1))
                }
            }
            .frame(height: 8)
        }
    }

    private var solarStreak: some View {
        let days = weekMomentum()
        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Solar Streak")
                    .font(AppTypography.title3)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                Text("\(days.filter(\.active).count)/7")
                    .font(AppTypography.captionMedium)
                    .foregroundStyle(AppColor.primary)
            }
            HStack(spacing: AppSpacing.xs) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: AppSpacing.xxs) {
                        Image(systemName: day.active ? "sun.max.fill" : "sun.haze")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(day.active ? AppColor.primary : AppColor.textMuted.opacity(0.4))
                            .frame(height: 24)
                        Text(day.label)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(day.isToday ? AppColor.secondary : AppColor.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xs)
                    .background(day.isToday ? AppColor.primary.opacity(0.1) : .clear)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
    }

    private func insightRow(_ s: TodayDashboardSummary) -> some View {
        HStack(spacing: AppSpacing.sm) {
            NavigationLink { GoalsView() } label: {
                insightChip(
                    title: "Goals",
                    value: "\(s.activeGoalsCount) active",
                    icon: AppIcons.goals,
                    color: AppColor.accent
                )
            }
            NavigationLink { LibraryView() } label: {
                insightChip(
                    title: "Reading",
                    value: s.currentReadingBookTitle ?? "Open shelf",
                    icon: AppIcons.library,
                    color: AppColor.secondary
                )
            }
        }
        .buttonStyle(.plain)
    }

    private func insightChip(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(AppTypography.captionMedium)
                .foregroundStyle(AppColor.textSecondary)
            Text(value)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColor.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
    }

    private func solarIndex(for s: TodayDashboardSummary) -> Double {
        let train = s.completedWorkoutsCount > 0 ? 1.0 : 0.0
        let fuel = progress(s.caloriesConsumed, s.caloriesGoal)
        let water = progress(Double(s.waterConsumedMl), Double(s.waterGoalMl))
        return (train + fuel + water) / 3
    }

    private func progress(_ current: Double, _ goal: Double) -> Double {
        guard goal > 0 else { return 0 }
        return min(current / goal, 1)
    }

    private func weekMomentum() -> [(label: String, active: Bool, isToday: Bool)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        guard let start = calendar.date(byAdding: .day, value: -6, to: today),
              let end = calendar.date(byAdding: .day, value: 1, to: today) else { return [] }
        let sessions = (try? environment.workoutRepository.fetchSessions(from: start, to: end)) ?? []
        let activeDays = Set(
            sessions
                .filter { $0.status == .completed }
                .map { calendar.startOfDay(for: $0.startedAt) }
        )
        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset - 6, to: today) ?? today
            let weekday = calendar.component(.weekday, from: day) - 1
            let label = String(calendar.shortWeekdaySymbols[weekday].prefix(1))
            return (label, activeDays.contains(day), calendar.isDate(day, inSameDayAs: today))
        }
    }

    private func reload() {
        summary = try? environment.analyticsService.todaySummary(profile: environment.currentProfile())
    }
}
