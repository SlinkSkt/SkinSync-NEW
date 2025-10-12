/// Core/Theme.swift
//
// Theme.swift
// Zhen Xiao - Comment 23/8/2025
// This file defines app-wide theming, including color schemes and utilities for consistent UI appearance.
// provides a Color extension for hex string initialization and the AppTheme struct for managing theme colors.
//
import SwiftUI

// MARK: - Color Extension for Hex Strings
// https://developer.apple.com/documentation/SwiftUI/Color - source of methonds - Zhen Xiao
extension Color {
    /// Initializes a Color from a hex string (e.g., "#RRGGBB" or "#RRGGBBAA").
    /// Supports optional leading '#' and 6 (RGB) or 8 (RGBA) hex digits.
    init?(hex: String) {
        var hex = hex
        // Remove leading '#' if present
        if hex.hasPrefix("#") { hex.removeFirst() }
        // Parse hex string into UInt64
        guard let v = UInt64(hex, radix: 16) else { return nil }
        let r, g, b, a: Double
        switch hex.count {
        case 6:
            // Format: RRGGBB (opaque)
            r = Double((v >> 16) & 0xFF) / 255
            g = Double((v >> 8) & 0xFF) / 255
            b = Double(v & 0xFF) / 255
            a = 1
        case 8:
            // Format: RRGGBBAA (with alpha)
            r = Double((v >> 24) & 0xFF) / 255
            g = Double((v >> 16) & 0xFF) / 255
            b = Double((v >> 8) & 0xFF) / 255
            a = Double(v & 0xFF) / 255
        default:
            // Invalid format
            return nil
        }
        self = Color(red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - AppTheme Definition
struct AppTheme {
    /// The primary brand color, usually used for accents and highlights.
    let primary: Color
    let primaryLight: Color
    let primaryDark: Color
    
    /// The main background color for views and screens.
    let background: Color
    /// Elevated surface color for cards (with better contrast)
    let cardBackground: Color
    /// Secondary card background for nested cards
    let secondaryCardBackground: Color
    
    // MARK: - Premium Color Palette
    /// Gradient colors for premium feel
    let gradientStart: Color
    let gradientEnd: Color
    
    /// Accent colors for variety
    let accentPurple: Color = Color(hex: "#A78BFA") ?? .purple
    let accentBlue: Color = Color(hex: "#60A5FA") ?? .blue
    let accentPink: Color = Color(hex: "#F472B6") ?? .pink
    let accentTeal: Color = Color(hex: "#2DD4BF") ?? .teal
    
    // MARK: - Text Colors (enhanced)
    /// The main color for primary text content.
    let textPrimary: Color = .primary
    /// The color for secondary or less prominent text.
    let textSecondary: Color = .secondary
    /// The color for tertiary text.
    let textTertiary: Color = Color(.tertiaryLabel)
    /// The color for quaternary text (least prominent).
    let textQuaternary: Color = Color(.quaternaryLabel)
    
    // MARK: - Semantic Colors (enhanced)
    /// Success color for positive actions and states
    let success: Color = Color(hex: "#10B981") ?? .green
    /// Warning color for caution states
    let warning: Color = Color(hex: "#F59E0B") ?? .orange
    /// Error color for destructive actions and errors
    let error: Color = Color(hex: "#EF4444") ?? .red
    /// Info color for informational content
    let info: Color = Color(hex: "#3B82F6") ?? .blue
    
    // MARK: - Design Tokens
    
    /// Premium rounded corner radius for cards and large elements
    static let cardCornerRadius: CGFloat = 20
    /// Medium rounded corner radius for smaller elements
    static let mediumCornerRadius: CGFloat = 12
    /// Small rounded corner radius for buttons and chips
    static let smallCornerRadius: CGFloat = 8
    
    /// Premium shadow for cards and elevated elements
    let cardShadow: Color
    /// Subtle shadow for interactive elements
    let subtleShadow: Color
    /// Strong shadow for emphasis
    let strongShadow: Color
    
    /// Spacing constants following Apple HIG 8pt grid system
    struct Spacing {
        // Micro spacing
        static let xs: CGFloat = 4
        
        // Small spacing
        static let sm: CGFloat = 8
        
        // Medium spacing (most common)
        static let md: CGFloat = 16
        
        // Large spacing
        static let lg: CGFloat = 24
        
        // Extra large spacing
        static let xl: CGFloat = 32
        
        // Extra extra large spacing
        static let xxl: CGFloat = 48
        
        // Section spacing
        static let section: CGFloat = 40
        
        // Screen edge padding
        static let screenEdge: CGFloat = 20
    }
    
    /// Typography scale following Apple HIG guidelines
    struct Typography {
        // Display styles - for large, prominent text
        static let largeTitle: Font = .largeTitle.weight(.bold)
        static let title: Font = .title.weight(.bold)
        static let title2: Font = .title2.weight(.bold)
        static let title3: Font = .title3.weight(.semibold)
        
        // Text styles - for body content
        static let headline: Font = .headline.weight(.semibold)
        static let subheadline: Font = .subheadline.weight(.medium)
        static let body: Font = .body.weight(.regular)
        static let bodyEmphasized: Font = .body.weight(.medium)
        static let callout: Font = .callout.weight(.regular)
        
        // Caption styles - for secondary information
        static let caption: Font = .caption.weight(.regular)
        static let caption2: Font = .caption2.weight(.medium)
        static let footnote: Font = .footnote.weight(.regular)
    }

    init(config: AppConfig, colorScheme: ColorScheme = .light) {
        // Initialize the primary color from the configuration's hex string
        self.primary = Color(hex: config.brandPrimaryHex) ?? Color(hex: "#6B8E7F")!
        
        // Create lighter and darker variants
        self.primaryLight = Color(hex: "#88A599") ?? self.primary.opacity(0.7)
        self.primaryDark = Color(hex: "#4F6A5E") ?? self.primary
        
        // Gradient colors based on primary
        self.gradientStart = self.primary
        self.gradientEnd = self.primaryLight
        
        // Dynamic backgrounds based on color scheme parameter (no UIKit lookup needed!)
        let isDark = colorScheme == .dark
        
        if isDark {
            // Dark mode - elevate cards with lighter colors
            self.background = Color(hex: "#000000") ?? Color(.systemBackground)
            self.cardBackground = Color(hex: "#1C1C1E") ?? Color(.secondarySystemBackground)
            self.secondaryCardBackground = Color(hex: "#2C2C2E") ?? Color(.tertiarySystemBackground)
            
            // Shadows for dark mode
            self.cardShadow = Color.black.opacity(0.3)
            self.subtleShadow = Color.black.opacity(0.2)
            self.strongShadow = Color.black.opacity(0.5)
        } else {
            // Light mode - cards with subtle tint and better contrast
            self.background = Color(hex: "#F5F5F7") ?? Color(.systemBackground)
            self.cardBackground = Color.white
            self.secondaryCardBackground = Color(hex: "#FAFAFA") ?? Color(.secondarySystemBackground)
            
            // Shadows for light mode
            self.cardShadow = Color.black.opacity(0.08)
            self.subtleShadow = Color.black.opacity(0.04)
            self.strongShadow = Color.black.opacity(0.15)
        }
    }
    
    // MARK: - Premium Card Style
    
    /// Creates a premium card style with gradient border
    func premiumCardStyle() -> some View {
        return AnyView(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(cardBackground)
                .shadow(color: cardShadow, radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [primary.opacity(0.3), primary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    /// Creates a gradient card background
    func gradientCardBackground() -> some View {
        return AnyView(
            LinearGradient(
                colors: [
                    gradientStart.opacity(0.15),
                    gradientEnd.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
