//
//  RemoteImageLoader.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import UIKit

nonisolated final class RemoteImageLoader: ImageLoader {
    private struct InFlightHandle {
        let id: UUID
        let task: Task<UIImage, Error>
    }

    private final class InFlightRequest {
        let id: UUID
        let task: Task<UIImage, Error>
        var waiterIDs: Set<UUID>

        init(id: UUID, task: Task<UIImage, Error>, waiterID: UUID) {
            self.id = id
            self.task = task
            self.waiterIDs = [waiterID]
        }
    }

    private let session: URLSession
    private let cache: NSCache<NSURL, UIImage>
    private let lock = NSLock()
    private var inFlightRequests: [URL: InFlightRequest] = [:]

    init(
        session: URLSession = .shared,
        cache: NSCache<NSURL, UIImage> = NSCache<NSURL, UIImage>()
    ) {
        self.session = session
        self.cache = cache
    }

    func image(from url: URL) async throws -> UIImage {
        try Task.checkCancellation()
        guard Self.canLoad(url) else {
            throw ImageLoadingError.invalidURL
        }

        if let cachedImage = cachedImage(for: url) {
            return cachedImage
        }

        let waiterID = UUID()
        let handle = task(for: url, waiterID: waiterID)

        return try await withTaskCancellationHandler {
            do {
                let image = try await handle.task.value
                cache(image, for: url, completedRequestID: handle.id)
                return image
            } catch is CancellationError {
                removeWaiter(waiterID, for: url, requestID: handle.id)
                throw CancellationError()
            } catch {
                removeCompletedRequest(for: url, requestID: handle.id)
                throw error
            }
        } onCancel: {
            removeWaiter(waiterID, for: url, requestID: handle.id)
        }
    }

    private func cachedImage(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    private static func canLoad(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else {
            return false
        }
        return scheme == "http" || scheme == "https"
    }

    private func task(for url: URL, waiterID: UUID) -> InFlightHandle {
        lock.lock()
        defer { lock.unlock() }

        if let inFlightRequest = inFlightRequests[url] {
            inFlightRequest.waiterIDs.insert(waiterID)
            return InFlightHandle(id: inFlightRequest.id, task: inFlightRequest.task)
        }

        let requestID = UUID()
        let task = Task { [session] in
            try Task.checkCancellation()
            let request = URLRequest(url: url)

            let data: Data
            let response: URLResponse
            do {
                (data, response) = try await session.data(for: request)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                if Task.isCancelled {
                    throw CancellationError()
                }
                throw ImageLoadingError.transport(error.localizedDescription)
            }

            try Task.checkCancellation()

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ImageLoadingError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw ImageLoadingError.httpStatus(httpResponse.statusCode)
            }

            guard let image = UIImage(data: data) else {
                throw ImageLoadingError.invalidImageData
            }

            return image
        }

        inFlightRequests[url] = InFlightRequest(id: requestID, task: task, waiterID: waiterID)
        return InFlightHandle(id: requestID, task: task)
    }

    private func cache(_ image: UIImage, for url: URL, completedRequestID: UUID) {
        lock.lock()
        defer { lock.unlock() }

        cache.setObject(image, forKey: url as NSURL)
        if inFlightRequests[url]?.id == completedRequestID {
            inFlightRequests[url] = nil
        }
    }

    private func removeCompletedRequest(for url: URL, requestID: UUID) {
        lock.lock()
        defer { lock.unlock() }

        if inFlightRequests[url]?.id == requestID {
            inFlightRequests[url] = nil
        }
    }

    private func removeWaiter(_ waiterID: UUID, for url: URL, requestID: UUID) {
        lock.lock()
        defer { lock.unlock() }

        guard let inFlightRequest = inFlightRequests[url], inFlightRequest.id == requestID else {
            return
        }

        inFlightRequest.waiterIDs.remove(waiterID)
        if inFlightRequest.waiterIDs.isEmpty {
            inFlightRequest.task.cancel()
            inFlightRequests[url] = nil
        }
    }
}
