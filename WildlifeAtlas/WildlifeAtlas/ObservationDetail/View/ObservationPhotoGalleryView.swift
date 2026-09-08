//
//  ObservationPhotoGalleryView.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import UIKit

final class ObservationPhotoGalleryView: UIView {
    private var photos: [ObservationDetailPhotoItem] = []
    private var imageLoader: ImageLoader?

    private let layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            ObservationPhotoGalleryCell.self,
            forCellWithReuseIdentifier: ObservationPhotoGalleryCell.reuseIdentifier
        )
        return collectionView
    }()

    private let pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.currentPageIndicatorTintColor = .wildlifePrimaryText
        pageControl.pageIndicatorTintColor = UIColor.wildlifePrimaryText.withAlphaComponent(0.25)
        pageControl.hidesForSinglePage = true
        return pageControl
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(frame:) instead.")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard layout.itemSize != bounds.size else { return }
        layout.itemSize = bounds.size
        layout.invalidateLayout()
    }

    func configure(photos: [ObservationDetailPhotoItem], imageLoader: ImageLoader) {
        collectionView.visibleCells
            .compactMap { $0 as? ObservationPhotoGalleryCell }
            .forEach { $0.cancelImageLoad() }

        self.photos = photos
        self.imageLoader = imageLoader
        pageControl.numberOfPages = photos.count
        pageControl.currentPage = 0
        pageControl.isHidden = photos.count <= 1
        collectionView.setContentOffset(.zero, animated: false)
        collectionView.reloadData()
        accessibilityLabel = photos.count > 1 ? "Observation photo gallery" : photos.first?.accessibilityLabel
    }

    private func configureHierarchy() {
        layer.cornerRadius = 14
        clipsToBounds = true
        isAccessibilityElement = false

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false

        addSubview(collectionView)
        addSubview(pageControl)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),

            pageControl.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            pageControl.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            pageControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }
}

extension ObservationPhotoGalleryView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        photos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ObservationPhotoGalleryCell.reuseIdentifier,
            for: indexPath
        )

        guard
            let cell = cell as? ObservationPhotoGalleryCell,
            let imageLoader
        else {
            return cell
        }

        cell.configure(with: photos[indexPath.item], imageLoader: imageLoader)
        return cell
    }
}

extension ObservationPhotoGalleryView: UICollectionViewDelegateFlowLayout {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentPage(for: scrollView)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateCurrentPage(for: scrollView)
    }

    private func updateCurrentPage(for scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else { return }
        let currentPage = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        pageControl.currentPage = max(0, min(currentPage, max(photos.count - 1, 0)))
    }
}
