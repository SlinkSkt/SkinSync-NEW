//
//  UVIndexViewModel.swift
//  SkinSync
//
//  ViewModel for managing UV index data and location services
//

import Foundation
import CoreLocation
import Combine
import WidgetKit

@MainActor
final class UVIndexViewModel: NSObject, ObservableObject {
    @Published var uvIndex: Double?
    @Published var isLoading = false
    @Published var error: UVIndexError?
    @Published var lastUpdated: Date?
    @Published var currentCity: String?
    
    private let uvService: UVIndexService
    private let mockService = MockUVIndexService()
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var cancellables = Set<AnyCancellable>()
    
    // Cache settings
    private let cacheExpirationInterval: TimeInterval = 3600 // 1 hour
    private let userDefaults = UserDefaults.standard
    private let sharedDefaults = UserDefaults(suiteName: "group.com.skinsync.app")
    private let cacheKey = "cached_uv_index"
    private let timestampKey = "uv_index_timestamp"
    
    init(uvService: UVIndexService) {
        self.uvService = uvService
        super.init()
        setupLocationManager()
        loadCachedData()
    }
    
    // MARK: - Public Methods
    
    func testWithFallbackLocation() {
        print("🧪 Testing UV API with fallback location...")
        fetchUVIndexWithFallback()
    }
    
    func forceMockData() {
        print("🧪 Forcing mock UV data...")
        let mockLocation = CLLocation(latitude: -33.8688, longitude: 151.2093)
        Task {
            await fetchMockData(for: mockLocation)
        }
    }
    
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
        print("📍 Requesting location and UV data...")
        print("📍 Location services enabled: \(CLLocationManager.locationServicesEnabled())")
        
        guard CLLocationManager.locationServicesEnabled() else {
            print("❌ Location services disabled")
            error = .locationUnavailable
            return
        }
        
        // Check current authorization status first
        let currentStatus = locationManager.authorizationStatus
        print("📍 Current authorization status: \(currentStatus.rawValue)")
        
        switch currentStatus {
        case .notDetermined:
            print("📍 Authorization not determined, requesting permission...")
            // Set up to handle the authorization request
            // The delegate will be called when authorization changes
            isLoading = true
            error = nil
            // Request authorization - this will trigger the delegate callback
            // Note: This method can cause UI unresponsiveness, but it's the standard iOS pattern
            // The delegate callback will handle the response appropriately
            // This is the recommended approach per Apple's documentation
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("❌ Location permission denied or restricted")
            error = .locationPermissionDenied
            isLoading = false
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Location permission granted, fetching UV data...")
            fetchUVIndexWithFallback()
        @unknown default:
            print("❌ Unknown location authorization status")
            error = .locationUnavailable
            isLoading = false
        }
    }
    
    
    // MARK: - Private Methods
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        print("📍 Location manager setup complete")
    }
    
    private func fetchUVIndex() {
        guard let location = locationManager.location else {
            print("❌ No location available for UV fetch, starting location updates...")
            locationManager.startUpdatingLocation()
            error = .locationUnavailable
            return
        }
        
        print("🌍 Fetching UV data for location: \(location.coordinate)")
        isLoading = true
        error = nil
        
        Task {
            do {
                print("🔄 Starting UV API call...")
                let result = try await uvService.fetchUVIndex(for: location)
                print("✅ UV API call successful, UV index: \(result.uv)")
                
                await MainActor.run {
                    self.uvIndex = result.uv
                    self.lastUpdated = Date()
                    self.isLoading = false
                    self.cacheData()
                    print("✅ UV data updated in UI")
                }
                
                // Get city name from location
                print("🌍 Starting geocoding for location: \(location.coordinate)")
                await getCityName(from: location)
            } catch {
                print("❌ UV fetch error: \(error.localizedDescription)")
                print("🔄 Falling back to mock data...")
                await fetchMockData(for: location)
            }
        }
    }
    
    private func fetchUVIndexWithFallback() {
        // Try with current location first
        if locationManager.location != nil {
            fetchUVIndex()
        } else {
            // Fallback to Sydney coordinates for testing
            print("🔄 Using fallback location (Sydney) for UV data...")
            let fallbackLocation = CLLocation(latitude: -33.8688, longitude: 151.2093)
            
            isLoading = true
            error = nil
            
            Task {
                do {
                    print("🔄 Starting UV API call with fallback location...")
                    let result = try await uvService.fetchUVIndex(for: fallbackLocation)
                    print("✅ UV API call successful with fallback, UV index: \(result.uv)")
                    
                    await MainActor.run {
                        self.uvIndex = result.uv
                        self.lastUpdated = Date()
                        self.isLoading = false
                        self.cacheData()
                        self.currentCity = "Sydney, Australia"
                        print("✅ UV data updated in UI with fallback location")
                    }
                } catch {
                    print("❌ UV fetch error with fallback: \(error.localizedDescription)")
                    print("🔄 Falling back to mock data...")
                    await fetchMockData(for: fallbackLocation)
                }
            }
        }
    }
    
    private func fetchMockData(for location: CLLocation) async {
        print("🧪 Fetching mock UV data for location: \(location.coordinate)")
        
        do {
            let result = try await mockService.fetchUVIndex(for: location)
            print("✅ Mock UV data successful, UV index: \(result.uv)")
            
            await MainActor.run {
                self.uvIndex = result.uv
                self.lastUpdated = Date()
                self.isLoading = false
                self.error = nil
                self.cacheData()
                print("✅ Mock UV data updated in UI")
            }
            
            // Get city name from location
            await getCityName(from: location)
        } catch {
            print("❌ Mock UV fetch error: \(error.localizedDescription)")
            await MainActor.run {
                self.error = error as? UVIndexError ?? .networkError(error)
                self.isLoading = false
                print("❌ Mock error set in UI: \(self.error?.localizedDescription ?? "Unknown")")
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
            safeExposureTime: nil,
            sunInfo: nil
        )
        
        do {
            let data = try JSONEncoder().encode(result)
            userDefaults.set(data, forKey: cacheKey)
            userDefaults.set(Date(), forKey: timestampKey)
            
            // Also save to shared UserDefaults for widget access
            sharedDefaults?.set(uvIndex, forKey: "lastUVIndex")
            sharedDefaults?.set(Date(), forKey: "lastUVUpdate")
            if let cityName = currentCity {
                sharedDefaults?.set(cityName, forKey: "lastCity")
            }
            
            // Verify the data was saved
            if let savedUV = sharedDefaults?.object(forKey: "lastUVIndex") as? Double {
                print("✅ Saved UV data to shared UserDefaults for widget: \(savedUV)")
            } else {
                print("⚠️ Failed to save UV data to shared UserDefaults")
            }
            
            // Reload widget timelines
            WidgetCenter.shared.reloadAllTimelines()
            print("🔄 Triggered widget refresh")
        } catch {
            // Cache error - not critical
            print("⚠️ Failed to cache UV data: \(error)")
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension UVIndexViewModel: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            print("📍 Location updated: \(locations.first?.coordinate ?? CLLocationCoordinate2D())")
            // Stop location updates to save battery
            manager.stopUpdatingLocation()
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
            print("📍 Authorization status changed to: \(status.rawValue)")
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                print("✅ Location permission granted, fetching UV data...")
                fetchUVIndexWithFallback()
            case .denied, .restricted:
                print("❌ Location permission denied or restricted")
                self.error = .locationPermissionDenied
                self.isLoading = false
            case .notDetermined:
                print("⏳ Still waiting for user decision")
                // Still waiting for user decision
                break
            @unknown default:
                print("❌ Unknown authorization status")
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
