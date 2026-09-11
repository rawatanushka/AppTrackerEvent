//
//  EventStatistics.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import Foundation

/// Aggregated view over every successfully processed event.
struct EventStatistics: Equatable {
    /// Per-type breakdown showing the count and relative percentage of processed events.
    struct Breakdown: Equatable {
        /// The event type this row represents.
        let type: EventType
        /// Absolute number of processed events of this type.
        let count: Int
        /// Percentage share relative to all processed events (0–100).
        let percentage: Double
    }

    let totalProcessed: Int
    /// Distinct sessions that produced a processed VISIT event.
    let totalVisits: Int
    let breakdown: [Breakdown]

    static let empty = EventStatistics(
        totalProcessed: 0,
        totalVisits: 0,
        breakdown: EventType.allCases.map { Breakdown(type: $0, count: 0, percentage: 0) }
    )

    /// Computes aggregate statistics from the given list of tracked events.
    ///
    /// - Parameter events: All events currently tracked by the repository.
    /// - Returns: An `EventStatistics` snapshot with totals and per-type breakdowns.
    static func make(from events: [TrackedEvent]) -> EventStatistics {
        let uniqueSessions = Set(events.map(\.sessionId)).count
        let processed = events.filter { $0.status == .processed }
        guard !events.isEmpty else { return .empty }

        var counts: [EventType: Int] = [:]
        for event in processed {
            counts[event.type, default: 0] += 1
        }

        let total = processed.count

        let breakdown = EventType.allCases.map { type -> Breakdown in
            let count = counts[type] ?? 0
            return Breakdown(
                type: type,
                count: count,
                percentage: total > 0 ? Double(count) / Double(total) * 100 : 0
            )
        }

        return EventStatistics(
            totalProcessed: total,
            totalVisits: uniqueSessions,
            breakdown: breakdown
        )
    }
}
