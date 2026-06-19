import SwiftUI
import UniformTypeIdentifiers

struct DataExportView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var exportURL: URL?
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: AppIcons.export).font(.system(size: 56)).foregroundStyle(AppColor.primary)
                Text("Export Your Data").font(AppTypography.title2).foregroundStyle(AppColor.textPrimary)
                Text("Create a local JSON backup of your workouts, nutrition, books, goals, and settings.")
                    .font(AppTypography.body).foregroundStyle(AppColor.textSecondary).multilineTextAlignment(.center)
                if let url = exportURL {
                    ShareLink(item: url) {
                        Label("Share Backup", systemImage: "square.and.arrow.up").font(.headline).frame(maxWidth: .infinity).frame(minHeight: 52)
                            .background(AppColor.primary).foregroundStyle(.black).clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }
                }
                PrimaryButton(title: "Export Data", systemImage: AppIcons.export) { export() }
                if let error { Text(error).font(AppTypography.caption).foregroundStyle(AppColor.danger) }
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColor.background)
        .navigationTitle("Data Export")
    }

    private func export() {
        do { exportURL = try environment.exportImportService.writeExport(); HapticsManager.success() }
        catch { self.error = "Export failed." }
    }
}

struct DataImportView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var showPicker = false
    @State private var backup: BackupFile?
    @State private var preview: ImportPreview?
    @State private var mode: ImportMode = .merge
    @State private var error: String?
    @State private var done = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: AppIcons.importIcon).font(.system(size: 56)).foregroundStyle(AppColor.secondary)
                Text("Import Data").font(AppTypography.title2).foregroundStyle(AppColor.textPrimary)
                Text("Restore a JSON backup created by SolarStride.")
                    .font(AppTypography.body).foregroundStyle(AppColor.textSecondary).multilineTextAlignment(.center)

                if let preview {
                    AppCard {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            SectionHeader(title: "Preview")
                            previewRow("Workouts", preview.workouts)
                            previewRow("Workout Sessions", preview.workoutSessions)
                            previewRow("Foods", preview.foods)
                            previewRow("Meals", preview.meals)
                            previewRow("Books", preview.books)
                            previewRow("Goals", preview.goals)
                            previewRow("Body Measurements", preview.bodyMeasurements)
                            previewRow("Calendar Events", preview.calendarEvents)
                        }
                    }
                    Picker("Mode", selection: $mode) {
                        Text("Merge with existing data").tag(ImportMode.merge)
                        Text("Replace all data").tag(ImportMode.replaceAll)
                    }.pickerStyle(.inline)
                    PrimaryButton(title: "Confirm Import") { confirm() }
                } else {
                    PrimaryButton(title: "Select JSON File", systemImage: "doc") { showPicker = true }
                }

                if done { Label("Import complete", systemImage: AppIcons.success).foregroundStyle(AppColor.success) }
                if let error { Text(error).font(AppTypography.caption).foregroundStyle(AppColor.danger) }
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColor.background)
        .navigationTitle("Data Import")
        .fileImporter(isPresented: $showPicker, allowedContentTypes: [.json]) { result in
            handle(result)
        }
    }

    private func previewRow(_ title: String, _ count: Int) -> some View {
        HStack { Text(title).foregroundStyle(AppColor.textSecondary); Spacer(); Text("\(count)").foregroundStyle(AppColor.textPrimary) }
    }

    private func handle(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            let parsed = try environment.exportImportService.decode(data)
            backup = parsed
            preview = environment.exportImportService.preview(parsed)
            error = nil
        } catch let e as ExportImportError {
            error = e.errorDescription
        } catch {
            self.error = "Failed to read the backup file."
        }
    }

    private func confirm() {
        guard let backup else { return }
        do { try environment.exportImportService.performImport(backup, mode: mode); done = true; preview = nil; HapticsManager.success() }
        catch { self.error = "Import failed." }
    }
}
