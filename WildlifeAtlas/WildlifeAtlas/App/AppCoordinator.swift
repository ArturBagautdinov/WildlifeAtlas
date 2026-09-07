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
    private let navigationController: UINavigationController

    init(window: UIWindow, appContainer: AppContainer) {
        self.window = window
        self.appContainer = appContainer
        self.navigationController = UINavigationController()
    }

    func start() {
        let exploreViewController = appContainer.makeExploreViewController()
        navigationController.setViewControllers([exploreViewController], animated: false)

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}
