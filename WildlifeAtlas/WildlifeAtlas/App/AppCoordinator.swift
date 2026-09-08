//
//  AppCoordinator.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import UIKit

final class AppCoordinator {
    private let window: UIWindow
    private let appContainer: AppContainer
    private let tabBarController = UITabBarController()
    private let exploreNavigationController = UINavigationController()
    private let favoritesNavigationController = UINavigationController()

    init(window: UIWindow, appContainer: AppContainer) {
        self.window = window
        self.appContainer = appContainer
    }

    func start() {
        let exploreViewController = appContainer.makeExploreViewController()
        exploreViewController.onObservationSelected = { [weak self] observationID in
            guard let self else { return }
            showObservationDetail(observationID: observationID, in: exploreNavigationController)
        }
        exploreNavigationController.tabBarItem = UITabBarItem(
            title: "Explore",
            image: UIImage(systemName: "leaf"),
            selectedImage: UIImage(systemName: "leaf.fill")
        )
        exploreNavigationController.setViewControllers([exploreViewController], animated: false)

        let favoritesViewController = appContainer.makeFavoritesViewController()
        favoritesViewController.onObservationSelected = { [weak self] observationID in
            guard let self else { return }
            showObservationDetail(observationID: observationID, in: favoritesNavigationController)
        }
        favoritesNavigationController.tabBarItem = UITabBarItem(
            title: "Favorites",
            image: UIImage(systemName: "heart"),
            selectedImage: UIImage(systemName: "heart.fill")
        )
        favoritesNavigationController.setViewControllers([favoritesViewController], animated: false)

        tabBarController.viewControllers = [exploreNavigationController, favoritesNavigationController]
        tabBarController.tabBar.tintColor = .wildlifeAccent
        configureTabBarAppearance()

        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.35)

        tabBarController.tabBar.standardAppearance = appearance
        tabBarController.tabBar.scrollEdgeAppearance = appearance
        tabBarController.tabBar.isTranslucent = true
    }

    private func showObservationDetail(observationID: Int, in navigationController: UINavigationController) {
        let viewController = appContainer.makeObservationDetailViewController(observationID: observationID)
        navigationController.pushViewController(viewController, animated: true)
    }
}
