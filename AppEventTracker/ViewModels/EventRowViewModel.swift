//
//  EventRowViewModel.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import UIKit

/// Everything a queue cell needs to render, derived from a `TrackedEvent`.
struct EventRowViewModel: Equatable {
    let id: UUID
    let title: String
    let timeText: String
    let statusText: String
    let statusColor: UIColor
    let accentColor: UIColor
    let dotBackgroundColor: UIColor
    /// True while the row shows a live countdown and needs per-second refreshes.
    let isCountingDown: Bool

    init(event: TrackedEvent, now: Date = Date()) {
        id = event.id
        title = event.type.displayName
        timeText = Formatters.clock.string(from: event.timestamp)
        accentColor = Theme.Color.forEventType(event.type)
        dotBackgroundColor = Theme.Color.dotBackgroundForEventType(event.type)

        switch event.status {
        case .queued:
            statusText = AppStrings.EventStatusText.queued
            statusColor = Theme.Color.muted
            isCountingDown = false

        case .processing:
            statusText = AppStrings.EventStatusText.processing
            statusColor = Theme.Color.info
            isCountingDown = false

        case .retrying:
            let seconds = event.retryCountdown(now: now) ?? 0
            statusText = AppStrings.EventStatusText.retryingIn(seconds: seconds)
            statusColor = Theme.Color.warning
            isCountingDown = true

        case .processed:
            statusText = AppStrings.EventStatusText.processed
            statusColor = Theme.Color.success
            isCountingDown = false

        case .duplicate:
            statusText = AppStrings.EventStatusText.duplicate
            statusColor = Theme.Color.danger
            isCountingDown = false
        }
    }
}
