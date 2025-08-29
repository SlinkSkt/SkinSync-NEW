/// Core/Theme.swift
import SwiftUI

extension Color {
    init?(hex: String) {
        var hex = hex
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard let v = UInt64(hex, radix: 16) else { return nil }
        let r,g,b,a: Double
        switch hex.count {
        case 6:
            r = Double((v >> 16) & 0xFF) / 255
            g = Double((v >> 8) & 0xFF) / 255
            b = Double(v & 0xFF) / 255
            a = 1
        case 8:
            r = Double((v >> 24) & 0xFF) / 255
            g = Double((v >> 16) & 0xFF) / 255
            b = Double((v >> 8) & 0xFF) / 255
            a = Double(v & 0xFF) / 255
        default: return nil
        }
        self = Color(red: r, green: g, blue: b, opacity: a)
    }
}

struct AppTheme {
    let primary: Color
    let background: Color = Color(.systemBackground)
    let surface: Color = Color(.secondarySystemBackground)
    let textPrimary: Color = .primary
    let textSecondary: Color = .secondary
    
    init(config: AppConfig) {
        self.primary = Color(hex: config.brandPrimaryHex) ?? .green
    }
}
