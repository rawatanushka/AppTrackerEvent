//
//  EventCollector.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import Foundation

/// Outcome of a single reporting call.
struct CollectionSummary: Equatable {
    let accepted: [TrackedEvent]
    let rejected: [TrackedEvent]

    /// The number of events accepted into the queue.
    var acceptedCount: Int { accepted.count }
    /// The number of events rejected by the deduplication rules.
    var rejectedCount: Int { rejected.count }

    /// Human-readable summary of the collection outcome.
    var description: String {
        switch (acceptedCount, rejectedCount) {
        case (let a, 0):
            return AppStrings.CollectionSummaryText.queued(accepted: a)
        case (0, let r):
            return AppStrings.CollectionSummaryText.skipped(rejected: r)
        case (let a, let r):
            return AppStrings.CollectionSummaryText.combined(accepted: a, rejected: r)
        }
    }
}

/// The public entry point the app uses to report events.
///
/// Stamps each event with the current timestamp and session id, runs it through the
/// deduplication rules, and hands the survivors to the queue.
final class EventCollector {
    private let repository: EventRepository
    private let deduplication: DeduplicationService
    private let session: SessionProviding

    init(
        repository: EventRepository,
        deduplication: DeduplicationService,
        session: SessionProviding
    ) {
        self.repository = repository
        self.deduplication = deduplication
        self.session = session
    }

    /// Reports a JSON batch. Throws only when the payload itself cannot be understood.
    @discardableResult
    func report(json: String) throws -> CollectionSummary {
        report(try EventJSONParser.parse(json))
    }

    /// Reports a single event by type, optionally with key-value properties.
    ///
    /// - Parameters:
    ///   - type: The event type to report.
    ///   - properties: Optional key-value pairs to attach.
    /// - Returns: A summary of how many events were accepted or rejected.
    @discardableResult
    func report(type: EventType, properties: [String: String] = [:]) -> CollectionSummary {
        report([IncomingEvent(type: type, properties: properties)])
    }

    /// Reports a batch of pre-parsed incoming events through the collection pipeline.
    ///
    /// Each event is stamped with the current timestamp and session id, evaluated against
    /// the deduplication rules, then inserted into the repository.
    ///
    /// - Parameter incoming: The batch of `IncomingEvent` values to process.
    /// - Returns: A summary of how many events were accepted or rejected.
    @discardableResult
    func report(_ incoming: [IncomingEvent]) -> CollectionSummary {
        var accepted: [TrackedEvent] = []
        var rejected: [TrackedEvent] = []

        for item in incoming {
            let sessionId = session.currentSessionId
            // Timestamp and session are attached here, as the event enters the queue.
            var event = TrackedEvent(
                type: item.type,
                timestamp: Date(),
                sessionId: sessionId,
                properties: item.properties
            )

            switch deduplication.evaluate(type: item.type, sessionId: sessionId) {
            case .accept:
                accepted.append(event)
            case .reject(let reason):
                event.status = .duplicate
                event.lastFailureReason = reason
                rejected.append(event)
            }
        }

        repository.insert(accepted + rejected)
        return CollectionSummary(accepted: accepted, rejected: rejected)
    }
}
