// Models/SwiftDataModels.swift
// SwiftData models for persistent storage of chat history and app settings
// https://developer.apple.com/documentation/swiftdata

import Foundation
import SwiftData

// MARK: - Chat History Models

/// Represents a single chat message stored in SwiftData
@Model
final class ChatMessageEntity {
    @Attribute(.unique) var id: UUID
    var role: String  // "user", "assistant", "system"
    var content: String
    var timestamp: Date
    var conversationID: UUID  // Groups messages into conversations
    
    init(id: UUID = UUID(), role: String, content: String, timestamp: Date = Date(), conversationID: UUID) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.conversationID = conversationID
    }
    
    /// Convert to ChatMessage (Domain model)
    func toChatMessage() -> ChatMessage {
        return ChatMessage(
            id: self.id,
            role: MessageRole(rawValue: self.role) ?? .assistant,
            content: self.content,
            timestamp: self.timestamp
        )
    }
    
    /// Create from ChatMessage (Domain model)
    static func from(_ message: ChatMessage, conversationID: UUID) -> ChatMessageEntity {
        return ChatMessageEntity(
            id: message.id,
            role: message.role.rawValue,
            content: message.content,
            timestamp: message.timestamp,
            conversationID: conversationID
        )
    }
}

/// Represents a chat conversation (session) in SwiftData
@Model
final class ConversationEntity {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var lastMessageAt: Date
    var messageCount: Int
    
    init(id: UUID = UUID(), title: String = "New Conversation", createdAt: Date = Date(), lastMessageAt: Date = Date(), messageCount: Int = 0) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.lastMessageAt = lastMessageAt
        self.messageCount = messageCount
    }
}

// MARK: - App Settings Model

/// Represents app settings stored in SwiftData
@Model
final class AppSettingsEntity {
    @Attribute(.unique) var id: String  // Always "main" for singleton
    
    // Theme settings
    var colorScheme: String  // "system", "light", "dark"
    var brandColorHex: String
    
    // Notification settings
    var notificationsEnabled: Bool
    var amNotificationEnabled: Bool
    var amNotificationHour: Int
    var amNotificationMinute: Int
    var pmNotificationEnabled: Bool
    var pmNotificationHour: Int
    var pmNotificationMinute: Int
    
    // AI settings
    var aiChatHistoryEnabled: Bool
    var maxChatHistoryDays: Int
    
    // Privacy settings
    var analyticsEnabled: Bool
    
    // Last updated
    var lastUpdated: Date
    
    init(
        id: String = "main",
        colorScheme: String = "system",
        brandColorHex: String = "#8B9461",
        notificationsEnabled: Bool = false,
        amNotificationEnabled: Bool = false,
        amNotificationHour: Int = 7,
        amNotificationMinute: Int = 30,
        pmNotificationEnabled: Bool = false,
        pmNotificationHour: Int = 21,
        pmNotificationMinute: Int = 0,
        aiChatHistoryEnabled: Bool = true,
        maxChatHistoryDays: Int = 30,
        analyticsEnabled: Bool = false,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.colorScheme = colorScheme
        self.brandColorHex = brandColorHex
        self.notificationsEnabled = notificationsEnabled
        self.amNotificationEnabled = amNotificationEnabled
        self.amNotificationHour = amNotificationHour
        self.amNotificationMinute = amNotificationMinute
        self.pmNotificationEnabled = pmNotificationEnabled
        self.pmNotificationHour = pmNotificationHour
        self.pmNotificationMinute = pmNotificationMinute
        self.aiChatHistoryEnabled = aiChatHistoryEnabled
        self.maxChatHistoryDays = maxChatHistoryDays
        self.analyticsEnabled = analyticsEnabled
        self.lastUpdated = lastUpdated
    }
}

// MARK: - ChatMessage Extension for SwiftData compatibility

extension ChatMessage {
    init(id: UUID, role: MessageRole, content: String, timestamp: Date) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

