//
//  ExploreHeaderChip.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import UIKit

final class ExploreHeaderChip: UIView {
    private let button = UIButton(type: .system)

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .wildlifePrimaryText
        label.textAlignment = .center
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
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
        configureHierarchy()
        setTitle(title)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(title:) instead.")
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
        button.accessibilityLabel = title
    }

    func setMenu(_ menu: UIMenu?) {
        button.menu = menu
        button.showsMenuAsPrimaryAction = menu != nil
    }

    private func configureHierarchy() {
        layer.cornerRadius = 18
        layer.borderWidth = 1.5
        layer.borderColor = UIColor.wildlifePrimaryText.cgColor
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        isAccessibilityElement = false
        titleLabel.isAccessibilityElement = false
        chevronImageView.isAccessibilityElement = false
        button.isAccessibilityElement = true
        button.accessibilityTraits = .button

        let stackView = UIStackView(arrangedSubviews: [titleLabel, chevronImageView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalCentering
        stackView.spacing = 8
        stackView.isUserInteractionEnabled = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)
        addSubview(button)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            chevronImageView.widthAnchor.constraint(equalToConstant: 14),
            chevronImageView.heightAnchor.constraint(equalToConstant: 14),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 12),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

            button.topAnchor.constraint(equalTo: topAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
