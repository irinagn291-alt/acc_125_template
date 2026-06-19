import SwiftUI

// SolarStride — Solar Energy typography
enum AppTypography {
    static let largeTitle = Font.system(size: 38, weight: .heavy, design: .rounded)
    static let title1 = Font.system(size: 30, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 24, weight: .bold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .bold, design: .rounded)

    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 17, weight: .semibold, design: .default)

    static let caption = Font.system(size: 12, weight: .medium, design: .default)
    static let captionMedium = Font.system(size: 13, weight: .bold, design: .default)

    static let metric = Font.system(size: 36, weight: .heavy, design: .rounded)
}

enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 40
}

enum AppRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 18
    static let xl: CGFloat = 24
    static let pill: CGFloat = 999
}

enum AppSize {
    static let minTouchTarget: CGFloat = 44
    static let cardMinHeight: CGFloat = 96
}

enum AppIcons {
    static let today = "sun.max.fill"
    static let calendar = "calendar"
    static let workouts = "dumbbell.fill"
    static let nutrition = "fuelpump.fill"
    static let library = "books.vertical.fill"
    static let analytics = "chart.bar.fill"
    static let settings = "gearshape.fill"
    static let profile = "person.crop.circle"
    static let goals = "target"
    static let body = "scalemass.fill"
    static let water = "drop.fill"
    static let calories = "flame.fill"
    static let protein = "p.circle.fill"
    static let fat = "f.circle.fill"
    static let carbs = "c.circle.fill"
    static let search = "magnifyingglass"
    static let add = "plus"
    static let edit = "pencil"
    static let delete = "trash"
    static let export = "square.and.arrow.up"
    static let importIcon = "square.and.arrow.down"
    static let privacy = "lock.shield.fill"
    static let offline = "wifi.slash"
    static let error = "exclamationmark.triangle.fill"
    static let success = "checkmark.circle.fill"
    static let programs = "square.stack.3d.up.fill"
}
