import SwiftUI

struct GoalsView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var goals: [UserGoal] = []
    @State private var showEditor = false

    var body: some View {
        Group {
            if goals.isEmpty {
                EmptyStateView(systemImage: AppIcons.goals, title: "No goals yet", message: "Set a goal to track your progress over time.", actionTitle: "Create Goal") { showEditor = true }
            } else {
                List {
                    ForEach(goals) { goal in
                        NavigationLink { GoalDetailView(goal: goal) } label: { row(goal) }
                            .listRowBackground(AppColor.surface)
                            .swipeActions {
                                Button(role: .destructive) { try? environment.goalRepository.deleteGoal(goal); reload() } label: { Label("Delete", systemImage: AppIcons.delete) }
                            }
                    }
                }
                .listStyle(.insetGrouped).scrollContentBackground(.hidden)
            }
        }
        .background(AppColor.background)
        .navigationTitle("Goals")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showEditor = true } label: { Image(systemName: AppIcons.add) }.accessibilityLabel("Create Goal") } }
        .sheet(isPresented: $showEditor, onDismiss: reload) { GoalEditorView(goal: nil) }
        .onAppear(perform: reload)
    }

    private func row(_ goal: UserGoal) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text(goal.title).font(AppTypography.bodyMedium).foregroundStyle(AppColor.textPrimary)
                Spacer()
                if goal.isCompleted { StatusTag(text: "Completed", color: AppColor.success) }
            }
            Text("\(NumberFormatterUtils.decimal(goal.currentValue)) / \(NumberFormatterUtils.decimal(goal.targetValue)) \(goal.unit)").font(AppTypography.caption).foregroundStyle(AppColor.textMuted)
            ProgressView(value: goal.progress).tint(AppColor.primary)
        }
    }

    private func reload() { goals = (try? environment.goalRepository.fetchGoals()) ?? [] }
}

struct GoalEditorView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    let goal: UserGoal?

    @State private var title = ""
    @State private var type: GoalType = .bodyWeight
    @State private var target = ""
    @State private var current = ""
    @State private var unit = "kg"
    @State private var hasDeadline = false
    @State private var deadline = Date.now
    @State private var notes = ""

    private var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty && (Double(target) ?? 0) > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("Goal Title", text: $title)
                    Picker("Type", selection: $type) { ForEach(GoalType.allCases) { Text($0.displayName).tag($0) } }
                        .onChange(of: type) { _, v in unit = v.defaultUnit }
                    HStack { Text("Target"); Spacer(); TextField("0", text: $target).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(maxWidth: 100) }
                    HStack { Text("Current"); Spacer(); TextField("0", text: $current).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(maxWidth: 100) }
                    TextField("Unit", text: $unit)
                }
                Section {
                    Toggle("Set Deadline", isOn: $hasDeadline)
                    if hasDeadline { DatePicker("Deadline", selection: $deadline, in: Date.now..., displayedComponents: .date) }
                }
                Section("Notes") { TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...4) }
            }
            .navigationTitle(goal == nil ? "Create Goal" : "Edit Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!isValid) }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let goal else { unit = type.defaultUnit; return }
        title = goal.title; type = goal.type; target = String(goal.targetValue); current = String(goal.currentValue)
        unit = goal.unit; notes = goal.notes ?? ""
        if let d = goal.deadline { hasDeadline = true; deadline = d }
    }

    private func save() {
        let target0 = goal ?? UserGoal(title: title, type: type, targetValue: 0, unit: unit)
        target0.title = title; target0.type = type
        target0.targetValue = Double(target) ?? 0
        target0.currentValue = Double(current) ?? 0
        target0.unit = unit
        target0.deadline = hasDeadline ? deadline : nil
        target0.notes = notes.isEmpty ? nil : notes
        try? environment.goalRepository.saveGoal(target0)
        HapticsManager.success(); dismiss()
    }
}

struct GoalDetailView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    let goal: UserGoal
    @State private var showEditor = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                AppCard {
                    VStack(spacing: AppSpacing.sm) {
                        ProgressRing(progress: goal.progress, color: AppColor.primary).frame(width: 120, height: 120)
                            .overlay(Text("\(Int(goal.progress * 100))%").font(AppTypography.title2).foregroundStyle(AppColor.textPrimary))
                        Text(goal.title).font(AppTypography.title3).foregroundStyle(AppColor.textPrimary)
                        Text("\(NumberFormatterUtils.decimal(goal.currentValue)) / \(NumberFormatterUtils.decimal(goal.targetValue)) \(goal.unit)").foregroundStyle(AppColor.textSecondary)
                        if let d = goal.deadline { Text("Deadline: \(DateUtils.string(d))").font(AppTypography.caption).foregroundStyle(AppColor.textMuted) }
                    }
                    .frame(maxWidth: .infinity)
                }
                if let notes = goal.notes, !notes.isEmpty { AppCard { Text(notes).foregroundStyle(AppColor.textSecondary) } }
                SecondaryButton(title: "Edit Goal", systemImage: AppIcons.edit) { showEditor = true }
                PrimaryButton(title: goal.isCompleted ? "Mark Active" : "Mark as Completed", systemImage: AppIcons.success) {
                    goal.isCompleted.toggle(); try? environment.goalRepository.saveGoal(goal); HapticsManager.success()
                }
                Button(role: .destructive) { try? environment.goalRepository.deleteGoal(goal); dismiss() } label: {
                    Label("Delete Goal", systemImage: AppIcons.delete).frame(maxWidth: .infinity).frame(minHeight: 44)
                }.foregroundStyle(AppColor.danger)
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
        .navigationTitle("Goal")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditor) { GoalEditorView(goal: goal) }
    }
}
