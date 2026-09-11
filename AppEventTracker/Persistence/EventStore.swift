//
//  EventStore.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import CoreData
import Foundation

/// Everything the app needs from durable storage.
protocol EventStoring: AnyObject {
    /// Loads all persisted events from the database, ordered by timestamp.
    func loadAllEvents() -> [TrackedEvent]
    /// Persists a single event (insert or update).
    func save(_ event: TrackedEvent)
    /// Persists a batch of events (insert or update).
    func save(_ events: [TrackedEvent])
    /// Atomically claims a dedup key. Returns `false` when the key was already taken.
    func claimDedupKey(_ key: String) -> Bool
    /// Writes a row into the mocked ingestion endpoint's table.
    func recordIngestion(of event: TrackedEvent)
    /// Deletes all events, dedup markers, and ingested records.
    func deleteEverything()
}

/// Core Data backed implementation. All work happens on the stack's serial write context,
/// so callers get a consistent view without extra locking.
final class EventStore: EventStoring {
    private let stack: CoreDataStack
    private var context: NSManagedObjectContext { stack.writeContext }

    init(stack: CoreDataStack) {
        self.stack = stack
    }

    /// Loads every persisted `TrackedEvent`, sorted by timestamp ascending.
    ///
    /// - Returns: An array of domain-level events reconstructed from Core Data.
    func loadAllEvents() -> [TrackedEvent] {
        var result: [TrackedEvent] = []
        context.performAndWait {
            let request = StoredEvent.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
            let stored = (try? context.fetch(request)) ?? []
            result = stored.compactMap { $0.toDomain() }
        }
        return result
    }

    /// Persists a single event, delegating to the batch variant.
    ///
    /// - Parameter event: The event to persist.
    func save(_ event: TrackedEvent) {
        save([event])
    }

    /// Persists a batch of events, updating existing rows by UUID or inserting new ones.
    ///
    /// - Parameter events: The events to persist.
    func save(_ events: [TrackedEvent]) {
        guard !events.isEmpty else { return }
        context.performAndWait {
            for event in events {
                let object = existingObject(id: event.id) ?? StoredEvent(
                    entity: entityDescription(CoreDataStack.Entity.event),
                    insertInto: context
                )
                object.apply(event)
            }
            commit()
        }
    }

    /// Attempts to claim a dedup key atomically.
    ///
    /// - Parameter key: The deduplication key to claim.
    /// - Returns: `true` if the key was freshly claimed; `false` if it already existed.
    func claimDedupKey(_ key: String) -> Bool {
        var claimed = false
        context.performAndWait {
            let request = DedupMarker.fetchRequest()
            request.predicate = NSPredicate(format: "key == %@", key)
            request.fetchLimit = 1

            if let existing = try? context.fetch(request), !existing.isEmpty {
                claimed = false
                return
            }

            let marker = DedupMarker(
                entity: entityDescription(CoreDataStack.Entity.dedupMarker),
                insertInto: context
            )
            marker.key = key
            marker.claimedAt = Date()
            commit()
            claimed = true
        }
        return claimed
    }

    /// Records a successful delivery in the mock ingestion table.
    ///
    /// - Parameter event: The event that was successfully ingested.
    func recordIngestion(of event: TrackedEvent) {
        context.performAndWait {
            let request = IngestedRecord.fetchRequest()
            request.predicate = NSPredicate(format: "eventId == %@", event.id as CVarArg)
            request.fetchLimit = 1

            let record = (try? context.fetch(request))?.first ?? IngestedRecord(
                entity: entityDescription(CoreDataStack.Entity.ingestedRecord),
                insertInto: context
            )
            record.eventId = event.id
            record.typeRaw = event.type.rawValue
            record.sessionId = event.sessionId
            record.ingestedAt = Date()
            record.attempts = Int32(event.attemptCount)
            commit()
        }
    }

    /// Deletes all rows from every Core Data entity (events, markers, ingested records).
    func deleteEverything() {
        context.performAndWait {
            let entities = [
                CoreDataStack.Entity.event,
                CoreDataStack.Entity.dedupMarker,
                CoreDataStack.Entity.ingestedRecord
            ]
            for entity in entities {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
                let objects = (try? context.fetch(request)) as? [NSManagedObject] ?? []
                objects.forEach(context.delete)
            }
            commit()
        }
    }

    // MARK: - Helpers

    /// Fetches the existing managed object for the given UUID, if one exists.
    ///
    /// - Parameter id: The event UUID to look up.
    /// - Returns: The matching `StoredEvent`, or `nil`.
    private func existingObject(id: UUID) -> StoredEvent? {
        let request = StoredEvent.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    /// Resolves an entity description by name from the current context.
    ///
    /// - Parameter name: The entity name as declared in the managed object model.
    /// - Returns: The matching `NSEntityDescription`.
    private func entityDescription(_ name: String) -> NSEntityDescription {
        // Force unwrap is safe: both entities are declared in `CoreDataStack.makeModel()`.
        NSEntityDescription.entity(forEntityName: name, in: context)!
    }

    /// Saves the managed object context if it has pending changes; rolls back on failure.
    private func commit() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
            assertionFailure("Core Data save failed: \(error)")
        }
    }
}
