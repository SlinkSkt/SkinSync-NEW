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
        HStack(spacing: AppTheme.Spacing.lg) {
            // Left side - UV Index Info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                // Header with UV Index and Level
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: viewModel.uvLevel.icon)
                        .font(.title2)
                        .foregroundStyle(uvIndexColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        if let uvIndex = viewModel.uvIndex {
                            Text("UV Index \(uvIndex, specifier: "%.1f")")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(.primary)
                            
                            Text(viewModel.uvLevel.rawValue)
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(uvIndexColor)
                                .fontWeight(.medium)
                        } else if viewModel.isLoading {
                            Text("Loading UV data...")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(.secondary)
                        } else if viewModel.error != nil {
                            Text("UV data unavailable")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Tap to get UV index")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                // Location and Recommendation
                if let uvIndex = viewModel.uvIndex {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        // Location info
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: "location")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(viewModel.currentCity ?? "Current location")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(.secondary)
                                .onAppear {
                                    print("🏙️ Displaying city: \(viewModel.currentCity ?? "nil")")
                                }
                        }
                        
                        // Sunscreen recommendation
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: "sun.max.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Text(sunscreenRecommendation(for: uvIndex))
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
            }
            
            // Right side - Graphics
            if let uvIndex = viewModel.uvIndex {
                VStack(spacing: AppTheme.Spacing.md) {
                    // UV Index Circle
                    ZStack {
                        Circle()
                            .stroke(uvIndexColor.opacity(0.3), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: min(uvIndex / 11.0, 1.0))
                            .stroke(uvIndexColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.0), value: uvIndex)
                        
                        VStack(spacing: 2) {
                            Text("\(Int(uvIndex))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(uvIndexColor)
                            Text("UV")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Current UV Level Indicator
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(uvIndexColor)
                                .frame(width: 8, height: 8)
                            Text(viewModel.uvLevel.rawValue)
                                .font(.caption2)
                                .foregroundStyle(uvIndexColor)
                                .fontWeight(.medium)
                        }
                        
                        Text("Current Level")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                // Placeholder graphics when no data
                VStack(spacing: AppTheme.Spacing.md) {
                    Circle()
                        .stroke(Color(.quaternaryLabel), lineWidth: 8)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "questionmark")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        )
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius)
                .stroke(uvIndexColor.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            if viewModel.uvIndex == nil && !viewModel.isLoading {
                viewModel.requestLocationAndFetchUVIndex()
            }
            // Always try to get city name
            viewModel.requestLocationAndFetchCity()
        }
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
        UVIndexView(theme: AppTheme(config: AppConfig.default), uvService: OpenUVService(apiKey: "openuv-2sy4amrmgcdf6jo-io"))
        
        UVIndexView(theme: AppTheme(config: AppConfig.default), uvService: MockUVIndexService())
    }
    .padding()
    .background(Color(.systemBackground))
}
