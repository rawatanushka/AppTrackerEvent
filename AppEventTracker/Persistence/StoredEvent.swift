//
//  StoredEvent.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import CoreData
import Foundation

/// Core Data managed object that persists a single `TrackedEvent` to the database.
///
/// Maps every domain-level property onto a flat set of `@NSManaged` attributes that
/// Core Data can store. Conversion between the managed object and the value-type
/// domain model is handled by `apply(_:)` and `toDomain()`.
@objc(StoredEvent)
final class StoredEvent: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var typeRaw: String
    @NSManaged var timestamp: Date
    @NSManaged var sessionId: String
    @NSManaged var propertiesJSON: String?
    @NSManaged var statusRaw: String
    @NSManaged var attemptCount: Int32
    @NSManaged var lastFailureReason: String?
    @NSManaged var nextAttemptAt: Date?
    @NSManaged var processedAt: Date?

    /// Creates a typed fetch request targeting the `StoredEvent` entity.
    static func fetchRequest() -> NSFetchRequest<StoredEvent> {
        NSFetchRequest<StoredEvent>(entityName: CoreDataStack.Entity.event)
    }

    /// Copies all values from the domain model onto this managed object's attributes.
    ///
    /// - Parameter event: The `TrackedEvent` whose values should be persisted.
    func apply(_ event: TrackedEvent) {
        id = event.id
        typeRaw = event.type.rawValue
        timestamp = event.timestamp
        sessionId = event.sessionId
        propertiesJSON = StoredEvent.encode(event.properties)
        statusRaw = event.status.rawValue
        attemptCount = Int32(event.attemptCount)
        lastFailureReason = event.lastFailureReason
        nextAttemptAt = event.nextAttemptAt
        processedAt = event.processedAt
    }

    /// Converts this managed object back into a domain-level `TrackedEvent`.
    ///
    /// - Returns: A `TrackedEvent` if the raw strings can be resolved, or `nil` if the
    ///   stored type/status strings are no longer valid enum cases.
    func toDomain() -> TrackedEvent? {
        guard let type = EventType(rawValue: typeRaw),
              let status = EventStatus(rawValue: statusRaw) else { return nil }

        return TrackedEvent(
            id: id,
            type: type,
            timestamp: timestamp,
            sessionId: sessionId,
            properties: StoredEvent.decode(propertiesJSON),
            status: status,
            attemptCount: Int(attemptCount),
            lastFailureReason: lastFailureReason,
            nextAttemptAt: nextAttemptAt,
            processedAt: processedAt
        )
    }

    /// Encodes a dictionary of string properties into a JSON string for storage.
    ///
    /// - Parameter properties: Key-value pairs carried by the event.
    /// - Returns: A JSON-encoded string, or `nil` when the dictionary is empty.
    private static func encode(_ properties: [String: String]) -> String? {
        guard !properties.isEmpty,
              let data = try? JSONEncoder().encode(properties) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Decodes a previously stored JSON string back into a string dictionary.
    ///
    /// - Parameter json: The JSON string retrieved from Core Data, or `nil`.
    /// - Returns: The decoded dictionary, or an empty dictionary on failure.
    private static func decode(_ json: String?) -> [String: String] {
        guard let json, let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data) else { return [:] }
        return decoded
    }
}

/// Core Data managed object used by `DeduplicationService` to track claimed dedup keys.
///
/// A row is inserted when a deduplication claim succeeds, ensuring the same event type
/// (or type+session pair) is not accepted again.
@objc(DedupMarker)
final class DedupMarker: NSManagedObject {
    @NSManaged var key: String
    @NSManaged var claimedAt: Date

    /// Creates a typed fetch request targeting the `DedupMarker` entity.
    static func fetchRequest() -> NSFetchRequest<DedupMarker> {
        NSFetchRequest<DedupMarker>(entityName: CoreDataStack.Entity.dedupMarker)
    }
}

/// One row per event accepted by the mocked ingestion endpoint.
///
/// Acts as the "server-side" record, proving the event was successfully delivered.
@objc(IngestedRecord)
final class IngestedRecord: NSManagedObject {
    @NSManaged var eventId: UUID
    @NSManaged var typeRaw: String
    @NSManaged var sessionId: String
    @NSManaged var ingestedAt: Date
    @NSManaged var attempts: Int32

    /// Creates a typed fetch request targeting the `IngestedRecord` entity.
    static func fetchRequest() -> NSFetchRequest<IngestedRecord> {
        NSFetchRequest<IngestedRecord>(entityName: CoreDataStack.Entity.ingestedRecord)
    }
}
