//
//  TaxonSearchResultCell.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import UIKit

final class TaxonSearchResultCell: UITableViewCell {
    static let reuseIdentifier = "TaxonSearchResultCell"

    private let taxonImageView = TaxonThumbnailImageView()

    private let primaryNameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
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

    private let iconicTaxonLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .right
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()

    private lazy var nameStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [primaryNameLabel, scientificNameLabel])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 4
        return stackView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureHierarchy()
        configureCell()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(style:reuseIdentifier:) instead.")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        taxonImageView.cancelImageLoad()
        primaryNameLabel.text = nil
        scientificNameLabel.text = nil
        iconicTaxonLabel.text = nil
    }

    func configure(with item: TaxonSearchItem, imageLoader: ImageLoader) {
        primaryNameLabel.text = item.primaryName
        scientificNameLabel.setVisibleText(item.scientificName)
        iconicTaxonLabel.setVisibleText(item.iconicTaxonName)
        taxonImageView.loadImage(from: item.imageURL, imageLoader: imageLoader)

        isAccessibilityElement = true
        accessibilityLabel = item.accessibilityLabel
        accessibilityTraits = .button
    }

    private func configureCell() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .default
        separatorInset = UIEdgeInsets(top: 0, left: 92, bottom: 0, right: 34)
    }

    private func configureHierarchy() {
        [
            taxonImageView,
            nameStackView,
            iconicTaxonLabel
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            taxonImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 34),
            taxonImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            taxonImageView.widthAnchor.constraint(equalToConstant: 58),
            taxonImageView.heightAnchor.constraint(equalTo: taxonImageView.widthAnchor),

            nameStackView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 12),
            nameStackView.leadingAnchor.constraint(equalTo: taxonImageView.trailingAnchor, constant: 22),
            nameStackView.trailingAnchor.constraint(lessThanOrEqualTo: iconicTaxonLabel.leadingAnchor, constant: -12),
            nameStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),

            iconicTaxonLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -34),
            iconicTaxonLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconicTaxonLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 112)
        ])
    }
}

private final class TaxonThumbnailImageView: RemoteImageView {
    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setLoadedContentMode(.scaleAspectFill)
        placeholderContentMode = .center
        placeholderImage = UIImage(systemName: "leaf")
        image = placeholderImage
        tintColor = .secondaryLabel
        backgroundColor = .tertiarySystemFill
        clipsToBounds = true
        layer.cornerRadius = 29
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(frame:) instead.")
    }
}
