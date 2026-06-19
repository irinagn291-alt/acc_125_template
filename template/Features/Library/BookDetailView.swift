import SwiftUI

struct BookDetailView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    let book: Book

    @State private var status: ReadingStatus = .wantToRead
    @State private var progress: Double = 0
    @State private var rating = 0
    @State private var notes = ""
    @State private var sessions: [ReadingSession] = []
    @State private var showAddSession = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                header
                statusCard
                progressCard
                ratingCard
                notesCard
                sessionsCard
                Button(role: .destructive) { try? environment.bookRepository.deleteBook(book); dismiss() } label: {
                    Label("Delete Book", systemImage: AppIcons.delete).frame(maxWidth: .infinity).frame(minHeight: 44)
                }.foregroundStyle(AppColor.danger)
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
        .navigationTitle("Book")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddSession, onDismiss: reloadSessions) { ReadingSessionEditorView(book: book) }
        .onAppear(perform: load)
    }

    private var header: some View {
        HStack(spacing: AppSpacing.md) {
            RemoteImage(urlString: book.coverUrl, placeholderSymbol: "book.closed.fill").frame(width: 90, height: 120).clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(book.title).font(AppTypography.title3).foregroundStyle(AppColor.textPrimary)
                Text(book.authorsText).font(AppTypography.body).foregroundStyle(AppColor.textSecondary)
                if let year = book.firstPublishYear { Text(String(year)).font(AppTypography.caption).foregroundStyle(AppColor.textMuted) }
                if let lang = book.language { Text("Language: \(lang)").font(AppTypography.caption).foregroundStyle(AppColor.textMuted) }
            }
            Spacer()
        }
    }

    private var statusCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SectionHeader(title: "Reading Status")
                Picker("Status", selection: $status) { ForEach(ReadingStatus.allCases) { Text($0.displayName).tag($0) } }
                    .pickerStyle(.menu)
                    .onChange(of: status) { _, v in book.readingStatus = v; save() }
            }
        }
    }

    private var progressCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SectionHeader(title: "Progress")
                HStack { Text("\(Int(progress))%").foregroundStyle(AppColor.textPrimary); Spacer() }
                Slider(value: $progress, in: 0...100, step: 1) { editing in if !editing { book.progressPercent = progress; save() } }
                    .tint(AppColor.primary)
            }
        }
    }

    private var ratingCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SectionHeader(title: "Rating")
                HStack {
                    ForEach(1...5, id: \.self) { star in
                        Button { rating = star; book.rating = star; save() } label: {
                            Image(systemName: star <= rating ? "star.fill" : "star").foregroundStyle(AppColor.warning).font(.title3)
                        }.frame(width: 44, height: 44)
                    }
                }
            }
        }
    }

    private var notesCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SectionHeader(title: "Notes")
                TextField("Add notes...", text: $notes, axis: .vertical).lineLimit(3...6)
                    .onChange(of: notes) { _, v in book.notes = v.isEmpty ? nil : v }
                SecondaryButton(title: "Save Notes") { save() }
            }
        }
    }

    private var sessionsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack { SectionHeader(title: "Reading Sessions"); Button { showAddSession = true } label: { Image(systemName: AppIcons.add) } }
                if sessions.isEmpty { Text("No sessions logged").foregroundStyle(AppColor.textMuted) }
                ForEach(sessions) { s in
                    HStack {
                        Text(DateUtils.string(s.date, DateUtils.shortDay)).foregroundStyle(AppColor.textPrimary)
                        Spacer()
                        Text("\(s.durationMinutes) min").foregroundStyle(AppColor.textMuted)
                        if let pages = s.pagesRead { Text("\(pages) p").font(.caption).foregroundStyle(AppColor.textMuted) }
                    }.font(AppTypography.body)
                }
            }
        }
    }

    private func load() {
        status = book.readingStatus; progress = book.progressPercent; rating = book.rating ?? 0; notes = book.notes ?? ""
        reloadSessions()
    }

    private func reloadSessions() {
        sessions = ((try? environment.bookRepository.fetchAllReadingSessions()) ?? []).filter { $0.bookId == book.id }
    }

    private func save() { try? environment.bookRepository.saveBook(book) }
}

struct ReadingSessionEditorView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    let book: Book
    @State private var date = Date.now
    @State private var minutes = 30
    @State private var pages = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Stepper("Duration: \(minutes) min", value: $minutes, in: 1...600, step: 5)
                HStack { Text("Pages read"); Spacer(); TextField("—", text: $pages).keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(maxWidth: 80) }
            }
            .navigationTitle("Add Reading Session")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let session = ReadingSession(bookId: book.id, bookTitle: book.title, date: date, durationMinutes: minutes, pagesRead: Int(pages))
                        try? environment.bookRepository.saveReadingSession(session)
                        HapticsManager.success(); dismiss()
                    }
                }
            }
        }
    }
}
