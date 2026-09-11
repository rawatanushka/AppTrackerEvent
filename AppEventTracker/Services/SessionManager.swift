//
//  SessionManager.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import Foundation

/// Provides the current session identifier.
///
/// Extracted as a protocol so the `EventCollector` can be tested without a real `SessionManager`.
protocol SessionProviding: AnyObject {
    /// The identifier of the currently active session.
    var currentSessionId: String { get }
}

/// Owns the session identifier stamped onto every collected event.
///
/// A session starts on cold launch; `startNewSession()` lets the demo roll over to a fresh
/// one so the "VISIT once per session" rule can be observed without relaunching.
final class SessionManager: SessionProviding {
    /// UserDefaults keys used by `SessionManager`.
    private enum Keys {
        static let sessionCount = "tracker.sessionCount"
    }

    /// The backing `UserDefaults` store.
    private let defaults: UserDefaults
    /// The current session's string identifier (e.g. `"S3-A1B2C3"`).
    private(set) var currentSessionId: String
    /// The ordinal number of the current session, starting from 1 on first launch.
    private(set) var sessionNumber: Int

    /// Initialises the session manager and increments the session counter.
    ///
    /// - Parameter defaults: The `UserDefaults` store to persist the session counter.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.sessionNumber = defaults.integer(forKey: Keys.sessionCount) + 1
        self.currentSessionId = SessionManager.makeSessionId(number: sessionNumber)
        defaults.set(sessionNumber, forKey: Keys.sessionCount)
    }

    /// Rolls the session counter forward and generates a new session identifier.
    ///
    /// - Returns: The newly created session id.
    @discardableResult
    func startNewSession() -> String {
        sessionNumber += 1
        defaults.set(sessionNumber, forKey: Keys.sessionCount)
        currentSessionId = SessionManager.makeSessionId(number: sessionNumber)
        return currentSessionId
    }

    /// Resets the session counter to zero, typically after clearing all data.
    func reset() {
        sessionNumber = 0
        defaults.set(sessionNumber, forKey: Keys.sessionCount)
        currentSessionId = SessionManager.makeSessionId(number: sessionNumber)
    }

    /// Short, readable ids make the session column legible in the UI.
    private static func makeSessionId(number: Int) -> String {
        let suffix = UUID().uuidString.prefix(6)
        return "S\(number)-\(suffix)"
    }
}
