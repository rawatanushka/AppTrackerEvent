//
//  CoreDataStack.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import CoreData
import Foundation

/// Core Data container for the tracker.
///
/// The managed object model is built in code rather than shipped as an `.xcdatamodeld`
/// so the schema lives next to the entity descriptions that use it.
final class CoreDataStack {
    /// Entity name constants used throughout the Core Data layer.
    enum Entity {
        /// Entity name for persisted events.
        static let event = "StoredEvent"
        /// Entity name for deduplication claim markers.
        static let dedupMarker = "DedupMarker"
        /// Entity name for records created by the mock ingestion endpoint.
        static let ingestedRecord = "IngestedRecord"
    }

    /// The persistent container that manages the Core Data store.
    let container: NSPersistentContainer

    /// Single serial background context. Every write in the app funnels through it,
    /// which keeps the dedup "check then claim" step race free.
    let writeContext: NSManagedObjectContext

    init() {
        let model = CoreDataStack.makeModel()
        container = NSPersistentContainer(name: "AppEventTracker", managedObjectModel: model)

        container.loadPersistentStores { description, error in
            if let error {
                // A corrupt store should not take the app down; start from a clean slate instead.
                assertionFailure("Failed to load store: \(error)")
                if let url = description.url {
                    try? FileManager.default.removeItem(at: url)
                }
            }
        }

        writeContext = container.newBackgroundContext()
        writeContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        writeContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: - Schema

    /// Builds the managed object model programmatically rather than from an `.xcdatamodeld`.
    ///
    /// - Returns: A fully configured `NSManagedObjectModel` with event, marker, and ingested entities.
    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let event = NSEntityDescription()
        event.name = Entity.event
        event.managedObjectClassName = NSStringFromClass(StoredEvent.self)
        event.properties = [
            makeAttribute(name: "id", type: .UUIDAttributeType),
            makeAttribute(name: "typeRaw", type: .stringAttributeType),
            makeAttribute(name: "timestamp", type: .dateAttributeType),
            makeAttribute(name: "sessionId", type: .stringAttributeType),
            makeAttribute(name: "propertiesJSON", type: .stringAttributeType, optional: true),
            makeAttribute(name: "statusRaw", type: .stringAttributeType),
            makeAttribute(name: "attemptCount", type: .integer32AttributeType, defaultValue: 0),
            makeAttribute(name: "lastFailureReason", type: .stringAttributeType, optional: true),
            makeAttribute(name: "nextAttemptAt", type: .dateAttributeType, optional: true),
            makeAttribute(name: "processedAt", type: .dateAttributeType, optional: true)
        ]
        event.uniquenessConstraints = [["id"]]

        let marker = NSEntityDescription()
        marker.name = Entity.dedupMarker
        marker.managedObjectClassName = NSStringFromClass(DedupMarker.self)
        marker.properties = [
            makeAttribute(name: "key", type: .stringAttributeType),
            makeAttribute(name: "claimedAt", type: .dateAttributeType)
        ]
        marker.uniquenessConstraints = [["key"]]

        // Stands in for the remote ingestion endpoint: successful deliveries land here.
        let ingested = NSEntityDescription()
        ingested.name = Entity.ingestedRecord
        ingested.managedObjectClassName = NSStringFromClass(IngestedRecord.self)
        ingested.properties = [
            makeAttribute(name: "eventId", type: .UUIDAttributeType),
            makeAttribute(name: "typeRaw", type: .stringAttributeType),
            makeAttribute(name: "sessionId", type: .stringAttributeType),
            makeAttribute(name: "ingestedAt", type: .dateAttributeType),
            makeAttribute(name: "attempts", type: .integer32AttributeType, defaultValue: 0)
        ]
        ingested.uniquenessConstraints = [["eventId"]]

        model.entities = [event, marker, ingested]
        return model
    }

    /// Convenience builder for an `NSAttributeDescription`.
    ///
    /// - Parameters:
    ///   - name: The attribute name.
    ///   - type: The Core Data attribute type.
    ///   - optional: Whether the attribute accepts `nil`.
    ///   - defaultValue: Optional default value for the attribute.
    /// - Returns: A configured `NSAttributeDescription`.
    private static func makeAttribute(
        name: String,
        type: NSAttributeType,
        optional: Bool = false,
        defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let attr = NSAttributeDescription()
        attr.name = name
        attr.attributeType = type
        attr.isOptional = optional
        attr.defaultValue = defaultValue
        return attr
    }
}
