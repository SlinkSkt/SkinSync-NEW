//
//  UVIndexWidget.swift
//  SkinSync
//
//  UV Index Widget - Shows current UV index on home screen
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct UVWidgetEntry: TimelineEntry {
    let date: Date
    let uvIndex: Double?
    let uvLevel: String
    let uvColor: Color
    let cityName: String?
}

// MARK: - Timeline Provider
struct UVWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> UVWidgetEntry {
        UVWidgetEntry(
            date: Date(),
            uvIndex: 5.0,
            uvLevel: "Moderate",
            uvColor: Color.orange,
            cityName: nil
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (UVWidgetEntry) -> Void) {
        let entry = UVWidgetEntry(
            date: Date(),
            uvIndex: 5.0,
            uvLevel: "Moderate",
            uvColor: Color.orange,
            cityName: nil
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<UVWidgetEntry>) -> Void) {
        Task {
            let entry = await fetchUVData()
            
            // Update every 30 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            completion(timeline)
        }
    }
    
    private func fetchUVData() async -> UVWidgetEntry {
        // Try to read from shared UserDefaults
        if let sharedDefaults = UserDefaults(suiteName: "group.com.skinsync.app") {
            if let uvIndex = sharedDefaults.object(forKey: "lastUVIndex") as? Double {
                let cityName = sharedDefaults.string(forKey: "lastCity")
                let (level, color) = getUVLevelAndColor(uvIndex)
                
                return UVWidgetEntry(
                    date: Date(),
                    uvIndex: uvIndex,
                    uvLevel: level,
                    uvColor: color,
                    cityName: cityName
                )
            }
        }
        
        // Fallback to default
        return UVWidgetEntry(
            date: Date(),
            uvIndex: nil,
            uvLevel: "No Data",
            uvColor: Color.gray,
            cityName: nil
        )
    }
    
    private func getUVLevelAndColor(_ uv: Double) -> (String, Color) {
        switch uv {
        case 0..<3:
            return ("Low", Color.green)
        case 3..<6:
            return ("Moderate", Color.yellow)
        case 6..<8:
            return ("High", Color.orange)
        case 8..<11:
            return ("Very High", Color.red)
        default:
            return ("Extreme", Color.purple)
        }
    }
}

// MARK: - Widget View
struct UVWidgetView: View {
    var entry: UVWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    var entry: UVWidgetEntry
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    entry.uvColor.opacity(0.3),
                    entry.uvColor.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                // Header
                HStack {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(entry.uvColor)
                    
                    Text("UV Index")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                
                Spacer()
                
                // UV Index value
                if let uvIndex = entry.uvIndex {
                    VStack(spacing: 4) {
                        Text("\(Int(uvIndex.rounded()))")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(entry.uvColor)
                        
                        Text(entry.uvLevel)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                        
                        Text("No Data")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Footer with time
                Text("Updated \(entry.date, style: .time)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    var entry: UVWidgetEntry
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    entry.uvColor.opacity(0.3),
                    entry.uvColor.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack(spacing: 12) {
                // Left side - UV Index
                VStack(spacing: 4) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(entry.uvColor)
                    
                    if let uvIndex = entry.uvIndex {
                        Text("\(Int(uvIndex.rounded()))")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(entry.uvColor)
                        
                        Text(entry.uvLevel)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                    } else {
                        VStack(spacing: 2) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 24))
                                .foregroundStyle(.secondary)
                            
                            Text("No Data")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Right side - Details
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("UV Index")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        if let cityName = entry.cityName {
                            HStack(spacing: 3) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 9))
                                Text(cityName)
                                    .font(.system(size: 10))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 2)
                    
                    if entry.uvIndex != nil {
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(entry.uvColor)
                            
                            Text(getRecommendation())
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    Text("Updated \(entry.date, style: .time)")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
    
    private func getRecommendation() -> String {
        guard let uv = entry.uvIndex else { return "No data available" }
        
        switch uv {
        case 0..<3:
            return "Minimal protection needed"
        case 3..<6:
            return "Wear sunscreen SPF 30+"
        case 6..<8:
            return "Seek shade, wear protection"
        case 8..<11:
            return "Avoid sun exposure"
        default:
            return "Stay indoors if possible"
        }
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    var entry: UVWidgetEntry
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    entry.uvColor.opacity(0.3),
                    entry.uvColor.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 10) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("UV Index")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        if let cityName = entry.cityName {
                            HStack(spacing: 3) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 10))
                                Text(cityName)
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(entry.uvColor)
                }
                
                // Main UV Display
                if let uvIndex = entry.uvIndex {
                    VStack(spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(Int(uvIndex.rounded()))")
                                .font(.system(size: 56, weight: .bold))
                                .foregroundStyle(entry.uvColor)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.uvLevel)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.primary)
                                
                                Text("UV Level")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        // UV Scale
                        UVScaleView(currentUV: uvIndex)
                            .padding(.horizontal, 4)
                    }
                    .padding(.vertical, 6)
                    
                    // Recommendations
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Protection Advice")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        VStack(spacing: 6) {
                            RecommendationRow(
                                icon: "figure.walk",
                                text: getActivityRecommendation(),
                                color: entry.uvColor
                            )
                            
                            RecommendationRow(
                                icon: "eyeglasses",
                                text: getProtectionRecommendation(),
                                color: entry.uvColor
                            )
                            
                            if let exposure = getExposureTime() {
                                RecommendationRow(
                                    icon: "clock.fill",
                                    text: exposure,
                                    color: entry.uvColor
                                )
                            }
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary)
                        
                        Text("No UV Data Available")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        Text("Open the app to fetch current UV levels")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    .padding(.vertical)
                }
                
                Spacer(minLength: 0)
                
                // Footer
                HStack {
                    Text("Updated \(entry.date, style: .time)")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    
                    Spacer()
                    
                    Text("SkinSync")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
    
    private func getActivityRecommendation() -> String {
        guard let uv = entry.uvIndex else { return "No data" }
        
        switch uv {
        case 0..<3:
            return "Safe for outdoor activities"
        case 3..<6:
            return "Take precautions if outdoors"
        case 6..<8:
            return "Reduce time in midday sun"
        case 8..<11:
            return "Minimize sun exposure"
        default:
            return "Avoid being outside"
        }
    }
    
    private func getProtectionRecommendation() -> String {
        guard let uv = entry.uvIndex else { return "No data" }
        
        switch uv {
        case 0..<3:
            return "Sunglasses recommended"
        case 3..<6:
            return "SPF 30+, hat & sunglasses"
        case 6..<8:
            return "SPF 50+, protective clothing"
        case 8..<11:
            return "Maximum protection required"
        default:
            return "Full protection essential"
        }
    }
    
    private func getExposureTime() -> String? {
        guard let uv = entry.uvIndex else { return nil }
        
        switch uv {
        case 0..<3:
            return "Safe exposure: 60+ minutes"
        case 3..<6:
            return "Safe exposure: 30-45 minutes"
        case 6..<8:
            return "Safe exposure: 15-20 minutes"
        case 8..<11:
            return "Safe exposure: <10 minutes"
        default:
            return "Safe exposure: <5 minutes"
        }
    }
}

// MARK: - Helper Views

struct UVScaleView: View {
    let currentUV: Double
    
    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background scale
                    LinearGradient(
                        colors: [
                            Color.green,
                            Color.yellow,
                            Color.orange,
                            Color.red,
                            Color.purple
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 8)
                    .clipShape(Capsule())
                    
                    // Current position indicator
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .offset(x: getIndicatorPosition(width: geometry.size.width))
                }
            }
            .frame(height: 16)
            
            HStack {
                Text("0")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("11+")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func getIndicatorPosition(width: CGFloat) -> CGFloat {
        let maxUV: CGFloat = 11
        let position = min(currentUV / maxUV, 1.0) * width
        return position - 8 // Center the indicator
    }
}

struct RecommendationRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(color)
                .frame(width: 16)
            
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Widget Configuration
struct UVIndexWidget: Widget {
    let kind: String = "UVIndexWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UVWidgetProvider()) { entry in
            UVWidgetView(entry: entry)
        }
        .configurationDisplayName("UV Index")
        .description("Stay informed about current UV levels")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Bundle
@main
struct SkinSyncWidgets: WidgetBundle {
    var body: some Widget {
        UVIndexWidget()
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    UVIndexWidget()
} timeline: {
    UVWidgetEntry(date: Date(), uvIndex: 3.0, uvLevel: "Moderate", uvColor: .orange, cityName: "Sydney")
    UVWidgetEntry(date: Date(), uvIndex: 8.0, uvLevel: "Very High", uvColor: .red, cityName: "Melbourne")
    UVWidgetEntry(date: Date(), uvIndex: nil, uvLevel: "No Data", uvColor: .gray, cityName: nil)
}
