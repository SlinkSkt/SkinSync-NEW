/// The main entry point for the SkinSync app.  
/// Sets up the app's environment and initializes data storage.

import SwiftUI

@main
struct SkinSyncApp: App {
    @StateObject private var appModel = AppModel()
    
    init() {
        FileDataStore().seedIfNeeded()   // Seed JSON data into Documents folder if missing
    }
    var body: some Scene {
        WindowGroup { RootView().environmentObject(appModel) }
    }
}
