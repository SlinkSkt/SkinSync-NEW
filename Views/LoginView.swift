//
//  LoginView.swift
//  SkinSync
//
//  
//

import SwiftUI

struct LoginView: View {
    let isLoading: Bool
    let errorMessage: String?
    let onSignIn: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Sign in").font(.title).bold()

            if let errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }

            Button(action: onSignIn) {
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                    Text(isLoading ? "Signing in…" : "Sign in with Google")
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)

            if isLoading { ProgressView() }
        }
        .padding()
    }
}


