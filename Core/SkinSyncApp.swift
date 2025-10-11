/// The main entry point for the SkinSync app.  
/// Sets up the app's environment and initializes data storage.

import SwiftUI

@main
struct SkinSyncApp: App {
    @StateObject private var appModel = AppModel()
    @AppStorage("colorScheme") private var selectedColorScheme: String = "system"
    
    init() {
        FileDataStore().seedIfNeeded()   // Seed JSON data into Documents folder if missing
    }
    
    var body: some Scene {
        WindowGroup { 
            RootView()
                .environmentObject(appModel)
                .preferredColorScheme(colorScheme)
        }
    }
    
    private var colorScheme: ColorScheme? {
        switch selectedColorScheme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil // System default
        }
    }
}
