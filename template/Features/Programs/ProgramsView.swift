import SwiftUI

struct ProgramsListView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var programs: [TrainingProgram] = []
    @State private var showEditor = false

    var body: some View {
        Group {
            if programs.isEmpty {
                EmptyStateView(systemImage: AppIcons.programs, title: "No programs yet", message: "Create a multi-week training program to structure your training.", actionTitle: "Create Program") { showEditor = true }
            } else {
                List {
                    ForEach(programs) { program in
                        NavigationLink { ProgramDetailView(program: program) } label: { row(program) }
                            .listRowBackground(AppColor.surface)
                            .swipeActions {
                                Button(role: .destructive) { try? environment.programRepository.deleteProgram(program); reload() } label: { Label("Delete", systemImage: AppIcons.delete) }
                            }
                    }
                }
                .listStyle(.insetGrouped).scrollContentBackground(.hidden)
            }
        }
        .background(AppColor.background)
        .navigationTitle("Training Programs")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showEditor = true } label: { Image(systemName: AppIcons.add) }.accessibilityLabel("Create Program") } }
        .sheet(isPresented: $showEditor, onDismiss: reload) { ProgramEditorView(program: nil) }
        .onAppear(perform: reload)
    }

    private func row(_ p: TrainingProgram) -> some View {
        let progress = ProgramProgressCalculator.progress(p)
        return VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text(p.title).font(AppTypography.bodyMedium).foregroundStyle(AppColor.textPrimary)
                Spacer()
                StatusTag(text: p.status.displayName, color: statusColor(p.status))
            }
            Text("\(p.goal) • \(p.weeksCount) weeks • \(p.daysPerWeek)/week").font(AppTypography.caption).foregroundStyle(AppColor.textMuted)
            ProgressView(value: progress.fraction).tint(AppColor.primary)
        }
    }

    private func statusColor(_ s: ProgramStatus) -> Color {
        switch s {
        case .draft: AppColor.textMuted
        case .active: AppColor.success
        case .paused: AppColor.warning
        case .completed: AppColor.secondary
        }
    }

    private func reload() { programs = (try? environment.programRepository.fetchPrograms()) ?? [] }
}

struct ProgramEditorView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    let program: TrainingProgram?

    @State private var title = ""
    @State private var description = ""
    @State private var goal = ""
    @State private var difficulty: DifficultyLevel = .beginner
    @State private var startDate = Date.now
    @State private var weeks = 4
    @State private var daysPerWeek = 3

    var body: some View {
        NavigationStack {
            Form {
                Section("Program") {
                    TextField("Program Name", text: $title)
                    TextField("Description", text: $description, axis: .vertical).lineLimit(2...4)
                    TextField("Goal", text: $goal)
                    Picker("Difficulty", selection: $difficulty) { ForEach(DifficultyLevel.allCases) { Text($0.displayName).tag($0) } }
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    Stepper("Weeks: \(weeks)", value: $weeks, in: 1...104)
                    Stepper("Days per week: \(daysPerWeek)", value: $daysPerWeek, in: 1...7)
                }
            }
            .navigationTitle(program == nil ? "Create Program" : "Edit Program")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || goal.isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let program else { return }
        title = program.title; description = program.programDescription ?? ""; goal = program.goal
        difficulty = program.difficulty; startDate = program.startDate ?? .now; weeks = program.weeksCount; daysPerWeek = program.daysPerWeek
    }

    private func save() {
        let target = program ?? TrainingProgram(title: title, goal: goal, weeksCount: weeks, daysPerWeek: daysPerWeek)
        target.title = title; target.programDescription = description.isEmpty ? nil : description
        target.goal = goal; target.difficulty = difficulty; target.startDate = startDate
        let end = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: startDate)
        target.endDate = end; target.weeksCount = weeks; target.daysPerWeek = daysPerWeek
        if target.weeks.isEmpty {
            target.weeks = (1...weeks).map { w in
                ProgramWeek(weekIndex: w, title: "Week \(w)", days: (1...daysPerWeek).map { d in
                    ProgramDay(dayIndex: d, title: "Day \(d)")
                })
            }
        }
        try? environment.programRepository.saveProgram(target)
        HapticsManager.success()
        dismiss()
    }
}
