//
//  Theme.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import UIKit

/// Centralized design tokens used for consistent styling across every screen.
enum Theme {
    /// Semantic colors shared by all UI components.
    enum Color {
        static let background = UIColor(hex: 0xF8FAFC)
        static let surface = UIColor.white
        static let surfaceElevated = UIColor(hex: 0xF1F5F9)
        static let separator = UIColor(hex: 0xE2E8F0)

        static let accent = UIColor(hex: 0x4E47DD)
        static let textPrimary = UIColor(hex: 0x0F172A)
        static let textSecondary = UIColor(hex: 0x64748B)

        static let success = UIColor(hex: 0x16A34A)
        static let warning = UIColor(hex: 0xD97706)
        static let danger = UIColor(hex: 0xDC2626)
        static let info = UIColor(hex: 0x4F46E5)
        static let muted = UIColor(hex: 0x94A3B8)

        /// Returns the primary accent color associated with a given event type.
        ///
        /// - Parameter type: The event type.
        /// - Returns: A `UIColor` representing the type's visual identity.
        static func forEventType(_ type: EventType) -> UIColor {
            switch type {
            case .install: return UIColor(hex: 0x16A34A)
            case .visit: return UIColor(hex: 0x2563EB)
            case .addToCart: return UIColor(hex: 0x7C3AED)
            case .purchase: return UIColor(hex: 0xD97706)
            }
        }

        /// Returns the lighter background tint for the dot indicator of a given event type.
        ///
        /// - Parameter type: The event type.
        /// - Returns: A light-tinted `UIColor` used behind the dot view.
        static func dotBackgroundForEventType(_ type: EventType) -> UIColor {
            switch type {
            case .install: return UIColor(hex: 0xDCFCE7)
            case .visit: return UIColor(hex: 0xDBEAFE)
            case .addToCart: return UIColor(hex: 0xF3E8FF)
            case .purchase: return UIColor(hex: 0xFCEED8)
            }
        }
    }

    /// Layout dimensions and spacing constants.
    enum Metrics {
        static let cornerRadius: CGFloat = 12
        static let cardSpacing: CGFloat = 12
        static let horizontalInset: CGFloat = 16
    }

    /// Typography presets used throughout the app.
    ///
    /// Font values default to Roboto Mono where a monospaced look is desired,
    /// with a system font fallback if the custom font is not available.
    enum Font {
        /// Creates a Roboto Mono font with the given size and weight.
        ///
        /// Falls back to a system monospaced font if the custom font is not found.
        ///
        /// - Parameters:
        ///   - size: The point size for the font.
        ///   - weight: The desired weight.
        /// - Returns: A `UIFont` instance.
        static func robotoMono(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
            let fontName: String
            switch weight {
            case .bold, .heavy, .black:
                fontName = "RobotoMono-Bold"
            case .medium, .semibold:
                fontName = "RobotoMono-Medium"
            case .light, .ultraLight, .thin:
                fontName = "RobotoMono-Light"
            default:
                fontName = "RobotoMono-Regular"
            }
            return UIFont(name: fontName, size: size) ?? UIFont.monospacedSystemFont(ofSize: size, weight: weight)
        }

        static let screenTitle = UIFont.systemFont(ofSize: 15, weight: .regular)
        static let sectionTitle = UIFont.systemFont(ofSize: 14, weight: .semibold)
        static let cardTitle = robotoMono(size: 13, weight: .bold)
        static let cardTime = robotoMono(size: 12, weight: .regular)
        static let caption = UIFont.systemFont(ofSize: 12, weight: .regular)
        static let badge = robotoMono(size: 13, weight: .bold)
        static let tabButton = UIFont.systemFont(ofSize: 13, weight: .bold)
        static let metric = robotoMono(size: 34, weight: .bold)
        static let metricSmall = robotoMono(size: 22, weight: .bold)
        static let monospacedCaption = robotoMono(size: 12, weight: .regular)
    }
}

extension UIColor {
    /// Creates a `UIColor` from a hex integer (e.g. `0x4F46E5`).
    ///
    /// - Parameter hex: A 24-bit RGB integer.
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

