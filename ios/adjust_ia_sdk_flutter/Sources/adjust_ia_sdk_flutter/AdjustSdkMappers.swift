//
//  AdjustSdkMappers.swift
//  Adjust SDK
//
//  Created by Adjust SDK Team on 20th February 2026.
//  Copyright (c) 2018-Present Adjust GmbH. All rights reserved.
//

import Foundation
import AdjustSdk

struct AdjustSdkMappers {

    static func attributionToMap(_ attribution: ADJAttribution) -> NSMutableDictionary {
        let dictionary = NSMutableDictionary()

        addValueOrEmpty(attribution.trackerToken, withKey: "trackerToken", to: dictionary)
        addValueOrEmpty(attribution.trackerName, withKey: "trackerName", to: dictionary)
        addValueOrEmpty(attribution.network, withKey: "network", to: dictionary)
        addValueOrEmpty(attribution.campaign, withKey: "campaign", to: dictionary)
        addValueOrEmpty(attribution.creative, withKey: "creative", to: dictionary)
        addValueOrEmpty(attribution.adgroup, withKey: "adgroup", to: dictionary)
        addValueOrEmpty(attribution.clickLabel, withKey: "clickLabel", to: dictionary)
        addValueOrEmpty(attribution.costType, withKey: "costType", to: dictionary)
        addNumberOrEmpty(attribution.costAmount, withKey: "costAmount", to: dictionary)
        addValueOrEmpty(attribution.costCurrency, withKey: "costCurrency", to: dictionary)

        if let jsonResponse = attribution.jsonResponse {
            if let dataJsonResponse = try? JSONSerialization.data(withJSONObject: jsonResponse, options: []) {
                let stringJsonResponse = String(data: dataJsonResponse, encoding: .utf8)
                addValueOrEmpty(stringJsonResponse, withKey: "jsonResponse", to: dictionary)
            } else {
                addValueOrEmpty("", withKey: "jsonResponse", to: dictionary)
            }
        } else {
            addValueOrEmpty("", withKey: "jsonResponse", to: dictionary)
        }

        return dictionary
    }

    static func verificationResultToMap(_ verificationResult: ADJPurchaseVerificationResult) -> NSMutableDictionary {
        let dictionary = NSMutableDictionary()

        addValueOrEmpty(
            verificationResult.verificationStatus,
            withKey: "verificationStatus",
            to: dictionary
        )
        addValueOrEmpty(
            String(format: "%d", verificationResult.code),
            withKey: "code",
            to: dictionary
        )
        addValueOrEmpty(
            verificationResult.message,
            withKey: "message",
            to: dictionary
        )

        return dictionary
    }

    static func isFieldValid(_ field: Any?) -> Bool {
        guard let field = field else {
            return false
        }

        // check if its an instance of NSNull
        if field is NSNull {
            return false
        }

        // if field can be converted to a string, check if it has any content
        let str = String(describing: field)
        if str.isEmpty {
            return false
        }

        return true
    }

    static func addValueOrEmpty(_ value: Any?, withKey key: String, to dictionary: NSMutableDictionary) {
        if let value = value {
            dictionary[key] = String(describing: value)
        } else {
            dictionary[key] = ""
        }
    }

    static func addNumberOrEmpty(_ value: NSNumber?, withKey key: String, to dictionary: NSMutableDictionary) {
        if let value = value {
            dictionary[key] = value.stringValue
        } else {
            dictionary[key] = ""
        }
    }
}
