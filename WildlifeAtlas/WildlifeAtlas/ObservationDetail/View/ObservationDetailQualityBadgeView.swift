//
//  ObservationDetailQualityBadgeView.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import UIKit

final class ObservationDetailQualityBadgeView: UIView {
    private let symbolLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .wildlifePrimaryText
        label.textAlignment = .center
        return label
    }()

    private let textLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .wildlifePrimaryText
        label.textAlignment = .center
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
        symbolLabel.text = symbol
        symbolLabel.isHidden = symbol == nil
        textLabel.text = text
        textLabel.isHidden = text == nil
        isHidden = symbol == nil && text == nil
        accessibilityLabel = text
    }

    private func configureHierarchy() {
        backgroundColor = .wildlifeAccentBackground
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.wildlifeAccent.withAlphaComponent(0.25).cgColor
        isAccessibilityElement = true

        let stackView = UIStackView(arrangedSubviews: [symbolLabel, textLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
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
