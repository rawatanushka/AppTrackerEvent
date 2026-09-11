//
//  AppResources.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import Foundation

/// Centralized constants for Storyboard names, ViewController identifiers, Nib names, Reuse Identifiers, and System Image names.
enum AppResources {
    /// Storyboard file names.
    enum Storyboard {
        static let main = "Main"
    }

    /// Storyboard identifiers for view controllers.
    enum ViewController {
        static let eventQueue = "EventQueueViewController"
        static let statistics = "StatisticsViewController"
        static let jsonInput = "JSONInputViewController"
        static let mainTabBar = "MainTabBarController"
    }

    /// XIB / Nib file names for programmatically loaded views.
    enum Nib {
        static let metricCardView = "MetricCardView"
        static let eventCountTileView = "EventCountTileView"
        static let breakdownRowView = "BreakdownRowView"
        static let segmentedTabsView = "SegmentedTabsView"
        static let eventCardCell = "EventCardCell"
    }

    /// Reuse identifiers for `UITableViewCell` subclasses.
    enum ReuseIdentifier {
        static let eventCardCell = "EventCardCell"
    }

    /// SF Symbol names used throughout the app.
    enum ImageName {
        static let queueTab = "list.bullet.rectangle"
        static let queueTabSelected = "list.bullet.rectangle.fill"
        static let statisticsTab = "chart.bar"
        static let statisticsTabSelected = "chart.bar.fill"
        static let addPlus = "plus.circle.fill"
        static let menuEllipsis = "ellipsis.circle"
        static let refreshClockwise = "arrow.clockwise"
        static let newSessionArrow = "arrow.triangle.2.circlepath"
        static let trash = "trash"
    }
}
