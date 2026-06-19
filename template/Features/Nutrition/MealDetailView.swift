import SwiftUI

struct MealDetailView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    let meal: Meal
    @State private var showAddFood = false
    @State private var refresh = UUID()

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                AppCard {
                    HStack {
                        summaryItem("\(NumberFormatterUtils.int(meal.totalCalories))", "kcal")
                        summaryItem("\(NumberFormatterUtils.int(meal.totalProtein))", "P")
                        summaryItem("\(NumberFormatterUtils.int(meal.totalFat))", "F")
                        summaryItem("\(NumberFormatterUtils.int(meal.totalCarbs))", "C")
                    }
                }
                AppCard {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        SectionHeader(title: "Food Items")
                        if meal.items.isEmpty { Text("No items").foregroundStyle(AppColor.textMuted) }
                        ForEach(meal.items) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.productName).foregroundStyle(AppColor.textPrimary)
                                    Text("\(NumberFormatterUtils.int(item.amountGrams)) g • \(NumberFormatterUtils.int(item.calories)) kcal").font(.caption).foregroundStyle(AppColor.textMuted)
                                }
                                Spacer()
                                Button { remove(item) } label: { Image(systemName: AppIcons.delete).foregroundStyle(AppColor.danger) }.frame(width: 44, height: 44)
                            }
                        }
                    }
                }
                .id(refresh)
                PrimaryButton(title: "Add Food", systemImage: AppIcons.add) { showAddFood = true }
                Button(role: .destructive) { try? environment.nutritionRepository.deleteMeal(meal); dismiss() } label: {
                    Label("Delete Meal", systemImage: AppIcons.delete).frame(maxWidth: .infinity).frame(minHeight: 44)
                }.foregroundStyle(AppColor.danger)
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
        .navigationTitle(meal.type.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddFood, onDismiss: { refresh = UUID() }) { AddFoodFlowView(date: meal.date) }
    }

    private func summaryItem(_ v: String, _ l: String) -> some View {
        VStack { Text(v).font(AppTypography.title3).foregroundStyle(AppColor.textPrimary); Text(l).font(.caption).foregroundStyle(AppColor.textMuted) }.frame(maxWidth: .infinity)
    }

    private func remove(_ item: MealItem) {
        meal.items.removeAll { $0.id == item.id }
        try? environment.nutritionRepository.saveMeal(meal)
        refresh = UUID()
    }
}
