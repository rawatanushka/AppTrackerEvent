//
//  EventType.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import Foundation

/// The four event kinds the tracker understands.
enum EventType: String, CaseIterable, Codable {
    case install = "INSTALL"
    case visit = "VISIT"
    case addToCart = "ADD_TO_CART"
    case purchase = "PURCHASE"

    /// Lenient lookup so hand written JSON such as `"add to cart"` or `"Install"` still resolves.
    init?(loose raw: String) {
        let normalized = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")

        switch normalized {
        case "INSTALL", "APP_INSTALL":
            self = .install
        case "VISIT", "SESSION_VISIT", "APP_VISIT":
            self = .visit
        case "ADD_TO_CART", "ADDTOCART", "CART_ADD":
            self = .addToCart
        case "PURCHASE", "BUY", "ORDER":
            self = .purchase
        default:
            return nil
        }
    }

    /// The deduplication rule applied when this event type enters the collection pipeline.
    var deduplicationPolicy: DeduplicationPolicy {
        switch self {
        case .install: return .onlyOnce
        case .visit: return .oncePerSession
        case .addToCart, .purchase: return .unrestricted
        }
    }

    /// Human-readable label used in the UI (matches the raw value, e.g. `"INSTALL"`).
    var displayName: String { rawValue }

    /// SF Symbol name representing this event type.
    var iconName: String {
        switch self {
        case .install: return AppResources.ImageName.installIcon
        case .visit: return AppResources.ImageName.visitIcon
        case .addToCart: return AppResources.ImageName.addToCartIcon
        case .purchase: return AppResources.ImageName.purchaseIcon
        }
    }
}
