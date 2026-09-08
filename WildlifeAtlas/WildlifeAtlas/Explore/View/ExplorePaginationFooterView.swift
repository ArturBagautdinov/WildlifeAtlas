//
//  ExplorePaginationFooterView.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import UIKit

final class ExplorePaginationFooterView: UICollectionReusableView {
    static let reuseIdentifier = "ExplorePaginationFooterView"
    static let elementKind = UICollectionView.elementKindSectionFooter

    var onRetry: (() -> Void)?

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .wildlifePrimaryText
        return indicator
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .wildlifePrimaryText
        label.numberOfLines = 2
        label.textAlignment = .center
        return label
    }()

    private let retryButton: UIButton = {
        var configuration = UIButton.Configuration.tinted()
        configuration.title = "Try again"
        configuration.baseBackgroundColor = .wildlifeAccentBackground
        configuration.baseForegroundColor = .wildlifeAccent
        let button = UIButton(configuration: configuration)
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.accessibilityLabel = "Retry loading more observations"
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [activityIndicator, messageLabel, retryButton])
        stackView.axis = .horizontal
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

    override func prepareForReuse() {
        super.prepareForReuse()
        onRetry = nil
    }

    func configure(with state: ExploreViewModel.PaginationState) {
        switch (state.isLoadingNextPage, state.error) {
        case (true, _):
            isHidden = false
            stackView.axis = .horizontal
            stackView.spacing = 12
            activityIndicator.startAnimating()
            messageLabel.text = "Loading more observations..."
            messageLabel.isHidden = false
            retryButton.isHidden = true
        case (false, let error?):
            isHidden = false
            stackView.axis = .vertical
            stackView.spacing = 4
            activityIndicator.stopAnimating()
            messageLabel.text = error.title
            messageLabel.isHidden = false
            retryButton.isHidden = false
        case (false, nil):
            isHidden = true
            activityIndicator.stopAnimating()
            messageLabel.text = nil
            retryButton.isHidden = true
        }
    }

    private func configureHierarchy() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            messageLabel.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -32),
            retryButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 92)
        ])
    }

    @objc private func retryTapped() {
        onRetry?()
    }
}
