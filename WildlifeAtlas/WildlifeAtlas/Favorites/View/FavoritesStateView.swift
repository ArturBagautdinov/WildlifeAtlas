//
//  FavoritesStateView.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import UIKit

final class FavoritesStateView: UIView {
    var onRetry: (() -> Void)?

    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title3)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .wildlifePrimaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var retryButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Try again"
        configuration.baseBackgroundColor = .wildlifeAccent
        configuration.baseForegroundColor = .white

        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(frame:) instead.")
    }

    func configureLoading() {
        isHidden = false
        activityIndicator.startAnimating()
        titleLabel.isHidden = true
        messageLabel.isHidden = true
        retryButton.isHidden = true
    }

    func configureMessage(title: String, message: String, showsRetry: Bool) {
        isHidden = false
        activityIndicator.stopAnimating()
        titleLabel.text = title
        messageLabel.text = message
        titleLabel.isHidden = false
        messageLabel.isHidden = false
        retryButton.isHidden = !showsRetry
    }

    private func configureHierarchy() {
        let stackView = UIStackView(arrangedSubviews: [activityIndicator, titleLabel, messageLabel, retryButton])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24)
        ])
    }

    @objc private func retryTapped() {
        onRetry?()
    }
}
