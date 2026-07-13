//
//  AdjustSdkDelegate.swift
//  Adjust SDK
//
//  Created by Adjust SDK Team on 20th February 2026.
//  Copyright (c) 2018-Present Adjust GmbH. All rights reserved.
//

import Flutter
import AdjustSdk

class AdjustSdkDelegate: NSObject, AdjustDelegate {
    static var shared: AdjustSdkDelegate?

    var shouldLaunchDeferredDeeplink: Bool = true
    weak var channel: FlutterMethodChannel?

    var attributionCallbackName: String?
    var sessionSuccessCallbackName: String?
    var sessionFailureCallbackName: String?
    var eventSuccessCallbackName: String?
    var eventFailureCallbackName: String?
    var deferredDeeplinkCallbackName: String?
    var skanUpdatedCallbackName: String?
    var remoteTriggerCallbackName: String?
    var thirdPartySharingSettingsChangedCallbackName: String?

    static func getInstance(
        attributionCallback: String?,
        sessionSuccessCallback: String?,
        sessionFailureCallback: String?,
        eventSuccessCallback: String?,
        eventFailureCallback: String?,
        deferredDeeplinkCallback: String?,
        skanUpdatedCallback: String?,
        remoteTriggerCallback: String?,
        thirdPartySharingSettingsChangedCallback: String?,
        shouldLaunchDeferredDeeplink: Bool,
        channel: FlutterMethodChannel
    ) -> AdjustSdkDelegate {
        if let existing = shared {
            return existing
        }

        let instance = AdjustSdkDelegate()
        instance.attributionCallbackName = attributionCallback
        instance.sessionSuccessCallbackName = sessionSuccessCallback
        instance.sessionFailureCallbackName = sessionFailureCallback
        instance.eventSuccessCallbackName = eventSuccessCallback
        instance.eventFailureCallbackName = eventFailureCallback
        instance.deferredDeeplinkCallbackName = deferredDeeplinkCallback
        instance.skanUpdatedCallbackName = skanUpdatedCallback
        instance.remoteTriggerCallbackName = remoteTriggerCallback
        instance.thirdPartySharingSettingsChangedCallbackName = thirdPartySharingSettingsChangedCallback
        instance.shouldLaunchDeferredDeeplink = shouldLaunchDeferredDeeplink
        instance.channel = channel

        shared = instance
        return instance
    }

    static func teardown() {
        shared = nil
    }

    // MARK: - AdjustDelegate methods

    func adjustAttributionChanged(_ attribution: ADJAttribution?) {
        guard let attribution = attribution,
              let callbackName = attributionCallbackName else {
            return
        }

        // Serialize jsonResponse
        var strJsonResponse: String?
        if let jsonResponse = attribution.jsonResponse {
            if let dataJsonResponse = try? JSONSerialization.data(withJSONObject: jsonResponse, options: []) {
                strJsonResponse = String(data: dataJsonResponse, encoding: .utf8)
            }
        }

        let attributionMap: [String: String] = [
            "trackerToken": getValueOrEmpty(attribution.trackerToken),
            "trackerName": getValueOrEmpty(attribution.trackerName),
            "network": getValueOrEmpty(attribution.network),
            "campaign": getValueOrEmpty(attribution.campaign),
            "adgroup": getValueOrEmpty(attribution.adgroup),
            "creative": getValueOrEmpty(attribution.creative),
            "clickLabel": getValueOrEmpty(attribution.clickLabel),
            "costType": getValueOrEmpty(attribution.costType),
            "costAmount": getNumberValueOrEmpty(attribution.costAmount),
            "costCurrency": getValueOrEmpty(attribution.costCurrency),
            "jsonResponse": getValueOrEmpty(strJsonResponse)
        ]

        channel?.invokeMethod(callbackName, arguments: attributionMap)
    }

    func adjustSessionTrackingSucceeded(_ sessionSuccess: ADJSessionSuccess?) {
        guard let sessionSuccess = sessionSuccess,
              let callbackName = sessionSuccessCallbackName else {
            return
        }

        let sessionSuccessMap: [String: String] = [
            "message": getValueOrEmpty(sessionSuccess.message),
            "timestamp": getValueOrEmpty(sessionSuccess.timestamp),
            "adid": getValueOrEmpty(sessionSuccess.adid),
            "jsonResponse": toJson(getObjectValueOrEmpty(sessionSuccess.jsonResponse))
        ]

        channel?.invokeMethod(callbackName, arguments: sessionSuccessMap)
    }

    func adjustSessionTrackingFailed(_ sessionFailure: ADJSessionFailure?) {
        guard let sessionFailure = sessionFailure,
              let callbackName = sessionFailureCallbackName else {
            return
        }

        let willRetryString = sessionFailure.willRetry ? "true" : "false"

        let sessionFailureMap: [String: String] = [
            "message": getValueOrEmpty(sessionFailure.message),
            "timestamp": getValueOrEmpty(sessionFailure.timestamp),
            "adid": getValueOrEmpty(sessionFailure.adid),
            "willRetry": willRetryString,
            "jsonResponse": toJson(getObjectValueOrEmpty(sessionFailure.jsonResponse))
        ]

        channel?.invokeMethod(callbackName, arguments: sessionFailureMap)
    }

    func adjustEventTrackingSucceeded(_ eventSuccess: ADJEventSuccess?) {
        guard let eventSuccess = eventSuccess,
              let callbackName = eventSuccessCallbackName else {
            return
        }

        let eventSuccessMap: [String: String] = [
            "message": getValueOrEmpty(eventSuccess.message),
            "timestamp": getValueOrEmpty(eventSuccess.timestamp),
            "adid": getValueOrEmpty(eventSuccess.adid),
            "eventToken": getValueOrEmpty(eventSuccess.eventToken),
            "callbackId": getValueOrEmpty(eventSuccess.callbackId),
            "jsonResponse": toJson(getObjectValueOrEmpty(eventSuccess.jsonResponse))
        ]

        channel?.invokeMethod(callbackName, arguments: eventSuccessMap)
    }

    func adjustEventTrackingFailed(_ eventFailure: ADJEventFailure?) {
        guard let eventFailure = eventFailure,
              let callbackName = eventFailureCallbackName else {
            return
        }

        let willRetryString = eventFailure.willRetry ? "true" : "false"

        let eventFailureMap: [String: String] = [
            "message": getValueOrEmpty(eventFailure.message),
            "timestamp": getValueOrEmpty(eventFailure.timestamp),
            "adid": getValueOrEmpty(eventFailure.adid),
            "eventToken": getValueOrEmpty(eventFailure.eventToken),
            "callbackId": getValueOrEmpty(eventFailure.callbackId),
            "willRetry": willRetryString,
            "jsonResponse": toJson(getObjectValueOrEmpty(eventFailure.jsonResponse))
        ]

        channel?.invokeMethod(callbackName, arguments: eventFailureMap)
    }

    func adjustDeferredDeeplinkReceived(_ deeplink: URL?) -> Bool {
        guard let deeplink = deeplink,
              let callbackName = deferredDeeplinkCallbackName else {
            return false
        }

        let deeplinkMap: [String: String] = [
            "deeplink": deeplink.absoluteString
        ]

        channel?.invokeMethod(callbackName, arguments: deeplinkMap)
        return shouldLaunchDeferredDeeplink
    }

    func adjustSkanUpdated(withConversionData data: [String: String]) {
        guard let callbackName = skanUpdatedCallbackName else {
            return
        }

        channel?.invokeMethod(callbackName, arguments: data)
    }

    func adjustRemoteTriggerReceived(_ remoteTrigger: ADJRemoteTrigger) {
        guard let callbackName = remoteTriggerCallbackName else {
            return
        }

        let payloadJson = toCompactJson(remoteTrigger.payload) ?? "{}"
        let remoteTriggerMap: [String: String] = [
            "label": getValueOrEmpty(remoteTrigger.label),
            "payloadJson": payloadJson
        ]

        channel?.invokeMethod(callbackName, arguments: remoteTriggerMap)
    }

    func adjustThirdPartySharingSettingsChanged(_ thirdPartySharingResult: ADJThirdPartySharingResult?) {
        guard let thirdPartySharingResult = thirdPartySharingResult,
              let callbackName = thirdPartySharingSettingsChangedCallbackName else {
            return
        }

        let thirdPartySharingResultMap: [String: String] = [
            "thirdPartySharingSettingsJson": getValueOrEmpty(thirdPartySharingResult.thirdPartySharingSettingsJson)
        ]

        channel?.invokeMethod(callbackName, arguments: thirdPartySharingResultMap)
    }

    // MARK: - Private helper methods

    private func getValueOrEmpty(_ value: String?) -> String {
        if let value = value {
            return value
        }
        return ""
    }

    private func getNumberValueOrEmpty(_ value: NSNumber?) -> String {
        if let value = value {
            return value.stringValue
        }
        return ""
    }

    private func getObjectValueOrEmpty(_ value: Any?) -> Any {
        if let value = value {
            return value
        }
        return [String: Any]()
    }

    private func toJson(_ object: Any) -> String {
        if let jsonData = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted) {
            return String(data: jsonData, encoding: .utf8) ?? ""
        }
        return ""
    }

    private func toCompactJson(_ object: Any) -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: object, options: []) else {
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
    }
}
