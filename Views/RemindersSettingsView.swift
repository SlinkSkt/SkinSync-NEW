//
//  RemindersSettingsView.swift
//  SkinSync
//
//  Premium notification settings with permission handling
//
import SwiftUI
import UserNotifications

/// Premium reminders settings screen for AM / PM routine notifications.
/// Handles permission requests and provides beautiful UI
struct RemindersSettingsView: View {
    @EnvironmentObject private var vm: NotificationViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showPermissionAlert = false
    @State private var permissionDenied = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    
    private var theme: AppTheme {
        AppTheme(config: .default, colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            // Background
            theme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header Card
                    VStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [theme.primary, theme.primaryDark],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .symbolRenderingMode(.hierarchical)
                        
                        VStack(spacing: AppTheme.Spacing.xs) {
                            Text("Skincare Reminders")
                                .font(AppTheme.Typography.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            
                            Text("Stay consistent with daily notifications")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(AppTheme.Spacing.xl)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                .fill(theme.cardBackground)
                            
                            LinearGradient(
                                colors: [
                                    theme.primary.opacity(0.08),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                            .strokeBorder(theme.primary.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: theme.cardShadow, radius: 12, x: 0, y: 6)
                    
                    // Permission Status Card (if not authorized)
                    if notificationStatus != .authorized {
                        PermissionCard(
                            status: notificationStatus,
                            onRequestPermission: {
                                _ = await requestPermission()
                            },
                            theme: theme
                        )
                    }
                    
                    // Morning Reminder Card
                    ReminderCard(
                        icon: "sun.max.fill",
                        title: "Morning Routine",
                        subtitle: "Start your day fresh",
                        color: theme.success,
                        isEnabled: vm.notif.enableAM,
                        time: dateFrom(hour: vm.notif.amHour, minute: vm.notif.amMinute),
                        message: "Time for your morning skincare routine! ☀️",
                        onToggle: { enabled in
                            await handleToggle(enabled: enabled, isMorning: true)
                        },
                        onTimeChange: { date in
                            let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                            vm.notif.amHour = c.hour ?? 7
                            vm.notif.amMinute = c.minute ?? 30
                            Task { await vm.applyNotificationPrefs(vm.notif) }
                        },
                        theme: theme
                    )
                    
                    // Evening Reminder Card
                    ReminderCard(
                        icon: "moon.fill",
                        title: "Evening Routine",
                        subtitle: "End your day right",
                        color: theme.info,
                        isEnabled: vm.notif.enablePM,
                        time: dateFrom(hour: vm.notif.pmHour, minute: vm.notif.pmMinute),
                        message: "Time for your evening skincare routine! 🌙",
                        onToggle: { enabled in
                            await handleToggle(enabled: enabled, isMorning: false)
                        },
                        onTimeChange: { date in
                            let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                            vm.notif.pmHour = c.hour ?? 21
                            vm.notif.pmMinute = c.minute ?? 0
                            Task { await vm.applyNotificationPrefs(vm.notif) }
                        },
                        theme: theme
                    )
                    
                    // Tips Card
                    if vm.notif.enableAM || vm.notif.enablePM {
                        TipsCard(theme: theme)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.screenEdge)
                .padding(.vertical, AppTheme.Spacing.md)
            }
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkNotificationStatus()
        }
        .alert("Permission Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable notifications in Settings to receive skincare reminders.")
        }
    }

    // MARK: - Helpers
    
    private func dateFrom(hour: Int, minute: Int) -> Date {
        Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationStatus = settings.authorizationStatus
            }
        }
    }
    
    private func requestPermission() async -> Bool {
        let granted = await vm.requestNotificationPermission()
        
        if granted {
            notificationStatus = .authorized
        } else {
            permissionDenied = true
            showPermissionAlert = true
        }
        
        return granted
    }
    
    private func handleToggle(enabled: Bool, isMorning: Bool) async {
        // Check permission first
        if enabled && notificationStatus != .authorized {
            let granted = await requestPermission()
            if !granted {
                return  // Don't enable if permission denied
            }
        }
        
        // Update the preference
        if isMorning {
            vm.notif.enableAM = enabled
        } else {
            vm.notif.enablePM = enabled
        }
        
        await vm.applyNotificationPrefs(vm.notif)
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Permission Card

struct PermissionCard: View {
    let status: UNAuthorizationStatus
    let onRequestPermission: () async -> Void
    let theme: AppTheme
    
    @State private var isRequesting = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: status == .denied ? "bell.slash.fill" : "bell.badge.fill")
                    .font(.title2)
                    .foregroundStyle(status == .denied ? theme.error : theme.warning)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(status == .denied ? "Notifications Disabled" : "Enable Notifications")
                        .font(AppTheme.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(status == .denied 
                        ? "Go to Settings to enable notifications"
                        : "Allow SkinSync to send you reminders")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            Button(action: {
                isRequesting = true
                Task {
                    await onRequestPermission()
                    isRequesting = false
                }
            }) {
                HStack {
                    if isRequesting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: status == .denied ? "gear" : "bell.badge")
                    }
                    
                    Text(status == .denied ? "Open Settings" : "Enable Notifications")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(
                    LinearGradient(
                        colors: [
                            status == .denied ? theme.error : theme.warning,
                            (status == .denied ? theme.error : theme.warning).opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius))
                .shadow(color: (status == .denied ? theme.error : theme.warning).opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(isRequesting)
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(
                    (status == .denied ? theme.error : theme.warning).opacity(0.3),
                    lineWidth: 1.5
                )
        )
        .shadow(color: theme.cardShadow, radius: 12, x: 0, y: 6)
    }
}

// MARK: - Reminder Card

struct ReminderCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let isEnabled: Bool
    let time: Date
    let message: String
    let onToggle: (Bool) async -> Void
    let onTimeChange: (Date) -> Void
    let theme: AppTheme
    
    @State private var isToggling = false
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Header
            HStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                        .symbolRenderingMode(.hierarchical)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTheme.Typography.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { isEnabled },
                    set: { newValue in
                        isToggling = true
                        Task {
                            await onToggle(newValue)
                            isToggling = false
                        }
                    }
                ))
                .labelsHidden()
                .tint(color)
                .disabled(isToggling)
            }
            
            // Time Picker (when enabled)
            if isEnabled {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Reminder Time")
                        .font(AppTheme.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { time },
                            set: { onTimeChange($0) }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .datePickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .padding(AppTheme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius)
                            .fill(theme.secondaryCardBackground)
                    )
                    
                    // Notification Message Preview
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "text.bubble.fill")
                            .font(.caption)
                            .foregroundStyle(color)
                        
                        Text(message)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(AppTheme.Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                            .fill(color.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .fill(theme.cardBackground)
                
                LinearGradient(
                    colors: [
                        color.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: theme.cardShadow, radius: 12, x: 0, y: 6)
        .shadow(color: color.opacity(0.08), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Tips Card

struct TipsCard: View {
    let theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.title3)
                    .foregroundStyle(theme.warning)
                
                Text("Tips for Success")
                    .font(AppTheme.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                TipRow(
                    icon: "checkmark.circle.fill",
                    text: "Consistency is key - stick to your routine times",
                    color: theme.success
                )
                
                TipRow(
                    icon: "clock.fill",
                    text: "Morning: Best applied after washing your face",
                    color: theme.info
                )
                
                TipRow(
                    icon: "moon.fill",
                    text: "Evening: Apply before bedtime for best results",
                    color: theme.accentPurple
                )
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(theme.warning.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: theme.subtleShadow, radius: 8, x: 0, y: 4)
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 20)
            
            Text(text)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RemindersSettingsView()
            .environmentObject(NotificationViewModel(
                store: FileDataStore(),
                scheduler: LocalNotificationScheduler()
            ))
    }
}

