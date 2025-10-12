//
//  ContentView.swift
//  SkinSync
//
//  Created by Zhen Xiao on 30/8/2025.
//

import SwiftUI

struct ContentView: View {
    // RootView expects an AppModel in the environment
    @StateObject private var app = AppModel()

    var body: some View {
        RootView()
            .environmentObject(app)
    }
}

#Preview {
    // Preview the full app shell
    let app = AppModel()
    return RootView()
        .environmentObject(app)
}
