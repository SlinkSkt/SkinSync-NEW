// Services/SwiftDataService.swift
// Service layer for SwiftData operations
// Provides clean API for chat history and settings management

import Foundation
import SwiftData

// MARK: - SwiftData Service

@MainActor
final class SwiftDataService {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    static let shared = SwiftDataService()
    
    private init() {
        do {
            let schema = Schema([
                ChatMessageEntity.self,
                ConversationEntity.self,
                AppSettingsEntity.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            
            self.modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            self.modelContext = ModelContext(modelContainer)
            
            // Enable auto-save
            modelContext.autosaveEnabled = true
        } catch {
            // Fallback to in-memory store
            do {
                let schema = Schema([
                    ChatMessageEntity.self,
                    ConversationEntity.self,
                    AppSettingsEntity.self
                ])
                
                let modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true,
                    cloudKitDatabase: .none
                )
                
                self.modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
                
                self.modelContext = ModelContext(modelContainer)
                modelContext.autosaveEnabled = true
            } catch {
                fatalError("SwiftDataService: Fatal error - cannot initialize even in-memory store: \(error)")
            }
        }
    }
    
    // MARK: - Conversation Management
    
    /// Get current conversation ID (or create new one)
    func getCurrentConversationID() -> UUID {
        // For now, we'll use a single active conversation
        // In the future, this could support multiple conversations
        let descriptor = FetchDescriptor<ConversationEntity>(
            sortBy: [SortDescriptor(\.lastMessageAt, order: .reverse)]
        )
        
        do {
            let conversations = try modelContext.fetch(descriptor)
            if let latest = conversations.first {
                return latest.id
            } else {
                // Create new conversation
                let newConversation = ConversationEntity(
                    title: "SyncAI Chat",
                    createdAt: Date(),
                    lastMessageAt: Date(),
                    messageCount: 0
                )
                modelContext.insert(newConversation)
                try modelContext.save()
                return newConversation.id
            }
        } catch {
            return UUID()
        }
    }
    
    /// Update conversation metadata
    func updateConversation(id: UUID, messageCount: Int) {
        let descriptor = FetchDescriptor<ConversationEntity>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            let conversations = try modelContext.fetch(descriptor)
            if let conversation = conversations.first {
                conversation.lastMessageAt = Date()
                conversation.messageCount = messageCount
                try modelContext.save()
            }
        } catch { }
    }
    
    // MARK: - Chat History Management
    
    /// Save a chat message
    func saveMessage(_ message: ChatMessage, conversationID: UUID) {
        let entity = ChatMessageEntity.from(message, conversationID: conversationID)
        modelContext.insert(entity)
        
        do {
            try modelContext.save()
        } catch { }
    }
    
    /// Load all messages for a conversation
    func loadMessages(conversationID: UUID) -> [ChatMessage] {
        let descriptor = FetchDescriptor<ChatMessageEntity>(
            predicate: #Predicate { $0.conversationID == conversationID },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.map { $0.toChatMessage() }
        } catch {
            return []
        }
    }
    
    /// Delete all messages for a conversation
    func deleteMessages(conversationID: UUID) {
        let descriptor = FetchDescriptor<ChatMessageEntity>(
            predicate: #Predicate { $0.conversationID == conversationID }
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            for entity in entities {
                modelContext.delete(entity)
            }
            try modelContext.save()
        } catch { }
    }
    
    /// Delete old messages (older than specified days)
    func deleteOldMessages(olderThanDays days: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let descriptor = FetchDescriptor<ChatMessageEntity>(
            predicate: #Predicate { $0.timestamp < cutoffDate }
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            for entity in entities {
                modelContext.delete(entity)
            }
            try modelContext.save()
        } catch { }
    }
    
    /// Get message count for a conversation
    func getMessageCount(conversationID: UUID) -> Int {
        let descriptor = FetchDescriptor<ChatMessageEntity>(
            predicate: #Predicate { $0.conversationID == conversationID }
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.count
        } catch {
            return 0
        }
    }
    
    // MARK: - App Settings Management
    
    /// Load app settings (singleton)
    func loadSettings() -> AppSettingsEntity {
        let descriptor = FetchDescriptor<AppSettingsEntity>(
            predicate: #Predicate { $0.id == "main" }
        )
        
        do {
            let settings = try modelContext.fetch(descriptor)
            if let existing = settings.first {
                return existing
            } else {
                // Create default settings
                let newSettings = AppSettingsEntity()
                modelContext.insert(newSettings)
                try modelContext.save()
                return newSettings
            }
        } catch {
            return AppSettingsEntity()
        }
    }
    
    /// Save app settings
    func saveSettings(_ settings: AppSettingsEntity) {
        settings.lastUpdated = Date()
        
        do {
            try modelContext.save()
        } catch { }
    }
    
    /// Update specific setting
    func updateSettings(_ update: (AppSettingsEntity) -> Void) {
        let settings = loadSettings()
        update(settings)
        saveSettings(settings)
    }
    
    // MARK: - Maintenance
    
    /// Get storage statistics
    func getStorageStats() -> (messages: Int, conversations: Int, settings: Int) {
        do {
            let messageCount = try modelContext.fetchCount(FetchDescriptor<ChatMessageEntity>())
            let conversationCount = try modelContext.fetchCount(FetchDescriptor<ConversationEntity>())
            let settingsCount = try modelContext.fetchCount(FetchDescriptor<AppSettingsEntity>())
            
            return (messages: messageCount, conversations: conversationCount, settings: settingsCount)
        } catch {
            return (messages: 0, conversations: 0, settings: 0)
        }
    }
    
    /// Clear all data (for testing/debugging)
    func clearAllData() {
        do {
            // Delete all messages
            try modelContext.delete(model: ChatMessageEntity.self)
            
            // Delete all conversations
            try modelContext.delete(model: ConversationEntity.self)
            
            // Delete all settings
            try modelContext.delete(model: AppSettingsEntity.self)
            
            try modelContext.save()
        } catch { }
    }
}

