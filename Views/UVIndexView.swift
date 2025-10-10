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
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                // Header with UV Index and Level
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: viewModel.uvLevel.icon)
                        .font(.title)
                        .foregroundStyle(uvIndexColor)
                        .frame(width: 32, height: 32)
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        if let uvIndex = viewModel.uvIndex {
                            Text("UV Index \(uvIndex, specifier: "%.1f")")
                                .font(AppTheme.Typography.title3)
                                .foregroundStyle(.primary)
                            
                            Text(viewModel.uvLevel.rawValue)
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(uvIndexColor)
                                .fontWeight(.semibold)
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
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.9)
                    }
                }
                
                // Location and Recommendation
                if let uvIndex = viewModel.uvIndex {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        // Location info
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: "location.fill")
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
                                .lineLimit(2)
                        }
                    }
                }
            }
            
            // Right side - Graphics
            if let uvIndex = viewModel.uvIndex {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // UV Index Circle
                    ZStack {
                        Circle()
                            .stroke(uvIndexColor.opacity(0.2), lineWidth: 6)
                            .frame(width: 88, height: 88)
                        
                        Circle()
                            .trim(from: 0, to: min(uvIndex / 11.0, 1.0))
                            .stroke(uvIndexColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 88, height: 88)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.2), value: uvIndex)
                        
                        VStack(spacing: AppTheme.Spacing.xs) {
                            Text("\(Int(uvIndex))")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(uvIndexColor)
                            Text("UV")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(.secondary)
                                .fontWeight(.medium)
                        }
                    }
                    
                    // Current UV Level Indicator
                    VStack(spacing: AppTheme.Spacing.xs) {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Circle()
                                .fill(uvIndexColor)
                                .frame(width: 10, height: 10)
                            Text(viewModel.uvLevel.rawValue)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(uvIndexColor)
                                .fontWeight(.semibold)
                        }
                        
                        Text("Current Level")
                            .font(AppTheme.Typography.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                // Placeholder graphics when no data
                VStack(spacing: AppTheme.Spacing.lg) {
                    Circle()
                        .stroke(Color(.quaternaryLabel), lineWidth: 6)
                        .frame(width: 88, height: 88)
                        .overlay(
                            Image(systemName: "questionmark")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        )
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(uvIndexColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        .onAppear {
            if viewModel.uvIndex == nil && !viewModel.isLoading {
                viewModel.requestLocationAndFetchUVIndex()
            }
            // Always try to get city name
            viewModel.requestLocationAndFetchCity()
        }
        .onTapGesture {
            // Allow tapping to retry UV data fetch
            print("🔄 UV Index tapped - retrying...")
            viewModel.requestLocationAndFetchUVIndex()
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
        UVIndexView(theme: AppTheme(config: AppConfig.default), uvService: OpenUVService(apiKey: "openuv-2sy4amrmgcdf6jo-io"))
        
        UVIndexView(theme: AppTheme(config: AppConfig.default), uvService: MockUVIndexService())
    }
    .padding()
    .background(Color(.systemBackground))
}
