//
//  TaxonSearchPanelView.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import UIKit

final class TaxonSearchPanelView: UIView {
    private let imageLoader: ImageLoader
    private var items: [TaxonSearchItem] = []
    private var tableHeightConstraint: NSLayoutConstraint?
    private var tableBottomConstraint: NSLayoutConstraint?
    private var messageTopConstraint: NSLayoutConstraint?
    private var messageBottomConstraint: NSLayoutConstraint?

    var onItemSelected: ((Int) -> Void)?

    private let panelView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 18
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.14
        view.layer.shadowOffset = CGSize(width: 0, height: 6)
        view.layer.shadowRadius = 18
        return view
    }()

    private let arrowView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.transform = CGAffineTransform(rotationAngle: .pi / 4)
        return view
    }()

    private let headerLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .wildlifeAccent
        indicator.hidesWhenStopped = true
        return indicator
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

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorColor = .separator
        tableView.rowHeight = 94
        tableView.estimatedRowHeight = 94
        tableView.keyboardDismissMode = .onDrag
        tableView.tableFooterView = UIView()
        return tableView
    }()

    init(imageLoader: ImageLoader) {
        self.imageLoader = imageLoader
        super.init(frame: .zero)
        configureHierarchy()
        configureTableView()
        isHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(imageLoader:) instead.")
    }

    func render(_ state: TaxonSearchViewModel.State) {
        switch state {
        case .recent(let items):
            renderPanel(
                header: "Recent species",
                items: items,
                message: nil,
                isLoading: false,
                hidesWhenEmpty: true
            )
        case .loading(let previousItems):
            renderPanel(
                header: "Choose a species to filter observations",
                items: previousItems,
                message: previousItems.isEmpty ? "Searching..." : nil,
                isLoading: true,
                hidesWhenEmpty: false
            )
        case .results(let items):
            renderPanel(
                header: "Choose a species to filter observations",
                items: items,
                message: nil,
                isLoading: false,
                hidesWhenEmpty: false
            )
        case .empty:
            renderPanel(
                header: "Choose a species to filter observations",
                items: [],
                message: "No matching taxa",
                isLoading: false,
                hidesWhenEmpty: false
            )
        case .error(_, let message):
            renderPanel(
                header: "Choose a species to filter observations",
                items: [],
                message: message,
                isLoading: false,
                hidesWhenEmpty: false
            )
        }
    }

    func hide() {
        isHidden = true
        activityIndicator.stopAnimating()
    }

    private func renderPanel(
        header: String,
        items: [TaxonSearchItem],
        message: String?,
        isLoading: Bool,
        hidesWhenEmpty: Bool
    ) {
        self.items = items
        headerLabel.text = header
        messageLabel.text = message
        messageLabel.isHidden = message == nil
        tableView.isHidden = items.isEmpty
        isHidden = hidesWhenEmpty && items.isEmpty
        tableHeightConstraint?.constant = min(CGFloat(items.count) * tableView.rowHeight, 386)

        let showsMessage = message != nil
        tableBottomConstraint?.isActive = !items.isEmpty || !showsMessage
        messageTopConstraint?.isActive = showsMessage
        messageBottomConstraint?.isActive = showsMessage

        if isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }

        tableView.reloadData()
    }

    private func configureHierarchy() {
        panelView.translatesAutoresizingMaskIntoConstraints = false
        arrowView.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(panelView)
        panelView.addSubview(arrowView)
        panelView.addSubview(headerLabel)
        panelView.addSubview(activityIndicator)
        panelView.addSubview(tableView)
        panelView.addSubview(messageLabel)

        tableHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        tableBottomConstraint = tableView.bottomAnchor.constraint(equalTo: panelView.bottomAnchor, constant: -16)
        messageTopConstraint = messageLabel.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 12)
        messageBottomConstraint = messageLabel.bottomAnchor.constraint(equalTo: panelView.bottomAnchor, constant: -28)

        NSLayoutConstraint.activate([
            panelView.topAnchor.constraint(equalTo: topAnchor),
            panelView.leadingAnchor.constraint(equalTo: leadingAnchor),
            panelView.trailingAnchor.constraint(equalTo: trailingAnchor),
            panelView.bottomAnchor.constraint(equalTo: bottomAnchor),

            arrowView.topAnchor.constraint(equalTo: panelView.topAnchor, constant: -9),
            arrowView.centerXAnchor.constraint(equalTo: panelView.centerXAnchor),
            arrowView.widthAnchor.constraint(equalToConstant: 24),
            arrowView.heightAnchor.constraint(equalTo: arrowView.widthAnchor),

            headerLabel.topAnchor.constraint(equalTo: panelView.topAnchor, constant: 24),
            headerLabel.leadingAnchor.constraint(equalTo: panelView.leadingAnchor, constant: 34),
            headerLabel.trailingAnchor.constraint(lessThanOrEqualTo: activityIndicator.leadingAnchor, constant: -12),

            activityIndicator.trailingAnchor.constraint(equalTo: panelView.trailingAnchor, constant: -34),
            activityIndicator.centerYAnchor.constraint(equalTo: headerLabel.centerYAnchor),

            tableView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 14),
            tableView.leadingAnchor.constraint(equalTo: panelView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: panelView.trailingAnchor),
            tableHeightConstraint!,

            messageLabel.leadingAnchor.constraint(equalTo: panelView.leadingAnchor, constant: 34),
            messageLabel.trailingAnchor.constraint(equalTo: panelView.trailingAnchor, constant: -34)
        ])
    }

    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TaxonSearchResultCell.self, forCellReuseIdentifier: TaxonSearchResultCell.reuseIdentifier)
    }
}

extension TaxonSearchPanelView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: TaxonSearchResultCell.reuseIdentifier,
            for: indexPath
        )

        guard let taxonCell = cell as? TaxonSearchResultCell else {
            return cell
        }

        taxonCell.configure(with: items[indexPath.row], imageLoader: imageLoader)
        return taxonCell
    }
}

extension TaxonSearchPanelView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onItemSelected?(items[indexPath.row].id)
    }
}
