import SwiftUI

struct LibrarySearchView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var network: NetworkMonitor
    @StateObject private var vm = LibrarySearchViewModel()

    private let suggestions = ["strength training", "running", "endurance", "nutrition", "bodybuilding", "mobility", "sports psychology", "recovery", "exercise anatomy", "powerlifting", "weight loss", "fitness habits"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                searchField
                content
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
        .navigationTitle("Search Books")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { vm.configure(service: environment.openLibraryService, repository: environment.bookRepository, networkMonitor: network) }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: AppIcons.search).foregroundStyle(AppColor.textMuted)
            TextField("Search sports books...", text: $vm.query)
                .foregroundStyle(AppColor.textPrimary).submitLabel(.search)
                .onChange(of: vm.query) { _, _ in vm.queryChanged() }
                .onSubmit { Task { await vm.search() } }
        }
        .padding().background(AppColor.surface).clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    @ViewBuilder
    private var content: some View {
        switch vm.state {
        case .idle: suggestionsView
        case .loading: LoadingStateView(message: "Searching...")
        case .loaded(let docs): ForEach(docs) { bookRow($0) }
        case .empty: EmptyStateView(systemImage: "magnifyingglass", title: "No books found", message: "Try another search term.")
        case .error(let m): ErrorStateView(title: "Search failed", message: m, retryTitle: "Retry") { Task { await vm.search() } }
        case .offline: EmptyStateView(systemImage: AppIcons.offline, title: "No Internet Connection", message: "You can still open My Library offline.")
        }
    }

    private var suggestionsView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(title: "Suggestions")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.xs) {
                ForEach(suggestions, id: \.self) { s in
                    Button { vm.query = s; vm.queryChanged() } label: {
                        Text(s).font(AppTypography.caption).frame(maxWidth: .infinity).padding(AppSpacing.sm)
                            .background(AppColor.surface).foregroundStyle(AppColor.textSecondary).clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                    }
                }
            }
        }
    }

    private func bookRow(_ dto: OpenLibraryBookDTO) -> some View {
        AppCard {
            HStack(spacing: AppSpacing.sm) {
                RemoteImage(urlString: dto.coverURL, placeholderSymbol: "book.closed.fill").frame(width: 48, height: 64).clipShape(RoundedRectangle(cornerRadius: 6))
                VStack(alignment: .leading, spacing: 2) {
                    Text(dto.title).font(AppTypography.bodyMedium).foregroundStyle(AppColor.textPrimary).lineLimit(2)
                    Text(dto.authorsText).font(AppTypography.caption).foregroundStyle(AppColor.textMuted).lineLimit(1)
                    if let year = dto.firstPublishYear { Text("\(String(year))").font(.caption2).foregroundStyle(AppColor.textMuted) }
                }
                Spacer()
                Button { vm.saveBook(dto) } label: { Image(systemName: "bookmark.circle.fill").font(.title2).foregroundStyle(AppColor.primary) }
                    .frame(width: 44, height: 44).accessibilityLabel("Save Book")
            }
        }
    }
}
