//
//  MainTabBarController.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import UIKit

/// Queue / Statistics tabs, matching the mock's bottom tab bar.
final class MainTabBarController: UITabBarController {

    /// Creates the tab bar controller from the main storyboard, injecting view models
    /// from the given environment.
    ///
    /// Falls back to a programmatic setup if the storyboard identifier is missing.
    ///
    /// - Parameter environment: The shared `AppEnvironment` that provides dependencies.
    /// - Returns: A fully configured `MainTabBarController` with two tabs.
    static func instantiate(environment: AppEnvironment) -> MainTabBarController {
        let storyboard = UIStoryboard(name: AppResources.Storyboard.main, bundle: nil)

        let queueVC = storyboard.instantiateViewController(identifier: AppResources.ViewController.eventQueue, creator: { coder in
            EventQueueViewController(coder: coder, viewModel: environment.makeEventQueueViewModel())
        })
        queueVC.tabBarItem = UITabBarItem(
            title: AppStrings.Navigation.queueTab,
            image: UIImage(systemName: AppResources.ImageName.queueTab),
            selectedImage: UIImage(systemName: AppResources.ImageName.queueTabSelected)
        )
        let queueNav = UINavigationController(rootViewController: queueVC)

        let statsVC = storyboard.instantiateViewController(identifier: AppResources.ViewController.statistics, creator: { coder in
            StatisticsViewController(coder: coder, viewModel: environment.makeStatisticsViewModel())
        })
        statsVC.tabBarItem = UITabBarItem(
            title: AppStrings.Navigation.statisticsTab,
            image: UIImage(systemName: AppResources.ImageName.statisticsTab),
            selectedImage: UIImage(systemName: AppResources.ImageName.statisticsTabSelected)
        )
        let statsNav = UINavigationController(rootViewController: statsVC)

        guard let tabBarController = storyboard.instantiateViewController(withIdentifier: AppResources.ViewController.mainTabBar) as? MainTabBarController else {
            let fallback = MainTabBarController(environment: environment)
            return fallback
        }

        tabBarController.viewControllers = [queueNav, statsNav]
        return tabBarController
    }

    /// Programmatic fallback initializer when the storyboard is not available.
    ///
    /// - Parameter environment: The shared `AppEnvironment`.
    init(environment: AppEnvironment) {
        super.init(nibName: nil, bundle: nil)

        let queue = UINavigationController(
            rootViewController: EventQueueViewController(viewModel: environment.makeEventQueueViewModel())
        )
        queue.tabBarItem = UITabBarItem(
            title: AppStrings.Navigation.queueTab,
            image: UIImage(systemName: AppResources.ImageName.queueTab),
            selectedImage: UIImage(systemName: AppResources.ImageName.queueTabSelected)
        )

        let statistics = UINavigationController(
            rootViewController: StatisticsViewController(viewModel: environment.makeStatisticsViewModel())
        )
        statistics.tabBarItem = UITabBarItem(
            title: AppStrings.Navigation.statisticsTab,
            image: UIImage(systemName: AppResources.ImageName.statisticsTab),
            selectedImage: UIImage(systemName: AppResources.ImageName.statisticsTabSelected)
        )

        viewControllers = [queue, statistics]
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Theme.Color.surface
        appearance.stackedLayoutAppearance.selected.iconColor = Theme.Color.accent
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: Theme.Color.accent
        ]
        appearance.stackedLayoutAppearance.normal.iconColor = Theme.Color.textSecondary
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: Theme.Color.textSecondary
        ]

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }
}
