//
//  ObservationCellComponents.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import UIKit

final class ObservationCardBackgroundView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 10
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.10
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(frame:) instead.")
    }
}

final class ObservationPreviewImageView: RemoteImageView {
    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setLoadedContentMode(.scaleAspectFill)
        placeholderContentMode = .center
        placeholderImage = UIImage(systemName: "photo")
        image = placeholderImage
        tintColor = .secondaryLabel
        clipsToBounds = true
        layer.cornerRadius = 10
        backgroundColor = .tertiarySystemFill
        isAccessibilityElement = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(frame:) instead.")
    }
}

final class ObservationTextLabel: UILabel {
    init(font: UIFont, color: UIColor, lines: Int) {
        super.init(frame: .zero)
        self.font = font
        adjustsFontForContentSizeCategory = true
        textColor = color
        numberOfLines = lines
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(font:color:lines:) instead.")
    }
}

final class ObservationMetadataRow: UIView {
    private let imageView: UIImageView
    private let label: UILabel

    init(systemImageName: String) {
        self.imageView = UIImageView(image: UIImage(systemName: systemImageName))
        self.label = UILabel()
        super.init(frame: .zero)
        configureHierarchy()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(systemImageName:) instead.")
    }

    func setText(_ text: String?) {
        label.setVisibleText(text)
        isHidden = text == nil
    }

    private func configureHierarchy() {
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false

        addSubview(imageView)
        addSubview(label)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.heightAnchor.constraint(equalToConstant: 20),

            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

final class ObservationQualityBadgeView: UIView {
    private let symbolLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.textColor = .wildlifePrimaryText
        return label
    }()

    private let textLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.textAlignment = .center
        label.textColor = .wildlifePrimaryText
        label.numberOfLines = 1
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(frame:) instead.")
    }

    func configure(symbol: String?, text: String?) {
        symbolLabel.setVisibleText(symbol)
        textLabel.setVisibleText(text)
        isHidden = symbol == nil && text == nil
    }

    private func configureHierarchy() {
        backgroundColor = UIColor(red: 0.89, green: 0.93, blue: 0.82, alpha: 1.0)
        layer.cornerRadius = 10
        clipsToBounds = true

        let stackView = UIStackView(arrangedSubviews: [symbolLabel, textLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.spacing = 0
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

final class ObservationFavoriteButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(frame:) instead.")
    }

    func setFavorite(_ isFavorite: Bool) {
        let imageName = isFavorite ? "heart.fill" : "heart"
        setImage(UIImage(systemName: imageName), for: .normal)
        tintColor = isFavorite ? .systemRed : .wildlifeAccent
        accessibilityValue = isFavorite ? "Favorite" : "Not favorite"
    }

    private func configure() {
        backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.92)
        layer.cornerRadius = 16
        clipsToBounds = true
        accessibilityLabel = "Favorite observation"
        accessibilityTraits = .button
    }
}

extension UILabel {
    func setVisibleText(_ text: String?) {
        self.text = text
        isHidden = text == nil
    }
}

extension UIColor {
    static let wildlifePrimaryText = UIColor(red: 0.06, green: 0.22, blue: 0.12, alpha: 1.0)
    static let wildlifeAccent = UIColor(red: 0.12, green: 0.43, blue: 0.23, alpha: 1.0)
    static let wildlifeAccentBackground = UIColor(red: 0.87, green: 0.93, blue: 0.82, alpha: 1.0)
}
