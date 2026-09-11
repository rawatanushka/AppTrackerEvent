//
//  SceneDelegate.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import UIKit

/// Manages the app's main window scene lifecycle.
///
/// Creates the root `MainTabBarController` and assigns it to the window on first connect.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    /// Called when a new scene session is being connected.
    ///
    /// Instantiates the primary `UIWindow`, sets the `MainTabBarController` as its
    /// root view controller, and makes the window visible.
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = MainTabBarController.instantiate(environment: .shared)
        window.makeKeyAndVisible()
        self.window = window
    }
}
