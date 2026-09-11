//
//  IngestionService.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import Foundation

/// Errors that the ingestion layer can produce.
enum IngestionError: LocalizedError {
    /// A simulated network/transport failure.
    case transportFailure

    var errorDescription: String? {
        switch self {
        case .transportFailure: return "Ingestion endpoint returned an error"
        }
    }
}

/// Contract for a service that delivers events to a remote analytics endpoint.
protocol IngestionService: AnyObject {
    /// Sends the event to the backend. Throws on transport or server-side failure.
    ///
    /// - Parameter event: The event to deliver.
    func ingest(_ event: TrackedEvent) async throws
}

/// Stands in for a real analytics backend.
///
/// Every call waits 1–5 seconds and fails 20% of the time so the retry machinery has
/// something to chew on. Successful calls are written to a local database table, which is
/// the "server side" record of the event.
final class MockIngestionService: IngestionService {
    /// Tuneable knobs for the simulated backend.
    struct Configuration {
        /// Range of artificial delay in seconds applied before returning.
        var delayRange: ClosedRange<Double> = 1.0...5.0
        /// Fraction of calls that simulate a transport failure (0.0–1.0).
        var failureRate: Double = 0.2

        static let `default` = Configuration()
    }

    private let repository: EventRepository
    private let configuration: Configuration

    init(repository: EventRepository, configuration: Configuration = .default) {
        self.repository = repository
        self.configuration = configuration
    }

    /// Simulates sending the event to a backend.
    ///
    /// Waits a random duration within the configured delay range, then either records
    /// the event in the local ingestion table or throws a transport failure.
    ///
    /// - Parameter event: The event to deliver.
    /// - Throws: `IngestionError.transportFailure` at the configured failure rate.
    func ingest(_ event: TrackedEvent) async throws {
        let delay = Double.random(in: configuration.delayRange)
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

        if Double.random(in: 0..<1) < configuration.failureRate {
            throw IngestionError.transportFailure
        }

        repository.recordIngestion(of: event)
    }
}
