//
//  EventQueueViewModel.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import Foundation

/// Drives the Event Queue screen.
final class EventQueueViewModel {
    /// Filter tabs for the event queue (In Progress vs. Failed/Retrying).
    enum Filter: Int, CaseIterable {
        case inProgress
        case failed

        /// The display title for the filter tab.
        var title: String {
            switch self {
            case .inProgress: return AppStrings.EventQueue.inProgressFilter
            case .failed: return AppStrings.EventQueue.failedFilter
            }
        }
    }

    // MARK: - Outputs (closures set by the ViewController)

    /// Called when the visible row data has changed.
    var onRowsChanged: (([EventRowViewModel]) -> Void)?
    /// Called to present a toast message.
    var onMessage: ((String) -> Void)?
    /// Called when the ticker timer should start or stop.
    var onNeedsTickerChanged: ((Bool) -> Void)?

    private(set) var rows: [EventRowViewModel] = []
    private(set) var filter: Filter = .inProgress

    // MARK: - Dependencies

    private let repository: EventRepository
    private let collector: EventCollector
    private let session: SessionManager
    private var token: ObservationToken?
    private var latestEvents: [TrackedEvent] = []

    init(repository: EventRepository, collector: EventCollector, session: SessionManager) {
        self.repository = repository
        self.collector = collector
        self.session = session
    }

    /// Starts observing the repository for changes and seeds the initial state.
    func start() {
        token = repository.observe { [weak self] events in
            self?.latestEvents = events
            self?.rebuild()
        }
    }

    // MARK: - Inputs

    /// Switches the visible filter and rebuilds the row list.
    ///
    /// - Parameter filter: The filter to activate.
    func select(filter: Filter) {
        guard filter != self.filter else { return }
        self.filter = filter
        rebuild()
    }

    /// Recomputes the countdown labels without touching the underlying data.
    func tick() {
        rebuild()
    }

    /// Submits a raw JSON string through the collection pipeline.
    ///
    /// - Parameter json: The JSON text entered by the user.
    func submit(json: String) {
        do {
            let summary = try collector.report(json: json)
            onMessage?(summary.description)
        } catch {
            onMessage?(error.localizedDescription)
        }
    }

    /// Reports a single event of the given type via the collector.
    ///
    /// - Parameter eventType: The event type to report.
    func quickAdd(_ eventType: EventType) {
        let summary = collector.report(type: eventType)
        onMessage?(summary.description)
    }

    /// Increments the session counter, logs a VISIT event, and notifies the UI.
    func startNewSession() {
        session.startNewSession()
        collector.report(type: .visit)
        onMessage?(AppStrings.EventQueue.newSessionStartedToast)
    }

    /// Purges all events, markers, and resets the session counter.
    func clearAll() {
        repository.removeAll()
        session.reset()
        onMessage?(AppStrings.EventQueue.queueClearedToast)
    }

    // MARK: - Derivation

    /// Recomputes the visible rows and emits all output callbacks.
    private func rebuild() {
        let now = Date()
        let visible: [TrackedEvent]

        switch filter {
        case .inProgress:
            visible = latestEvents
        case .failed:
            visible = latestEvents.filter { $0.status == .retrying }
        }

        let ordered = visible.sorted { $0.timestamp > $1.timestamp }
        let models = ordered.map { EventRowViewModel(event: $0, now: now) }

        rows = models
        onRowsChanged?(models)
        onNeedsTickerChanged?(models.contains { $0.isCountingDown })
    }
}
