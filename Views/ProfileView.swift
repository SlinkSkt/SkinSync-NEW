//
//  ProfileView.swift
//  SkinSync
//
//  Premium, branded Profile experience following Apple HIG
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var vm: ProfileViewModel
    @EnvironmentObject private var routineVM: RoutineViewModel
    let theme: AppTheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var newAllergy: String = ""
    @State private var showingReminders = false
    @State private var showingResetAlert = false
    @State private var showingIconPicker = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.xl) {
                    // Header Section
                    headerSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Personal Information
                    personalInfoSection
                    
                    // Skin Profile
                    skinProfileSection
                    
                    // Goals
                    goalsSection
                    
                    // App Settings
                    appSettingsSection
                    
                    // Danger Zone
                    dangerZoneSection
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.lg)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingReminders) {
            RemindersSettingsView()
                .environmentObject(routineVM)
        }
        .alert("Reset All Data", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                vm.resetAllData()
            }
        } message: {
            Text("This will permanently delete all your profile data, routines, and preferences. This action cannot be undone.")
        }
        .sheet(isPresented: $showingIconPicker) {
            IconPickerView(selectedIcon: Binding(
                get: { vm.profile.profileIcon },
                set: { vm.profile.profileIcon = $0; vm.save() }
            ))
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Avatar
            Button {
                showingIconPicker = true
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [theme.primary.opacity(0.3), theme.primary.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: vm.profile.profileIcon)
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(theme.primary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Change profile icon")
            
            VStack(spacing: AppTheme.Spacing.sm) {
                Text(vm.profile.nickname.isEmpty ? "Your Profile" : vm.profile.nickname)
                    .font(AppTheme.Typography.largeTitle)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text("SkinSync Member")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.lg)
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Quick Actions")
                .font(AppTheme.Typography.title)
                .foregroundStyle(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.md) {
                    QuickActionCard(
                        title: "Edit Profile",
                        icon: "pencil",
                        color: theme.primary
                    ) {
                        // Edit profile action
                    }
                    
                    QuickActionCard(
                        title: "Goals",
                        icon: "target",
                        color: .blue
                    ) {
                        // Goals action
                    }
                    
                    QuickActionCard(
                        title: "Allergies",
                        icon: "exclamationmark.triangle",
                        color: .orange
                    ) {
                        // Allergies action
                    }
                    
                    QuickActionCard(
                        title: "Reminders",
                        icon: "bell.badge",
                        color: .purple
                    ) {
                        showingReminders = true
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xs)
            }
        }
    }
    
    // MARK: - Personal Information Section
    
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Label("Personal Information", systemImage: "person.text.rectangle")
                .font(AppTheme.Typography.title)
                .foregroundStyle(.primary)
            
            VStack(spacing: AppTheme.Spacing.md) {
                ProfileField(
                    title: "Nickname",
                    value: Binding(
                        get: { vm.profile.nickname },
                        set: { vm.profile.nickname = $0; vm.save() }
                    ),
                    placeholder: "Enter your nickname"
                )
                
                ProfileField(
                    title: "Birth Year Range",
                    value: Binding(
                        get: { vm.profile.yearOfBirthRange },
                        set: { vm.profile.yearOfBirthRange = $0; vm.save() }
                    ),
                    placeholder: "e.g. 2001-2005"
                )
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .shadow(color: theme.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Skin Profile Section
    
    private var skinProfileSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Label("Skin Profile", systemImage: "face.smiling")
                .font(AppTheme.Typography.title)
                .foregroundStyle(.primary)
            
            VStack(spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Skin Type")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Menu {
                        ForEach(SkinType.allCases) { skinType in
                            Button(action: {
                                vm.profile.skinType = skinType
                                vm.save()
                            }) {
                                HStack {
                                    Text(skinType.rawValue.capitalized)
                                    if vm.profile.skinType == skinType {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(vm.profile.skinType.rawValue.capitalized)
                                .font(AppTheme.Typography.body)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(AppTheme.Spacing.md)
                        .background(Color(.quaternaryLabel).opacity(0.3), in: RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius))
                    }
                }
                
                // Allergies
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Allergies")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: AppTheme.Spacing.sm) {
                        TextField("Add allergy", text: $newAllergy)
                            .font(AppTheme.Typography.body)
                            .padding(AppTheme.Spacing.md)
                            .background(Color(.quaternaryLabel).opacity(0.3), in: RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius))
                        
                        Button("Add") {
                            let allergy = newAllergy.trimmingCharacters(in: .whitespaces)
                            guard !allergy.isEmpty else { return }
                            vm.profile.allergies.append(allergy)
                            newAllergy = ""
                            vm.save()
                        }
                        .font(AppTheme.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.md)
                        .background(theme.primary, in: RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius))
                    }
                    
                    if !vm.profile.allergies.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                ForEach(Array(vm.profile.allergies.enumerated()), id: \.offset) { idx, allergy in
                                    HStack(spacing: AppTheme.Spacing.xs) {
                                        Text(allergy)
                                            .font(AppTheme.Typography.caption)
                                        Button {
                                            vm.profile.allergies.remove(at: idx)
                                            vm.save()
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.horizontal, AppTheme.Spacing.sm)
                                    .padding(.vertical, AppTheme.Spacing.xs)
                                    .background(theme.primary.opacity(0.15))
                                    .foregroundStyle(theme.primary)
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.xs)
                        }
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .shadow(color: theme.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Goals Section
    
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Label("Skin Goals", systemImage: "target")
                .font(AppTheme.Typography.title)
                .foregroundStyle(.primary)
            
            VStack(spacing: AppTheme.Spacing.md) {
                ForEach(SkinGoal.allCases) { goal in
                    HStack {
                        Toggle(goal.rawValue, isOn: Binding(
                            get: { vm.profile.goals.contains(goal) },
                            set: { isOn in
                                if isOn {
                                    vm.profile.goals.append(goal)
                                } else {
                                    vm.profile.goals.removeAll { $0 == goal }
                                }
                                vm.save()
                            }
                        ))
                        .font(AppTheme.Typography.body)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .shadow(color: theme.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - App Settings Section
    
    private var appSettingsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Label("App Settings", systemImage: "gear")
                .font(AppTheme.Typography.title)
                .foregroundStyle(.primary)
            
            VStack(spacing: AppTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("Theme Color")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Olive Green")
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(.primary)
                    }
                    
                    Spacer()
                    
                    Circle()
                        .fill(theme.primary)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(Color(.quaternaryLabel), lineWidth: 1)
                        )
                }
                .padding(AppTheme.Spacing.md)
                        .background(Color(.quaternaryLabel).opacity(0.2), in: RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius))
                
                Button {
                    showingReminders = true
                } label: {
                    HStack {
                        Label("Notification Settings", systemImage: "bell.badge")
                            .font(AppTheme.Typography.body)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(AppTheme.Spacing.md)
                        .background(Color(.quaternaryLabel).opacity(0.2), in: RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .shadow(color: theme.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Danger Zone Section
    
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Label("Danger Zone", systemImage: "exclamationmark.triangle")
                .font(AppTheme.Typography.title)
                .foregroundStyle(.red)
            
            Button {
                showingResetAlert = true
            } label: {
                HStack {
                    Label("Reset All Data", systemImage: "trash")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(.red)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(AppTheme.Spacing.md)
                .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                        .stroke(.red.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(AppTheme.Spacing.lg)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .shadow(color: theme.cardShadow, radius: 4, x: 0, y: 2)
        .padding(.bottom, AppTheme.Spacing.xl)
    }
}

// MARK: - Supporting Views

private struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius))
                
                Text(title)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80)
            .padding(AppTheme.Spacing.sm)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius))
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

private struct ProfileField: View {
    let title: String
    let value: Binding<String>
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(.secondary)
            
            TextField(placeholder, text: value)
                .font(AppTheme.Typography.body)
                .padding(AppTheme.Spacing.md)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius))
        }
    }
}

// MARK: - Icon Picker View

private struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss
    
    private let availableIcons = [
        "person.crop.circle.fill",
        "person.crop.circle",
        "person.fill",
        "person",
        "face.smiling",
        "face.smiling.fill",
        "heart.fill",
        "heart",
        "star.fill",
        "star",
        "sparkles",
        "leaf.fill",
        "leaf",
        "sun.max.fill",
        "sun.max",
        "moon.fill",
        "moon",
        "cloud.fill",
        "cloud",
        "drop.fill",
        "drop"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: AppTheme.Spacing.lg) {
                    ForEach(availableIcons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                            dismiss()
                        } label: {
                            Image(systemName: icon)
                                .font(.title)
                                .foregroundStyle(selectedIcon == icon ? .white : .primary)
                                .frame(width: 60, height: 60)
                                .background(
                                    Circle()
                                        .fill(selectedIcon == icon ? Color.accentColor : Color(.quaternaryLabel).opacity(0.3))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
