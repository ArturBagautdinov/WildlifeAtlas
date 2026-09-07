//
//  ExploreViewController.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import UIKit

final class ExploreViewController: UIViewController {
    private nonisolated enum Section {
        case observations
    }

    private let viewModel: ExploreViewModel
    private let imageLoader: ImageLoader
    private var dataSource: UICollectionViewDiffableDataSource<Section, ExploreObservationItem>?

    private let headerView = ExploreHeaderView()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: makeCollectionViewLayout()
        )
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.register(
            ObservationCollectionViewCell.self,
            forCellWithReuseIdentifier: ObservationCollectionViewCell.reuseIdentifier
        )
        collectionView.accessibilityIdentifier = "explore.observations.collection"
        return collectionView
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
        configureDataSource()
        bindViewModel()
        render(viewModel.state)
        viewModel.loadInitialObservations()
    }

    private func configureView() {
        view.backgroundColor = UIColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1.0)
        navigationItem.largeTitleDisplayMode = .never
    }

    private func configureHierarchy() {
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        headerView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerView)
        view.addSubview(contentView)

        [collectionView, stateView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

            contentView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            stateView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stateView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stateView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stateView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource(
            collectionView: collectionView
        ) { [imageLoader] collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ObservationCollectionViewCell.reuseIdentifier,
                for: indexPath
            )

            guard let observationCell = cell as? ObservationCollectionViewCell else {
                return cell
            }

            observationCell.configure(with: item, imageLoader: imageLoader)
            return observationCell
        }
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
        stateView.onRetry = { [weak self] in
            self?.viewModel.retry()
        }
    }

    private func render(_ state: ExploreViewModel.State) {
        switch state {
        case .loading:
            collectionView.isHidden = true
            stateView.showLoading()
            applySnapshot(items: [])

        case .content(let items):
            collectionView.isHidden = false
            stateView.hide()
            applySnapshot(items: items)

        case .empty:
            collectionView.isHidden = true
            stateView.showEmpty()
            applySnapshot(items: [])

        case .error(let error):
            collectionView.isHidden = true
            stateView.showError(error)
            applySnapshot(items: [])
        }
    }

    private func applySnapshot(items: [ExploreObservationItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, ExploreObservationItem>()
        snapshot.appendSections([.observations])
        snapshot.appendItems(items)
        dataSource?.apply(snapshot, animatingDifferences: true)
    }

    private func makeCollectionViewLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(160)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(160)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 14
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 24, trailing: 20)

        return UICollectionViewCompositionalLayout(section: section)
    }

}
