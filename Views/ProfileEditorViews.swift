//
//  ProfileEditorViews.swift
//  SkinSync
//
//  Editor views for profile management
//

import SwiftUI

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Binding var profile: Profile
    let theme: AppTheme
    var onSave: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var selectedBirthYear: Date = Calendar.current.date(from: DateComponents(year: 2000)) ?? Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("Nickname", text: $profile.nickname)
                        .textContentType(.nickname)
                        .autocapitalization(.words)
                    
                    TextField("Email", text: $profile.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    TextField("Phone Number", text: $profile.phoneNumber)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Birth Year")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(.secondary)
                        
                        DatePicker("", selection: $selectedBirthYear, displayedComponents: .date)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .onAppear {
                                // Parse existing year or set default to 2000
                                if !profile.yearOfBirthRange.isEmpty {
                                    let yearString = profile.yearOfBirthRange.trimmingCharacters(in: .whitespaces)
                                    if let year = Int(yearString) {
                                        selectedBirthYear = Calendar.current.date(from: DateComponents(year: year)) ?? Calendar.current.date(from: DateComponents(year: 2000)) ?? Date()
                                    } else {
                                        selectedBirthYear = Calendar.current.date(from: DateComponents(year: 2000)) ?? Date()
                                    }
                                } else {
                                    selectedBirthYear = Calendar.current.date(from: DateComponents(year: 2000)) ?? Date()
                                }
                            }
                            .onChange(of: selectedBirthYear) { _, newValue in
                                let year = Calendar.current.component(.year, from: newValue)
                                profile.yearOfBirthRange = "\(year)"
                            }
                    }
                }
                
                Section("Skin Type") {
                    Picker("Skin Type", selection: $profile.skinType) {
                        ForEach(SkinType.allCases) { skinType in
                            Text(skinType.rawValue.capitalized).tag(skinType)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave?()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Goals Editor View

struct GoalsEditorView: View {
    @Binding var goals: [SkinGoal]
    let theme: AppTheme
    var onSave: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(SkinGoal.allCases) { goal in
                    HStack {
                        Text(goal.rawValue)
                            .font(AppTheme.Typography.body)
                        
                        Spacer()
                        
                        if goals.contains(goal) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(theme.primary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if goals.contains(goal) {
                            goals.removeAll { $0 == goal }
                        } else {
                            goals.append(goal)
                        }
                    }
                }
            }
            .navigationTitle("Skin Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onSave?()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Allergies Editor View

struct AllergiesEditorView: View {
    @Binding var allergies: [String]
    let theme: AppTheme
    var onSave : (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var newAllergy = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Add new allergy
                HStack(spacing: AppTheme.Spacing.md) {
                    TextField("Add allergy", text: $newAllergy)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Add") {
                        let allergy = newAllergy.trimmingCharacters(in: .whitespaces)
                        guard !allergy.isEmpty else { return }
                        allergies.append(allergy)
                        newAllergy = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newAllergy.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                
                // Current allergies
                if !allergies.isEmpty {
                    List {
                        ForEach(Array(allergies.enumerated()), id: \.offset) { index, allergy in
                            HStack {
                                Text(allergy)
                                    .font(AppTheme.Typography.body)
                                
                                Spacer()
                                
                                Button {
                                    allergies.remove(at: index)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }
                } else {
                    VStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: "checkmark.circle")
                            .font(.largeTitle)
                            .foregroundStyle(.green)
                        
                        Text("No allergies recorded")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Allergies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onSave?()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
