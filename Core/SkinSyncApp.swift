// Core/SkinSyncApp.swift
// Assessment 1 Prototype — Part 2 (SwiftUI)
// SwiftUI only (no Storyboards). Uses MVVM + simple file persistence.

// Core/SkinSyncApp.swift
// SkinSync — SwiftUI only, no Storyboards

import SwiftUI

@main
struct SkinSyncApp: App {
    init() {
        FileDataStore().seedIfNeeded()   // seeds JSON into Documents if missing
    }
    var body: some Scene {
        WindowGroup { RootView().environmentObject(AppModel()) }
    }
}
