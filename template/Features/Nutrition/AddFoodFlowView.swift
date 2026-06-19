import SwiftUI

struct AddFoodFlowView: View {
    @Environment(\.dismiss) private var dismiss
    let date: Date

    @State private var pendingProduct: FoodProduct?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        FoodSearchView { product in pendingProduct = product }
                    } label: { optionRow("Search OpenFoodFacts", AppIcons.search) }
                    NavigationLink {
                        SavedFoodsView { product in pendingProduct = product }
                    } label: { optionRow("Saved Foods", "bookmark.fill") }
                    NavigationLink {
                        ManualFoodEditorView(product: nil) { product in pendingProduct = product }
                    } label: { optionRow("Create Manually", "square.and.pencil") }
                }
                .listRowBackground(AppColor.surface)
            }
            .listStyle(.insetGrouped).scrollContentBackground(.hidden).background(AppColor.background)
            .navigationTitle("Add Food")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .sheet(item: $pendingProduct) { product in
                AddFoodToMealView(product: product, date: date) { dismiss() }
            }
        }
    }

    private func optionRow(_ title: String, _ icon: String) -> some View {
        Label(title, systemImage: icon).foregroundStyle(AppColor.textPrimary).frame(minHeight: 44)
    }
}

struct AddFoodToMealView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    let product: FoodProduct
    let date: Date
    var onComplete: () -> Void

    @State private var mealType: MealType = .breakfast
    @State private var amount = "100"

    private var grams: Double { Double(amount) ?? 0 }
    private var nutrition: NutritionSummary { environment.nutritionCalculation.calculate(product: product, amountGrams: grams) }
    private var isValid: Bool { grams >= 0.1 && grams <= 10000 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    Text(product.name).foregroundStyle(AppColor.textPrimary)
                    if let brand = product.brand { Text(brand).font(.caption).foregroundStyle(AppColor.textMuted) }
                }
                Section("Add to Meal") {
                    Picker("Meal", selection: $mealType) { ForEach(MealType.allCases) { Text($0.displayName).tag($0) } }
                    HStack { Text("Amount (g)"); Spacer(); TextField("100", text: $amount).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(maxWidth: 100) }
                }
                Section("Calculated") {
                    row("Calories", "\(NumberFormatterUtils.int(nutrition.calories)) kcal")
                    row("Protein", "\(NumberFormatterUtils.decimal(nutrition.protein)) g")
                    row("Fat", "\(NumberFormatterUtils.decimal(nutrition.fat)) g")
                    row("Carbs", "\(NumberFormatterUtils.decimal(nutrition.carbs)) g")
                }
            }
            .navigationTitle("Add to Meal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Add") { add() }.disabled(!isValid) }
            }
        }
    }

    private func row(_ l: String, _ v: String) -> some View {
        HStack { Text(l).foregroundStyle(AppColor.textSecondary); Spacer(); Text(v).foregroundStyle(AppColor.textPrimary) }
    }

    private func add() {
        let existing = (try? environment.nutritionRepository.fetchMeals(for: date)) ?? []
        let meal = existing.first { $0.type == mealType } ?? Meal(date: date, type: mealType, title: mealType.displayName)
        let item = MealItem(foodProductId: product.id, productName: product.name, amountGrams: grams, calories: nutrition.calories, protein: nutrition.protein, fat: nutrition.fat, carbs: nutrition.carbs, sugar: nutrition.sugar, fiber: nutrition.fiber, salt: nutrition.salt)
        meal.items.append(item)
        try? environment.nutritionRepository.saveMeal(meal)
        HapticsManager.success()
        dismiss()
        onComplete()
    }
}
