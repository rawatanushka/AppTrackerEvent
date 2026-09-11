//
//  AppEnvironment.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import Foundation

/// Composition root: owns the object graph and keeps the pipeline running for the
/// lifetime of the process.
final class AppEnvironment {
    static let shared = AppEnvironment()

    let stack: CoreDataStack
    let store: EventStoring
    let repository: EventRepository
    let session: SessionManager
    let deduplication: DeduplicationService
    let ingestion: IngestionService
    let processor: EventProcessor
    let collector: EventCollector

    private init() {
        stack = CoreDataStack()
        store = EventStore(stack: stack)
        repository = EventRepository(store: store)
        session = SessionManager()
        deduplication = DeduplicationService(repository: repository)
        ingestion = MockIngestionService(repository: repository)
        processor = EventProcessor(repository: repository, ingestion: ingestion)
        collector = EventCollector(
            repository: repository,
            deduplication: deduplication,
            session: session
        )
    }

    /// Restores persisted state and starts draining the queue.
    func bootstrap() {
        repository.bootstrap()
        processor.start()

        // Seed initial sample events if the database is empty or --seed-sample is passed
        if repository.snapshot.isEmpty || ProcessInfo.processInfo.arguments.contains("--seed-sample") {
            _ = try? collector.report(json: SamplePayload.batch)
        }
    }

    /// Creates a new `EventQueueViewModel` wired to the shared repository, collector, and session.
    ///
    /// - Returns: A freshly constructed view model ready to drive the Event Queue screen.
    func makeEventQueueViewModel() -> EventQueueViewModel {
        EventQueueViewModel(repository: repository, collector: collector, session: session)
    }

    /// Creates a new `StatisticsViewModel` wired to the shared repository and session.
    ///
    /// - Returns: A freshly constructed view model ready to drive the Statistics screen.
    func makeStatisticsViewModel() -> StatisticsViewModel {
        StatisticsViewModel(repository: repository, session: session)
    }
}
