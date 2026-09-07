//
//  ExploreStateView.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import UIKit

final class ExploreStateView: UIView {
    var onRetry: (() -> Void)?

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No observations found."
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private let errorTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let errorMessageLabel: UILabel = {
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
        configuration.title = "Retry"
        configuration.cornerStyle = .medium
        configuration.baseBackgroundColor = UIColor(red: 0.06, green: 0.22, blue: 0.12, alpha: 1.0)

        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        button.accessibilityIdentifier = "explore.error.retry"
        return button
    }()

    private lazy var errorStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            errorTitleLabel,
            errorMessageLabel,
            retryButton
        ])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 12
        stackView.isHidden = true
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        hide()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(frame:) instead.")
    }

    func showLoading() {
        isHidden = false
        activityIndicator.startAnimating()
        emptyLabel.isHidden = true
        errorStackView.isHidden = true
    }

    func showEmpty() {
        isHidden = false
        activityIndicator.stopAnimating()
        emptyLabel.isHidden = false
        errorStackView.isHidden = true
    }

    func showError(_ error: ExploreErrorViewModel) {
        isHidden = false
        activityIndicator.stopAnimating()
        emptyLabel.isHidden = true
        errorTitleLabel.text = error.title
        errorMessageLabel.text = error.message
        errorStackView.isHidden = false
    }

    func hide() {
        isHidden = true
        activityIndicator.stopAnimating()
        emptyLabel.isHidden = true
        errorStackView.isHidden = true
    }

    private func configureHierarchy() {
        [activityIndicator, emptyLabel, errorStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),

            emptyLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            emptyLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            errorStackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            errorStackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            errorStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @objc private func retryButtonTapped() {
        onRetry?()
    }
}
