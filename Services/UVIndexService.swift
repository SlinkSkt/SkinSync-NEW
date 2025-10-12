//
//  UVIndexService.swift
//  SkinSync
//
//  Service for fetching UV index data from OpenUV API
//

import Foundation
import CoreLocation

// MARK: - UV Index Data Models

struct UVIndexResponse: Codable {
    let result: UVIndexResult
}

struct UVIndexResult: Codable {
    let uv: Double
    let uvTime: String
    let uvMax: Double
    let uvMaxTime: String
    let ozone: Double
    let ozoneTime: String
    let safeExposureTime: SafeExposureTime?
    let sunInfo: SunInfo?
    
    enum CodingKeys: String, CodingKey {
        case uv, uvTime, uvMax, uvMaxTime, ozone, ozoneTime, safeExposureTime
        case sunInfo = "sun_info"
    }
}

struct SafeExposureTime: Codable {
    let st1: Int?
    let st2: Int?
    let st3: Int?
    let st4: Int?
    let st5: Int?
    let st6: Int?
}

struct SunInfo: Codable {
    let sunTimes: SunTimes?
    let sunPosition: SunPosition?
    
    enum CodingKeys: String, CodingKey {
        case sunTimes = "sun_times"
        case sunPosition = "sun_position"
    }
}

struct SunTimes: Codable {
    let solarNoon: String?
    let nadir: String?
    let sunrise: String?
    let sunset: String?
    let sunriseEnd: String?
    let sunsetStart: String?
    let dawn: String?
    let dusk: String?
    let nauticalDawn: String?
    let nauticalDusk: String?
    let nightEnd: String?
    let night: String?
    let goldenHourEnd: String?
    let goldenHour: String?
    
    enum CodingKeys: String, CodingKey {
        case solarNoon = "solarNoon"
        case nadir, sunrise, sunset
        case sunriseEnd = "sunriseEnd"
        case sunsetStart = "sunsetStart"
        case dawn, dusk
        case nauticalDawn = "nauticalDawn"
        case nauticalDusk = "nauticalDusk"
        case nightEnd = "nightEnd"
        case night
        case goldenHourEnd = "goldenHourEnd"
        case goldenHour = "goldenHour"
    }
}

struct SunPosition: Codable {
    let azimuth: Double?
    let altitude: Double?
}

// MARK: - UV Index Service Protocol

protocol UVIndexService {
    func fetchUVIndex(for location: CLLocation) async throws -> UVIndexResult
}

// MARK: - OpenUV API Implementation

final class OpenUVService: UVIndexService {
    private let session: URLSession
    private let plistKey = "OpenUV_API_Key"
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - API Key Management
    private var apiKey: String? {
        return getAPIKeyFromPlist()
    }
    
    func hasAPIKey() -> Bool {
        return apiKey != nil
    }
    
    // MARK: - Info.plist Configuration
    private func getAPIKeyFromPlist() -> String? {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let apiKey = plist[plistKey] as? String,
              !apiKey.isEmpty else {
            return nil
        }
        return apiKey
    }
    
    func fetchUVIndex(for location: CLLocation) async throws -> UVIndexResult {
        guard let apiKey = apiKey else {
            throw UVIndexError.noAPIKey
        }
        
        let url = buildURL(for: location)
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-access-token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw UVIndexError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw UVIndexError.apiError(httpResponse.statusCode)
            }
            
            // Check if response data is empty
            guard !data.isEmpty else {
                throw UVIndexError.invalidResponse
            }
            
            // Parse JSON manually to handle the complex structure
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let result = json["result"] as? [String: Any] else {
                throw UVIndexError.invalidResponse
            }
            
            guard let uv = result["uv"] as? Double,
                  let uvTime = result["uv_time"] as? String,
                  let uvMax = result["uv_max"] as? Double,
                  let uvMaxTime = result["uv_max_time"] as? String,
                  let ozone = result["ozone"] as? Double,
                  let ozoneTime = result["ozone_time"] as? String else {
                throw UVIndexError.invalidResponse
            }
            
            // Parse safe exposure time if available
            var safeExposureTime: SafeExposureTime?
            if let safeExposureData = result["safe_exposure_time"] as? [String: Any] {
                safeExposureTime = SafeExposureTime(
                    st1: safeExposureData["st1"] as? Int,
                    st2: safeExposureData["st2"] as? Int,
                    st3: safeExposureData["st3"] as? Int,
                    st4: safeExposureData["st4"] as? Int,
                    st5: safeExposureData["st5"] as? Int,
                    st6: safeExposureData["st6"] as? Int
                )
            }
            
            let uvResult = UVIndexResult(
                uv: uv,
                uvTime: uvTime,
                uvMax: uvMax,
                uvMaxTime: uvMaxTime,
                ozone: ozone,
                ozoneTime: ozoneTime,
                safeExposureTime: safeExposureTime,
                sunInfo: nil // Ignore sun_info for now
            )
            
            return uvResult
            
        } catch let error as UVIndexError {
            throw error
        } catch {
            throw UVIndexError.networkError(error)
        }
    }
    
    private func buildURL(for location: CLLocation) -> URL {
        var components = URLComponents(string: "https://api.openuv.io/api/v1/uv")!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(location.coordinate.latitude)),
            URLQueryItem(name: "lng", value: String(location.coordinate.longitude))
        ]
        return components.url!
    }
}

// MARK: - Mock Service for Testing

final class MockUVIndexService: UVIndexService {
    func fetchUVIndex(for location: CLLocation) async throws -> UVIndexResult {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Return realistic mock data based on time of day
        let hour = Calendar.current.component(.hour, from: Date())
        let baseUV: Double
        
        // Simulate realistic UV levels based on time of day
        switch hour {
        case 6...8:
            baseUV = Double.random(in: 1...3) // Low morning UV
        case 9...11:
            baseUV = Double.random(in: 3...6) // Moderate morning UV
        case 12...14:
            baseUV = Double.random(in: 6...9) // High midday UV
        case 15...17:
            baseUV = Double.random(in: 4...7) // Moderate afternoon UV
        case 18...20:
            baseUV = Double.random(in: 1...4) // Low evening UV
        default:
            baseUV = Double.random(in: 0...2) // Very low night UV
        }
        
        return UVIndexResult(
            uv: baseUV,
            uvTime: ISO8601DateFormatter().string(from: Date()),
            uvMax: baseUV + Double.random(in: 0...2),
            uvMaxTime: ISO8601DateFormatter().string(from: Date()),
            ozone: Double.random(in: 200...500),
            ozoneTime: ISO8601DateFormatter().string(from: Date()),
            safeExposureTime: SafeExposureTime(
                st1: Int.random(in: 10...60),
                st2: Int.random(in: 10...60),
                st3: Int.random(in: 10...60),
                st4: Int.random(in: 10...60),
                st5: Int.random(in: 10...60),
                st6: Int.random(in: 10...60)
            ),
            sunInfo: nil // Mock doesn't need sun info
        )
    }
}

// MARK: - Errors

enum UVIndexError: LocalizedError {
    case noAPIKey
    case locationPermissionDenied
    case locationUnavailable
    case invalidResponse
    case apiError(Int)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "OpenUV API key not configured. Please add your API key in settings."
        case .locationPermissionDenied:
            return "Location permission denied"
        case .locationUnavailable:
            return "Location unavailable"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let code):
            return "API error: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
