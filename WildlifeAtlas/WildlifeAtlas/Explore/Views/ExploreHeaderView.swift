//
//  ExploreHeaderView.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import UIKit

final class ExploreHeaderView: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Wild Atlas"
        label.font = .preferredFont(forTextStyle: .largeTitle)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = UIColor(red: 0.06, green: 0.22, blue: 0.12, alpha: 1.0)
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private let searchField: UISearchTextField = {
        let field = UISearchTextField()
        field.placeholder = "Search species"
        field.isUserInteractionEnabled = false
        field.backgroundColor = .secondarySystemBackground
        field.layer.borderColor = UIColor.separator.cgColor
        field.layer.borderWidth = 1
        field.layer.cornerRadius = 18
        field.clipsToBounds = true
        field.accessibilityIdentifier = "explore.search.placeholder"
        return field
    }()

    private lazy var filterStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            makeFilterButton(title: "All wildlife"),
            makeFilterButton(title: "Any grade"),
            makeFilterButton(title: "Newest")
        ])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(frame:) instead.")
    }

    private func configureHierarchy() {
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            searchField,
            filterStackView
        ])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            searchField.heightAnchor.constraint(greaterThanOrEqualToConstant: 54),
            filterStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    private func makeFilterButton(title: String) -> UIButton {
        var configuration = UIButton.Configuration.bordered()
        configuration.title = title
        configuration.image = UIImage(systemName: "chevron.down")
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 8
        configuration.cornerStyle = .capsule
        configuration.baseForegroundColor = UIColor(red: 0.05, green: 0.20, blue: 0.12, alpha: 1.0)
        configuration.background.strokeColor = UIColor(red: 0.05, green: 0.20, blue: 0.12, alpha: 1.0)
        configuration.background.strokeWidth = 1.5

        let button = UIButton(configuration: configuration)
        button.isUserInteractionEnabled = false
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        return button
    }
}
