//
//  UVIndexView.swift
//  SkinSync
//
//  SwiftUI view component for displaying UV index information
//

import SwiftUI

struct UVIndexView: View {
    @StateObject private var viewModel: UVIndexViewModel
    let theme: AppTheme
    
    init(theme: AppTheme, uvService: UVIndexService) {
        self.theme = theme
        self._viewModel = StateObject(wrappedValue: UVIndexViewModel(uvService: uvService))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Header with UV Index and Level
            HStack {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: viewModel.uvLevel.icon)
                        .font(.title2)
                        .foregroundStyle(uvIndexColor)
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        if let uvIndex = viewModel.uvIndex {
                            Text("UV Index \(uvIndex, specifier: "%.1f")")
                                .font(AppTheme.Typography.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            Text(viewModel.uvLevel.rawValue)
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(uvIndexColor)
                                .fontWeight(.medium)
                        } else if viewModel.isLoading {
                            Text("Loading UV data...")
                                .font(AppTheme.Typography.title3)
                                .foregroundStyle(.secondary)
                        } else if viewModel.error != nil {
                            Text("UV data unavailable")
                                .font(AppTheme.Typography.title3)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Tap to get UV index")
                                .font(AppTheme.Typography.title3)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // UV Level Progress Line
            if let uvIndex = viewModel.uvIndex {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    HStack {
                        Text("Current Level")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(uvIndex))/11")
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(uvIndexColor)
                    }
                    
                    // Progress line
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background line
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(.quaternaryLabel))
                                .frame(height: 8)
                            
                            // Progress line
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: [uvIndexColor.opacity(0.7), uvIndexColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * min(uvIndex / 11.0, 1.0), height: 8)
                                .animation(.easeInOut(duration: 1.2), value: uvIndex)
                        }
                    }
                    .frame(height: 8)
                    
                    // Level markers
                    HStack {
                        ForEach(0..<6) { index in
                            VStack(spacing: 2) {
                                Rectangle()
                                    .fill(Color(.quaternaryLabel))
                                    .frame(width: 1, height: 4)
                                
                                Text("\(index * 2)")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.tertiary)
                            }
                            
                            if index < 5 {
                                Spacer()
                            }
                        }
                    }
                }
            } else {
                // Placeholder line when no data
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    HStack {
                        Text("UV Level")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("--/11")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.quaternaryLabel))
                        .frame(height: 8)
                }
            }
            
            // Location and Recommendation
            if let uvIndex = viewModel.uvIndex {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    // Location info
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text(viewModel.currentCity ?? "Unknown location")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Recommendation
                    Text(sunscreenRecommendation(for: uvIndex))
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(uvIndexColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: theme.cardShadow, radius: 4, x: 0, y: 2)
        .onAppear {
            if viewModel.uvIndex == nil && !viewModel.isLoading {
                viewModel.requestLocationAndFetchUVIndex()
            }
            // Always try to get city name
            viewModel.requestLocationAndFetchCity()
        }
        .onTapGesture {
            // Allow tapping to retry UV data fetch or use mock data
            print("🔄 UV Index tapped - retrying...")
            if viewModel.error != nil {
                print("🧪 API failed, using mock data...")
                viewModel.forceMockData()
            } else {
                viewModel.requestLocationAndFetchUVIndex()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("UV Index: \(viewModel.uvIndex?.formatted() ?? "Loading")")
        .accessibilityHint("Tap to refresh UV index data")
    }
    
    private var uvIndexColor: Color {
        switch viewModel.uvLevel {
        case .low:
            return .green
        case .moderate:
            return .yellow
        case .high:
            return .orange
        case .veryHigh:
            return .red
        case .extreme:
            return .purple
        case .unknown:
            return .secondary
        }
    }
    
    private func sunscreenRecommendation(for uvIndex: Double) -> String {
        switch UVLevel.from(value: uvIndex) {
        case .low:
            return "Minimal sun protection needed"
        case .moderate:
            return "Apply sunscreen with SPF 30 or higher"
        case .high:
            return "Apply sunscreen SPF 30+, seek shade during midday"
        case .veryHigh:
            return "Apply sunscreen SPF 50+, avoid sun 10am-4pm"
        case .extreme:
            return "Apply sunscreen SPF 50+, stay indoors if possible"
        case .unknown:
            return "UV data unavailable"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppTheme.Spacing.md) {
        UVIndexView(theme: AppTheme(config: AppConfig.default), uvService: OpenUVService())
        
        UVIndexView(theme: AppTheme(config: AppConfig.default), uvService: MockUVIndexService())
    }
    .padding()
    .background(Color(.systemBackground))
}
