import SwiftUI

struct SyncAIView: View {
    let theme: AppTheme
    @ObservedObject var viewModel: SyncAIViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.md) {
                            ForEach(viewModel.messages) { message in
                                ChatBubbleView(message: message, theme: theme)
                                    .id(message.id)
                            }
                            
                            if viewModel.isLoading {
                                TypingIndicatorView(theme: theme)
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.screenEdge)
                        .padding(.vertical, AppTheme.Spacing.md)
                        .padding(.bottom, 80) // Space for chat input + tab bar
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onTapGesture {
                        // Dismiss keyboard when tapping on chat area
                        hideKeyboard()
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { _ in
                                // Dismiss keyboard when dragging
                                hideKeyboard()
                            }
                    )
                }
                
                // Quick Actions (if no messages or first message)
                if viewModel.messages.count <= 1 {
                    QuickActionsView(viewModel: viewModel, theme: theme)
                        .padding(.horizontal, AppTheme.Spacing.screenEdge)
                        .padding(.bottom, AppTheme.Spacing.md)
                        .onTapGesture {
                            // Dismiss keyboard when tapping on quick actions
                            hideKeyboard()
                        }
                }
                
                Spacer(minLength: 0)
                
                // Input Area (positioned at bottom)
                ChatInputView(viewModel: viewModel, theme: theme)
            }
            .navigationTitle("SyncAI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear Chat") {
                        viewModel.clearChat()
                    }
                }
            }
            .onTapGesture {
                // Dismiss keyboard when tapping anywhere in the view
                hideKeyboard()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Chat Components

struct ChatBubbleView: View {
    let message: ChatMessage
    let theme: AppTheme
    
    var isUser: Bool {
        message.role == .user
    }
    
    var body: some View {
        HStack {
            if isUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(isUser ? .white : .primary)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isUser ? theme.primary : Color(.systemGray6))
                    )
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, AppTheme.Spacing.sm)
            }
            
            if !isUser {
                Spacer(minLength: 60)
            }
        }
    }
}

struct TypingIndicatorView: View {
    let theme: AppTheme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(theme.primary.opacity(0.6))
                            .frame(width: 8, height: 8)
                            .scaleEffect(1.0)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: UUID()
                            )
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemGray6))
                )
                
                Text("SyncAI is typing...")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, AppTheme.Spacing.sm)
            }
            
            Spacer(minLength: 60)
        }
    }
}

struct QuickActionsView: View {
    @ObservedObject var viewModel: SyncAIViewModel
    let theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Quick Questions")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppTheme.Spacing.sm)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.sm) {
                ForEach(viewModel.quickActions, id: \.self) { action in
                    Button(action: {
                        viewModel.sendQuickMessage(action)
                    }) {
                        Text(action)
                            .font(.caption)
                            .foregroundStyle(theme.primary)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, AppTheme.Spacing.xs)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.primary.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(theme.primary.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ChatInputView: View {
    @ObservedObject var viewModel: SyncAIViewModel
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: AppTheme.Spacing.sm) {
                TextField("Ask me about skincare...", text: $viewModel.currentMessage, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemGray6))
                    )
                    .lineLimit(1...4)
                
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            viewModel.currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading
                            ? .secondary
                            : theme.primary
                        )
                }
                .disabled(viewModel.currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            }
            .padding(.horizontal, AppTheme.Spacing.screenEdge)
            .padding(.top, AppTheme.Spacing.md)
            .padding(.bottom, 85) // Extra padding for tab bar (70pt height + 15pt margin)
            .background(
                ZStack {
                    // Solid background that extends below
                    Rectangle()
                        .fill(Color(.systemBackground))
                        .ignoresSafeArea(edges: .bottom)
                    
                    // Blur overlay
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea(edges: .bottom)
                }
            )
        }
    }
}


#Preview {
    SyncAIView(theme: AppTheme(config: .default), viewModel: SyncAIViewModel())
}
