//
//  AdjustSdkCallbacks.kt
//  Adjust SDK
//
//  Copyright (c) 2018-Present Adjust GmbH. All rights reserved.
//

package com.adjust.sdk.flutter

import com.adjust.sdk.AdjustConfig
import io.flutter.plugin.common.MethodChannel

object AdjustSdkCallbacks {

    fun setupAttributionCallback(
        config: AdjustConfig,
        dartMethodName: String,
        channel: MethodChannel?
    ) {
        config.setOnAttributionChangedListener { adjustAttribution ->
            val adjustAttributionMap = HashMap<String, Any?>()
            adjustAttributionMap["trackerToken"] = adjustAttribution.trackerToken
            adjustAttributionMap["trackerName"] = adjustAttribution.trackerName
            adjustAttributionMap["network"] = adjustAttribution.network
            adjustAttributionMap["campaign"] = adjustAttribution.campaign
            adjustAttributionMap["adgroup"] = adjustAttribution.adgroup
            adjustAttributionMap["creative"] = adjustAttribution.creative
            adjustAttributionMap["clickLabel"] = adjustAttribution.clickLabel
            adjustAttributionMap["costType"] = adjustAttribution.costType
            adjustAttributionMap["costAmount"] = adjustAttribution.costAmount?.toString() ?: ""
            adjustAttributionMap["costCurrency"] = adjustAttribution.costCurrency
            adjustAttributionMap["fbInstallReferrer"] = adjustAttribution.fbInstallReferrer
            if (adjustAttribution.jsonResponse != null) {
                adjustAttributionMap["jsonResponse"] = adjustAttribution.jsonResponse
            }
            channel?.invokeMethod(dartMethodName, adjustAttributionMap)
        }
    }

    fun setupSessionSuccessCallback(
        config: AdjustConfig,
        dartMethodName: String,
        channel: MethodChannel?
    ) {
        config.setOnSessionTrackingSucceededListener { adjustSessionSuccess ->
            val adjustSessionSuccessMap = HashMap<String, String>()
            adjustSessionSuccessMap["message"] = adjustSessionSuccess.message
            adjustSessionSuccessMap["timestamp"] = adjustSessionSuccess.timestamp
            adjustSessionSuccessMap["adid"] = adjustSessionSuccess.adid
            if (adjustSessionSuccess.jsonResponse != null) {
                adjustSessionSuccessMap["jsonResponse"] = adjustSessionSuccess.jsonResponse.toString()
            }
            channel?.invokeMethod(dartMethodName, adjustSessionSuccessMap)
        }
    }

    fun setupSessionFailureCallback(
        config: AdjustConfig,
        dartMethodName: String,
        channel: MethodChannel?
    ) {
        config.setOnSessionTrackingFailedListener { adjustSessionFailure ->
            val adjustSessionFailureMap = HashMap<String, String>()
            adjustSessionFailureMap["message"] = adjustSessionFailure.message
            adjustSessionFailureMap["timestamp"] = adjustSessionFailure.timestamp
            adjustSessionFailureMap["adid"] = adjustSessionFailure.adid
            adjustSessionFailureMap["willRetry"] = adjustSessionFailure.willRetry.toString()
            if (adjustSessionFailure.jsonResponse != null) {
                adjustSessionFailureMap["jsonResponse"] = adjustSessionFailure.jsonResponse.toString()
            }
            channel?.invokeMethod(dartMethodName, adjustSessionFailureMap)
        }
    }

    fun setupEventSuccessCallback(
        config: AdjustConfig,
        dartMethodName: String,
        channel: MethodChannel?
    ) {
        config.setOnEventTrackingSucceededListener { adjustEventSuccess ->
            val adjustEventSuccessMap = HashMap<String, String>()
            adjustEventSuccessMap["message"] = adjustEventSuccess.message
            adjustEventSuccessMap["timestamp"] = adjustEventSuccess.timestamp
            adjustEventSuccessMap["adid"] = adjustEventSuccess.adid
            adjustEventSuccessMap["eventToken"] = adjustEventSuccess.eventToken
            adjustEventSuccessMap["callbackId"] = adjustEventSuccess.callbackId
            if (adjustEventSuccess.jsonResponse != null) {
                adjustEventSuccessMap["jsonResponse"] = adjustEventSuccess.jsonResponse.toString()
            }
            channel?.invokeMethod(dartMethodName, adjustEventSuccessMap)
        }
    }

    fun setupEventFailureCallback(
        config: AdjustConfig,
        dartMethodName: String,
        channel: MethodChannel?
    ) {
        config.setOnEventTrackingFailedListener { adjustEventFailure ->
            val adjustEventFailureMap = HashMap<String, String>()
            adjustEventFailureMap["message"] = adjustEventFailure.message
            adjustEventFailureMap["timestamp"] = adjustEventFailure.timestamp
            adjustEventFailureMap["adid"] = adjustEventFailure.adid
            adjustEventFailureMap["eventToken"] = adjustEventFailure.eventToken
            adjustEventFailureMap["callbackId"] = adjustEventFailure.callbackId
            adjustEventFailureMap["willRetry"] = adjustEventFailure.willRetry.toString()
            if (adjustEventFailure.jsonResponse != null) {
                adjustEventFailureMap["jsonResponse"] = adjustEventFailure.jsonResponse.toString()
            }
            channel?.invokeMethod(dartMethodName, adjustEventFailureMap)
        }
    }

    fun setupDeferredDeeplinkCallback(
        config: AdjustConfig,
        dartMethodName: String,
        channel: MethodChannel?,
        isDeferredDeeplinkOpeningEnabled: Boolean
    ) {
        config.setOnDeferredDeeplinkResponseListener { deeplink ->
            val uriParamsMap = HashMap<String, String>()
            uriParamsMap["deeplink"] = deeplink.toString()
            channel?.invokeMethod(dartMethodName, uriParamsMap)
            isDeferredDeeplinkOpeningEnabled
        }
    }

    fun setupRemoteTriggerCallback(
        config: AdjustConfig,
        dartMethodName: String,
        channel: MethodChannel?
    ) {
        config.setOnRemoteTriggerListener { remoteTrigger ->
            channel?.invokeMethod(dartMethodName, AdjustSdkMappers.remoteTriggerToMap(remoteTrigger))
        }
    }

    fun setupThirdPartySharingSettingsChangedCallback(
        config: AdjustConfig,
        dartMethodName: String,
        channel: MethodChannel?
    ) {
        config.setOnThirdPartySharingSettingsChangedListener { thirdPartySharingResult ->
            channel?.invokeMethod(dartMethodName, AdjustSdkMappers.thirdPartySharingResultToMap(thirdPartySharingResult))
        }
    }
}
