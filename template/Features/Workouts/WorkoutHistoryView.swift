import SwiftUI

struct WorkoutHistoryView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var sessions: [WorkoutSession] = []

    var body: some View {
        Group {
            if sessions.isEmpty {
                EmptyStateView(systemImage: "clock.arrow.circlepath", title: "No history yet", message: "Complete a workout to see it here.")
            } else {
                List {
                    ForEach(sessions) { s in
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            HStack {
                                Text(s.workoutTitle).font(AppTypography.bodyMedium).foregroundStyle(AppColor.textPrimary)
                                Spacer()
                                StatusTag(text: s.status.displayName, color: AppColor.success)
                            }
                            Text(DateUtils.string(s.startedAt)).font(AppTypography.caption).foregroundStyle(AppColor.textMuted)
                            HStack(spacing: AppSpacing.md) {
                                Label(NumberFormatterUtils.durationMinutes(s.durationSeconds / 60), systemImage: "clock")
                                Label("\(s.completedSetsCount) sets", systemImage: "list.number")
                                Label("vol \(NumberFormatterUtils.int(s.totalVolume))", systemImage: "scalemass")
                            }
                            .font(AppTypography.caption).foregroundStyle(AppColor.textSecondary)
                        }
                        .listRowBackground(AppColor.surface)
                        .swipeActions {
                            Button(role: .destructive) {
                                try? environment.workoutRepository.deleteSession(s); reload()
                            } label: { Label("Delete", systemImage: AppIcons.delete) }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(AppColor.background)
        .navigationTitle("Workout History")
        .onAppear(perform: reload)
    }

    private func reload() {
        sessions = (try? environment.workoutRepository.fetchAllSessions()) ?? []
    }
}
