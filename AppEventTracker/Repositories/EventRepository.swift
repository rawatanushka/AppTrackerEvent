//
//  EventRepository.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import Foundation

/// Handle returned by `EventRepository.observe`. Observation stops when it is released.
final class ObservationToken {
    private let cancel: () -> Void

    init(cancel: @escaping () -> Void) {
        self.cancel = cancel
    }

    deinit { cancel() }
}

/// The single source of truth for events.
///
/// Keeps an in-memory mirror of the database so the UI can read a snapshot cheaply, and
/// serialises every mutation on a private queue so the processing worker and the UI never
/// race each other.
final class EventRepository {
    private let store: EventStoring
    private let queue = DispatchQueue(label: "com.demo.AppEventTracker.repository")

    private var events: [TrackedEvent] = []
    private var observers: [UUID: ([TrackedEvent]) -> Void] = [:]

    init(store: EventStoring) {
        self.store = store
    }

    /// Loads persisted events and rescues anything that was mid-flight when the app died.
    func bootstrap() {
        queue.sync {
            var loaded = store.loadAllEvents()
            var rescued: [TrackedEvent] = []

            for index in loaded.indices where loaded[index].status == .processing {
                loaded[index].status = .queued
                loaded[index].nextAttemptAt = nil
                rescued.append(loaded[index])
            }
            // A retry that was scheduled before a cold start should fire as soon as we resume.
            for index in loaded.indices where loaded[index].status == .retrying {
                if let next = loaded[index].nextAttemptAt, next < Date() {
                    loaded[index].nextAttemptAt = Date()
                    rescued.append(loaded[index])
                }
            }

            events = loaded
            if !rescued.isEmpty {
                store.save(rescued)
            }
        }
        broadcast()
    }

    // MARK: - Reads

    var snapshot: [TrackedEvent] {
        queue.sync { events }
    }

    /// The next event eligible for a delivery attempt, oldest first.
    func nextDeliverableEvent(now: Date = Date()) -> TrackedEvent? {
        queue.sync {
            events.first { event in
                switch event.status {
                case .queued:
                    return true
                case .retrying:
                    return (event.nextAttemptAt ?? now) <= now
                case .processing, .processed, .duplicate:
                    return false
                }
            }
        }
    }

    // MARK: - Writes

    /// Inserts new events into the in-memory list and persists them.
    ///
    /// - Parameter newEvents: The events to insert.
    func insert(_ newEvents: [TrackedEvent]) {
        guard !newEvents.isEmpty else { return }
        queue.sync {
            events.append(contentsOf: newEvents)
            events.sort { $0.timestamp < $1.timestamp }
            store.save(newEvents)
        }
        broadcast()
    }

    /// Updates a single event in-place and persists the change.
    ///
    /// If an event with the same UUID doesn't exist, it is appended.
    ///
    /// - Parameter event: The updated event.
    func update(_ event: TrackedEvent) {
        queue.sync {
            if let index = events.firstIndex(where: { $0.id == event.id }) {
                events[index] = event
            } else {
                events.append(event)
            }
            store.save(event)
        }
        broadcast()
    }

    /// Mirrors a successful delivery into the mocked ingestion table.
    func recordIngestion(of event: TrackedEvent) {
        queue.sync { store.recordIngestion(of: event) }
    }

    /// Atomically claims a dedup key through the underlying store.
    ///
    /// - Parameter key: The deduplication key to claim.
    /// - Returns: `true` if the key was freshly claimed.
    func claimDedupKey(_ key: String) -> Bool {
        queue.sync { store.claimDedupKey(key) }
    }

    /// Removes all events from memory and deletes all persisted data.
    func removeAll() {
        queue.sync {
            events.removeAll()
            store.deleteEverything()
        }
        broadcast()
    }

    // MARK: - Observation

    /// Registers `block` for change notifications. It fires immediately with the current
    /// snapshot and afterwards on every mutation, always on the main queue.
    func observe(_ block: @escaping ([TrackedEvent]) -> Void) -> ObservationToken {
        let id = UUID()
        queue.sync { observers[id] = block }

        let current = snapshot
        DispatchQueue.main.async { block(current) }

        return ObservationToken { [weak self] in
            self?.queue.sync { self?.observers[id] = nil }
        }
    }

    /// Sends the current event list to all registered observers on the main queue.
    private func broadcast() {
        let (current, listeners) = queue.sync { (events, Array(observers.values)) }
        DispatchQueue.main.async {
            listeners.forEach { $0(current) }
        }
    }
}
