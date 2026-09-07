//
//  RemoteImageView.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import UIKit

class RemoteImageView: UIImageView {
    private var representedURL: URL?
    private var imageTask: Task<Void, Never>?
    private var loadedContentMode: UIView.ContentMode = .scaleAspectFill
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .secondaryLabel
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    var placeholderImage: UIImage?
    var placeholderContentMode: UIView.ContentMode = .scaleAspectFit

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureLoadingIndicator()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(frame:) instead.")
    }

    func loadImage(from url: URL?, imageLoader: ImageLoader) {
        cancelImageLoad()

        representedURL = url

        guard let url else {
            showPlaceholder()
            return
        }

        showLoading()

        imageTask = Task { [weak self] in
            do {
                let image = try await imageLoader.image(from: url)
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    guard self?.representedURL == url else { return }
                    self?.loadingIndicator.stopAnimating()
                    self?.contentMode = self?.loadedContentMode ?? .scaleAspectFill
                    self?.image = image
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    guard self?.representedURL == url else { return }
                    self?.showPlaceholder()
                }
            }
        }
    }

    func cancelImageLoad() {
        imageTask?.cancel()
        imageTask = nil
        representedURL = nil
        showPlaceholder()
    }

    func setLoadedContentMode(_ contentMode: UIView.ContentMode) {
        loadedContentMode = contentMode
        if image !== placeholderImage {
            self.contentMode = contentMode
        }
    }

    private func configureLoadingIndicator() {
        addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func showLoading() {
        contentMode = placeholderContentMode
        image = nil
        loadingIndicator.startAnimating()
    }

    private func showPlaceholder() {
        loadingIndicator.stopAnimating()
        contentMode = placeholderContentMode
        image = placeholderImage
    }
}
