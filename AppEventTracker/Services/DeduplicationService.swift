//
//  DeduplicationService.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import Foundation

/// The outcome of running an event through the deduplication rules.
enum DeduplicationDecision: Equatable {
    /// The event is allowed into the processing queue.
    case accept
    /// The event is rejected; the associated string explains why.
    case reject(reason: String)
}

/// Enforces the strict deduplication rules at collection time:
/// INSTALL is admitted once ever, VISIT once per session, everything else always.
///
/// The claim is persisted, so the rules survive app restarts.
final class DeduplicationService {
    private let repository: EventRepository

    init(repository: EventRepository) {
        self.repository = repository
    }

    /// Evaluates whether an event of the given type and session should be accepted.
    ///
    /// - Parameters:
    ///   - type: The kind of event being reported.
    ///   - sessionId: The session in which the event was generated.
    /// - Returns: `.accept` if the event passes the rules, or `.reject` with a reason.
    func evaluate(type: EventType, sessionId: String) -> DeduplicationDecision {
        let policy = type.deduplicationPolicy
        guard let key = policy.claimKey(for: type, sessionId: sessionId) else {
            return .accept
        }
        return repository.claimDedupKey(key) ? .accept : .reject(reason: policy.rejectionReason)
    }
}
