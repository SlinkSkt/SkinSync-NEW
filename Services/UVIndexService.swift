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
}

struct SafeExposureTime: Codable {
    let st1: Int?
    let st2: Int?
    let st3: Int?
    let st4: Int?
    let st5: Int?
    let st6: Int?
}

// MARK: - UV Index Service Protocol

protocol UVIndexService {
    func fetchUVIndex(for location: CLLocation) async throws -> UVIndexResult
}

// MARK: - OpenUV API Implementation

final class OpenUVService: UVIndexService {
    private let apiKey: String
    private let session: URLSession
    
    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }
    
    func fetchUVIndex(for location: CLLocation) async throws -> UVIndexResult {
        let url = buildURL(for: location)
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-access-token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UVIndexError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw UVIndexError.apiError(httpResponse.statusCode)
        }
        
        let uvResponse = try JSONDecoder().decode(UVIndexResponse.self, from: data)
        return uvResponse.result
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
        
        // Return mock data
        return UVIndexResult(
            uv: Double.random(in: 0...11),
            uvTime: ISO8601DateFormatter().string(from: Date()),
            uvMax: Double.random(in: 0...11),
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
            )
        )
    }
}

// MARK: - Errors

enum UVIndexError: LocalizedError {
    case locationPermissionDenied
    case locationUnavailable
    case invalidResponse
    case apiError(Int)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
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
