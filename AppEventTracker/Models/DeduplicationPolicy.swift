//
//  DeduplicationPolicy.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import Foundation

/// How many times an event of a given type is allowed into the processing queue.
enum DeduplicationPolicy {
    /// Accepted a single time for the lifetime of the install.
    case onlyOnce
    /// Accepted a single time per session id.
    case oncePerSession
    /// Never deduplicated.
    case unrestricted

    /// The key claimed in the dedup registry, or `nil` when the event is never deduplicated.
    func claimKey(for type: EventType, sessionId: String) -> String? {
        switch self {
        case .onlyOnce: return "type:\(type.rawValue)"
        case .oncePerSession: return "type:\(type.rawValue)|session:\(sessionId)"
        case .unrestricted: return nil
        }
    }

    var rejectionReason: String {
        switch self {
        case .onlyOnce: return AppStrings.DeduplicationReason.alreadyProcessedOnce
        case .oncePerSession: return AppStrings.DeduplicationReason.alreadySeenInSession
        case .unrestricted: return ""
        }
    }
}
