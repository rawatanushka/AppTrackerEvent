//
//  TrackedEvent.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import Foundation

/// A single reported event with the metadata the tracker stamps on it at collection time.
struct TrackedEvent: Equatable, Identifiable {
    let id: UUID
    let type: EventType
    /// Stamped the moment the event enters the queue.
    let timestamp: Date
    /// Session that was active when the event entered the queue.
    let sessionId: String
    /// Free form key/value pairs carried over from the incoming JSON.
    let properties: [String: String]

    var status: EventStatus
    var attemptCount: Int
    var lastFailureReason: String?
    /// When the next delivery attempt becomes eligible (only set while `retrying`).
    var nextAttemptAt: Date?
    var processedAt: Date?

    init(
        id: UUID = UUID(),
        type: EventType,
        timestamp: Date,
        sessionId: String,
        properties: [String: String] = [:],
        status: EventStatus = .queued,
        attemptCount: Int = 0,
        lastFailureReason: String? = nil,
        nextAttemptAt: Date? = nil,
        processedAt: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.sessionId = sessionId
        self.properties = properties
        self.status = status
        self.attemptCount = attemptCount
        self.lastFailureReason = lastFailureReason
        self.nextAttemptAt = nextAttemptAt
        self.processedAt = processedAt
    }

    /// Seconds left in the backoff window, rounded up, or `nil` when not retrying.
    func retryCountdown(now: Date = Date()) -> Int? {
        guard status == .retrying, let nextAttemptAt else { return nil }
        return max(0, Int(nextAttemptAt.timeIntervalSince(now).rounded(.up)))
    }

    var isAwaitingDelivery: Bool {
        status == .queued || status == .processing || status == .retrying
    }
}
