import SwiftUI

@MainActor
final class WorkoutExecutionViewModel: ObservableObject {
    struct ExerciseBlock: Identifiable {
        let id = UUID()
        let name: String
        let muscleGroup: MuscleGroup
        var sets: [PerformedSet]
    }

    @Published var blocks: [ExerciseBlock] = []
    @Published var currentIndex = 0
    @Published var elapsed = 0
    @Published var restRemaining = 0

    let workout: Workout
    let startedAt = Date.now
    private var timer: Timer?

    init(workout: Workout) {
        self.workout = workout
        blocks = workout.sortedExercises.map { ex in
            let sets = (0..<max(ex.sets, 1)).map { i in
                PerformedSet(exerciseName: ex.name, muscleGroup: ex.muscleGroup, setIndex: i, reps: ex.reps, weightKg: ex.weightKg, durationSeconds: ex.durationSeconds, distanceMeters: ex.distanceMeters, rpe: ex.rpe)
            }
            return ExerciseBlock(name: ex.name, muscleGroup: ex.muscleGroup, sets: sets)
        }
    }

    var current: ExerciseBlock? { blocks.indices.contains(currentIndex) ? blocks[currentIndex] : nil }
    var completedSetsCount: Int { blocks.flatMap { $0.sets }.filter { $0.isCompleted }.count }
    var totalVolume: Double { blocks.flatMap { $0.sets }.filter { $0.isCompleted }.reduce(0) { $0 + WorkoutVolumeCalculator.volume(for: $1) } }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.elapsed += 1
                if self.restRemaining > 0 { self.restRemaining -= 1 }
            }
        }
    }
    func stop() { timer?.invalidate(); timer = nil }

    func toggle(blockIndex: Int, setIndex: Int, restSeconds: Int) {
        guard blocks.indices.contains(blockIndex), blocks[blockIndex].sets.indices.contains(setIndex) else { return }
        let set = blocks[blockIndex].sets[setIndex]
        set.isCompleted.toggle()
        set.completedAt = set.isCompleted ? .now : nil
        if set.isCompleted { restRemaining = restSeconds; HapticsManager.light() }
        objectWillChange.send()
    }

    func buildSession() -> WorkoutSession {
        let session = WorkoutSession(workoutId: workout.id, workoutTitle: workout.title, startedAt: startedAt)
        session.endedAt = .now
        session.durationSeconds = elapsed
        session.status = .completed
        session.performedSets = blocks.flatMap { $0.sets }
        let completed = session.performedSets.filter { $0.isCompleted }
        session.completedSetsCount = completed.count
        session.completedExercisesCount = Set(completed.map { $0.exerciseName }).count
        session.totalVolume = completed.reduce(0) { $0 + WorkoutVolumeCalculator.volume(for: $1) }
        return session
    }
}

struct WorkoutExecutionView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: WorkoutExecutionViewModel

    @State private var showExitDialog = false
    @State private var summary: WorkoutSession?
    @State private var sessionNotes = ""

    init(workout: Workout) {
        _vm = StateObject(wrappedValue: WorkoutExecutionViewModel(workout: workout))
    }

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            if let summary {
                summaryView(summary)
            } else {
                executionView
            }
        }
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
        .confirmationDialog("Exit Workout?", isPresented: $showExitDialog, titleVisibility: .visible) {
            Button("Save and Exit") { saveSession(); dismiss() }
            Button("Discard Workout", role: .destructive) { dismiss() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var executionView: some View {
        VStack(spacing: 0) {
            HStack {
                Button { showExitDialog = true } label: { Image(systemName: "xmark").font(.title3) }
                    .accessibilityLabel("Close")
                Spacer()
                Text(vm.workout.title).font(AppTypography.bodyMedium).foregroundStyle(AppColor.textPrimary)
                Spacer()
                Text(NumberFormatterUtils.duration(seconds: vm.elapsed)).font(AppTypography.title3.monospacedDigit()).foregroundStyle(AppColor.primary)
            }
            .padding(AppSpacing.md)

            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    if let block = vm.current {
                        currentExerciseCard(block)
                    }
                    if vm.restRemaining > 0 { restCard }
                }
                .padding(AppSpacing.md)
            }

            navBar
        }
    }

    private func currentExerciseCard(_ block: WorkoutExecutionViewModel.ExerciseBlock) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Exercise \(vm.currentIndex + 1) of \(vm.blocks.count)").font(AppTypography.caption).foregroundStyle(AppColor.textMuted)
                Text(block.name).font(AppTypography.title2).foregroundStyle(AppColor.textPrimary)
                Text(block.muscleGroup.displayName).font(AppTypography.caption).foregroundStyle(AppColor.textSecondary)
                Divider().overlay(AppColor.textMuted)
                ForEach(Array(block.sets.enumerated()), id: \.element.id) { idx, set in
                    setRow(blockIndex: vm.currentIndex, setIndex: idx, set: set)
                }
            }
        }
    }

    private func setRow(blockIndex: Int, setIndex: Int, set: PerformedSet) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Text("Set \(setIndex + 1)").font(AppTypography.bodyMedium).foregroundStyle(AppColor.textSecondary).frame(width: 56, alignment: .leading)
            TextField("reps", value: bindingReps(blockIndex, setIndex), format: .number)
                .keyboardType(.numberPad).frame(width: 56).multilineTextAlignment(.center)
                .padding(8).background(AppColor.elevatedSurface).clipShape(RoundedRectangle(cornerRadius: 8))
            TextField("kg", value: bindingWeight(blockIndex, setIndex), format: .number)
                .keyboardType(.decimalPad).frame(width: 64).multilineTextAlignment(.center)
                .padding(8).background(AppColor.elevatedSurface).clipShape(RoundedRectangle(cornerRadius: 8))
            Spacer()
            Button {
                let rest = vm.workout.sortedExercises.indices.contains(blockIndex) ? vm.workout.sortedExercises[blockIndex].restSeconds : 90
                vm.toggle(blockIndex: blockIndex, setIndex: setIndex, restSeconds: rest)
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2).foregroundStyle(set.isCompleted ? AppColor.success : AppColor.textMuted)
            }
            .frame(width: 44, height: 44)
            .accessibilityLabel(set.isCompleted ? "Completed set" : "Mark set complete")
        }
    }

    private var restCard: some View {
        AppCard {
            HStack {
                Image(systemName: "timer").foregroundStyle(AppColor.secondary)
                Text("Rest").foregroundStyle(AppColor.textPrimary)
                Spacer()
                Text(NumberFormatterUtils.duration(seconds: vm.restRemaining)).font(AppTypography.title3.monospacedDigit()).foregroundStyle(AppColor.secondary)
                Button("Skip") { vm.restRemaining = 0 }.foregroundStyle(AppColor.textMuted)
            }
        }
    }

    private var navBar: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                SecondaryButton(title: "Previous", systemImage: "chevron.left") {
                    if vm.currentIndex > 0 { vm.currentIndex -= 1 }
                }
                SecondaryButton(title: "Next", systemImage: "chevron.right") {
                    if vm.currentIndex < vm.blocks.count - 1 { vm.currentIndex += 1 }
                }
            }
            PrimaryButton(title: "Finish Workout", systemImage: "flag.checkered") {
                summary = vm.buildSession()
            }
        }
        .padding(AppSpacing.md)
    }

    private func summaryView(_ session: WorkoutSession) -> some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "checkmark.seal.fill").font(.system(size: 64)).foregroundStyle(AppColor.success)
                Text("Workout Complete").font(AppTypography.title1).foregroundStyle(AppColor.textPrimary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                    MetricCard(title: "Duration", value: NumberFormatterUtils.duration(seconds: session.durationSeconds), color: AppColor.primary, icon: "clock.fill")
                    MetricCard(title: "Sets", value: "\(session.completedSetsCount)", color: AppColor.secondary, icon: "list.number")
                    MetricCard(title: "Exercises", value: "\(session.completedExercisesCount)", color: AppColor.accent, icon: AppIcons.workouts)
                    MetricCard(title: "Volume", value: NumberFormatterUtils.int(session.totalVolume), color: AppColor.info, icon: "scalemass")
                }
                AppCard {
                    VStack(alignment: .leading) {
                        Text("Notes").font(AppTypography.captionMedium).foregroundStyle(AppColor.textSecondary)
                        TextField("How did it go?", text: $sessionNotes, axis: .vertical).lineLimit(2...4)
                    }
                }
                PrimaryButton(title: "Save Workout", systemImage: "square.and.arrow.down") {
                    saveSession(session); dismiss()
                }
            }
            .padding(AppSpacing.md)
        }
    }

    private func bindingReps(_ b: Int, _ s: Int) -> Binding<Int?> {
        Binding(get: { vm.blocks[b].sets[s].reps }, set: { vm.blocks[b].sets[s].reps = $0 })
    }
    private func bindingWeight(_ b: Int, _ s: Int) -> Binding<Double?> {
        Binding(get: { vm.blocks[b].sets[s].weightKg }, set: { vm.blocks[b].sets[s].weightKg = $0 })
    }

    private func saveSession(_ provided: WorkoutSession? = nil) {
        let session = provided ?? vm.buildSession()
        session.notes = sessionNotes.isEmpty ? nil : sessionNotes
        try? environment.workoutRepository.saveSession(session)
        vm.workout.lastPerformedAt = .now
        try? environment.workoutRepository.saveWorkout(vm.workout)
        HapticsManager.success()
    }
}
