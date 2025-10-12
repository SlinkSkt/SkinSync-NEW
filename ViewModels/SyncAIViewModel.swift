import Foundation
import SwiftUI

@MainActor
class SyncAIViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentMessage = ""
    @Published var isLoading = false
    @Published var error: String?
    
    private let openAIService = OpenAIService()
    private let swiftDataService = SwiftDataService.shared
    private var conversationID: UUID
    private var isChatHistoryEnabled: Bool = true
    
    init() {
        // Initialize conversation ID
        self.conversationID = UUID()
        
        // Defer SwiftData initialization to avoid blocking main thread
        Task { @MainActor in
            // Load settings to check if chat history is enabled
            let settings = swiftDataService.loadSettings()
            self.isChatHistoryEnabled = settings.aiChatHistoryEnabled
            
            // Load existing messages from SwiftData if enabled
            if self.isChatHistoryEnabled {
                self.loadChatHistory()
            }
            
            // Add welcome message if no messages exist
            if self.messages.isEmpty {
                self.addWelcomeMessage()
            }
        }
    }
    
    func hasAPIKey() -> Bool {
        return openAIService.hasAPIKey()
    }
    
    // MARK: - Chat History Management
    
    private func loadChatHistory() {
        conversationID = swiftDataService.getCurrentConversationID()
        let loadedMessages = swiftDataService.loadMessages(conversationID: conversationID)
        messages = loadedMessages
        print("📖 SyncAIViewModel: Loaded \(loadedMessages.count) messages from history")
    }
    
    private func saveMessageToHistory(_ message: ChatMessage) {
        guard isChatHistoryEnabled else { return }
        
        swiftDataService.saveMessage(message, conversationID: conversationID)
        swiftDataService.updateConversation(id: conversationID, messageCount: messages.count)
    }
    
    func toggleChatHistory(_ enabled: Bool) {
        isChatHistoryEnabled = enabled
        swiftDataService.updateSettings { settings in
            settings.aiChatHistoryEnabled = enabled
        }
        
        if !enabled {
            // Clear local messages but don't delete from SwiftData
            print("🔒 SyncAIViewModel: Chat history disabled")
        } else {
            // Reload messages from SwiftData
            loadChatHistory()
            if messages.isEmpty {
                addWelcomeMessage()
            }
            print("🔓 SyncAIViewModel: Chat history enabled")
        }
    }
    
    // MARK: - Chat Management
    func sendMessage() {
        guard !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = currentMessage
        currentMessage = ""
        
        // Add user message
        let userChatMessage = ChatMessage(role: .user, content: userMessage)
        messages.append(userChatMessage)
        
        // Save to SwiftData
        saveMessageToHistory(userChatMessage)
        
        // Send to OpenAI
        Task {
            await sendToOpenAI(userMessage)
        }
    }
    
    private func sendToOpenAI(_ message: String) async {
        isLoading = true
        error = nil
        
        do {
            let response = try await openAIService.sendMessage(message, conversationHistory: messages)
            
            // Add assistant response
            let assistantMessage = ChatMessage(role: .assistant, content: response)
            messages.append(assistantMessage)
            
            // Save to SwiftData
            saveMessageToHistory(assistantMessage)
            
        } catch {
            self.error = error.localizedDescription
            
            // Add error message
            let errorMessage = ChatMessage(role: .assistant, content: "Sorry, I encountered an error: \(error.localizedDescription)")
            messages.append(errorMessage)
            
            // Don't save error messages to history
        }
        
        isLoading = false
    }
    
    func clearChat() {
        // Delete messages from SwiftData
        if isChatHistoryEnabled {
            swiftDataService.deleteMessages(conversationID: conversationID)
            
            // Create new conversation
            conversationID = swiftDataService.getCurrentConversationID()
        }
        
        messages.removeAll()
        addWelcomeMessage()
    }
    
    private func addWelcomeMessage() {
        let welcomeMessage = ChatMessage(
            role: .assistant,
            content: """
            👋 Hello! I'm SyncAI, your personal skincare assistant.
            
            I can help you with:
            • Skincare routine recommendations
            • Product ingredient analysis
            • Skin concern advice
            • Personalized skincare tips
            
            What would you like to know about skincare today?
            """
        )
        messages.append(welcomeMessage)
        
        // Save welcome message to history
        saveMessageToHistory(welcomeMessage)
    }
    
    // MARK: - Quick Actions
    func sendQuickMessage(_ message: String) {
        currentMessage = message
        sendMessage()
    }
    
    let quickActions = [
        "What's a good morning skincare routine?",
        "How do I choose the right moisturizer?",
        "What ingredients should I avoid for sensitive skin?",
        "How often should I exfoliate?",
        "What's the difference between chemical and physical exfoliants?"
    ]
}
