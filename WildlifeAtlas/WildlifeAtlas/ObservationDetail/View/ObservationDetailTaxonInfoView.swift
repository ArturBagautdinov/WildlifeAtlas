//
//  ObservationDetailTaxonInfoView.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import UIKit

final class ObservationDetailTaxonInfoView: UIView {
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
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

    func configure(rows: [ObservationDetailInfoRow]) {
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        rows.forEach { row in
            stackView.addArrangedSubview(makeRow(title: row.title, value: row.value))
        }

        isHidden = rows.isEmpty
        accessibilityLabel = rows.map { "\($0.title), \($0.value)" }.joined(separator: ", ")
    }

    private func configureHierarchy() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 10
        layer.borderColor = UIColor.separator.cgColor
        layer.borderWidth = 1
        isAccessibilityElement = true

        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func makeRow(title: String, value: String) -> UIView {
        let titleLabel = ObservationDetailTextLabel(
            font: .preferredFont(forTextStyle: .subheadline),
            color: .secondaryLabel,
            lines: 1
        )
        titleLabel.text = title

        let valueLabel = ObservationDetailTextLabel(
            font: .preferredFont(forTextStyle: .body),
            color: .label,
            lines: 0
        )
        valueLabel.text = value

        let stackView = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stackView.axis = .vertical
        stackView.spacing = 3
        stackView.isAccessibilityElement = true
        stackView.accessibilityLabel = [title, value].joined(separator: ", ")
        return stackView
    }
}
