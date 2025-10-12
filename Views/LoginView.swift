//
//  LoginView.swift
//  SkinSync
//
//  Premium login screen with brand imagery and modern design
//

import SwiftUI

struct LoginView: View {
    let isLoading: Bool
    let errorMessage: String?
    let onSignIn: () -> Void
    
    @State private var isAnimating = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var theme: AppTheme {
        AppTheme(config: .default, colorScheme: colorScheme)
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    theme.primary.opacity(0.1),
                    theme.primaryLight.opacity(0.05),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo/Hero Image (smaller)
                Image("Login")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 200, maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: theme.primary.opacity(0.2), radius: 15, x: 0, y: 8)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .padding(.horizontal, AppTheme.Spacing.screenEdge)
                
                Spacer()
                    .frame(height: 32)
                
                // Features (compact)
                VStack(spacing: AppTheme.Spacing.sm) {
                    CompactFeatureRow(
                        icon: "qrcode.viewfinder",
                        title: "Scan & Analyze Products",
                        color: theme.primary
                    )
                    
                    CompactFeatureRow(
                        icon: "sparkle.magnifyingglass",
                        title: "AI Skincare Assistant",
                        color: theme.accentPurple
                    )
                    
                    CompactFeatureRow(
                        icon: "star.circle.fill",
                        title: "Custom Daily Routines",
                        color: theme.accentBlue
                    )
                }
                .padding(.horizontal, AppTheme.Spacing.screenEdge)
                .opacity(isAnimating ? 1.0 : 0.0)
                .offset(y: isAnimating ? 0 : 20)
                
                Spacer()
                    .frame(height: 32)
                    
                    // Sign in section
                    VStack(spacing: AppTheme.Spacing.lg) {
                        // Error message (if any)
                        if let errorMessage, !errorMessage.isEmpty {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(theme.error)
                                
                                Text(errorMessage)
                                    .font(AppTheme.Typography.footnote)
                                    .foregroundStyle(theme.error)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(AppTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius)
                                    .fill(theme.error.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius)
                                    .stroke(theme.error.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        // Google Sign In Button
                        Button(action: {
                            // Haptic feedback
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            onSignIn()
                        }) {
                            HStack(spacing: AppTheme.Spacing.md) {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "g.circle.fill")
                                        .font(.title2)
                                }
                                
                                Text(isLoading ? "Signing in..." : "Continue with Google")
                                    .font(AppTheme.Typography.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                ZStack {
                                    // Gradient background
                                    LinearGradient(
                                        colors: [theme.primaryLight, theme.primary, theme.primaryDark],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    
                                    // Shimmer effect when loading
                                    if isLoading {
                                        LinearGradient(
                                            colors: [
                                                Color.clear,
                                                Color.white.opacity(0.3),
                                                Color.clear
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        .animation(
                                            .linear(duration: 1.5).repeatForever(autoreverses: false),
                                            value: isLoading
                                        )
                                    }
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.5), .clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            .shadow(color: theme.primary.opacity(0.4), radius: 20, x: 0, y: 10)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isLoading)
                        .scaleEffect(isAnimating ? 1.0 : 0.95)
                        
                        // Privacy note
                        Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .opacity(isAnimating ? 1.0 : 0.0)
                    }
                    .padding(.horizontal, AppTheme.Spacing.screenEdge)
                    .padding(.bottom, AppTheme.Spacing.lg)
                    
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Compact Feature Row Component

struct CompactFeatureRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Icon container (smaller)
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
                    .symbolRenderingMode(.hierarchical)
            }
            
            // Text content
            Text(title)
                .font(AppTheme.Typography.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius)
                .fill(Color(.systemBackground))
                .shadow(color: color.opacity(0.08), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    LoginView(
        isLoading: false,
        errorMessage: nil,
        onSignIn: {}
    )
}

#Preview("Loading") {
    LoginView(
        isLoading: true,
        errorMessage: nil,
        onSignIn: {}
    )
}

#Preview("Error") {
    LoginView(
        isLoading: false,
        errorMessage: "Failed to sign in. Please try again.",
        onSignIn: {}
    )
}


