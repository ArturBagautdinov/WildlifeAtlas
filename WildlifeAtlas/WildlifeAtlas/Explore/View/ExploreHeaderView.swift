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
    var onTaxonCleared: (() -> Void)?
    var onQualityChanged: ((ObservationQualityFilter) -> Void)?
    var onSortOrderChanged: ((ObservationSortOrder) -> Void)?
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
        setFilters(.defaultValue)
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

    func setFilters(_ filters: ObservationFilters) {
        taxonChip.setTitle(Self.taxonTitle(for: filters.taxon))
        qualityChip.setTitle(Self.qualityTitle(for: filters.quality))
        sortChip.setTitle(Self.sortTitle(for: filters.sortOrder))
        configureFilterMenus(selectedFilters: filters)
    }

    private func configureHierarchy() {
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        searchContainerView.addSubview(searchTextField)

        let chipsScrollView = UIScrollView()
        chipsScrollView.showsHorizontalScrollIndicator = false
        chipsScrollView.alwaysBounceHorizontal = true
        chipsScrollView.translatesAutoresizingMaskIntoConstraints = false

        let chipsStackView = UIStackView(arrangedSubviews: [taxonChip, qualityChip, sortChip])
        chipsStackView.axis = .horizontal
        chipsStackView.alignment = .center
        chipsStackView.distribution = .fill
        chipsStackView.spacing = 8
        chipsStackView.translatesAutoresizingMaskIntoConstraints = false
        chipsScrollView.addSubview(chipsStackView)

        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            searchContainerView,
            chipsScrollView,
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

            chipsScrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            chipsStackView.topAnchor.constraint(equalTo: chipsScrollView.contentLayoutGuide.topAnchor),
            chipsStackView.leadingAnchor.constraint(equalTo: chipsScrollView.contentLayoutGuide.leadingAnchor),
            chipsStackView.trailingAnchor.constraint(equalTo: chipsScrollView.contentLayoutGuide.trailingAnchor),
            chipsStackView.bottomAnchor.constraint(equalTo: chipsScrollView.contentLayoutGuide.bottomAnchor),
            chipsStackView.heightAnchor.constraint(equalTo: chipsScrollView.frameLayoutGuide.heightAnchor),

            modeControl.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])
    }

    private func configureActions() {
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(searchTextDidChange), for: .editingChanged)
        modeControl.addTarget(self, action: #selector(displayModeChanged), for: .valueChanged)
    }

    private func configureFilterMenus(selectedFilters: ObservationFilters) {
        taxonChip.setMenu(UIMenu(children: [
            UIAction(
                title: "All observations",
                state: selectedFilters.taxon == nil ? .on : .off
            ) { [weak self] _ in
                self?.onTaxonCleared?()
            }
        ]))

        qualityChip.setMenu(UIMenu(children: [
            UIAction(
                title: "Any",
                state: selectedFilters.quality == .any ? .on : .off
            ) { [weak self] _ in
                self?.onQualityChanged?(.any)
            },
            UIAction(
                title: "Research Grade",
                state: selectedFilters.quality == .research ? .on : .off
            ) { [weak self] _ in
                self?.onQualityChanged?(.research)
            }
        ]))

        sortChip.setMenu(UIMenu(children: [
            UIAction(
                title: "Newest first",
                state: selectedFilters.sortOrder == .newestFirst ? .on : .off
            ) { [weak self] _ in
                self?.onSortOrderChanged?(.newestFirst)
            },
            UIAction(
                title: "Oldest first",
                state: selectedFilters.sortOrder == .oldestFirst ? .on : .off
            ) { [weak self] _ in
                self?.onSortOrderChanged?(.oldestFirst)
            }
        ]))
    }

    private static func taxonTitle(for taxon: Taxon?) -> String {
        guard let taxon else {
            return "All wildlife"
        }

        return taxon.commonName ?? taxon.scientificName
    }

    private static func qualityTitle(for quality: ObservationQualityFilter) -> String {
        switch quality {
        case .any:
            return "Any grade"
        case .research:
            return "Research"
        }
    }

    private static func sortTitle(for sortOrder: ObservationSortOrder) -> String {
        switch sortOrder {
        case .newestFirst:
            return "Newest"
        case .oldestFirst:
            return "Oldest"
        }
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
