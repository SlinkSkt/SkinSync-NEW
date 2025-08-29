// Core/AppModel.swift
import Foundation

/// Global container for services and config injected into SwiftUI environment.
final class AppModel: ObservableObject {
    let services: Services
    @Published var config: AppConfig
    
    init(services: Services = .live(), config: AppConfig = .default) {
        self.services = services
        self.config = config
    }
}

struct Services {
    let dataStore: DataStore
    let imageLoader: ImageLoader
    let notif: NotificationScheduler
    let faceScan: FaceScanService
    let productAPI: ProductAPI
    
    static func live() -> Services {
        Services(
            dataStore: FileDataStore(),
            imageLoader: DefaultImageLoader(),
            notif: LocalNotificationScheduler(),
            faceScan: MockFaceScanService(),
            productAPI: LocalProductAPI()
        )
    }
}

struct AppConfig: Codable, Equatable {
    var appTitle: String
    var brandPrimaryHex: String // e.g., "#A2AA7B" (olive)
    var enableLogging: Bool
    
    static let `default` = AppConfig(appTitle: "SkinSync",
                                     brandPrimaryHex: "#A2AA7B",
                                     enableLogging: true)
}
