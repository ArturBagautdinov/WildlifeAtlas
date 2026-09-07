//
//  RemoteImageView.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import UIKit

final class RemoteImageView: UIImageView {
    private var representedURL: URL?
    private var imageTask: Task<Void, Never>?

    deinit {
        imageTask?.cancel()
    }

    func loadImage(from url: URL, imageLoader: ImageLoader) {
        imageTask?.cancel()
        image = nil
        representedURL = url

        imageTask = Task { [weak self] in
            do {
                let loadedImage = try await imageLoader.image(from: url)
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    guard self?.representedURL == url else { return }
                    self?.image = loadedImage
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    guard self?.representedURL == url else { return }
                    self?.image = nil
                }
            }
        }
    }

    func cancelImageLoad() {
        imageTask?.cancel()
        imageTask = nil
        representedURL = nil
        image = nil
    }
}
