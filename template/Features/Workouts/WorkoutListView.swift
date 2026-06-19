import SwiftUI

struct WorkoutListView: View {
    @EnvironmentObject private var environment: AppEnvironment

    enum SortOption: String, CaseIterable, Identifiable {
        case recent = "Recent", duration = "Duration", difficulty = "Difficulty"
        var id: String { rawValue }
    }

    @State private var workouts: [Workout] = []
    @State private var query = ""
    @State private var typeFilter: WorkoutType?
    @State private var sort: SortOption = .recent
    @State private var showEditor = false

    private var filtered: [Workout] {
        var list = workouts
        if !query.isEmpty { list = list.filter { $0.title.localizedCaseInsensitiveContains(query) } }
        if let typeFilter { list = list.filter { $0.type == typeFilter } }
        switch sort {
        case .recent: list.sort { $0.updatedAt > $1.updatedAt }
        case .duration: list.sort { $0.estimatedDurationMinutes > $1.estimatedDurationMinutes }
        case .difficulty: list.sort { $0.difficulty.rawValue < $1.difficulty.rawValue }
        }
        return list
    }

    var body: some View {
        Group {
            if workouts.isEmpty {
                EmptyStateView(systemImage: AppIcons.workouts, title: "No workouts yet", message: "Create your first workout and add it to your calendar.", actionTitle: "Create Workout") { showEditor = true }
            } else {
                List {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                filterChip("All", isOn: typeFilter == nil) { typeFilter = nil }
                                ForEach(WorkoutType.allCases) { t in
                                    filterChip(t.displayName, isOn: typeFilter == t) { typeFilter = t }
                                }
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                    ForEach(filtered) { workout in
                        NavigationLink { WorkoutDetailView(workout: workout) } label: { row(workout) }
                            .listRowBackground(AppColor.surface)
                            .swipeActions {
                                Button(role: .destructive) { delete(workout) } label: { Label("Delete", systemImage: AppIcons.delete) }
                                Button { duplicate(workout) } label: { Label("Duplicate", systemImage: "doc.on.doc") }.tint(AppColor.secondary)
                            }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
        .navigationTitle("Workouts")
        .modifier(WorkoutSearchModifier(query: $query, isEnabled: !workouts.isEmpty))
        .toolbar {
            if !workouts.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort", selection: $sort) { ForEach(SortOption.allCases) { Text($0.rawValue).tag($0) } }
                    } label: { Image(systemName: "arrow.up.arrow.down") }
                        .accessibilityLabel("Sort Workouts")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: AppSpacing.md) {
                    if !workouts.isEmpty {
                        NavigationLink { WorkoutHistoryView() } label: {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                        .accessibilityLabel("Workout History")
                    }
                    Button { showEditor = true } label: { Image(systemName: AppIcons.add) }
                        .accessibilityLabel("Create Workout")
                }
            }
        }
        .sheet(isPresented: $showEditor, onDismiss: reload) { WorkoutEditorView(workout: nil) }
        .onAppear(perform: reload)
    }

    private func row(_ w: Workout) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(w.title).font(AppTypography.bodyMedium).foregroundStyle(AppColor.textPrimary)
            HStack(spacing: AppSpacing.sm) {
                Label(w.type.displayName, systemImage: w.type.icon)
                Text("\(w.estimatedDurationMinutes) min")
                Text("\(w.exercises.count) ex")
            }
            .font(AppTypography.caption).foregroundStyle(AppColor.textMuted)
            if let last = w.lastPerformedAt {
                Text("Last: \(DateUtils.string(last, DateUtils.shortDay))").font(AppTypography.caption).foregroundStyle(AppColor.textMuted)
            }
        }
    }

    private func filterChip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(AppTypography.captionMedium)
                .padding(.horizontal, AppSpacing.sm).padding(.vertical, AppSpacing.xs)
                .background(isOn ? AppColor.primary : AppColor.elevatedSurface)
                .foregroundStyle(isOn ? .black : AppColor.textSecondary)
                .clipShape(Capsule())
        }
    }

    private func reload() {
        workouts = (try? environment.workoutRepository.fetchWorkouts()) ?? []
    }

    private func delete(_ w: Workout) {
        try? environment.workoutRepository.deleteWorkout(w); reload()
    }

    private func duplicate(_ w: Workout) {
        let copy = Workout(title: w.title + " Copy", workoutDescription: w.workoutDescription, type: w.type, difficulty: w.difficulty, goal: w.goal, estimatedDurationMinutes: w.estimatedDurationMinutes, tags: w.tags, exercises: w.sortedExercises.map {
            WorkoutExercise(name: $0.name, muscleGroup: $0.muscleGroup, equipment: $0.equipment, sets: $0.sets, reps: $0.reps, weightKg: $0.weightKg, durationSeconds: $0.durationSeconds, distanceMeters: $0.distanceMeters, restSeconds: $0.restSeconds, tempo: $0.tempo, rpe: $0.rpe, notes: $0.notes, orderIndex: $0.orderIndex)
        })
        try? environment.workoutRepository.saveWorkout(copy); reload()
    }
}

private struct WorkoutSearchModifier: ViewModifier {
    @Binding var query: String
    let isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content.searchable(text: $query, prompt: "Search Workouts")
        } else {
            content
        }
    }
}
