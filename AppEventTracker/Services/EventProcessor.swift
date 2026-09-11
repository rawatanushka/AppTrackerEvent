//
//  EventProcessor.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import Foundation

/// Backoff schedule used after a failed delivery.
struct RetryPolicy {
    var initialDelay: TimeInterval = 2
    var maximumDelay: TimeInterval = 10

    /// 2s, 3s, 4s … capped, matching the "Retrying in Ns" copy in the design.
    func delay(forAttempt attempt: Int) -> TimeInterval {
        min(initialDelay + Double(max(0, attempt - 1)), maximumDelay)
    }

    static let `default` = RetryPolicy()
}

/// Single consumer that drains the queue, one event at a time, retrying until each
/// event is delivered. Nothing is ever dropped: every state transition is persisted
/// before the next attempt, so a relaunch resumes exactly where it left off.
final class EventProcessor {
    private let repository: EventRepository
    private let ingestion: IngestionService
    private let retryPolicy: RetryPolicy

    private var worker: Task<Void, Never>?
    /// How long the loop naps when there is nothing eligible to send.
    private let idlePollInterval: UInt64 = 250_000_000

    init(
        repository: EventRepository,
        ingestion: IngestionService,
        retryPolicy: RetryPolicy = .default
    ) {
        self.repository = repository
        self.ingestion = ingestion
        self.retryPolicy = retryPolicy
    }

    /// Starts the asynchronous processing loop if it is not already running.
    ///
    /// The loop continuously looks for the next deliverable event and attempts to send it.
    func start() {
        guard worker == nil else { return }
        worker = Task(priority: .utility) { [weak self] in
            await self?.runLoop()
        }
    }

    /// Cancels the processing loop, stopping all future delivery attempts.
    func stop() {
        worker?.cancel()
        worker = nil
    }

    /// Infinite loop that picks the next eligible event and delivers it.
    ///
    /// Sleeps for `idlePollInterval` nanoseconds when the queue is empty.
    private func runLoop() async {
        while !Task.isCancelled {
            guard let event = repository.nextDeliverableEvent() else {
                try? await Task.sleep(nanoseconds: idlePollInterval)
                continue
            }
            await deliver(event)
        }
    }

    /// Attempts to deliver a single event to the ingestion service.
    ///
    /// On success the event is marked `.processed`; on failure it transitions to
    /// `.retrying` with an exponential backoff delay.
    ///
    /// - Parameter event: The event to deliver.
    private func deliver(_ event: TrackedEvent) async {
        var working = event
        working.status = .processing
        working.attemptCount += 1
        working.nextAttemptAt = nil
        working.lastFailureReason = nil
        repository.update(working)

        do {
            try await ingestion.ingest(working)
            working.status = .processed
            working.processedAt = Date()
        } catch {
            working.status = .retrying
            working.lastFailureReason = error.localizedDescription
            working.nextAttemptAt = Date().addingTimeInterval(
                retryPolicy.delay(forAttempt: working.attemptCount)
            )
        }

        repository.update(working)
    }
}
