//
//  ExploreCollectionViewLayoutFactory.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import UIKit

enum ExploreCollectionViewLayoutFactory {
    static func makeLayout(for mode: ExploreDisplayMode) -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, environment in
            switch mode {
            case .list:
                return makeListSection()
            case .grid:
                return makeGridSection(containerWidth: environment.container.effectiveContentSize.width)
            }
        }
    }

    private static func makeListSection() -> NSCollectionLayoutSection {
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
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 24, bottom: 8, trailing: 24)
        section.interGroupSpacing = 14
        section.boundarySupplementaryItems = [makeFooterItem()]
        return section
    }

    private static func makeGridSection(containerWidth: CGFloat) -> NSCollectionLayoutSection {
        let horizontalInsets: CGFloat = 24
        let availableWidth = containerWidth - horizontalInsets * 2
        let columns = availableWidth >= 320 ? 2 : 1

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / CGFloat(columns)),
            heightDimension: .estimated(columns == 1 ? 260 : 278)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(columns == 1 ? 260 : 278)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: columns)
        group.interItemSpacing = .fixed(14)

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: horizontalInsets, bottom: 8, trailing: horizontalInsets)
        section.interGroupSpacing = 18
        section.boundarySupplementaryItems = [makeFooterItem()]
        return section
    }

    private static func makeFooterItem() -> NSCollectionLayoutBoundarySupplementaryItem {
        let size = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(86)
        )
        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: size,
            elementKind: ExplorePaginationFooterView.elementKind,
            alignment: .bottom
        )
    }
}
