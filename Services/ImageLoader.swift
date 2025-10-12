// Services/ImageLoader.swift
// Lightweight async image loader with in-memory caching.
// Keeps a tiny API surface so it’s easy to swap in tests or other loaders.
// !!!!!!!!!!  ---- STILL UNDER DEVELOPMENT, PLEASE EXCLUDE THIS FROM THE ASSESSMENT 1  --- !!!!!!!!!!
// !!!!!!!!!!  ---- STILL UNDER DEVELOPMENT, PLEASE EXCLUDE THIS FROM THE ASSESSMENT 1  --- !!!!!!!!!!
// !!!!!!!!!!  ---- STILL UNDER DEVELOPMENT, PLEASE EXCLUDE THIS FROM THE ASSESSMENT 1  --- !!!!!!!!!!-Zhen Xiao 30/8/2025
// THIS FIRST STAGE CODING FOR FUTURE REMOTE API IMPLEMENTATION, PLEASE EXCLUDE THIS FROM ASSESSMENT 1 --!!!!!!!!!
import UIKit

/// Loads images asynchronously from URLs.
/// Kept as a protocol so the app can inject a mock in previews/tests.
protocol ImageLoader {
    /// Fetch an image for the given URL.
    /// Implementations may return a cached image synchronously or fetch over the network.
    func image(from url: URL) async throws -> UIImage
}

/// Default loader backed by `URLSession` and an in-memory `NSCache`.
/// Thread-safe: `NSCache` is safe to access from multiple threads.
final class DefaultImageLoader: ImageLoader {

    // MARK: - Cache
    private let cache = NSCache<NSURL, UIImage>()

    init() {
        // Reasonable defaults to avoid unbounded memory growth.
        cache.countLimit = 200        // up to 200 images
        cache.totalCostLimit = 64 * 1024 * 1024 // ~64 MB (heuristic)
    }

    // MARK: - ImageLoader
    func image(from url: URL) async throws -> UIImage {
        // Fast path: memory cache
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }

        // Network fetch with a sensible request
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.cachePolicy = .returnCacheDataElseLoad // leverage URLCache when available

        let (data, response) = try await URLSession.shared.data(for: request)

        // Validate response
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }

        // Cache & return
        let cost = data.count
        cache.setObject(image, forKey: url as NSURL, cost: cost)
        return image
    }

    // MARK: - Maintenance
    /// Remove all cached images. Not part of the protocol on purpose.
    func clearCache() { cache.removeAllObjects() }
}
