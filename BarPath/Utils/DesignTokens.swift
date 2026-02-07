import SwiftUI

/// Centralized design system for BarPath, providing adaptive colors, spacing, typography, and animations.
enum DesignTokens {

    // MARK: - Colors

    enum Colors {
        // MARK: Primary Colors

        /// Primary brand color - adapts to light/dark/tinted modes.
        static let primary = Color.blue.opacity(0.9)

        /// Secondary brand color.
        static let secondary = Color.purple.opacity(0.8)

        // MARK: Backgrounds

        /// Primary background color (system adaptive).
        static let background = Color(uiColor: .systemBackground)

        /// Secondary background for cards and grouped content.
        static let secondaryBackground = Color(uiColor: .secondarySystemBackground)

        /// Tertiary background for additional layering.
        static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)

        // MARK: Text

        /// Primary text color (system adaptive).
        static let text = Color(uiColor: .label)

        /// Secondary text for less prominent content.
        static let secondaryText = Color(uiColor: .secondaryLabel)

        /// Tertiary text for disabled or placeholder content.
        static let tertiaryText = Color(uiColor: .tertiaryLabel)

        // MARK: Bar Path Colors

        /// Bar path color indicating good form/high velocity.
        static let barPathGood = Color.green

        /// Bar path color indicating warning/medium velocity.
        static let barPathWarning = Color.orange

        /// Bar path color indicating poor form/low velocity.
        static let barPathBad = Color.red

        // MARK: Semantic Colors

        /// Success state color.
        static let success = Color.green

        /// Warning state color.
        static let warning = Color.orange

        /// Error state color.
        static let error = Color.red

        /// Info/neutral state color.
        static let info = Color.blue

        // MARK: UI Elements

        /// Separator line color.
        static let separator = Color(uiColor: .separator)

        /// Card border color.
        static let border = Color(uiColor: .separator)
    }

    // MARK: - Spacing

    enum Spacing {
        /// Extra extra small spacing (4pt).
        static let xxs: CGFloat = 4

        /// Extra small spacing (8pt).
        static let xs: CGFloat = 8

        /// Small spacing (12pt).
        static let sm: CGFloat = 12

        /// Medium spacing (16pt) - standard default.
        static let md: CGFloat = 16

        /// Large spacing (24pt).
        static let lg: CGFloat = 24

        /// Extra large spacing (32pt).
        static let xl: CGFloat = 32

        /// Extra extra large spacing (48pt).
        static let xxl: CGFloat = 48
    }

    // MARK: - Typography

    enum Typography {
        /// Large title for main screen headers.
        static let largeTitle = Font.largeTitle.weight(.bold)

        /// Title for section headers.
        static let title = Font.title.weight(.semibold)

        /// Smaller title for subsections.
        static let title2 = Font.title2.weight(.semibold)

        /// Title 3 for smaller section headers.
        static let title3 = Font.title3.weight(.semibold)

        /// Headline for prominent content.
        static let headline = Font.headline

        /// Body text for main content.
        static let body = Font.body

        /// Callout for secondary content.
        static let callout = Font.callout

        /// Subheadline for de-emphasized content.
        static let subheadline = Font.subheadline

        /// Footnote for supplementary information.
        static let footnote = Font.footnote

        /// Caption for labels and annotations.
        static let caption = Font.caption

        /// Caption 2 for smaller annotations.
        static let caption2 = Font.caption2
    }

    // MARK: - Animation

    enum Animation {
        /// Quick animation (0.2s) for immediate feedback.
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)

        /// Standard animation (0.3s) for most UI transitions.
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)

        /// Slow animation (0.5s) for emphasized transitions.
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)

        /// Spring animation for bouncy interactions.
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
    }

    // MARK: - Dimensions

    enum Dimensions {
        /// Corner radius for buttons and cards.
        static let cornerRadius: CGFloat = 12

        /// Small corner radius for subtle rounding.
        static let cornerRadiusSmall: CGFloat = 8

        /// Large corner radius for prominent elements.
        static let cornerRadiusLarge: CGFloat = 16

        /// Standard icon size.
        static let iconSize: CGFloat = 24

        /// Small icon size.
        static let iconSizeSmall: CGFloat = 16

        /// Large icon size.
        static let iconSizeLarge: CGFloat = 32

        /// Minimum touch target size for accessibility.
        static let minTouchTarget: CGFloat = 44
    }

    // MARK: - Shadows

    enum Shadows {
        /// Subtle shadow for cards.
        static let card = Color.black.opacity(0.1)

        /// Shadow radius for cards.
        static let cardRadius: CGFloat = 8

        /// Shadow offset for cards.
        static let cardOffset: CGFloat = 2
    }
}
