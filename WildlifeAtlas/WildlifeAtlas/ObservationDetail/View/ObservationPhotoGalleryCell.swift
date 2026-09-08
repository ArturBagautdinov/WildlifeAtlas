//
//  ObservationPhotoGalleryCell.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import UIKit

final class ObservationPhotoGalleryCell: UICollectionViewCell {
    static let reuseIdentifier = "ObservationPhotoGalleryCell"

    private let imageView: RemoteImageView = {
        let imageView = RemoteImageView(frame: .zero)
        imageView.setLoadedContentMode(.scaleAspectFill)
        imageView.placeholderImage = UIImage(systemName: "photo")
        imageView.placeholderContentMode = .center
        imageView.tintColor = .secondaryLabel
        imageView.backgroundColor = .tertiarySystemFill
        imageView.clipsToBounds = true
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(frame:) instead.")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancelImageLoad()
    }

    func configure(with photo: ObservationDetailPhotoItem, imageLoader: ImageLoader) {
        imageView.loadImage(from: photo.imageURL, imageLoader: imageLoader)
        imageView.accessibilityLabel = photo.accessibilityLabel
    }

    func cancelImageLoad() {
        imageView.cancelImageLoad()
    }

    private func configureHierarchy() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}
