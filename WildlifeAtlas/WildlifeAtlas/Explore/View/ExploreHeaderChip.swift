//
//  ExploreHeaderChip.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import UIKit

final class ExploreHeaderChip: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .wildlifePrimaryText
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private let chevronImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.down"))
        imageView.tintColor = .wildlifePrimaryText
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        configureHierarchy()
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits = .button
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(title:) instead.")
    }

    private func configureHierarchy() {
        layer.cornerRadius = 18
        layer.borderWidth = 1.5
        layer.borderColor = UIColor.wildlifePrimaryText.cgColor

        let stackView = UIStackView(arrangedSubviews: [titleLabel, chevronImageView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalCentering
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            chevronImageView.widthAnchor.constraint(equalToConstant: 14),
            chevronImageView.heightAnchor.constraint(equalToConstant: 14),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 12),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
}
