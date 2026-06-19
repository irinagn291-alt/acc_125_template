import SwiftUI

struct FoodSearchView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var network: NetworkMonitor
    @StateObject private var vm = FoodSearchViewModel()

    var onPick: (FoodProduct) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                searchField
                if !vm.localResults.isEmpty {
                    SectionHeader(title: "Saved Foods")
                    ForEach(vm.localResults) { product in localRow(product) }
                }
                SectionHeader(title: "OpenFoodFacts Results")
                remoteContent
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
        .navigationTitle("Search Food")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            vm.configure(service: environment.openFoodFactsService, repository: environment.foodProductRepository, networkMonitor: network)
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: AppIcons.search).foregroundStyle(AppColor.textMuted)
            TextField("Search for oatmeal, banana, rice...", text: $vm.query)
                .foregroundStyle(AppColor.textPrimary)
                .submitLabel(.search)
                .onChange(of: vm.query) { _, _ in vm.queryChanged() }
                .onSubmit { Task { await vm.search() } }
        }
        .padding().background(AppColor.surface).clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    @ViewBuilder
    private var remoteContent: some View {
        switch vm.remoteState {
        case .idle:
            Text("Type at least 2 characters to search.").font(AppTypography.caption).foregroundStyle(AppColor.textMuted)
        case .loading:
            LoadingStateView(message: "Searching...")
        case .loaded(let products):
            ForEach(products) { dto in remoteRow(dto) }
        case .empty:
            EmptyStateView(systemImage: "magnifyingglass", title: "No products found", message: "Try another search term or create a food manually.")
        case .error(let message):
            ErrorStateView(title: "Search failed", message: message, retryTitle: "Retry") { Task { await vm.search() } }
        case .offline:
            EmptyStateView(systemImage: AppIcons.offline, title: "No Internet Connection", message: "You can still use saved foods or create a food manually.")
        }
    }

    private func localRow(_ product: FoodProduct) -> some View {
        Button { onPick(product) } label: {
            AppCard {
                HStack {
                    VStack(alignment: .leading) {
                        Text(product.name).foregroundStyle(AppColor.textPrimary)
                        Text("\(NumberFormatterUtils.int(product.caloriesPer100g)) kcal/100g").font(.caption).foregroundStyle(AppColor.textMuted)
                    }
                    Spacer()
                    Image(systemName: "plus.circle.fill").foregroundStyle(AppColor.primary)
                }
            }
        }
    }

    private func remoteRow(_ dto: OpenFoodFactsProductDTO) -> some View {
        AppCard {
            HStack(spacing: AppSpacing.sm) {
                RemoteImage(urlString: dto.imageUrl, placeholderSymbol: "fork.knife").frame(width: 48, height: 48).clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading) {
                    Text(dto.displayName).foregroundStyle(AppColor.textPrimary).lineLimit(2)
                    if let brand = dto.brands { Text(brand).font(.caption).foregroundStyle(AppColor.textMuted).lineLimit(1) }
                    if !dto.hasCompleteNutrition {
                        Text("Incomplete nutrition data").font(.caption2).foregroundStyle(AppColor.warning)
                    }
                }
                Spacer()
                Button {
                    if let product = vm.saveRemoteProduct(dto) { onPick(product) }
                } label: { Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(AppColor.primary) }
                .frame(width: 44, height: 44)
            }
        }
    }
}

struct SavedFoodsView: View {
    @EnvironmentObject private var environment: AppEnvironment
    var onPick: (FoodProduct) -> Void
    @State private var products: [FoodProduct] = []
    @State private var query = ""

    var body: some View {
        Group {
            if products.isEmpty {
                EmptyStateView(systemImage: "bookmark", title: "No saved foods", message: "Create a food manually or save one from OpenFoodFacts.")
            } else {
                List {
                    ForEach(products.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }) { product in
                        Button { onPick(product) } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(product.name).foregroundStyle(AppColor.textPrimary)
                                    Text("\(NumberFormatterUtils.int(product.caloriesPer100g)) kcal/100g").font(.caption).foregroundStyle(AppColor.textMuted)
                                }
                                Spacer()
                                if product.isFavorite { Image(systemName: "star.fill").foregroundStyle(AppColor.warning) }
                            }
                        }
                        .listRowBackground(AppColor.surface)
                        .swipeActions {
                            Button(role: .destructive) { try? environment.foodProductRepository.deleteProduct(product); reload() } label: { Label("Delete", systemImage: AppIcons.delete) }
                        }
                    }
                }
                .listStyle(.insetGrouped).scrollContentBackground(.hidden)
            }
        }
        .background(AppColor.background)
        .navigationTitle("Saved Foods")
        .searchable(text: $query)
        .onAppear(perform: reload)
    }

    private func reload() { products = (try? environment.foodProductRepository.fetchProducts()) ?? [] }
}
