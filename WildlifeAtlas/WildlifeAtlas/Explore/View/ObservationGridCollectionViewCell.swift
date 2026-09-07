//
//  ObservationGridCollectionViewCell.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import UIKit

final class ObservationGridCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "ObservationGridCollectionViewCell"
    private static let qualityBadgeHeight: CGFloat = 42

    private let cardView = ObservationCardBackgroundView()
    private let previewImageView = ObservationPreviewImageView()
    private let commonNameLabel = ObservationTextLabel(font: .preferredFont(forTextStyle: .subheadline), color: .wildlifePrimaryText, lines: 2)
    private let scientificNameLabel = ObservationTextLabel(font: .italicSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption1).pointSize), color: .secondaryLabel, lines: 1)
    private let dateRow = ObservationMetadataRow(systemImageName: "calendar")
    private let qualityBadgeView = ObservationQualityBadgeView()
    private lazy var infoStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            commonNameLabel,
            scientificNameLabel,
            dateRow
        ])
        stackView.axis = .vertical
        stackView.alignment = .fill
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
    }

    func configure(with item: ExploreObservationItem, imageLoader: ImageLoader) {
        commonNameLabel.setVisibleText(item.commonName)
        scientificNameLabel.setVisibleText(item.scientificName)
        dateRow.setText(item.observedDate)
        qualityBadgeView.configure(symbol: item.qualitySymbol, text: item.qualityText)

        isAccessibilityElement = true
        accessibilityLabel = item.accessibilityLabel
        accessibilityTraits = .button

        previewImageView.loadImage(from: item.imageURL, imageLoader: imageLoader)
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
            infoStackView,
            qualityBadgeView
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            previewImageView.topAnchor.constraint(equalTo: cardView.topAnchor),
            previewImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            previewImageView.heightAnchor.constraint(equalTo: previewImageView.widthAnchor, multiplier: 0.82),

            infoStackView.topAnchor.constraint(equalTo: previewImageView.bottomAnchor, constant: 10),
            infoStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            infoStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            infoStackView.bottomAnchor.constraint(lessThanOrEqualTo: qualityBadgeView.topAnchor, constant: -10),

            qualityBadgeView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            qualityBadgeView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            qualityBadgeView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -10),
            qualityBadgeView.heightAnchor.constraint(equalToConstant: Self.qualityBadgeHeight)
        ])
    }
}
