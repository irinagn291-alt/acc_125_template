import SwiftUI

struct AppCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
    }
}

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            guard !isLoading else { return }
            action()
        } label: {
            HStack(spacing: AppSpacing.xs) {
                if isLoading {
                    ProgressView().tint(AppColor.onPrimary)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title).font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .foregroundStyle(AppColor.onPrimary)
            .background(AppColor.primary)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        }
        .disabled(isLoading)
        .accessibilityLabel(title)
    }
}

struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title).font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .foregroundStyle(AppColor.textPrimary)
            .background(AppColor.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        }
        .accessibilityLabel(title)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let color: Color
    let icon: String

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: icon).foregroundStyle(color)
                    Text(title)
                        .font(AppTypography.captionMedium)
                        .foregroundStyle(AppColor.textSecondary)
                    Spacer()
                }
                Text(value)
                    .font(AppTypography.metric)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textMuted)
                }
            }
        }
    }
}

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer(minLength: AppSpacing.lg)
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(AppColor.textMuted)
            Text(title)
                .font(AppTypography.title3)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, systemImage: "plus", action: action)
                    .padding(.top, AppSpacing.xs)
            }
            Spacer(minLength: AppSpacing.lg)
        }
        .padding(.horizontal, AppSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
    }
}

struct ErrorStateView: View {
    let title: String
    let message: String
    var retryTitle: String? = nil
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(AppColor.warning)
            Text(title)
                .font(AppTypography.title3)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
            if let retryTitle, let retryAction {
                SecondaryButton(title: retryTitle, systemImage: "arrow.clockwise", action: retryAction)
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity)
    }
}

struct LoadingStateView: View {
    var message: String = "Loading..."
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView().tint(AppColor.primary)
            Text(message)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity)
    }
}

struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "wifi.slash").foregroundStyle(AppColor.warning)
            Text("No Internet Connection. Saved data is still available.")
                .font(AppTypography.captionMedium)
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
        }
        .padding(AppSpacing.sm)
        .background(AppColor.warning.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .accessibilityLabel("No Internet Connection. Saved data is still available.")
    }
}

struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 10
    var color: Color = AppColor.primary

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

struct MacroLegend: View {
    let protein: Double
    let fat: Double
    let carbs: Double

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            legendItem(title: "Protein", value: protein, color: AppColor.protein)
            legendItem(title: "Fat", value: fat, color: AppColor.fat)
            legendItem(title: "Carbs", value: carbs, color: AppColor.carbs)
        }
    }

    private func legendItem(title: String, value: Double, color: Color) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(title) \(Int(value)) g")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
    }
}

struct StatusTag: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(AppTypography.captionMedium)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xxs)
            .background(color.opacity(0.18))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(AppTypography.title3)
            .foregroundStyle(AppColor.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
