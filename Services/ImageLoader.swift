// Services/ImageLoader.swift
import UIKit

protocol ImageLoader { func image(from url: URL) async throws -> UIImage }

final class DefaultImageLoader: ImageLoader {
    private let cache = NSCache<NSURL, UIImage>()
    func image(from url: URL) async throws -> UIImage {
        if let c = cache.object(forKey: url as NSURL) { return c }
        let (data, resp) = try await URLSession.shared.data(from: url)
        guard (resp as? HTTPURLResponse)?.statusCode == 200, let img = UIImage(data: data) else {
            throw URLError(.badServerResponse)
        }
        cache.setObject(img, forKey: url as NSURL)
        return img
    }
}
