//
//  ExploreStateView.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import UIKit

final class ExploreStateView: UIView {
    var onRetry: (() -> Void)?

    private let activityIndicator = UIActivityIndicatorView(style: .large)

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title2)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.textColor = .wildlifePrimaryText
        label.numberOfLines = 0
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private let retryButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Try again"
        configuration.baseBackgroundColor = .wildlifeAccent
        configuration.baseForegroundColor = .white
        let button = UIButton(configuration: configuration)
        button.accessibilityLabel = "Retry loading observations"
        return button
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [activityIndicator, titleLabel, messageLabel, retryButton])
        stackView.axis = .vertical
        stackView.alignment = .center
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

    func configureLoading() {
        isHidden = false
        activityIndicator.startAnimating()
        titleLabel.text = nil
        titleLabel.isHidden = true
        messageLabel.text = nil
        messageLabel.isHidden = true
        retryButton.isHidden = true
    }

    func configureMessage(title: String, message: String, showsRetry: Bool) {
        isHidden = false
        activityIndicator.stopAnimating()
        titleLabel.text = title
        titleLabel.isHidden = false
        messageLabel.text = message
        messageLabel.isHidden = false
        retryButton.isHidden = !showsRetry
    }

    private func configureHierarchy() {
        backgroundColor = .clear
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @objc private func retryTapped() {
        onRetry?()
    }
}
