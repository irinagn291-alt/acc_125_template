import SwiftUI

struct ProgramDetailView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    let program: TrainingProgram

    @State private var workouts: [Workout] = []
    @State private var refreshToken = UUID()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                header
                progressCard
                weeksSection
                actions
            }
            .padding(AppSpacing.md)
            .id(refreshToken)
        }
        .background(AppColor.background)
        .navigationTitle(program.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { workouts = (try? environment.workoutRepository.fetchWorkouts()) ?? [] }
    }

    private var header: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(program.goal).font(AppTypography.title3).foregroundStyle(AppColor.textPrimary)
                if let d = program.programDescription, !d.isEmpty {
                    Text(d).font(AppTypography.body).foregroundStyle(AppColor.textSecondary)
                }
                HStack { StatusTag(text: program.status.displayName, color: AppColor.success); StatusTag(text: program.difficulty.displayName, color: AppColor.secondary) }
            }
        }
    }

    private var progressCard: some View {
        let p = ProgramProgressCalculator.progress(program)
        return AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SectionHeader(title: "Progress")
                ProgressView(value: p.fraction).tint(AppColor.primary)
                Text("\(p.completedDays) / \(p.totalDays) days completed").font(AppTypography.caption).foregroundStyle(AppColor.textMuted)
            }
        }
    }

    private var weeksSection: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(program.sortedWeeks) { week in
                AppCard {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(week.title).font(AppTypography.bodyMedium).foregroundStyle(AppColor.textPrimary)
                        ForEach(week.sortedDays) { day in dayRow(day) }
                    }
                }
            }
        }
    }

    private func dayRow(_ day: ProgramDay) -> some View {
        let assigned = workouts.first { $0.id == day.plannedWorkoutId }
        return HStack {
            Button {
                day.isCompleted.toggle()
                try? environment.programRepository.saveProgram(program)
                refreshToken = UUID()
            } label: {
                Image(systemName: day.isCompleted ? "checkmark.circle.fill" : "circle").foregroundStyle(day.isCompleted ? AppColor.success : AppColor.textMuted)
            }
            .frame(width: 44, height: 44)
            VStack(alignment: .leading) {
                Text(day.title).foregroundStyle(AppColor.textPrimary)
                Text(assigned?.title ?? "No workout assigned").font(.caption).foregroundStyle(AppColor.textMuted)
            }
            Spacer()
            Menu {
                Button("None") { day.plannedWorkoutId = nil; try? environment.programRepository.saveProgram(program); refreshToken = UUID() }
                ForEach(workouts) { w in
                    Button(w.title) { day.plannedWorkoutId = w.id; try? environment.programRepository.saveProgram(program); refreshToken = UUID() }
                }
            } label: { Image(systemName: "dumbbell.fill").foregroundStyle(AppColor.primary) }
        }
    }

    private var actions: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                SecondaryButton(title: "Mark Active") { setStatus(.active) }
                SecondaryButton(title: "Pause") { setStatus(.paused) }
            }
            HStack(spacing: AppSpacing.sm) {
                SecondaryButton(title: "Complete") { setStatus(.completed) }
                SecondaryButton(title: "Add to Calendar", systemImage: AppIcons.calendar) { addToCalendar() }
            }
            Button(role: .destructive) {
                try? environment.programRepository.deleteProgram(program); dismiss()
            } label: { Label("Delete Program", systemImage: AppIcons.delete).frame(maxWidth: .infinity).frame(minHeight: 44) }
                .foregroundStyle(AppColor.danger)
        }
    }

    private func setStatus(_ s: ProgramStatus) {
        program.status = s
        try? environment.programRepository.saveProgram(program)
        refreshToken = UUID()
        HapticsManager.success()
    }

    private func addToCalendar() {
        guard let start = program.startDate else { return }
        for week in program.sortedWeeks {
            for day in week.sortedDays where day.plannedWorkoutId != nil {
                let offset = (week.weekIndex - 1) * 7 + (day.dayIndex - 1)
                let date = Calendar.current.date(byAdding: .day, value: offset, to: start) ?? start
                let event = CalendarEvent(title: day.title, eventType: .workout, startDate: date, relatedEntityId: day.plannedWorkoutId)
                try? environment.calendarRepository.saveEvent(event)
            }
        }
        HapticsManager.success()
    }
}
