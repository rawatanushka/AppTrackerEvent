//
//  EventStatus.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import Foundation

/// Lifecycle of an event inside the delivery pipeline.
enum EventStatus: String, Codable {
    /// Waiting in the queue for the ingestion worker.
    case queued
    /// Currently being sent to the (mocked) ingestion endpoint.
    case processing
    /// Last attempt failed, waiting for the backoff window to elapse.
    case retrying
    /// Successfully ingested and persisted.
    case processed
    /// Rejected at collection time by the deduplication rules.
    case duplicate
}
