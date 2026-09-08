//
//  ExploreViewController.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import UIKit

private nonisolated enum ExploreSection {
    case observations
}

final class ExploreViewController: UIViewController {
    private let viewModel: ExploreViewModel
    private let imageLoader: ImageLoader
    private var dataSource: UICollectionViewDiffableDataSource<ExploreSection, ExploreObservationItem>?

    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: ExploreCollectionViewLayoutFactory.makeLayout(for: viewModel.displayMode)
    )

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 42, weight: .semibold)
        label.adjustsFontForContentSizeCategory = true
        label.text = "Wild Atlas"
        label.textAlignment = .center
        label.textColor = .wildlifePrimaryText
        return label
    }()

    private let searchPlaceholderView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 20
        view.layer.borderColor = UIColor.wildlifeAccent.withAlphaComponent(0.28).cgColor
        view.layer.borderWidth = 1
        view.backgroundColor = UIColor.wildlifeAccentBackground.withAlphaComponent(0.26)
        return view
    }()

    private let searchIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        imageView.tintColor = .wildlifeAccent
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let searchLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.text = "Search species"
        label.textColor = .secondaryLabel
        return label
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

    private let stateView = ExploreStateView()

    init(viewModel: ExploreViewModel, imageLoader: ImageLoader) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(viewModel:imageLoader:) instead.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureHierarchy()
        configureCollectionView()
        configureDataSource()
        bindViewModel()
        stateView.onRetry = { [weak self] in
            self?.viewModel.loadInitialObservations()
        }
        render(state: viewModel.state)
        render(paginationState: viewModel.paginationState)
        viewModel.loadInitialObservations()
    }

    private func configureView() {
        view.backgroundColor = UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0)
        navigationItem.title = ""
    }

    private func configureHierarchy() {
        let searchStackView = UIStackView(arrangedSubviews: [searchIconView, searchLabel])
        searchStackView.axis = .horizontal
        searchStackView.alignment = .center
        searchStackView.spacing = 14
        searchStackView.translatesAutoresizingMaskIntoConstraints = false
        searchPlaceholderView.addSubview(searchStackView)

        let chipsStackView = UIStackView(arrangedSubviews: [taxonChip, qualityChip, sortChip])
        chipsStackView.axis = .horizontal
        chipsStackView.alignment = .center
        chipsStackView.distribution = .fillEqually
        chipsStackView.spacing = 12

        let headerStackView = UIStackView(arrangedSubviews: [
            titleLabel,
            searchPlaceholderView,
            chipsStackView,
            modeControl
        ])
        headerStackView.axis = .vertical
        headerStackView.alignment = .fill
        headerStackView.spacing = 14
        headerStackView.translatesAutoresizingMaskIntoConstraints = false

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        stateView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerStackView)
        view.addSubview(collectionView)
        view.addSubview(stateView)

        NSLayoutConstraint.activate([
            headerStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            headerStackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            headerStackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

            searchPlaceholderView.heightAnchor.constraint(equalToConstant: 44),
            searchIconView.widthAnchor.constraint(equalToConstant: 22),
            searchIconView.heightAnchor.constraint(equalToConstant: 22),
            searchStackView.leadingAnchor.constraint(equalTo: searchPlaceholderView.leadingAnchor, constant: 18),
            searchStackView.trailingAnchor.constraint(lessThanOrEqualTo: searchPlaceholderView.trailingAnchor, constant: -18),
            searchStackView.centerYAnchor.constraint(equalTo: searchPlaceholderView.centerYAnchor),

            modeControl.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),

            collectionView.topAnchor.constraint(equalTo: headerStackView.bottomAnchor, constant: 18),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stateView.topAnchor.constraint(equalTo: collectionView.topAnchor),
            stateView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stateView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stateView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func configureCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.register(
            ObservationListCollectionViewCell.self,
            forCellWithReuseIdentifier: ObservationListCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            ObservationGridCollectionViewCell.self,
            forCellWithReuseIdentifier: ObservationGridCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            ExplorePaginationFooterView.self,
            forSupplementaryViewOfKind: ExplorePaginationFooterView.elementKind,
            withReuseIdentifier: ExplorePaginationFooterView.reuseIdentifier
        )

        modeControl.addTarget(self, action: #selector(displayModeChanged), for: .valueChanged)
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<ExploreSection, ExploreObservationItem>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, item in
            guard let self else { return nil }

            switch viewModel.displayMode {
            case .list:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ObservationListCollectionViewCell.reuseIdentifier,
                    for: indexPath
                ) as? ObservationListCollectionViewCell
                cell?.configure(with: item, imageLoader: imageLoader)
                return cell
            case .grid:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ObservationGridCollectionViewCell.reuseIdentifier,
                    for: indexPath
                ) as? ObservationGridCollectionViewCell
                cell?.configure(with: item, imageLoader: imageLoader)
                return cell
            }
        }

        dataSource?.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard
                let self,
                kind == ExplorePaginationFooterView.elementKind,
                let footer = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: ExplorePaginationFooterView.reuseIdentifier,
                    for: indexPath
                ) as? ExplorePaginationFooterView
            else {
                return nil
            }

            footer.configure(with: viewModel.paginationState)
            footer.onRetry = { [weak self] in
                self?.viewModel.retryNextPage()
            }
            return footer
        }
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state: state)
        }
        viewModel.onPaginationStateChange = { [weak self] state in
            self?.render(paginationState: state)
        }
        viewModel.onDisplayModeChange = { [weak self] mode in
            self?.applyDisplayMode(mode)
        }
    }

    private func render(state: ExploreViewModel.State) {
        switch state {
        case .loading:
            collectionView.isHidden = true
            stateView.configureLoading()
        case .content(let items):
            collectionView.isHidden = false
            stateView.isHidden = true
            applySnapshot(items: items)
        case .empty:
            collectionView.isHidden = true
            stateView.configureMessage(title: "No observations yet", message: "Try again later.", showsRetry: false)
        case .error(let error):
            collectionView.isHidden = true
            stateView.configureMessage(title: error.title, message: error.message, showsRetry: true)
        }
    }

    private func render(paginationState: ExploreViewModel.PaginationState) {
        guard case .content = viewModel.state else { return }
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.visibleSupplementaryViews(ofKind: ExplorePaginationFooterView.elementKind)
            .compactMap { $0 as? ExplorePaginationFooterView }
            .forEach { $0.configure(with: paginationState) }
    }

    private func applySnapshot(items: [ExploreObservationItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<ExploreSection, ExploreObservationItem>()
        snapshot.appendSections([.observations])
        snapshot.appendItems(items, toSection: .observations)
        dataSource?.apply(snapshot, animatingDifferences: true)
    }

    private func applyDisplayMode(_ mode: ExploreDisplayMode) {
        modeControl.selectedSegmentIndex = mode == .list ? 0 : 1
        modeControl.accessibilityValue = mode == .list ? "List" : "Grid"

        let visibleItemID = firstVisibleItemID()
        UIView.performWithoutAnimation {
            collectionView.setCollectionViewLayout(
                ExploreCollectionViewLayoutFactory.makeLayout(for: mode),
                animated: false
            )
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
            scrollToItem(id: visibleItemID)
        }
    }

    private func firstVisibleItemID() -> Int? {
        collectionView.indexPathsForVisibleItems.sorted().compactMap { indexPath in
            dataSource?.itemIdentifier(for: indexPath)?.id
        }.first
    }

    private func scrollToItem(id: Int?) {
        guard
            let id,
            let item = viewModel.loadedItems.first(where: { $0.id == id }),
            let indexPath = dataSource?.indexPath(for: item)
        else {
            return
        }

        collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
    }

    @objc private func displayModeChanged() {
        viewModel.setDisplayMode(modeControl.selectedSegmentIndex == 0 ? .list : .grid)
    }
}

extension ExploreViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let item = dataSource?.itemIdentifier(for: indexPath)
        viewModel.loadNextPageIfNeeded(currentItemID: item?.id)
    }
}
