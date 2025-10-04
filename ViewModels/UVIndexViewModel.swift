//
//  UVIndexViewModel.swift
//  SkinSync
//
//  ViewModel for managing UV index data and location services
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class UVIndexViewModel: NSObject, ObservableObject {
    @Published var uvIndex: Double?
    @Published var isLoading = false
    @Published var error: UVIndexError?
    @Published var lastUpdated: Date?
    @Published var currentCity: String?
    
    private let uvService: UVIndexService
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var cancellables = Set<AnyCancellable>()
    
    // Cache settings
    private let cacheExpirationInterval: TimeInterval = 3600 // 1 hour
    private let userDefaults = UserDefaults.standard
    private let cacheKey = "cached_uv_index"
    private let timestampKey = "uv_index_timestamp"
    
    init(uvService: UVIndexService) {
        self.uvService = uvService
        super.init()
        setupLocationManager()
        loadCachedData()
    }
    
    // MARK: - Public Methods
    
    func requestLocationAndFetchCity() {
        guard let location = locationManager.location else {
            print("📍 No location available for geocoding")
            return
        }
        
        Task {
            print("🌍 Manually requesting city for location: \(location.coordinate)")
            await getCityName(from: location)
        }
    }
    
    func requestLocationAndFetchUVIndex() {
        guard CLLocationManager.locationServicesEnabled() else {
            error = .locationUnavailable
            return
        }
        
        // Check current authorization status first
        let currentStatus = locationManager.authorizationStatus
        
        switch currentStatus {
        case .notDetermined:
            // Set up to handle the authorization request
            // The delegate will be called when authorization changes
            isLoading = true
            error = nil
            // Request authorization - this will trigger the delegate callback
            // Note: This method can cause UI unresponsiveness, but it's the standard iOS pattern
            // The delegate callback will handle the response appropriately
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            error = .locationPermissionDenied
            isLoading = false
        case .authorizedWhenInUse, .authorizedAlways:
            fetchUVIndex()
        @unknown default:
            error = .locationUnavailable
            isLoading = false
        }
    }
    
    
    // MARK: - Private Methods
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    private func fetchUVIndex() {
        guard let location = locationManager.location else {
            error = .locationUnavailable
            return
        }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                let result = try await uvService.fetchUVIndex(for: location)
                await MainActor.run {
                    self.uvIndex = result.uv
                    self.lastUpdated = Date()
                    self.isLoading = false
                    self.cacheData()
                }
                
                // Get city name from location
                print("🌍 Starting geocoding for location: \(location.coordinate)")
                await getCityName(from: location)
            } catch {
                await MainActor.run {
                    self.error = error as? UVIndexError ?? .networkError(error)
                    self.isLoading = false
                }
            }
        }
    }
    
    private func getCityName(from location: CLLocation) async {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            await MainActor.run {
                if let placemark = placemarks.first {
                    // Try multiple fallback options for city name
                    let cityName = placemark.locality ?? 
                                  placemark.subLocality ?? 
                                  placemark.administrativeArea ?? 
                                  placemark.subAdministrativeArea ??
                                  placemark.country ?? 
                                  "Unknown Location"
                    
                    self.currentCity = cityName
                    print("📍 Geocoded city: \(cityName)")
                } else {
                    self.currentCity = "Unknown Location"
                    print("📍 No placemarks found")
                }
            }
        } catch {
            await MainActor.run {
                self.currentCity = "Unknown Location"
                print("📍 Geocoding error: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadCachedData() {
        guard let cachedData = userDefaults.data(forKey: cacheKey),
              let timestamp = userDefaults.object(forKey: timestampKey) as? Date,
              Date().timeIntervalSince(timestamp) < cacheExpirationInterval else {
            return
        }
        
        do {
            let result = try JSONDecoder().decode(UVIndexResult.self, from: cachedData)
            uvIndex = result.uv
            lastUpdated = timestamp
        } catch {
            // Clear invalid cache
            userDefaults.removeObject(forKey: cacheKey)
            userDefaults.removeObject(forKey: timestampKey)
        }
        
        // Always try to get current city name, even with cached UV data
        if let location = locationManager.location {
            Task {
                print("🌍 Loading cached data, getting city for location: \(location.coordinate)")
                await getCityName(from: location)
            }
        }
    }
    
    private func cacheData() {
        guard let uvIndex = uvIndex else { return }
        
        let result = UVIndexResult(
            uv: uvIndex,
            uvTime: ISO8601DateFormatter().string(from: Date()),
            uvMax: uvIndex,
            uvMaxTime: ISO8601DateFormatter().string(from: Date()),
            ozone: 0,
            ozoneTime: ISO8601DateFormatter().string(from: Date()),
            safeExposureTime: nil
        )
        
        do {
            let data = try JSONEncoder().encode(result)
            userDefaults.set(data, forKey: cacheKey)
            userDefaults.set(Date(), forKey: timestampKey)
        } catch {
            // Cache error - not critical
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension UVIndexViewModel: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            fetchUVIndex()
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.error = .networkError(error)
            isLoading = false
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                fetchUVIndex()
            case .denied, .restricted:
                self.error = .locationPermissionDenied
                self.isLoading = false
            case .notDetermined:
                // Still waiting for user decision
                break
            @unknown default:
                self.error = .locationUnavailable
                self.isLoading = false
            }
        }
    }
}

// MARK: - UV Index Level Helpers

extension UVIndexViewModel {
    var uvLevel: UVLevel {
        guard let uvIndex = uvIndex else { return .unknown }
        return UVLevel.from(value: uvIndex)
    }
    
}

enum UVLevel: String, CaseIterable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case veryHigh = "Very High"
    case extreme = "Extreme"
    case unknown = "Unknown"
    
    static func from(value: Double) -> UVLevel {
        switch value {
        case 0..<3:
            return .low
        case 3..<6:
            return .moderate
        case 6..<8:
            return .high
        case 8..<11:
            return .veryHigh
        case 11...:
            return .extreme
        default:
            return .unknown
        }
    }
    
    var color: String {
        switch self {
        case .low:
            return "green"
        case .moderate:
            return "yellow"
        case .high:
            return "orange"
        case .veryHigh:
            return "red"
        case .extreme:
            return "purple"
        case .unknown:
            return "gray"
        }
    }
    
    var icon: String {
        switch self {
        case .low, .moderate:
            return "sun.max"
        case .high, .veryHigh:
            return "sun.max.fill"
        case .extreme:
            return "exclamationmark.triangle.fill"
        case .unknown:
            return "questionmark.circle"
        }
    }
}
