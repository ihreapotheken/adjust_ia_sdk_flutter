//
//  AdjustSdkMethodHandler.swift
//  Adjust SDK
//
//  Created by Adjust SDK Team on 20th February 2026.
//  Copyright (c) 2018-Present Adjust GmbH. All rights reserved.
//

import Flutter
import AdjustSdk

class AdjustSdkMethodHandler: NSObject {
    private weak var channel: FlutterMethodChannel?
    private let onSdkInitialized: () -> Void

    init(channel: FlutterMethodChannel, onSdkInitialized: @escaping () -> Void = {}) {
        self.channel = channel
        self.onSdkInitialized = onSdkInitialized
        super.init()
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initSdk":
            initSdk(call, result: result)
        case "trackEvent":
            trackEvent(call, result: result)
        case "enable":
            Adjust.enable()
            result(nil)
        case "disable":
            Adjust.disable()
            result(nil)
        case "gdprForgetMe":
            gdprForgetMe(call, result: result)
        case "getAttribution":
            getAttribution(call, result: result)
        case "getAttributionWithTimeout":
            getAttributionWithTimeout(call, result: result)
        case "getIdfa":
            getIdfa(call, result: result)
        case "getIdfv":
            getIdfv(call, result: result)
        case "getSdkVersion":
            getSdkVersion(call, result: result)
        case "switchToOfflineMode":
            Adjust.switchToOfflineMode()
            result(nil)
        case "switchBackToOnlineMode":
            Adjust.switchBackToOnlineMode()
            result(nil)
        case "setPushToken":
            setPushToken(call, result: result)
        case "appWillOpenUrl":
            processDeeplink(call, result: result)
        case "trackAdRevenue":
            trackAdRevenue(call, result: result)
        case "trackAppStoreSubscription":
            trackAppStoreSubscription(call, result: result)
        case "requestAppTrackingAuthorization":
            requestAppTrackingAuthorization(call, result: result)
        case "getAppTrackingAuthorizationStatus":
            getAppTrackingAuthorizationStatus(call, result: result)
        case "trackThirdPartySharing":
            trackThirdPartySharing(call, result: result)
        case "trackMeasurementConsent":
            trackMeasurementConsent(call, result: result)
        case "updateSkanConversionValue":
            updateSkanConversionValue(call, result: result)
        case "endFirstSessionDelay":
            endFirstSessionDelay(call, result: result)
        case "enableCoppaComplianceInDelay":
            enableCoppaComplianceInDelay(call, result: result)
        case "disableCoppaComplianceInDelay":
            disableCoppaComplianceInDelay(call, result: result)
        case "enablePlayStoreKidsComplianceInDelay":
            enablePlayStoreKidsComplianceInDelay(call, result: result)
        case "disablePlayStoreKidsComplianceInDelay":
            disablePlayStoreKidsComplianceInDelay(call, result: result)
        case "setExternalDeviceIdInDelay":
            setExternalDeviceIdInDelay(call, result: result)
        case "addGlobalCallbackParameter":
            addGlobalCallbackParameter(call, result: result)
        case "removeGlobalCallbackParameter":
            removeGlobalCallbackParameter(call, result: result)
        case "removeGlobalCallbackParameters":
            Adjust.removeGlobalCallbackParameters()
            result(nil)
        case "addGlobalPartnerParameter":
            addGlobalPartnerParameter(call, result: result)
        case "removeGlobalPartnerParameter":
            removeGlobalPartnerParameter(call, result: result)
        case "removeGlobalPartnerParameters":
            Adjust.removeGlobalPartnerParameters()
            result(nil)
        case "isEnabled":
            Adjust.isEnabled { isEnabled in
                result(NSNumber(value: isEnabled))
            }
        case "getAdid":
            Adjust.adid { adid in
                result(adid)
            }
        case "getAdidWithTimeout":
            getAdidWithTimeout(call, result: result)
        case "getThirdPartySharingSettingsWithTimeout":
            getThirdPartySharingSettingsWithTimeout(call, result: result)
        case "verifyAppStorePurchase":
            verifyAppStorePurchase(call, result: result)
        case "verifyAndTrackAppStorePurchase":
            verifyAndTrackAppStorePurchase(call, result: result)
        case "processDeeplink":
            processDeeplink(call, result: result)
        case "processAndResolveDeeplink":
            processAndResolveDeeplink(call, result: result)
        case "getLastDeeplink":
            getLastDeeplink(call, result: result)
        case "getGoogleAdId":
            getGoogleAdId(call, result: result)
        case "getAmazonAdId":
            getAmazonAdId(call, result: result)
        case "trackPlayStoreSubscription":
            trackPlayStoreSubscription(call, result: result)
        case "verifyPlayStorePurchase":
            verifyPlayStorePurchase(call, result: result)
        case "verifyAndTrackPlayStorePurchase":
            verifyAndTrackPlayStorePurchase(call, result: result)
        case "onResume":
            Adjust.trackSubsessionStart()
            result(nil)
        case "onPause":
            Adjust.trackSubsessionEnd()
            result(nil)
        case "setTestOptions":
            setTestOptions(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Common methods

    private func initSdk(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(nil)
            return
        }

        let appToken = args["appToken"] as? String
        let environment = args["environment"] as? String
        let logLevel = args["logLevel"] as? String
        let sdkPrefix = args["sdkPrefix"] as? String
        let defaultTracker = args["defaultTracker"] as? String
        let externalDeviceId = args["externalDeviceId"] as? String
        let strUrlStrategyDomainsJson = args["urlStrategyDomains"] as? String
        let strIsDataResidency = args["isDataResidency"] as? String
        let isDataResidency = AdjustSdkMappers.isFieldValid(strIsDataResidency)
            ? (strIsDataResidency! as NSString).boolValue
            : false
        let strUseSubdomains = args["useSubdomains"] as? String
        let useSubdomains = AdjustSdkMappers.isFieldValid(strUseSubdomains)
            ? (strUseSubdomains! as NSString).boolValue
            : false
        let attConsentWaitingInterval = args["attConsentWaitingInterval"] as? String
        let isSendingInBackgroundEnabled = args["isSendingInBackgroundEnabled"] as? String
        let strEventDeduplicationIdsMaxSize = args["eventDeduplicationIdsMaxSize"] as? String
        let eventDeduplicationIdsMaxSize = AdjustSdkMappers.isFieldValid(strEventDeduplicationIdsMaxSize)
            ? Int(strEventDeduplicationIdsMaxSize!) ?? 0
            : 0
        let isCostDataInAttributionEnabled = args["isCostDataInAttributionEnabled"] as? String
        let isCoppaComplianceEnabled = args["isCoppaComplianceEnabled"] as? String
        let isFirstSessionDelayEnabled = args["isFirstSessionDelayEnabled"] as? String
        let isAppTrackingTransparencyUsageEnabled = args["isAppTrackingTransparencyUsageEnabled"] as? String
        let isLinkMeEnabled = args["isLinkMeEnabled"] as? String
        let isAdServicesEnabled = args["isAdServicesEnabled"] as? String
        let isIdfaReadingEnabled = args["isIdfaReadingEnabled"] as? String
        let isIdfvReadingEnabled = args["isIdfvReadingEnabled"] as? String
        let strStoreInfoJson = args["storeInfo"] as? String
        let isSkanAttributionEnabled = args["isSkanAttributionEnabled"] as? String
        let isDeviceIdsReadingOnceEnabled = args["isDeviceIdsReadingOnceEnabled"] as? String
        let dartAttributionCallback = args["attributionCallback"] as? String
        let dartSessionSuccessCallback = args["sessionSuccessCallback"] as? String
        let dartSessionFailureCallback = args["sessionFailureCallback"] as? String
        let dartEventSuccessCallback = args["eventSuccessCallback"] as? String
        let dartEventFailureCallback = args["eventFailureCallback"] as? String
        let dartDeferredDeeplinkCallback = args["deferredDeeplinkCallback"] as? String
        let dartSkanUpdatedCallback = args["skanUpdatedCallback"] as? String
        let dartRemoteTriggerCallback = args["remoteTriggerCallback"] as? String
        let dartThirdPartySharingSettingsChangedCallback = args["thirdPartySharingSettingsChangedCallback"] as? String
        let isDeferredDeeplinkOpeningEnabled = args["isDeferredDeeplinkOpeningEnabled"] as? String
        let launchDeferredDeeplink = AdjustSdkMappers.isFieldValid(isDeferredDeeplinkOpeningEnabled)
            ? (isDeferredDeeplinkOpeningEnabled! as NSString).boolValue
            : true

        // suppress log level
        var allowSuppressLogLevel = false
        if AdjustSdkMappers.isFieldValid(logLevel) {
            if ADJLogger.logLevel(from: logLevel!.lowercased()) == ADJLogLevel.suppress {
                allowSuppressLogLevel = true
            }
        }

        let adjustConfig = ADJConfig(
            appToken: appToken ?? "",
            environment: environment ?? "",
            suppressLogLevel: allowSuppressLogLevel
        )

        // SDK prefix
        if AdjustSdkMappers.isFieldValid(sdkPrefix) {
            adjustConfig?.sdkPrefix = sdkPrefix!
        }

        // log level
        if AdjustSdkMappers.isFieldValid(logLevel) {
            adjustConfig?.logLevel = ADJLogger.logLevel(from: logLevel!.lowercased())
        }

        // LinkMe
        if AdjustSdkMappers.isFieldValid(isLinkMeEnabled) {
            if (isLinkMeEnabled! as NSString).boolValue == true {
                adjustConfig?.enableLinkMe()
            }
        }

        // COPPA compliance
        if AdjustSdkMappers.isFieldValid(isCoppaComplianceEnabled) {
            if (isCoppaComplianceEnabled! as NSString).boolValue == true {
                adjustConfig?.enableCoppaCompliance()
            }
        }

        // first session delay
        if AdjustSdkMappers.isFieldValid(isFirstSessionDelayEnabled) {
            if (isFirstSessionDelayEnabled! as NSString).boolValue == true {
                adjustConfig?.enableFirstSessionDelay()
            }
        }

        // ATT usage
        if AdjustSdkMappers.isFieldValid(isAppTrackingTransparencyUsageEnabled) {
            if (isAppTrackingTransparencyUsageEnabled! as NSString).boolValue == false {
                adjustConfig?.disableAppTrackingTransparencyUsage()
            }
        }

        // default tracker
        if AdjustSdkMappers.isFieldValid(defaultTracker) {
            adjustConfig?.defaultTracker = defaultTracker!
        }

        // external device ID
        if AdjustSdkMappers.isFieldValid(externalDeviceId) {
            adjustConfig?.externalDeviceId = externalDeviceId!
        }

        // store info
        if AdjustSdkMappers.isFieldValid(strStoreInfoJson) {
            if let jsonData = strStoreInfoJson!.data(using: .utf8),
               let storeInfoDict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                let storeName = storeInfoDict["storeName"] as? String
                if AdjustSdkMappers.isFieldValid(storeName) {
                    let adjStoreInfo = ADJStoreInfo(storeName: storeName!)
                    let storeAppId = storeInfoDict["storeAppId"] as? String
                    if AdjustSdkMappers.isFieldValid(storeAppId) {
                        adjStoreInfo?.storeAppId = storeAppId!
                    }
                    if let adjStoreInfo = adjStoreInfo {
                        adjustConfig?.storeInfo = adjStoreInfo
                    }
                }
            }
        }

        // URL strategy
        if AdjustSdkMappers.isFieldValid(strUrlStrategyDomainsJson) {
            if let data = strUrlStrategyDomainsJson!.data(using: .utf8),
               let urlStrategyDomainsArray = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String] {
                adjustConfig?.setUrlStrategy(urlStrategyDomainsArray,
                                             useSubdomains: useSubdomains,
                                             isDataResidency: isDataResidency)
            }
        }

        // sending in background
        if AdjustSdkMappers.isFieldValid(isSendingInBackgroundEnabled) {
            if (isSendingInBackgroundEnabled! as NSString).boolValue == true {
                adjustConfig?.enableSendingInBackground()
            }
        }

        // event deduplication
        if eventDeduplicationIdsMaxSize > 0 {
            adjustConfig?.eventDeduplicationIdsMaxSize = Int(eventDeduplicationIdsMaxSize)
        }

        // cost data in attribution callback
        if AdjustSdkMappers.isFieldValid(isCostDataInAttributionEnabled) {
            if (isCostDataInAttributionEnabled! as NSString).boolValue == true {
                adjustConfig?.enableCostDataInAttribution()
            }
        }

        // AdServices.framework interaction
        if AdjustSdkMappers.isFieldValid(isAdServicesEnabled) {
            if (isAdServicesEnabled! as NSString).boolValue == false {
                adjustConfig?.disableAdServices()
            }
        }

        // IDFA reading
        if AdjustSdkMappers.isFieldValid(isIdfaReadingEnabled) {
            if (isIdfaReadingEnabled! as NSString).boolValue == false {
                adjustConfig?.disableIdfaReading()
            }
        }

        // IDFV reading
        if AdjustSdkMappers.isFieldValid(isIdfvReadingEnabled) {
            if (isIdfvReadingEnabled! as NSString).boolValue == false {
                adjustConfig?.disableIdfvReading()
            }
        }

        // SKAdNetwork attribution
        if AdjustSdkMappers.isFieldValid(isSkanAttributionEnabled) {
            if (isSkanAttributionEnabled! as NSString).boolValue == false {
                adjustConfig?.disableSkanAttribution()
            }
        }

        // read device info once
        if AdjustSdkMappers.isFieldValid(isDeviceIdsReadingOnceEnabled) {
            if (isDeviceIdsReadingOnceEnabled! as NSString).boolValue == true {
                adjustConfig?.enableDeviceIdsReadingOnce()
            }
        }

        // ATT consent delay
        if AdjustSdkMappers.isFieldValid(attConsentWaitingInterval) {
            adjustConfig?.attConsentWaitingInterval = UInt((attConsentWaitingInterval! as NSString).integerValue)
        }

        // callbacks
        if dartAttributionCallback != nil
            || dartSessionSuccessCallback != nil
            || dartSessionFailureCallback != nil
            || dartEventSuccessCallback != nil
            || dartEventFailureCallback != nil
            || dartDeferredDeeplinkCallback != nil
            || dartSkanUpdatedCallback != nil
            || dartRemoteTriggerCallback != nil
            || dartThirdPartySharingSettingsChangedCallback != nil {
            if let channel = self.channel {
                adjustConfig?.delegate = AdjustSdkDelegate.getInstance(
                    attributionCallback: dartAttributionCallback,
                    sessionSuccessCallback: dartSessionSuccessCallback,
                    sessionFailureCallback: dartSessionFailureCallback,
                    eventSuccessCallback: dartEventSuccessCallback,
                    eventFailureCallback: dartEventFailureCallback,
                    deferredDeeplinkCallback: dartDeferredDeeplinkCallback,
                    skanUpdatedCallback: dartSkanUpdatedCallback,
                    remoteTriggerCallback: dartRemoteTriggerCallback,
                    thirdPartySharingSettingsChangedCallback: dartThirdPartySharingSettingsChangedCallback,
                    shouldLaunchDeferredDeeplink: launchDeferredDeeplink,
                    channel: channel
                )
            }
        }

        // start SDK
        if let adjustConfig = adjustConfig {
            Adjust.initSdk(adjustConfig)
        }
        onSdkInitialized()
        result(nil)
    }

    private func trackEvent(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(nil)
            return
        }

        let eventToken = args["eventToken"] as? String
        let revenue = args["revenue"] as? String
        let currency = args["currency"] as? String
        let callbackId = args["callbackId"] as? String
        let productId = args["productId"] as? String
        let transactionId = args["transactionId"] as? String
        let deduplicationId = args["deduplicationId"] as? String
        let strCallbackParametersJson = args["callbackParameters"] as? String
        let strPartnerParametersJson = args["partnerParameters"] as? String

        // create event object
        let adjustEvent = ADJEvent(eventToken: eventToken ?? "")

        // revenue and currency
        if AdjustSdkMappers.isFieldValid(revenue) {
            let revenueValue = Double(revenue!) ?? 0.0
            adjustEvent?.setRevenue(revenueValue, currency: currency ?? "")
        }

        // product ID
        if AdjustSdkMappers.isFieldValid(productId) {
            adjustEvent?.setProductId(productId!)
        }

        // transaction ID
        if AdjustSdkMappers.isFieldValid(transactionId) {
            adjustEvent?.setTransactionId(transactionId!)
        }

        // deduplication ID
        if AdjustSdkMappers.isFieldValid(deduplicationId) {
            adjustEvent?.setDeduplicationId(deduplicationId!)
        }

        // callback ID
        if AdjustSdkMappers.isFieldValid(callbackId) {
            adjustEvent?.setCallbackId(callbackId!)
        }

        // callback parameters
        if let strCallbackParametersJson = strCallbackParametersJson {
            if let data = strCallbackParametersJson.data(using: .utf8),
               let callbackParametersJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                for (key, value) in callbackParametersJson {
                    adjustEvent?.addCallbackParameter(key, value: value)
                }
            }
        }

        // partner parameters
        if let strPartnerParametersJson = strPartnerParametersJson {
            if let data = strPartnerParametersJson.data(using: .utf8),
               let partnerParametersJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                for (key, value) in partnerParametersJson {
                    adjustEvent?.addPartnerParameter(key, value: value)
                }
            }
        }

        // track event
        if let adjustEvent = adjustEvent {
            Adjust.trackEvent(adjustEvent)
        }
        result(nil)
    }

    private func trackAdRevenue(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(nil)
            return
        }

        let source = args["source"] as? String
        let revenue = args["revenue"] as? String
        let currency = args["currency"] as? String
        let adImpressionsCount = args["adImpressionsCount"] as? String
        let adRevenueNetwork = args["adRevenueNetwork"] as? String
        let adRevenueUnit = args["adRevenueUnit"] as? String
        let adRevenuePlacement = args["adRevenuePlacement"] as? String
        let strCallbackParametersJson = args["callbackParameters"] as? String
        let strPartnerParametersJson = args["partnerParameters"] as? String

        // create ad revenue object
        let adjustAdRevenue = ADJAdRevenue(source: source ?? "")

        // revenue
        if AdjustSdkMappers.isFieldValid(revenue) {
            let revenueValue = Double(revenue!) ?? 0.0
            adjustAdRevenue?.setRevenue(revenueValue, currency: currency ?? "")
        }

        // ad impressions count
        if AdjustSdkMappers.isFieldValid(adImpressionsCount) {
            let adImpressionsCountValue = Int32(adImpressionsCount!) ?? 0
            adjustAdRevenue?.setAdImpressionsCount(adImpressionsCountValue)
        }

        // ad revenue network
        if AdjustSdkMappers.isFieldValid(adRevenueNetwork) {
            adjustAdRevenue?.setAdRevenueNetwork(adRevenueNetwork!)
        }

        // ad revenue unit
        if AdjustSdkMappers.isFieldValid(adRevenueUnit) {
            adjustAdRevenue?.setAdRevenueUnit(adRevenueUnit!)
        }

        // ad revenue placement
        if AdjustSdkMappers.isFieldValid(adRevenuePlacement) {
            adjustAdRevenue?.setAdRevenuePlacement(adRevenuePlacement!)
        }

        // callback parameters
        if let strCallbackParametersJson = strCallbackParametersJson {
            if let data = strCallbackParametersJson.data(using: .utf8),
               let callbackParametersJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                for (key, value) in callbackParametersJson {
                    adjustAdRevenue?.addCallbackParameter(key, value: value)
                }
            }
        }

        // partner parameters
        if let strPartnerParametersJson = strPartnerParametersJson {
            if let data = strPartnerParametersJson.data(using: .utf8),
               let partnerParametersJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                for (key, value) in partnerParametersJson {
                    adjustAdRevenue?.addPartnerParameter(key, value: value)
                }
            }
        }

        // track ad revenue
        if let adjustAdRevenue = adjustAdRevenue {
            Adjust.trackAdRevenue(adjustAdRevenue)
        }
        result(nil)
    }

    private func trackThirdPartySharing(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(nil)
            return
        }

        let isEnabled = args["isEnabled"] as? NSNumber
        let strGranularOptions = args["granularOptions"] as? String
        let strPartnerSharingSettings = args["partnerSharingSettings"] as? String

        let adjustThirdPartySharing = ADJThirdPartySharing(
            isEnabled: AdjustSdkMappers.isFieldValid(isEnabled) ? isEnabled : nil
        )

        // granular options
        if let strGranularOptions = strGranularOptions {
            let arrayGranularOptions = strGranularOptions.components(separatedBy: "__ADJ__")
            var i = 0
            while i < arrayGranularOptions.count {
                if i + 2 < arrayGranularOptions.count {
                    adjustThirdPartySharing?.addGranularOption(
                        arrayGranularOptions[i],
                        key: arrayGranularOptions[i + 1],
                        value: arrayGranularOptions[i + 2]
                    )
                }
                i += 3
            }
        }

        // partner sharing settings
        if let strPartnerSharingSettings = strPartnerSharingSettings {
            let arrayPartnerSharingSettings = strPartnerSharingSettings.components(separatedBy: "__ADJ__")
            var i = 0
            while i < arrayPartnerSharingSettings.count {
                if i + 2 < arrayPartnerSharingSettings.count {
                    adjustThirdPartySharing?.addPartnerSharingSetting(
                        arrayPartnerSharingSettings[i],
                        key: arrayPartnerSharingSettings[i + 1],
                        value: (arrayPartnerSharingSettings[i + 2] as NSString).boolValue
                    )
                }
                i += 3
            }
        }

        // track third party sharing
        if let adjustThirdPartySharing = adjustThirdPartySharing {
            Adjust.trackThirdPartySharing(adjustThirdPartySharing)
        }
        result(nil)
    }

    private func trackMeasurementConsent(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(nil)
            return
        }

        if let measurementConsent = args["measurementConsent"] as? NSNumber {
            Adjust.trackMeasurementConsent(measurementConsent.boolValue)
        }
        result(nil)
    }

    private func processDeeplink(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(nil)
            return
        }

        let deeplinkStr = args["deeplink"] as? String
        let referrer = args["referrer"] as? String

        if AdjustSdkMappers.isFieldValid(deeplinkStr) {
            if let urlDeeplink = URL(string: deeplinkStr!) {
                let deeplink = ADJDeeplink(deeplink: urlDeeplink)
                if AdjustSdkMappers.isFieldValid(referrer) {
                    if let urlReferrer = URL(string: referrer!) {
                        deeplink?.setReferrer(urlReferrer)
                    }
                }
                if let deeplink = deeplink {
                    Adjust.processDeeplink(deeplink)
                }
            }
        }
        result(nil)
    }

    private func processAndResolveDeeplink(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(nil)
            return
        }

        let deeplinkStr = args["deeplink"] as? String
        let referrer = args["referrer"] as? String

        if AdjustSdkMappers.isFieldValid(deeplinkStr) {
            if let urlDeeplink = URL(string: deeplinkStr!) {
                let deeplink = ADJDeeplink(deeplink: urlDeeplink)
                if AdjustSdkMappers.isFieldValid(referrer) {
                    if let urlReferrer = URL(string: referrer!) {
                        deeplink?.setReferrer(urlReferrer)
                    }
                }
                if let deeplink = deeplink {
                    Adjust.processAndResolve(deeplink) { [weak self] resolvedLink in
                        guard let self = self else {
                            result(nil)
                            return
                        }
                        if !AdjustSdkMappers.isFieldValid(resolvedLink) {
                            result(nil)
                        } else {
                            result(resolvedLink)
                        }
                    }
                } else {
                    result(nil)
                }
            } else {
                result(nil)
            }
        } else {
            result(nil)
        }
    }

    private func setPushToken(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(nil)
            return
        }

        let pushToken = args["pushToken"] as? String
        if AdjustSdkMappers.isFieldValid(pushToken) {
            Adjust.setPushTokenAs(pushToken!)
        }
        result(nil)
    }

    private func gdprForgetMe(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        Adjust.gdprForgetMe()
        result(nil)
    }

    private func endFirstSessionDelay(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        Adjust.endFirstSessionDelay()
        result(nil)
    }

    private func enableCoppaComplianceInDelay(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        Adjust.enableCoppaComplianceInDelay()
        result(nil)
    }

    private func disableCoppaComplianceInDelay(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        Adjust.disableCoppaComplianceInDelay()
        result(nil)
    }

    private func setExternalDeviceIdInDelay(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(nil)
            return
        }

        let externalDeviceId = args["externalDeviceId"] as? String
        if AdjustSdkMappers.isFieldValid(externalDeviceId) {
            Adjust.setExternalDeviceIdInDelay(externalDeviceId!)
        }
        result(nil)
    }

    private func addGlobalCallbackParameter(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(nil)
            return
        }

        let key = args["key"] as? String
        let value = args["value"] as? String
        if !AdjustSdkMappers.isFieldValid(key) || !AdjustSdkMappers.isFieldValid(value) {
            result(nil)
            return
        }
        Adjust.addGlobalCallbackParameter(value!, forKey: key!)
        result(nil)
    }

    private func removeGlobalCallbackParameter(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(nil)
            return
        }

        let key = args["key"] as? String
        if !AdjustSdkMappers.isFieldValid(key) {
            result(nil)
            return
        }
        Adjust.removeGlobalCallbackParameter(forKey: key!)
        result(nil)
    }

    private func addGlobalPartnerParameter(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(nil)
            return
        }

        let key = args["key"] as? String
        let value = args["value"] as? String
        if !AdjustSdkMappers.isFieldValid(key) || !AdjustSdkMappers.isFieldValid(value) {
            result(nil)
            return
        }
        Adjust.addGlobalPartnerParameter(value!, forKey: key!)
        result(nil)
    }

    private func removeGlobalPartnerParameter(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(nil)
            return
        }

        let key = args["key"] as? String
        if !AdjustSdkMappers.isFieldValid(key) {
            result(nil)
            return
        }
        Adjust.removeGlobalPartnerParameter(forKey: key!)
        result(nil)
    }

    private func getAttribution(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        Adjust.attribution { attribution in
            let dictionary = NSMutableDictionary()
            if attribution == nil {
                result(dictionary)
                return
            }

            AdjustSdkMappers.addValueOrEmpty(attribution?.trackerToken, withKey: "trackerToken", to: dictionary)
            AdjustSdkMappers.addValueOrEmpty(attribution?.trackerName, withKey: "trackerName", to: dictionary)
            AdjustSdkMappers.addValueOrEmpty(attribution?.network, withKey: "network", to: dictionary)
            AdjustSdkMappers.addValueOrEmpty(attribution?.campaign, withKey: "campaign", to: dictionary)
            AdjustSdkMappers.addValueOrEmpty(attribution?.creative, withKey: "creative", to: dictionary)
            AdjustSdkMappers.addValueOrEmpty(attribution?.adgroup, withKey: "adgroup", to: dictionary)
            AdjustSdkMappers.addValueOrEmpty(attribution?.clickLabel, withKey: "clickLabel", to: dictionary)
            AdjustSdkMappers.addValueOrEmpty(attribution?.costType, withKey: "costType", to: dictionary)
            AdjustSdkMappers.addNumberOrEmpty(attribution?.costAmount, withKey: "costAmount", to: dictionary)
            AdjustSdkMappers.addValueOrEmpty(attribution?.costCurrency, withKey: "costCurrency", to: dictionary)
            if let jsonResponse = attribution?.jsonResponse {
                if let dataJsonResponse = try? JSONSerialization.data(withJSONObject: jsonResponse, options: []) {
                    let stringJsonResponse = String(data: dataJsonResponse, encoding: .utf8)
                    AdjustSdkMappers.addValueOrEmpty(stringJsonResponse, withKey: "jsonResponse", to: dictionary)
                } else {
                    AdjustSdkMappers.addValueOrEmpty("", withKey: "jsonResponse", to: dictionary)
                }
            } else {
                AdjustSdkMappers.addValueOrEmpty("", withKey: "jsonResponse", to: dictionary)
            }
            result(dictionary)
        }
    }

    private func getAttributionWithTimeout(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(nil)
            return
        }

        guard let timeoutInMilliseconds = args["timeoutInMilliseconds"] as? NSNumber else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "timeoutInMilliseconds is required",
                details: nil
            ))
            return
        }

        let timeoutMs = timeoutInMilliseconds.intValue
        Adjust.attribution(withTimeout: timeoutMs) { attribution in
            if attribution == nil {
                result(nil)
                return
            }
            let dictionary = NSMutableDictionary()
            AdjustSdkMappers.addValueOrEmpty(attribution?.trackerToken, withKey: "trackerToken", to: dictionary)
            AdjustSdkMappers.addValueOrEmpty(attribution?.trackerName, withKey: "trackerName", to: dictionary)
            AdjustSdkMappers.addValueOrEmpty(attribution?.network, withKey: "network", to: dictionary)
            AdjustSdkMappers.addValueOrEmpty(attribution?.campaign, withKey: "campaign", to: dictionary)
            AdjustSdkMappers.addValueOrEmpty(attribution?.creative, withKey: "creative", to: dictionary)
            AdjustSdkMappers.addValueOrEmpty(attribution?.adgroup, withKey: "adgroup", to: dictionary)
            AdjustSdkMappers.addValueOrEmpty(attribution?.clickLabel, withKey: "clickLabel", to: dictionary)
            AdjustSdkMappers.addValueOrEmpty(attribution?.costType, withKey: "costType", to: dictionary)
            AdjustSdkMappers.addNumberOrEmpty(attribution?.costAmount, withKey: "costAmount", to: dictionary)
            AdjustSdkMappers.addValueOrEmpty(attribution?.costCurrency, withKey: "costCurrency", to: dictionary)
            if let jsonResponse = attribution?.jsonResponse {
                if let dataJsonResponse = try? JSONSerialization.data(withJSONObject: jsonResponse, options: []) {
                    let stringJsonResponse = String(data: dataJsonResponse, encoding: .utf8)
                    AdjustSdkMappers.addValueOrEmpty(stringJsonResponse, withKey: "jsonResponse", to: dictionary)
                } else {
                    AdjustSdkMappers.addValueOrEmpty("", withKey: "jsonResponse", to: dictionary)
                }
            } else {
                AdjustSdkMappers.addValueOrEmpty("", withKey: "jsonResponse", to: dictionary)
            }
            result(dictionary)
        }
    }

    private func getAdidWithTimeout(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(nil)
            return
        }

        guard let timeoutInMilliseconds = args["timeoutInMilliseconds"] as? NSNumber else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "timeoutInMilliseconds is required",
                details: nil
            ))
            return
        }

        let timeoutMs = timeoutInMilliseconds.intValue
        Adjust.adid(withTimeout: timeoutMs) { adid in
            result(adid)
        }
    }

    private func getThirdPartySharingSettingsWithTimeout(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(nil)
            return
        }

        guard let timeoutInMilliseconds = args["timeoutInMilliseconds"] as? NSNumber else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "timeoutInMilliseconds is required",
                details: nil
            ))
            return
        }

        let timeoutMs = timeoutInMilliseconds.intValue
        Adjust.thirdPartySharingSettings(withTimeout: timeoutMs) { thirdPartySharingResult in
            guard let thirdPartySharingResult = thirdPartySharingResult else {
                result(nil)
                return
            }
            let dictionary = NSMutableDictionary()
            AdjustSdkMappers.addValueOrEmpty(
                thirdPartySharingResult.thirdPartySharingSettingsJson,
                withKey: "thirdPartySharingSettingsJson",
                to: dictionary
            )
            result(dictionary)
        }
    }

    private func getLastDeeplink(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        Adjust.lastDeeplink { lastDeeplink in
            if !AdjustSdkMappers.isFieldValid(lastDeeplink) {
                result(nil)
            } else {
                result(lastDeeplink?.absoluteString)
            }
        }
    }

    private func getSdkVersion(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        Adjust.sdkVersion { sdkVersion in
            result(sdkVersion)
        }
    }

    // MARK: - iOS only methods

    private func trackAppStoreSubscription(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(nil)
            return
        }

        let price = args["price"] as? String
        let currency = args["currency"] as? String
        let transactionId = args["transactionId"] as? String
        let transactionDate = args["transactionDate"] as? String
        let salesRegion = args["salesRegion"] as? String
        let strCallbackParametersJson = args["callbackParameters"] as? String
        let strPartnerParametersJson = args["partnerParameters"] as? String

        // price
        var priceValue: NSDecimalNumber?
        if AdjustSdkMappers.isFieldValid(price) {
            priceValue = NSDecimalNumber(string: price!)
        }

        let subscription = ADJAppStoreSubscription(
            price: priceValue ?? NSDecimalNumber.zero,
            currency: currency ?? "",
            transactionId: transactionId ?? ""
        )

        // transaction date
        if AdjustSdkMappers.isFieldValid(transactionDate) {
            let transactionDateInterval = Double(transactionDate!) ?? 0.0
            let oTransactionDate = Date(timeIntervalSince1970: transactionDateInterval)
            subscription?.setTransactionDate(oTransactionDate)
        }

        // sales region
        if AdjustSdkMappers.isFieldValid(salesRegion) {
            subscription?.setSalesRegion(salesRegion!)
        }

        // callback parameters
        if let strCallbackParametersJson = strCallbackParametersJson {
            if let data = strCallbackParametersJson.data(using: .utf8),
               let callbackParametersJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                for (key, value) in callbackParametersJson {
                    subscription?.addCallbackParameter(key, value: value)
                }
            }
        }

        // partner parameters
        if let strPartnerParametersJson = strPartnerParametersJson {
            if let data = strPartnerParametersJson.data(using: .utf8),
               let partnerParametersJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                for (key, value) in partnerParametersJson {
                    subscription?.addPartnerParameter(key, value: value)
                }
            }
        }

        // track subscription
        if let subscription = subscription {
            Adjust.trackAppStoreSubscription(subscription)
        }
        result(nil)
    }

    private func verifyAppStorePurchase(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(nil)
            return
        }

        let productId = args["productId"] as? String
        let transactionId = args["transactionId"] as? String

        let purchase = ADJAppStorePurchase(
            transactionId: transactionId ?? "",
            productId: productId ?? ""
        )

        // verify purchase
        if let purchase = purchase {
            Adjust.verifyAppStorePurchase(purchase) { verificationResult in
                let dictionary = NSMutableDictionary()

                AdjustSdkMappers.addValueOrEmpty(
                    verificationResult.verificationStatus,
                    withKey: "verificationStatus",
                    to: dictionary
                )
                AdjustSdkMappers.addValueOrEmpty(
                    String(format: "%d", verificationResult.code),
                    withKey: "code",
                    to: dictionary
                )
                AdjustSdkMappers.addValueOrEmpty(
                    verificationResult.message,
                    withKey: "message",
                    to: dictionary
                )
                result(dictionary)
            }
        } else {
            result(NSMutableDictionary())
        }
    }

    private func verifyAndTrackAppStorePurchase(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(nil)
            return
        }

        let eventToken = args["eventToken"] as? String
        let revenue = args["revenue"] as? String
        let currency = args["currency"] as? String
        let callbackId = args["callbackId"] as? String
        let productId = args["productId"] as? String
        let transactionId = args["transactionId"] as? String
        let deduplicationId = args["deduplicationId"] as? String
        let strCallbackParametersJson = args["callbackParameters"] as? String
        let strPartnerParametersJson = args["partnerParameters"] as? String

        let adjustEvent = ADJEvent(eventToken: eventToken ?? "")

        // revenue
        if AdjustSdkMappers.isFieldValid(revenue) {
            let revenueValue = Double(revenue!) ?? 0.0
            adjustEvent?.setRevenue(revenueValue, currency: currency ?? "")
        }

        // product ID
        if AdjustSdkMappers.isFieldValid(productId) {
            adjustEvent?.setProductId(productId!)
        }

        // transaction ID
        if AdjustSdkMappers.isFieldValid(transactionId) {
            adjustEvent?.setTransactionId(transactionId!)
        }

        // deduplication ID
        if AdjustSdkMappers.isFieldValid(deduplicationId) {
            adjustEvent?.setDeduplicationId(deduplicationId!)
        }

        // callback ID
        if AdjustSdkMappers.isFieldValid(callbackId) {
            adjustEvent?.setCallbackId(callbackId!)
        }

        // callback parameters
        if let strCallbackParametersJson = strCallbackParametersJson {
            if let data = strCallbackParametersJson.data(using: .utf8),
               let callbackParametersJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                for (key, value) in callbackParametersJson {
                    adjustEvent?.addCallbackParameter(key, value: value)
                }
            }
        }

        // partner parameters
        if let strPartnerParametersJson = strPartnerParametersJson {
            if let data = strPartnerParametersJson.data(using: .utf8),
               let partnerParametersJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                for (key, value) in partnerParametersJson {
                    adjustEvent?.addPartnerParameter(key, value: value)
                }
            }
        }

        // verify and track app store purchase
        if let adjustEvent = adjustEvent {
            Adjust.verifyAndTrackAppStorePurchase(adjustEvent) { verificationResult in
                let dictionary = NSMutableDictionary()

                AdjustSdkMappers.addValueOrEmpty(
                    verificationResult.verificationStatus,
                    withKey: "verificationStatus",
                    to: dictionary
                )
                AdjustSdkMappers.addValueOrEmpty(
                    String(format: "%d", verificationResult.code),
                    withKey: "code",
                    to: dictionary
                )
                AdjustSdkMappers.addValueOrEmpty(
                    verificationResult.message,
                    withKey: "message",
                    to: dictionary
                )
                result(dictionary)
            }
        } else {
            result(NSMutableDictionary())
        }
    }

    private func updateSkanConversionValue(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(nil)
            return
        }

        let conversionValue = (args["conversionValue"] as? NSNumber)?.intValue ?? 0
        let coarseValue = args["coarseValue"] as? String
        let lockWindow = args["lockWindow"] as? NSNumber

        Adjust.updateSkanConversionValue(
            conversionValue,
            coarseValue: coarseValue,
            lockWindow: lockWindow
        ) { error in
            result(error?.localizedDescription)
        }
    }

    private func requestAppTrackingAuthorization(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        Adjust.requestAppTrackingAuthorization { status in
            result(NSNumber(value: status))
        }
    }

    private func getIdfa(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        Adjust.idfa { idfa in
            result(idfa)
        }
    }

    private func getIdfv(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        Adjust.idfv { idfv in
            result(idfv)
        }
    }

    private func getAppTrackingAuthorizationStatus(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(NSNumber(value: Adjust.appTrackingAuthorizationStatus()))
    }

    // MARK: - Android only methods

    private func getGoogleAdId(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(FlutterError(
            code: "non_existing_method",
            message: "getGoogleAdId not available on iOS platform!",
            details: nil
        ))
    }

    private func getAmazonAdId(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(FlutterError(
            code: "non_existing_method",
            message: "getAmazonAdId not available on iOS platform!",
            details: nil
        ))
    }

    private func trackPlayStoreSubscription(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(FlutterError(
            code: "non_existing_method",
            message: "trackPlayStoreSubscription not available on iOS platform!",
            details: nil
        ))
    }

    private func verifyPlayStorePurchase(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(FlutterError(
            code: "non_existing_method",
            message: "verifyPlayStorePurchase not available on iOS platform!",
            details: nil
        ))
    }

    private func verifyAndTrackPlayStorePurchase(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(FlutterError(
            code: "non_existing_method",
            message: "verifyAndTrackPlayStorePurchase not available on iOS platform!",
            details: nil
        ))
    }

    private func enablePlayStoreKidsComplianceInDelay(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(FlutterError(
            code: "non_existing_method",
            message: "enablePlayStoreKidsComplianceInDelay not available on iOS platform!",
            details: nil
        ))
    }

    private func disablePlayStoreKidsComplianceInDelay(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(FlutterError(
            code: "non_existing_method",
            message: "disablePlayStoreKidsComplianceInDelay not available on iOS platform!",
            details: nil
        ))
    }

    // MARK: - Testing only methods

    private func setTestOptions(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(nil)
            return
        }

        let testOptions = NSMutableDictionary()

        if let urlOverwrite = args["urlOverwrite"] {
            testOptions["testUrlOverwrite"] = urlOverwrite
        }
        if let extraPath = args["extraPath"] {
            testOptions["extraPath"] = extraPath
        }
        if let basePath = args["basePath"] {
            testOptions["basePath"] = basePath
        }
        if let timerIntervalInMilliseconds = args["timerIntervalInMilliseconds"] {
            testOptions["timerIntervalInMilliseconds"] = timerIntervalInMilliseconds
        }
        if let timerStartInMilliseconds = args["timerStartInMilliseconds"] {
            testOptions["timerStartInMilliseconds"] = timerStartInMilliseconds
        }
        if let sessionIntervalInMilliseconds = args["sessionIntervalInMilliseconds"] {
            testOptions["sessionIntervalInMilliseconds"] = sessionIntervalInMilliseconds
        }
        if let subsessionIntervalInMilliseconds = args["subsessionIntervalInMilliseconds"] {
            testOptions["subsessionIntervalInMilliseconds"] = subsessionIntervalInMilliseconds
        }
        if let teardown = args["teardown"] {
            testOptions["teardown"] = teardown
            if let teardownStr = teardown as? String, teardownStr == "true" {
                AdjustSdkDelegate.teardown()
            }
        }
        if let resetSdk = args["resetSdk"] {
            testOptions["resetSdk"] = resetSdk
        }
        if let deleteState = args["deleteState"] {
            testOptions["deleteState"] = deleteState
        }
        if let resetTest = args["resetTest"] {
            testOptions["resetTest"] = resetTest
        }
        if let noBackoffWait = args["noBackoffWait"] {
            testOptions["noBackoffWait"] = noBackoffWait
        }
        if let adServicesFrameworkEnabled = args["adServicesFrameworkEnabled"] {
            testOptions["adServicesFrameworkEnabled"] = adServicesFrameworkEnabled
        }
        if let attStatus = args["attStatus"] {
            testOptions["attStatusInt"] = attStatus
        }
        if let idfa = args["idfa"] {
            testOptions["idfa"] = idfa
        }

        Adjust.setTestOptions(testOptions as! [AnyHashable: Any])
        result(nil)
    }
}
