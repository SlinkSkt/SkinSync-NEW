// Core/AppModel.swift
import Foundation

/// Global container for services and app-wide configuration.
/// Inject this into the SwiftUI environment: `.environmentObject(AppModel())`
@MainActor
final class AppModel: ObservableObject {

    /// Concrete implementations of all app services (data store, APIs, etc.)
    let services: Services

    /// Live configuration that SwiftUI can react to (brand color, title, flags).
    @Published var config: AppConfig

    /// Default to live services and default config.
    init(services: Services = .live, config: AppConfig = .default) {
        self.services = services
        self.config = config
    }
}

/// A simple dependency container. Swap these out for mocks in tests.
struct Services {
    let dataStore: DataStore
    let imageLoader: ImageLoader
    let notif: NotificationScheduler
    let faceScan: FaceScanService
    let productAPI: ProductAPI
    let uvService: UVIndexService

    /// The production set of services used by the running app.
    static let live = Services(
        dataStore: FileDataStore(),
        imageLoader: DefaultImageLoader(),
        notif: LocalNotificationScheduler(),
        faceScan: MockFaceScanService(),   // This is still under dev, so replace with a real impl when ready
        productAPI: LocalProductAPI(),     // This is still under dev, so replace with a real impl when ready
        uvService: OpenUVService(apiKey: "openuv-2sy4amrmgcdf6jo-io")  // Real OpenUV API
    )
}

/// Serializable app configuration (useful for theming & feature flags).
struct AppConfig: Codable, Equatable {
    var appTitle: String
    /// Hex color string for brand primary, We're using the same colour code in Figma "#A2AA7B" (olive).
    var brandPrimaryHex: String
    var enableLogging: Bool

    static let `default` = AppConfig(
        appTitle: "SkinSync",
        brandPrimaryHex: "#8B9461",
        enableLogging: true
    )
}
