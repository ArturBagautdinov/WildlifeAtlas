//
//  ExploreHeaderView.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import UIKit

final class ExploreHeaderView: UIView {
    var onSearchBegan: ((String) -> Void)?
    var onSearchTextChanged: ((String) -> Void)?
    var onSearchCleared: (() -> Void)?
    var onSearchReturned: (() -> Void)?
    var onDisplayModeChanged: ((ExploreDisplayMode) -> Void)?

    var searchAnchorView: UIView {
        searchContainerView
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 42, weight: .semibold)
        label.adjustsFontForContentSizeCategory = true
        label.text = "Wild Atlas"
        label.textAlignment = .center
        label.textColor = .wildlifePrimaryText
        return label
    }()

    private let searchContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let searchTextField: UISearchTextField = {
        let textField = UISearchTextField()
        textField.placeholder = "Search species"
        textField.font = .preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .search
        textField.tintColor = .wildlifeAccent
        textField.accessibilityLabel = "Search species"
        return textField
    }()

    private let taxonChip = ExploreHeaderChip(title: "All wildlife")
    private let qualityChip = ExploreHeaderChip(title: "Any grade")
    private let sortChip = ExploreHeaderChip(title: "Newest")

    private let modeControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["List", "Grid"])
        control.selectedSegmentIndex = 0
        control.accessibilityLabel = "Explore display mode"
        return control
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureActions()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(frame:) instead.")
    }

    func setSearchText(_ text: String) {
        searchTextField.text = text
    }

    func resignSearchFocus() {
        searchTextField.resignFirstResponder()
    }

    func setDisplayMode(_ mode: ExploreDisplayMode) {
        modeControl.selectedSegmentIndex = mode == .list ? 0 : 1
        modeControl.accessibilityValue = mode == .list ? "List" : "Grid"
    }

    private func configureHierarchy() {
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        searchContainerView.addSubview(searchTextField)

        let chipsStackView = UIStackView(arrangedSubviews: [taxonChip, qualityChip, sortChip])
        chipsStackView.axis = .horizontal
        chipsStackView.alignment = .center
        chipsStackView.distribution = .fillEqually
        chipsStackView.spacing = 12

        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            searchContainerView,
            chipsStackView,
            modeControl
        ])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 14
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            searchContainerView.heightAnchor.constraint(equalToConstant: 44),
            searchTextField.leadingAnchor.constraint(equalTo: searchContainerView.leadingAnchor, constant: 12),
            searchTextField.trailingAnchor.constraint(equalTo: searchContainerView.trailingAnchor, constant: -12),
            searchTextField.topAnchor.constraint(equalTo: searchContainerView.topAnchor, constant: 2),
            searchTextField.bottomAnchor.constraint(equalTo: searchContainerView.bottomAnchor, constant: -2),

            modeControl.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])
    }

    private func configureActions() {
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(searchTextDidChange), for: .editingChanged)
        modeControl.addTarget(self, action: #selector(displayModeChanged), for: .valueChanged)
    }

    @objc private func searchTextDidChange() {
        onSearchTextChanged?(searchTextField.text ?? "")
    }

    @objc private func displayModeChanged() {
        onDisplayModeChanged?(modeControl.selectedSegmentIndex == 0 ? .list : .grid)
    }
}

extension ExploreHeaderView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        onSearchBegan?(textField.text ?? "")
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        onSearchCleared?()
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        onSearchReturned?()
        return true
    }
}
