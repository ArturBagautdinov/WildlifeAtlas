//
//  FavoritesViewController.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import UIKit

private nonisolated enum FavoritesSection {
    case observations
}

final class FavoritesViewController: UIViewController {
    private let viewModel: FavoritesViewModel
    private let imageLoader: ImageLoader
    private var dataSource: UICollectionViewDiffableDataSource<FavoritesSection, ExploreObservationItem>?

    var onObservationSelected: ((Int) -> Void)?

    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: Self.makeLayout()
    )
    private let stateView = FavoritesStateView()

    init(viewModel: FavoritesViewModel, imageLoader: ImageLoader) {
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
        render(state: viewModel.state)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadFavorites()
    }

    private func configureView() {
        title = "Favorites"
        view.backgroundColor = UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0)
        navigationController?.navigationBar.tintColor = .wildlifePrimaryText
    }

    private func configureHierarchy() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        stateView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(collectionView)
        view.addSubview(stateView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
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
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<FavoritesSection, ExploreObservationItem>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, item in
            guard let self else { return nil }

            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ObservationListCollectionViewCell.reuseIdentifier,
                for: indexPath
            ) as? ObservationListCollectionViewCell
            cell?.configure(with: item, imageLoader: imageLoader) { [weak self] in
                self?.viewModel.removeFavorite(id: item.id)
            }
            return cell
        }
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state: state)
        }
        stateView.onRetry = { [weak self] in
            self?.viewModel.loadFavorites()
        }
    }

    private func render(state: FavoritesViewModel.State) {
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
            stateView.configureMessage(
                title: "No favorites yet",
                message: "Tap the heart on an observation to save it here.",
                showsRetry: false
            )
        case .error(let error):
            collectionView.isHidden = true
            stateView.configureMessage(title: error.title, message: error.message, showsRetry: true)
        }
    }

    private func applySnapshot(items: [ExploreObservationItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<FavoritesSection, ExploreObservationItem>()
        snapshot.appendSections([.observations])
        snapshot.appendItems(items, toSection: .observations)
        dataSource?.apply(snapshot, animatingDifferences: true)
    }

    private static func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(128)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(128)
            )
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 24, bottom: 24, trailing: 24)
            section.interGroupSpacing = 14
            return section
        }
    }
}

extension FavoritesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource?.itemIdentifier(for: indexPath) else { return }
        onObservationSelected?(item.id)
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
