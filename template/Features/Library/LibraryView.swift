import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var environment: AppEnvironment

    enum Tab: String, CaseIterable, Identifiable {
        case myLibrary = "My Library", search = "Search", categories = "Categories", notes = "Notes"
        var id: String { rawValue }
    }

    @State private var tab: Tab = .myLibrary
    @State private var books: [Book] = []
    @State private var statusFilter: ReadingStatus?

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Group {
                switch tab {
                case .myLibrary: myLibrary
                case .search: LibrarySearchView()
                case .categories: categories
                case .notes: notes
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AppColor.background)
        .navigationTitle("Library")
        .onAppear(perform: reload)
    }

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(Tab.allCases) { item in
                    Button { tab = item } label: {
                        Text(item.rawValue)
                            .font(AppTypography.captionMedium)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xs)
                            .background(tab == item ? AppColor.primary : AppColor.surface)
                            .foregroundStyle(tab == item ? .black : AppColor.textSecondary)
                            .clipShape(Capsule())
                    }
                    .accessibilityLabel(item.rawValue)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
    }

    private var myLibrary: some View {
        Group {
            if books.isEmpty {
                EmptyStateView(systemImage: AppIcons.library, title: "No books saved", message: "Search OpenLibrary and save useful sports books.", actionTitle: "Search Books") { tab = .search }
            } else {
                ScrollView {
                    VStack(spacing: AppSpacing.sm) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                chip("All", isOn: statusFilter == nil) { statusFilter = nil }
                                ForEach(ReadingStatus.allCases) { st in chip(st.displayName, isOn: statusFilter == st) { statusFilter = st } }
                            }
                        }
                        ForEach(books.filter { statusFilter == nil || $0.readingStatus == statusFilter }) { book in
                            NavigationLink { BookDetailView(book: book) } label: { bookRow(book) }
                        }
                    }
                    .padding(AppSpacing.md)
                }
            }
        }
    }

    private var categories: some View {
        let subjects = Dictionary(grouping: books.flatMap { $0.subjects }, by: { $0 }).map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }
        return ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if subjects.isEmpty { Text("No categories yet").foregroundStyle(AppColor.textMuted).padding() }
                ForEach(subjects.prefix(40), id: \.0) { subject, count in
                    AppCard { HStack { Text(subject).foregroundStyle(AppColor.textPrimary); Spacer(); Text("\(count)").foregroundStyle(AppColor.textMuted) } }
                }
            }
            .padding(AppSpacing.md)
        }
    }

    private var notes: some View {
        let withNotes = books.filter { ($0.notes ?? "").isEmpty == false }
        return ScrollView {
            VStack(spacing: AppSpacing.sm) {
                if withNotes.isEmpty { EmptyStateView(systemImage: "note.text", title: "No notes", message: "Add notes to your saved books.") }
                ForEach(withNotes) { book in
                    NavigationLink { BookDetailView(book: book) } label: {
                        AppCard {
                            VStack(alignment: .leading) {
                                Text(book.title).font(AppTypography.bodyMedium).foregroundStyle(AppColor.textPrimary)
                                Text(book.notes ?? "").font(AppTypography.caption).foregroundStyle(AppColor.textSecondary).lineLimit(3)
                            }
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
        }
    }

    private func bookRow(_ book: Book) -> some View {
        AppCard {
            HStack(spacing: AppSpacing.sm) {
                RemoteImage(urlString: book.coverUrl, placeholderSymbol: "book.closed.fill").frame(width: 48, height: 64).clipShape(RoundedRectangle(cornerRadius: 6))
                VStack(alignment: .leading, spacing: 2) {
                    Text(book.title).font(AppTypography.bodyMedium).foregroundStyle(AppColor.textPrimary).lineLimit(2)
                    Text(book.authorsText).font(AppTypography.caption).foregroundStyle(AppColor.textMuted).lineLimit(1)
                    StatusTag(text: book.readingStatus.displayName, color: AppColor.secondary)
                }
                Spacer()
            }
        }
    }

    private func chip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(AppTypography.captionMedium).padding(.horizontal, AppSpacing.sm).padding(.vertical, AppSpacing.xs)
                .background(isOn ? AppColor.primary : AppColor.surface).foregroundStyle(isOn ? .black : AppColor.textSecondary).clipShape(Capsule())
        }
    }

    private func reload() { books = (try? environment.bookRepository.fetchBooks()) ?? [] }
}
