//
//  ObservationListCollectionViewCell.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import UIKit

final class ObservationListCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "ObservationListCollectionViewCell"
    private static let previewImageSize: CGFloat = 128
    private static let qualityBadgeSize = CGSize(width: 58, height: 52)

    private var previewWidthConstraint: NSLayoutConstraint?

    private let cardView = ObservationCardBackgroundView()
    private let previewImageView = ObservationPreviewImageView()
    private let commonNameLabel = ObservationTextLabel(font: .preferredFont(forTextStyle: .headline), color: .wildlifePrimaryText, lines: 2)
    private let scientificNameLabel = ObservationTextLabel(font: .italicSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize), color: .secondaryLabel, lines: 1)
    private let dateRow = ObservationMetadataRow(systemImageName: "calendar")
    private let qualityBadgeView = ObservationQualityBadgeView()
    private lazy var metadataStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [dateRow])
        stackView.axis = .vertical
        stackView.spacing = 6
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureCell()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(frame:) instead.")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        previewImageView.cancelImageLoad()
        previewImageView.isHidden = false
        previewWidthConstraint?.constant = Self.previewImageSize
    }

    func configure(with item: ExploreObservationItem, imageLoader: ImageLoader) {
        commonNameLabel.setVisibleText(item.commonName)
        scientificNameLabel.setVisibleText(item.scientificName)
        dateRow.setText(item.observedDate)
        metadataStackView.isHidden = item.observedDate == nil
        qualityBadgeView.configure(symbol: item.qualitySymbol, text: item.qualityText)

        isAccessibilityElement = true
        accessibilityLabel = item.accessibilityLabel
        accessibilityTraits = .button

        configureImage(from: item.imageURL, imageLoader: imageLoader)
    }

    private func configureCell() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    private func configureHierarchy() {
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        [
            previewImageView,
            commonNameLabel,
            scientificNameLabel,
            metadataStackView,
            qualityBadgeView
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview($0)
        }

        previewWidthConstraint = previewImageView.widthAnchor.constraint(equalToConstant: Self.previewImageSize)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            previewImageView.topAnchor.constraint(equalTo: cardView.topAnchor),
            previewImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            previewImageView.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor),
            previewWidthConstraint!,
            previewImageView.heightAnchor.constraint(equalTo: previewImageView.widthAnchor),

            commonNameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            commonNameLabel.leadingAnchor.constraint(equalTo: previewImageView.trailingAnchor, constant: 14),
            commonNameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),

            scientificNameLabel.topAnchor.constraint(equalTo: commonNameLabel.bottomAnchor, constant: 6),
            scientificNameLabel.leadingAnchor.constraint(equalTo: commonNameLabel.leadingAnchor),
            scientificNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: qualityBadgeView.leadingAnchor, constant: -10),

            metadataStackView.leadingAnchor.constraint(equalTo: commonNameLabel.leadingAnchor),
            metadataStackView.trailingAnchor.constraint(lessThanOrEqualTo: qualityBadgeView.leadingAnchor, constant: -10),
            metadataStackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),

            qualityBadgeView.widthAnchor.constraint(equalToConstant: Self.qualityBadgeSize.width),
            qualityBadgeView.heightAnchor.constraint(equalToConstant: Self.qualityBadgeSize.height),
            qualityBadgeView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
            qualityBadgeView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -8)
        ])
    }

    private func configureImage(from url: URL?, imageLoader: ImageLoader) {
        previewImageView.isHidden = false
        previewWidthConstraint?.constant = Self.previewImageSize
        previewImageView.loadImage(from: url, imageLoader: imageLoader)
    }
}
