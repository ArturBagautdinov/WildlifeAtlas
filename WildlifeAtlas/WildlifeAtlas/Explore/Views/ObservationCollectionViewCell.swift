//
//  ObservationCollectionViewCell.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import UIKit

final class ObservationCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "ObservationCollectionViewCell"
    private static let previewImageSize: CGFloat = 128
    private static let qualityBadgeSize = CGSize(width: 58, height: 52)

    private var previewWidthConstraint: NSLayoutConstraint?

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 10
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.10
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        return view
    }()

    private let previewImageView: RemoteImageView = {
        let imageView = RemoteImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        imageView.backgroundColor = .tertiarySystemFill
        imageView.isAccessibilityElement = false
        return imageView
    }()

    private let commonNameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = UIColor(red: 0.06, green: 0.22, blue: 0.12, alpha: 1.0)
        label.numberOfLines = 2
        return label
    }()

    private let scientificNameLabel: UILabel = {
        let label = UILabel()
        label.font = .italicSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()

    private let dateImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "calendar"))
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()

    private lazy var dateStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [dateImageView, dateLabel])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()

    private let qualitySymbolLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.textColor = UIColor(red: 0.06, green: 0.22, blue: 0.12, alpha: 1.0)
        return label
    }()

    private let qualityTextLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.textColor = UIColor(red: 0.06, green: 0.22, blue: 0.12, alpha: 1.0)
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()

    private lazy var qualityStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [qualitySymbolLabel, qualityTextLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.spacing = 0
        stackView.backgroundColor = UIColor(red: 0.89, green: 0.93, blue: 0.82, alpha: 1.0)
        stackView.layer.cornerRadius = 10
        stackView.clipsToBounds = true
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)
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
        dateLabel.setVisibleText(item.observedDate)
        dateStackView.isHidden = item.observedDate == nil
        qualitySymbolLabel.setVisibleText(item.qualitySymbol)
        qualityTextLabel.setVisibleText(item.qualityText)
        qualityStackView.isHidden = item.qualitySymbol == nil && item.qualityText == nil

        isAccessibilityElement = true
        accessibilityLabel = item.accessibilityLabel
        accessibilityTraits = .staticText

        configureImage(from: item.imageURL, imageLoader: imageLoader)
    }

    private func configureCell() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    private func configureHierarchy() {
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        let textStackView = UIStackView(arrangedSubviews: [
            commonNameLabel,
            scientificNameLabel,
            UIView(),
            dateStackView
        ])
        textStackView.axis = .vertical
        textStackView.spacing = 5

        let contentStackView = UIStackView(arrangedSubviews: [
            previewImageView,
            textStackView
        ])
        contentStackView.axis = .horizontal
        contentStackView.alignment = .center
        contentStackView.spacing = 14
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(contentStackView)
        qualityStackView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(qualityStackView)

        previewWidthConstraint = previewImageView.widthAnchor.constraint(equalToConstant: Self.previewImageSize)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: cardView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -14),
            contentStackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            textStackView.trailingAnchor.constraint(lessThanOrEqualTo: qualityStackView.leadingAnchor, constant: -10),

            previewWidthConstraint!,
            previewImageView.heightAnchor.constraint(equalTo: previewImageView.widthAnchor),

            dateImageView.widthAnchor.constraint(equalToConstant: 20),
            dateImageView.heightAnchor.constraint(equalToConstant: 20),

            dateStackView.trailingAnchor.constraint(lessThanOrEqualTo: qualityStackView.leadingAnchor, constant: -10),

            qualityStackView.widthAnchor.constraint(equalToConstant: Self.qualityBadgeSize.width),
            qualityStackView.heightAnchor.constraint(equalToConstant: Self.qualityBadgeSize.height),
            qualityStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
            qualityStackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -8)
        ])
    }

    private func configureImage(from url: URL?, imageLoader: ImageLoader) {
        previewImageView.cancelImageLoad()

        guard let url else {
            previewImageView.isHidden = true
            previewWidthConstraint?.constant = 0
            return
        }

        previewImageView.isHidden = false
        previewWidthConstraint?.constant = Self.previewImageSize
        previewImageView.loadImage(from: url, imageLoader: imageLoader)
    }
}

private extension UILabel {
    func setVisibleText(_ text: String?) {
        self.text = text
        isHidden = text == nil
    }
}
