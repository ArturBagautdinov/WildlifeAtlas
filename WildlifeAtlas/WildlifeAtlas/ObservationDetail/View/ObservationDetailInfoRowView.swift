//
//  ObservationDetailInfoRowView.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import UIKit

final class ObservationDetailInfoRowView: UIView {
    private let iconContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .wildlifeAccentBackground
        view.layer.cornerRadius = 28
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .wildlifePrimaryText
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel = ObservationDetailTextLabel(
        font: .preferredFont(forTextStyle: .subheadline),
        color: .secondaryLabel,
        lines: 1
    )

    private let valueLabel = ObservationDetailTextLabel(
        font: .preferredFont(forTextStyle: .body),
        color: .label,
        lines: 0
    )

    init(systemImageName: String, title: String, value: String) {
        super.init(frame: .zero)
        configureHierarchy()
        iconImageView.image = UIImage(systemName: systemImageName)
        titleLabel.text = title
        valueLabel.text = value
        accessibilityLabel = [title, value].joined(separator: ", ")
        isAccessibilityElement = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(systemImageName:title:value:) instead.")
    }

    private func configureHierarchy() {
        iconContainerView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        iconContainerView.addSubview(iconImageView)

        let textStackView = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        textStackView.axis = .vertical
        textStackView.spacing = 4
        textStackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconContainerView)
        addSubview(textStackView)

        NSLayoutConstraint.activate([
            iconContainerView.topAnchor.constraint(equalTo: topAnchor),
            iconContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconContainerView.widthAnchor.constraint(equalToConstant: 56),
            iconContainerView.heightAnchor.constraint(equalToConstant: 56),

            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 26),
            iconImageView.heightAnchor.constraint(equalToConstant: 26),

            textStackView.topAnchor.constraint(equalTo: topAnchor, constant: 3),
            textStackView.leadingAnchor.constraint(equalTo: iconContainerView.trailingAnchor, constant: 18),
            textStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
