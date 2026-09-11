//
//  AppDelegate.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import UIKit

/// The application delegate responsible for bootstrapping the shared environment
/// and providing the scene configuration.
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    /// Called once when the process finishes launching.
    ///
    /// Bootstraps the shared `AppEnvironment` (loads persisted events and starts the
    /// processing pipeline) before any scene is connected.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AppEnvironment.shared.bootstrap()
        return true
    }

    /// Returns the scene configuration for a new connecting session.
    ///
    /// - Parameters:
    ///   - application: The shared application instance.
    ///   - connectingSceneSession: The session that is being connected.
    ///   - options: Additional options for the connection.
    /// - Returns: A `UISceneConfiguration` whose delegate class is `SceneDelegate`.
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}
