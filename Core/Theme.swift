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
    /// The main background color for views and screens.
    let background: Color = Color(.systemBackground)
    /// The surface color for cards, sheets, and secondary UI elements.
    let surface: Color = Color(.secondarySystemBackground)
    /// The main color for primary text content.
    let textPrimary: Color = .primary
    /// The color for secondary or less prominent text.
    let textSecondary: Color = .secondary

    init(config: AppConfig) {
        // Initialize the primary color from the configuration's hex string, fallback to .green if invalid.
        self.primary = Color(hex: config.brandPrimaryHex) ?? .green
    }
}
