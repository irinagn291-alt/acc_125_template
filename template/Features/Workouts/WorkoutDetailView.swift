import SwiftUI

struct WorkoutDetailView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    let workout: Workout

    @State private var showEditor = false
    @State private var showExecution = false
    @State private var showAddToCalendar = false
    @State private var confirmDelete = false
    @State private var recentSessions: [WorkoutSession] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                header
                if let desc = workout.workoutDescription, !desc.isEmpty {
                    AppCard { Text(desc).font(AppTypography.body).foregroundStyle(AppColor.textSecondary) }
                }
                infoCard
                exercisesCard
                recentCard
                actions
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
        .navigationTitle(workout.title)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showExecution, onDismiss: reload) {
            WorkoutExecutionView(workout: workout)
        }
        .sheet(isPresented: $showEditor) { WorkoutEditorView(workout: workout) }
        .sheet(isPresented: $showAddToCalendar) { EventEditorView(event: nil, defaultDate: .now) }
        .confirmationDialog("Delete Workout?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Workout", role: .destructive) {
                try? environment.workoutRepository.deleteWorkout(workout); dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear(perform: reload)
    }

    private var header: some View {
        HStack {
            Image(systemName: workout.type.icon).font(.largeTitle).foregroundStyle(AppColor.primary)
            VStack(alignment: .leading) {
                Text(workout.type.displayName).font(AppTypography.title3).foregroundStyle(AppColor.textPrimary)
                StatusTag(text: workout.difficulty.displayName, color: AppColor.secondary)
            }
            Spacer()
        }
    }

    private var infoCard: some View {
        AppCard {
            HStack {
                infoItem("\(workout.estimatedDurationMinutes)", "Minutes")
                infoItem("\(workout.exercises.count)", "Exercises")
                infoItem(workout.goal ?? "—", "Goal")
            }
        }
    }

    private var exercisesCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SectionHeader(title: "Exercises")
                if workout.exercises.isEmpty {
                    Text("No exercises").foregroundStyle(AppColor.textMuted)
                }
                ForEach(workout.sortedExercises) { ex in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ex.name).font(AppTypography.bodyMedium).foregroundStyle(AppColor.textPrimary)
                        Text(detail(ex)).font(AppTypography.caption).foregroundStyle(AppColor.textMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func detail(_ ex: WorkoutExercise) -> String {
        var parts = ["\(ex.muscleGroup.displayName)", "\(ex.sets) sets"]
        if let reps = ex.reps { parts.append("\(reps) reps") }
        if let w = ex.weightKg { parts.append("\(NumberFormatterUtils.decimal(w)) kg") }
        return parts.joined(separator: " • ")
    }

    private var recentCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SectionHeader(title: "Recent Sessions")
                if recentSessions.isEmpty {
                    Text("No sessions yet").foregroundStyle(AppColor.textMuted)
                }
                ForEach(recentSessions.prefix(5)) { s in
                    HStack {
                        Text(DateUtils.string(s.startedAt, DateUtils.shortDay)).foregroundStyle(AppColor.textPrimary)
                        Spacer()
                        Text(NumberFormatterUtils.durationMinutes(s.durationSeconds / 60)).foregroundStyle(AppColor.textMuted)
                        Text("vol \(NumberFormatterUtils.int(s.totalVolume))").font(.caption).foregroundStyle(AppColor.textMuted)
                    }
                    .font(AppTypography.body)
                }
            }
        }
    }

    private var actions: some View {
        VStack(spacing: AppSpacing.sm) {
            PrimaryButton(title: "Start Workout", systemImage: "play.fill") { showExecution = true }
            HStack(spacing: AppSpacing.sm) {
                SecondaryButton(title: "Edit", systemImage: AppIcons.edit) { showEditor = true }
                SecondaryButton(title: "Add to Calendar", systemImage: AppIcons.calendar) { showAddToCalendar = true }
            }
            Button(role: .destructive) { confirmDelete = true } label: {
                Label("Delete Workout", systemImage: AppIcons.delete).frame(maxWidth: .infinity).frame(minHeight: 44)
            }
            .foregroundStyle(AppColor.danger)
        }
    }

    private func infoItem(_ value: String, _ label: String) -> some View {
        VStack {
            Text(value).font(AppTypography.title3).foregroundStyle(AppColor.textPrimary).lineLimit(1).minimumScaleFactor(0.6)
            Text(label).font(AppTypography.caption).foregroundStyle(AppColor.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private func reload() {
        let all = (try? environment.workoutRepository.fetchAllSessions()) ?? []
        recentSessions = all.filter { $0.workoutId == workout.id }
    }
}
