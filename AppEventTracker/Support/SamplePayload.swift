//
//  SamplePayload.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import Foundation

/// Ready made JSON used to prefill the input sheet.
enum SamplePayload {
    static let batch = """
    [
      { "type": "INSTALL", "source": "google_ads" },
      { "type": "VISIT", "screen": "home" },
      { "type": "ADD_TO_CART", "properties": { "sku": "SKU-4821", "qty": "2" } },
      { "type": "PURCHASE", "properties": { "orderId": "ORD-99127", "amount": "129.99" } },
      { "type": "VISIT", "screen": "cart" },
      { "type": "INSTALL", "source": "duplicate_attempt" },
      { "type": "ADD_TO_CART", "properties": { "sku": "SKU-1190", "qty": "1" } },
      { "type": "PURCHASE", "properties": { "orderId": "ORD-99128", "amount": "42.50" } }
    ]
    """
}
