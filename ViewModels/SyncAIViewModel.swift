import Foundation
import SwiftUI

@MainActor
class SyncAIViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentMessage = ""
    @Published var isLoading = false
    @Published var error: String?
    
    private let openAIService = OpenAIService()
    
    init() {
        addWelcomeMessage()
    }
    
    func hasAPIKey() -> Bool {
        return openAIService.hasAPIKey()
    }
    
    // MARK: - Chat Management
    func sendMessage() {
        guard !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = currentMessage
        currentMessage = ""
        
        // Add user message
        let userChatMessage = ChatMessage(role: .user, content: userMessage)
        messages.append(userChatMessage)
        
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
            
        } catch {
            self.error = error.localizedDescription
            
            // Add error message
            let errorMessage = ChatMessage(role: .assistant, content: "Sorry, I encountered an error: \(error.localizedDescription)")
            messages.append(errorMessage)
        }
        
        isLoading = false
    }
    
    func clearChat() {
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
