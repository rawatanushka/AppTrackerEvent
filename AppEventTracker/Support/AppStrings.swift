//
//  AppStrings.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import Foundation

/// Centralized string constants for UI components, ViewControllers, ViewModels, and Services.
enum AppStrings {
    /// Shared labels used across multiple screens.
    enum Common {
        static let appName = "Ad Attribution Tracker"
        static let cancel = "Cancel"
        static let clear = "Clear"
        static let sample = "Sample"
    }

    /// Titles and labels used in the navigation bar and tab bar.
    enum Navigation {
        static let title = "Ad Attribution Tracker"
        static let queueTab = "Queue"
        static let statisticsTab = "Statistics"
        static let reportEventsTitle = "Report Events"
    }

    /// Labels, filters, and messages for the Event Queue screen.
    enum EventQueue {
        static let screenTitle = "Event Queue"
        static let inProgressFilter = "IN PROGRESS"
        static let failedFilter = "FAILED / RETRYING"
        static let emptyQueue = "No events yet.\nTap + to feed the tracker a JSON batch."
        static let reportSingleEventMenu = "Report single event"
        static let startNewSessionAction = "Start new session"
        static let clearAllDataAction = "Clear all data"
        static let clearAllAlertTitle = "Clear all data?"
        static let clearAllAlertMessage = "Removes queued events, processed history and the deduplication markers."

        static let newSessionStartedToast = "New session started"

        static let queueClearedToast = "Queue, history and session counter cleared"
    }

    /// Labels for the Statistics screen, including section titles and metric captions.
    enum Statistics {
        static let sectionTitle = "Statistics"
        static let totalEventsProcessed = "Total Events Processed"
        static let totalVisits = "Total Visits"
        static let uniqueSessionSubcaption = "(Unique Session)"
        static let eventBreakdownSectionTitle = "Event Breakdown"
        static let successfullyProcessedSectionTitle = "Successfully Processed"
        static let emptyProcessedLog = "Nothing delivered yet."

        /// Column headers for the event breakdown table.
        enum BreakdownHeader {
            static let event = "Event"
            static let count = "Count"
            static let percentage = "Percentage"
        }
    }

    /// Status labels for individual event cards in the queue.
    enum EventStatusText {
        static let queued = "Queued"
        static let processing = "Processing"
        static let duplicate = "Duplicate"
        static let processed = "Processed ✓"

        static func retryingIn(seconds: Int) -> String {
            seconds > 0 ? "Retrying in \(seconds)s" : "Retrying…"
        }
    }

    /// Labels for the JSON input sheet.
    enum JSONInput {
        static let hintText = "Paste an array of events, a single event object, or { \"events\": [...] }."
        static let submitButtonTitle = "Add to Queue"
    }

    /// Toast messages describing the outcome of a collection call.
    enum CollectionSummaryText {
        static func queued(accepted: Int) -> String {
            "\(accepted) event\(accepted == 1 ? "" : "s") queued"
        }
        static func skipped(rejected: Int) -> String {
            "\(rejected) duplicate\(rejected == 1 ? "" : "s") skipped"
        }
        static func combined(accepted: Int, rejected: Int) -> String {
            "\(accepted) queued · \(rejected) duplicate\(rejected == 1 ? "" : "s") skipped"
        }
    }

    /// Rejection reasons surfaced by the deduplication rules.
    enum DeduplicationReason {
        static let alreadyProcessedOnce = "Already processed once"
        static let alreadySeenInSession = "Already seen in this session"
    }

    /// User-facing error messages produced when incoming JSON is invalid.
    enum JSONErrorText {
        static let notValidJSON = "The input is not valid JSON."
        static let unsupportedShape = "Expected an array of events, a single event object, or { \"events\": [...] }."
        static let emptyPayload = "The payload does not contain any events."
        static func unknownType(_ value: String) -> String {
            "\"\(value)\" is not a supported event type. Use INSTALL, VISIT, ADD_TO_CART or PURCHASE."
        }
        static func missingType(index: Int) -> String {
            "Event at index \(index) has no \"type\" field."
        }
    }

    /// Default / placeholder strings used by XIB-backed components.
    enum Components {
        /// Defaults for `MetricCardView`.
        enum MetricCard {
            static let defaultCaption = "Caption"
            static let defaultSubcaption = "(Unique Session)"
            static let defaultValue = "0"
        }

        /// Defaults for `EventCountTileView`.
        enum EventCountTile {
            static let defaultName = "INSTALL"
            static let defaultValue = "0"
        }

        /// Defaults for `BreakdownRowView`.
        enum BreakdownRow {
            static let defaultName = "INSTALL"
            static let defaultCount = "0"
            static let defaultPercentage = "0.00%"
        }

        /// Defaults for `SegmentedTabsView`.
        enum SegmentedTabs {
            static let inProgressTitle = "IN PROGRESS"
            static let failedTitle = "FAILED / RETRYING"
        }

        /// Defaults for `EventCardCell`.
        enum EventCardCell {
            static let defaultTitle = "EVENT"
            static let defaultTime = "12:00 PM"
            static let defaultStatus = "Queued"
        }
    }
}
