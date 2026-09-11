//
//  EventJSONParser.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import Foundation

/// A single event as it arrives from the outside world, before the tracker stamps it.
struct IncomingEvent: Equatable {
    /// The kind of event (e.g. `INSTALL`, `VISIT`).
    let type: EventType
    /// Arbitrary key-value pairs carried over from the incoming JSON.
    let properties: [String: String]
}

/// Errors thrown when the incoming JSON cannot be understood by ``EventJSONParser``.
enum EventJSONError: LocalizedError {
    case notValidJSON
    case unsupportedShape
    case emptyPayload
    case unknownType(String)
    case missingType(index: Int)

    /// User-facing description of the error.
    var errorDescription: String? {
        switch self {
        case .notValidJSON:
            return AppStrings.JSONErrorText.notValidJSON
        case .unsupportedShape:
            return AppStrings.JSONErrorText.unsupportedShape
        case .emptyPayload:
            return AppStrings.JSONErrorText.emptyPayload
        case .unknownType(let value):
            return AppStrings.JSONErrorText.unknownType(value)
        case .missingType(let index):
            return AppStrings.JSONErrorText.missingType(index: index)
        }
    }
}

/// Parses the JSON batches the app accepts as input.
///
/// Accepted shapes:
/// - `[{ "type": "INSTALL" }, ...]`
/// - `{ "type": "VISIT" }`
/// - `{ "events": [ ... ] }`
///
/// Any key other than the type key is carried along as a string property.
enum EventJSONParser {
    private static let typeKeys = ["type", "event", "eventType", "name"]

    /// Parses a JSON string into an array of `IncomingEvent` values.
    ///
    /// - Parameter jsonString: Raw JSON text supplied by the user.
    /// - Returns: An array of parsed `IncomingEvent` instances.
    /// - Throws: An `EventJSONError` when the payload is malformed or empty.
    static func parse(_ jsonString: String) throws -> [IncomingEvent] {
        guard let data = jsonString.data(using: .utf8), !data.isEmpty else {
            throw EventJSONError.notValidJSON
        }

        let root: Any
        do {
            root = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        } catch {
            throw EventJSONError.notValidJSON
        }

        let rawEvents: [[String: Any]]
        switch root {
        case let array as [[String: Any]]:
            rawEvents = array
        case let object as [String: Any]:
            if let nested = object["events"] as? [[String: Any]] {
                rawEvents = nested
            } else {
                rawEvents = [object]
            }
        default:
            throw EventJSONError.unsupportedShape
        }

        guard !rawEvents.isEmpty else { throw EventJSONError.emptyPayload }

        return try rawEvents.enumerated().map { index, raw in
            guard let (typeKey, rawType) = firstTypeValue(in: raw) else {
                throw EventJSONError.missingType(index: index)
            }
            guard let type = EventType(loose: rawType) else {
                throw EventJSONError.unknownType(rawType)
            }
            return IncomingEvent(type: type, properties: properties(from: raw, excluding: typeKey))
        }
    }

    /// Looks for the first recognised "type" key in a raw event dictionary.
    ///
    /// - Parameter raw: A single event object deserialized from JSON.
    /// - Returns: A `(key, value)` tuple, or `nil` if no known type key is present.
    private static func firstTypeValue(in raw: [String: Any]) -> (key: String, value: String)? {
        for key in typeKeys {
            if let value = raw[key] as? String { return (key, value) }
        }
        return nil
    }

    /// Extracts all keys other than the type key as flat string properties.
    ///
    /// Nested dictionaries under `"properties"` or `"params"` are flattened one level.
    ///
    /// - Parameters:
    ///   - raw: The original JSON dictionary.
    ///   - typeKey: The key that was already consumed as the event type.
    /// - Returns: A string-to-string dictionary of carried-over properties.
    private static func properties(from raw: [String: Any], excluding typeKey: String) -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in raw where key != typeKey {
            // Nested objects are flattened one level so `properties: { sku: ... }` still shows up.
            if key == "properties" || key == "params", let nested = value as? [String: Any] {
                for (nestedKey, nestedValue) in nested {
                    result[nestedKey] = stringify(nestedValue)
                }
            } else {
                result[key] = stringify(value)
            }
        }
        return result
    }

    /// Coerces any JSON value into its string representation.
    ///
    /// - Parameter value: The value to convert.
    /// - Returns: A human-readable string form of the value.
    private static func stringify(_ value: Any) -> String {
        switch value {
        case let string as String: return string
        case let number as NSNumber: return number.stringValue
        case let bool as Bool: return bool ? "true" : "false"
        default: return String(describing: value)
        }
    }
}
