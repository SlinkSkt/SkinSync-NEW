// ViewModels/SettingsViewModel.swift
// ViewModel for app settings management using SwiftData

import Foundation
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    // Theme settings
    @Published var selectedColorScheme: String = "system" {
        didSet { saveSettings() }
    }
    
    @Published var brandColorHex: String = "#8B9461" {
        didSet { saveSettings() }
    }
    
    // Notification settings
    @Published var notificationsEnabled: Bool = false {
        didSet { saveSettings() }
    }
    
    @Published var amNotificationEnabled: Bool = false {
        didSet { saveSettings() }
    }
    
    @Published var amNotificationHour: Int = 7 {
        didSet { saveSettings() }
    }
    
    @Published var amNotificationMinute: Int = 30 {
        didSet { saveSettings() }
    }
    
    @Published var pmNotificationEnabled: Bool = false {
        didSet { saveSettings() }
    }
    
    @Published var pmNotificationHour: Int = 21 {
        didSet { saveSettings() }
    }
    
    @Published var pmNotificationMinute: Int = 0 {
        didSet { saveSettings() }
    }
    
    // AI settings
    @Published var aiChatHistoryEnabled: Bool = true {
        didSet { saveSettings() }
    }
    
    @Published var maxChatHistoryDays: Int = 30 {
        didSet { saveSettings() }
    }
    
    // Privacy settings
    @Published var analyticsEnabled: Bool = false {
        didSet { saveSettings() }
    }
    
    private let swiftDataService = SwiftDataService.shared
    private var isLoadingSettings = false
    
    init() {
        // Defer loading to avoid blocking main thread
        Task { @MainActor in
            self.loadSettings()
        }
    }
    
    // MARK: - Settings Management
    
    func loadSettings() {
        isLoadingSettings = true
        
        let settings = swiftDataService.loadSettings()
        
        // Update published properties without triggering didSet
        _selectedColorScheme = Published(initialValue: settings.colorScheme)
        _brandColorHex = Published(initialValue: settings.brandColorHex)
        _notificationsEnabled = Published(initialValue: settings.notificationsEnabled)
        _amNotificationEnabled = Published(initialValue: settings.amNotificationEnabled)
        _amNotificationHour = Published(initialValue: settings.amNotificationHour)
        _amNotificationMinute = Published(initialValue: settings.amNotificationMinute)
        _pmNotificationEnabled = Published(initialValue: settings.pmNotificationEnabled)
        _pmNotificationHour = Published(initialValue: settings.pmNotificationHour)
        _pmNotificationMinute = Published(initialValue: settings.pmNotificationMinute)
        _aiChatHistoryEnabled = Published(initialValue: settings.aiChatHistoryEnabled)
        _maxChatHistoryDays = Published(initialValue: settings.maxChatHistoryDays)
        _analyticsEnabled = Published(initialValue: settings.analyticsEnabled)
        
        isLoadingSettings = false
    }
    
    private func saveSettings() {
        guard !isLoadingSettings else { return }
        
        swiftDataService.updateSettings { settings in
            settings.colorScheme = self.selectedColorScheme
            settings.brandColorHex = self.brandColorHex
            settings.notificationsEnabled = self.notificationsEnabled
            settings.amNotificationEnabled = self.amNotificationEnabled
            settings.amNotificationHour = self.amNotificationHour
            settings.amNotificationMinute = self.amNotificationMinute
            settings.pmNotificationEnabled = self.pmNotificationEnabled
            settings.pmNotificationHour = self.pmNotificationHour
            settings.pmNotificationMinute = self.pmNotificationMinute
            settings.aiChatHistoryEnabled = self.aiChatHistoryEnabled
            settings.maxChatHistoryDays = self.maxChatHistoryDays
            settings.analyticsEnabled = self.analyticsEnabled
        }
    }
    
    // MARK: - Utility Methods
    
    func resetToDefaults() {
        isLoadingSettings = true
        
        selectedColorScheme = "system"
        brandColorHex = "#8B9461"
        notificationsEnabled = false
        amNotificationEnabled = false
        amNotificationHour = 7
        amNotificationMinute = 30
        pmNotificationEnabled = false
        pmNotificationHour = 21
        pmNotificationMinute = 0
        aiChatHistoryEnabled = true
        maxChatHistoryDays = 30
        analyticsEnabled = false
        
        isLoadingSettings = false
        saveSettings()
    }
    
    func getStorageStats() -> String {
        let stats = swiftDataService.getStorageStats()
        return """
        Messages: \(stats.messages)
        Conversations: \(stats.conversations)
        Settings: \(stats.settings)
        """
    }
    
    func cleanupOldChatHistory() {
        swiftDataService.deleteOldMessages(olderThanDays: maxChatHistoryDays)
    }
}

