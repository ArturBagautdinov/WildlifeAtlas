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
    private let taxonSearchViewModel: TaxonSearchViewModel
    private let imageLoader: ImageLoader
    private var dataSource: UICollectionViewDiffableDataSource<ExploreSection, ExploreObservationItem>?

    var onTaxonSelected: ((Taxon) -> Void)?
    var onObservationSelected: ((Int) -> Void)?

    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: ExploreCollectionViewLayoutFactory.makeLayout(for: viewModel.displayMode)
    )

    private let headerView = ExploreHeaderView()
    private let stateView = ExploreStateView()
    private lazy var taxonSearchPanelView = TaxonSearchPanelView(imageLoader: imageLoader)
    private lazy var keyboardDismissTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(dismissSearchKeyboard))
        gesture.cancelsTouchesInView = false
        gesture.delegate = self
        return gesture
    }()

    init(
        viewModel: ExploreViewModel,
        taxonSearchViewModel: TaxonSearchViewModel,
        imageLoader: ImageLoader
    ) {
        self.viewModel = viewModel
        self.taxonSearchViewModel = taxonSearchViewModel
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(viewModel:taxonSearchViewModel:imageLoader:) instead.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureHierarchy()
        configureCollectionView()
        configureKeyboardDismissal()
        configureDataSource()
        bindViewModel()
        stateView.onRetry = { [weak self] in
            self?.viewModel.loadInitialObservations()
        }
        render(state: viewModel.state)
        render(paginationState: viewModel.paginationState)
        headerView.setFilters(viewModel.filters)
        viewModel.loadInitialObservations()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewModel.refreshFavoriteState()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func configureView() {
        view.backgroundColor = UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0)
        navigationItem.title = ""
    }

    private func configureHierarchy() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        stateView.translatesAutoresizingMaskIntoConstraints = false
        taxonSearchPanelView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerView)
        view.addSubview(collectionView)
        view.addSubview(stateView)
        view.addSubview(taxonSearchPanelView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            headerView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stateView.topAnchor.constraint(equalTo: collectionView.topAnchor),
            stateView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stateView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stateView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            taxonSearchPanelView.topAnchor.constraint(equalTo: headerView.searchAnchorView.bottomAnchor, constant: 12),
            taxonSearchPanelView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            taxonSearchPanelView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            taxonSearchPanelView.bottomAnchor.constraint(lessThanOrEqualTo: view.keyboardLayoutGuide.topAnchor, constant: -16)
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
    }

    private func configureKeyboardDismissal() {
        view.addGestureRecognizer(keyboardDismissTapGesture)
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
                cell?.configure(with: item, imageLoader: imageLoader) { [weak self] in
                    self?.viewModel.toggleFavorite(id: item.id)
                }
                return cell
            case .grid:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ObservationGridCollectionViewCell.reuseIdentifier,
                    for: indexPath
                ) as? ObservationGridCollectionViewCell
                cell?.configure(with: item, imageLoader: imageLoader) { [weak self] in
                    self?.viewModel.toggleFavorite(id: item.id)
                }
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
        viewModel.onFiltersChange = { [weak self] filters in
            self?.headerView.setFilters(filters)
        }
        headerView.onSearchBegan = { [weak self] text in
            self?.handleSearchBegan(text: text)
        }
        headerView.onSearchTextChanged = { [weak self] text in
            self?.taxonSearchViewModel.updateQuery(text)
        }
        headerView.onSearchCleared = { [weak self] in
            self?.taxonSearchViewModel.updateQuery("")
        }
        headerView.onSearchReturned = { [weak self] in
            self?.taxonSearchPanelView.hide()
        }
        headerView.onTaxonCleared = { [weak self] in
            self?.headerView.setSearchText("")
            self?.taxonSearchPanelView.hide()
            self?.viewModel.setTaxonFilter(nil)
        }
        headerView.onQualityChanged = { [weak self] quality in
            self?.viewModel.setQualityFilter(quality)
        }
        headerView.onSortOrderChanged = { [weak self] sortOrder in
            self?.viewModel.setSortOrder(sortOrder)
        }
        headerView.onDisplayModeChanged = { [weak self] mode in
            self?.viewModel.setDisplayMode(mode)
        }
        taxonSearchViewModel.onStateChange = { [weak self] state in
            self?.taxonSearchPanelView.render(state)
        }
        taxonSearchViewModel.onTaxonSelected = { [weak self] taxon in
            self?.headerView.setSearchText(taxon.commonName ?? taxon.scientificName)
            self?.headerView.resignSearchFocus()
            self?.taxonSearchPanelView.hide()
            self?.viewModel.setTaxonFilter(taxon)
            self?.onTaxonSelected?(taxon)
        }
        taxonSearchPanelView.onItemSelected = { [weak self] id in
            self?.taxonSearchViewModel.selectItem(id: id)
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
        headerView.setDisplayMode(mode)

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

    private func handleSearchBegan(text: String) {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            taxonSearchViewModel.viewDidLoad()
        } else {
            taxonSearchViewModel.updateQuery(text)
        }
    }

    @objc private func dismissSearchKeyboard() {
        headerView.resignSearchFocus()
        taxonSearchPanelView.hide()
    }
}

extension ExploreViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let item = dataSource?.itemIdentifier(for: indexPath)
        viewModel.loadNextPageIfNeeded(currentItemID: item?.id)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource?.itemIdentifier(for: indexPath) else { return }
        onObservationSelected?(item.id)
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension ExploreViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer === keyboardDismissTapGesture, let touchedView = touch.view else {
            return true
        }

        return !touchedView.isDescendant(of: headerView.searchAnchorView)
            && !touchedView.isDescendant(of: taxonSearchPanelView)
    }
}
