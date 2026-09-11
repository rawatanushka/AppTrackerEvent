//
//  StatisticsViewModel.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import Foundation

/// Drives the Statistics screen.
final class StatisticsViewModel {
    /// View-model data for a single row in the breakdown table.
    struct BreakdownRow: Equatable {
        /// The event type this row represents.
        let type: EventType
        /// Formatted count string (e.g. `"12"`).
        let countText: String
        /// Formatted percentage string (e.g. `"42.50%"`).
        let percentageText: String
        /// Decimal fraction (0–1) for progress bar rendering.
        let fraction: Double
    }

    // MARK: - Outputs (closures set by the ViewController)

    /// Called when the total processed events count label should update.
    var onTotalProcessedChanged: ((String) -> Void)?
    /// Called when the total unique visits label should update.
    var onTotalVisitsChanged: ((String) -> Void)?
    /// Called when the per-type count tiles should update.
    var onTypeCountsChanged: (([(type: EventType, count: String)]) -> Void)?
    /// Called when the breakdown table rows should update.
    var onBreakdownChanged: (([BreakdownRow]) -> Void)?
    /// Called when the processed events list changes.
    var onProcessedEventsChanged: (([EventRowViewModel]) -> Void)?
    /// Called when the empty state visibility should change.
    var onEmptyChanged: ((Bool) -> Void)?

    private let repository: EventRepository
    private let session: SessionManager
    private var token: ObservationToken?

    init(repository: EventRepository, session: SessionManager) {
        self.repository = repository
        self.session = session
    }

    /// Starts observing the repository and emits the initial statistics snapshot.
    func start() {
        token = repository.observe { [weak self] events in
            self?.apply(events)
        }
    }

    /// Derives aggregated statistics from the latest event list and pushes them to the UI.
    ///
    /// - Parameter events: The full list of tracked events from the repository.
    private func apply(_ events: [TrackedEvent]) {
        let statistics = EventStatistics.make(from: events)

        onTotalProcessedChanged?(Formatters.countString(statistics.totalProcessed))
        onTotalVisitsChanged?(Formatters.countString(session.sessionNumber))
        onTypeCountsChanged?(statistics.breakdown.map {
            (type: $0.type, count: Formatters.countString($0.count))
        })
        onBreakdownChanged?(statistics.breakdown.map {
            BreakdownRow(
                type: $0.type,
                countText: Formatters.countString($0.count),
                percentageText: Formatters.percentString($0.percentage),
                fraction: $0.percentage / 100
            )
        })

        let processed = events
            .filter { $0.status == .processed }
            .sorted { ($0.processedAt ?? $0.timestamp) > ($1.processedAt ?? $1.timestamp) }
        onProcessedEventsChanged?(processed.map { EventRowViewModel(event: $0) })
        onEmptyChanged?(statistics.totalProcessed == 0)
    }
}
