//
//  AdjustSdkMethodHandler.kt
//  Adjust SDK
//
//  Copyright (c) 2018-Present Adjust GmbH. All rights reserved.
//

package com.adjust.sdk.flutter

import android.content.Context
import android.net.Uri
import android.util.Log

import com.adjust.sdk.Adjust
import com.adjust.sdk.AdjustAdRevenue
import com.adjust.sdk.AdjustConfig
import com.adjust.sdk.AdjustDeeplink
import com.adjust.sdk.AdjustPlayStorePurchase
import com.adjust.sdk.AdjustPlayStoreSubscription
import com.adjust.sdk.AdjustStoreInfo
import com.adjust.sdk.AdjustTestOptions
import com.adjust.sdk.AdjustThirdPartySharing
import com.adjust.sdk.LogLevel

import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class AdjustSdkMethodHandler(
    private val applicationContext: Context,
    private val channel: MethodChannel,
    private val onSdkInitialized: () -> Unit = {}
) : MethodCallHandler {

    companion object {
        const val TAG = "AdjustBridge"
        var isDeferredDeeplinkOpeningEnabled = true
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            // common
            "initSdk" -> initSdk(call, result)
            "trackEvent" -> trackEvent(call, result)
            "trackAdRevenue" -> trackAdRevenue(call, result)
            "trackThirdPartySharing" -> trackThirdPartySharing(call, result)
            "trackMeasurementConsent" -> trackMeasurementConsent(call, result)
            "processDeeplink" -> processDeeplink(call, result)
            "processAndResolveDeeplink" -> processAndResolveDeeplink(call, result)
            "setPushToken" -> setPushToken(call, result)
            "gdprForgetMe" -> gdprForgetMe(result)
            "enable" -> enable(result)
            "disable" -> disable(result)
            "switchToOfflineMode" -> switchToOfflineMode(result)
            "switchBackToOnlineMode" -> switchBackToOnlineMode(result)
            "addGlobalCallbackParameter" -> addGlobalCallbackParameter(call, result)
            "addGlobalPartnerParameter" -> addGlobalPartnerParameter(call, result)
            "removeGlobalCallbackParameter" -> removeGlobalCallbackParameter(call, result)
            "removeGlobalPartnerParameter" -> removeGlobalPartnerParameter(call, result)
            "removeGlobalCallbackParameters" -> removeGlobalCallbackParameters(result)
            "removeGlobalPartnerParameters" -> removeGlobalPartnerParameters(result)
            "endFirstSessionDelay" -> endFirstSessionDelay(call, result)
            "enableCoppaComplianceInDelay" -> enableCoppaComplianceInDelay(call, result)
            "disableCoppaComplianceInDelay" -> disableCoppaComplianceInDelay(call, result)
            "enablePlayStoreKidsComplianceInDelay" -> enablePlayStoreKidsComplianceInDelay(call, result)
            "disablePlayStoreKidsComplianceInDelay" -> disablePlayStoreKidsComplianceInDelay(call, result)
            "setExternalDeviceIdInDelay" -> setExternalDeviceIdInDelay(call, result)
            "isEnabled" -> isEnabled(result)
            "getAttribution" -> getAttribution(result)
            "getAttributionWithTimeout" -> getAttributionWithTimeout(call, result)
            "getAdid" -> getAdid(result)
            "getAdidWithTimeout" -> getAdidWithTimeout(call, result)
            "getThirdPartySharingSettingsWithTimeout" -> getThirdPartySharingSettingsWithTimeout(call, result)
            "getLastDeeplink" -> getLastDeeplink(result)
            "getSdkVersion" -> getSdkVersion(result)
            // android only
            "trackPlayStoreSubscription" -> trackPlayStoreSubscription(call, result)
            "verifyPlayStorePurchase" -> verifyPlayStorePurchase(call, result)
            "verifyAndTrackPlayStorePurchase" -> verifyAndTrackPlayStorePurchase(call, result)
            "getGoogleAdId" -> getGoogleAdId(result)
            "getAmazonAdId" -> getAmazonAdId(result)
            // ios only methods
            "trackAppStoreSubscription" -> trackAppStoreSubscription(result)
            "verifyAppStorePurchase" -> verifyAppStorePurchase(call, result)
            "verifyAndTrackAppStorePurchase" -> verifyAndTrackAppStorePurchase(call, result)
            "requestAppTrackingAuthorization" -> requestAppTrackingAuthorization(result)
            "updateSkanConversionValue" -> updateSkanConversionValue(result)
            "getIdfa" -> getIdfa(result)
            "getIdfv" -> getIdfv(result)
            "getAppTrackingAuthorizationStatus" -> getAppTrackingAuthorizationStatus(call, result)
            // testing only
            "onPause" -> onPause(result)
            "onResume" -> onResume(result)
            "setTestOptions" -> setTestOptions(call, result)
            else -> {
                Log.e(TAG, "Not implemented method: ${call.method}")
                result.notImplemented()
            }
        }
    }

    // common

    private fun initSdk(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val configMap = call.arguments as? Map<*, *> ?: return

        var appToken: String? = null
        var environment: String? = null
        var logLevel: String? = null
        var isLogLevelSuppress = false

        // app token
        if (configMap.containsKey("appToken")) {
            appToken = configMap["appToken"] as? String
        }

        // environment
        if (configMap.containsKey("environment")) {
            environment = configMap["environment"] as? String
        }

        // suppress log level
        if (configMap.containsKey("logLevel")) {
            logLevel = configMap["logLevel"] as? String
            if (logLevel != null && logLevel == "suppress") {
                isLogLevelSuppress = true
            }
        }

        // create configuration object
        val adjustConfig = AdjustConfig(applicationContext, appToken, environment, isLogLevelSuppress)

        // SDK prefix
        if (configMap.containsKey("sdkPrefix")) {
            val sdkPrefix = configMap["sdkPrefix"] as? String
            adjustConfig.setSdkPrefix(sdkPrefix)
        }

        // log level
        if (configMap.containsKey("logLevel")) {
            logLevel = configMap["logLevel"] as? String
            if (logLevel != null) {
                when (logLevel) {
                    "verbose" -> adjustConfig.setLogLevel(LogLevel.VERBOSE)
                    "debug" -> adjustConfig.setLogLevel(LogLevel.DEBUG)
                    "warn" -> adjustConfig.setLogLevel(LogLevel.WARN)
                    "error" -> adjustConfig.setLogLevel(LogLevel.ERROR)
                    "assert" -> adjustConfig.setLogLevel(LogLevel.ASSERT)
                    "suppress" -> adjustConfig.setLogLevel(LogLevel.SUPPRESS)
                    "info" -> adjustConfig.setLogLevel(LogLevel.INFO)
                    else -> adjustConfig.setLogLevel(LogLevel.INFO)
                }
            }
        }

        // first session delay
        if (configMap.containsKey("isFirstSessionDelayEnabled")) {
            val strIsFirstSessionDelayEnabled = configMap["isFirstSessionDelayEnabled"] as? String
            val isFirstSessionDelayEnabled = strIsFirstSessionDelayEnabled.toBoolean()
            if (isFirstSessionDelayEnabled) {
                adjustConfig.enableFirstSessionDelay()
            }
        }

        // COPPA compliance
        if (configMap.containsKey("isCoppaComplianceEnabled")) {
            val strIsCoppaComplianceEnabled = configMap["isCoppaComplianceEnabled"] as? String
            val isCoppaComplianceEnabled = strIsCoppaComplianceEnabled.toBoolean()
            if (isCoppaComplianceEnabled) {
                adjustConfig.enableCoppaCompliance()
            }
        }

        // Google Play Store kids compliance
        if (configMap.containsKey("isPlayStoreKidsComplianceEnabled")) {
            val strIsPlayStoreKidsComplianceEnabled = configMap["isPlayStoreKidsComplianceEnabled"] as? String
            val isPlayStoreKidsComplianceEnabled = strIsPlayStoreKidsComplianceEnabled.toBoolean()
            if (isPlayStoreKidsComplianceEnabled) {
                adjustConfig.enablePlayStoreKidsCompliance()
            }
        }

        // read device info only once
        if (configMap.containsKey("isDeviceIdsReadingOnceEnabled")) {
            val strIsDeviceIdsReadingOnceEnabled = configMap["isDeviceIdsReadingOnceEnabled"] as? String
            val isDeviceIdsReadingOnceEnabled = strIsDeviceIdsReadingOnceEnabled.toBoolean()
            if (isDeviceIdsReadingOnceEnabled) {
                adjustConfig.enableDeviceIdsReadingOnce()
            }
        }

        // app set ID reading (Android only)
        if (configMap.containsKey("isAppSetIdReadingEnabled")) {
            val strIsAppSetIdReadingEnabled = configMap["isAppSetIdReadingEnabled"] as? String
            val isAppSetIdReadingEnabled = strIsAppSetIdReadingEnabled.toBoolean()
            if (!isAppSetIdReadingEnabled) {
                adjustConfig.disableAppSetIdReading()
            }
        }

        // event deduplication buffer size
        if (configMap.containsKey("eventDeduplicationIdsMaxSize")) {
            val strEventDeduplicationIdsMaxSize = configMap["eventDeduplicationIdsMaxSize"] as? String
            try {
                val eventDeduplicationIdsMaxSize = strEventDeduplicationIdsMaxSize?.toInt() ?: 0
                adjustConfig.setEventDeduplicationIdsMaxSize(eventDeduplicationIdsMaxSize)
            } catch (_: Exception) {
            }
        }

        // set store info
        if (configMap.containsKey("storeInfo")) {
            try {
                val strStoreInfo = configMap["storeInfo"] as? String
                val storeInfo = JSONObject(strStoreInfo ?: "")

                if (storeInfo.has("storeName") && !storeInfo.isNull("storeName")) {
                    val storeName = storeInfo.getString("storeName")
                    val adjustStoreInfo = AdjustStoreInfo(storeName)
                    if (storeInfo.has("storeAppId") && !storeInfo.isNull("storeAppId")) {
                        val storeAppId = storeInfo.getString("storeAppId")
                        adjustStoreInfo.setStoreAppId(storeAppId)
                    }
                    adjustConfig.setStoreInfo(adjustStoreInfo)
                }
            } catch (_: JSONException) {
            }
        }

        // URL strategy
        if (configMap.containsKey("urlStrategyDomains")
            && configMap.containsKey("useSubdomains")
            && configMap.containsKey("isDataResidency")
        ) {
            val strUrlStrategyDomains = configMap["urlStrategyDomains"] as? String
            try {
                val jsonArray = JSONArray(strUrlStrategyDomains)
                val urlStrategyDomainsArray = ArrayList<String>()
                for (i in 0 until jsonArray.length()) {
                    urlStrategyDomainsArray.add(jsonArray.get(i) as String)
                }
                val strShouldUseSubdomains = configMap["useSubdomains"] as? String
                val useSubdomains = strShouldUseSubdomains.toBoolean()

                val strIsDataResidency = configMap["isDataResidency"] as? String
                val isDataResidency = strIsDataResidency.toBoolean()

                adjustConfig.setUrlStrategy(urlStrategyDomainsArray, useSubdomains, isDataResidency)
            } catch (_: JSONException) {
            }
        }

        // main process name
        if (configMap.containsKey("processName")) {
            val processName = configMap["processName"] as? String
            adjustConfig.setProcessName(processName)
        }

        // default tracker
        if (configMap.containsKey("defaultTracker")) {
            val defaultTracker = configMap["defaultTracker"] as? String
            adjustConfig.setDefaultTracker(defaultTracker)
        }

        // external device ID
        if (configMap.containsKey("externalDeviceId")) {
            val externalDeviceId = configMap["externalDeviceId"] as? String
            adjustConfig.setExternalDeviceId(externalDeviceId)
        }

        // custom preinstall file path
        if (configMap.containsKey("preinstallFilePath")) {
            val preinstallFilePath = configMap["preinstallFilePath"] as? String
            adjustConfig.setPreinstallFilePath(preinstallFilePath)
        }

        // META install referrer
        if (configMap.containsKey("fbAppId")) {
            val fbAppId = configMap["fbAppId"] as? String
            adjustConfig.setFbAppId(fbAppId)
        }

        // sending in background
        if (configMap.containsKey("isSendingInBackgroundEnabled")) {
            val strIsSendingInBackgroundEnabled = configMap["isSendingInBackgroundEnabled"] as? String
            val isSendingInBackgroundEnabled = strIsSendingInBackgroundEnabled.toBoolean()
            if (isSendingInBackgroundEnabled) {
                adjustConfig.enableSendingInBackground()
            }
        }

        // cost data in attribution callback
        if (configMap.containsKey("isCostDataInAttributionEnabled")) {
            val strIsCostDataInAttributionEnabled = configMap["isCostDataInAttributionEnabled"] as? String
            val isCostDataInAttributionEnabled = strIsCostDataInAttributionEnabled.toBoolean()
            if (isCostDataInAttributionEnabled) {
                adjustConfig.enableCostDataInAttribution()
            }
        }

        // preinstall tracking
        if (configMap.containsKey("isPreinstallTrackingEnabled")) {
            val strIsPreinstallTrackingEnabled = configMap["isPreinstallTrackingEnabled"] as? String
            val isPreinstallTrackingEnabled = strIsPreinstallTrackingEnabled.toBoolean()
            if (isPreinstallTrackingEnabled) {
                adjustConfig.enablePreinstallTracking()
            }
        }

        // launch deferred deep link
        if (configMap.containsKey("isDeferredDeeplinkOpeningEnabled")) {
            val strIsDeferredDeeplinkOpeningEnabled = configMap["isDeferredDeeplinkOpeningEnabled"] as? String
            isDeferredDeeplinkOpeningEnabled = strIsDeferredDeeplinkOpeningEnabled == "true"
        }

        // attribution callback
        if (configMap.containsKey("attributionCallback")) {
            val dartMethodName = configMap["attributionCallback"] as? String
            if (dartMethodName != null) {
                AdjustSdkCallbacks.setupAttributionCallback(adjustConfig, dartMethodName, channel)
            }
        }

        // session success callback
        if (configMap.containsKey("sessionSuccessCallback")) {
            val dartMethodName = configMap["sessionSuccessCallback"] as? String
            if (dartMethodName != null) {
                AdjustSdkCallbacks.setupSessionSuccessCallback(adjustConfig, dartMethodName, channel)
            }
        }

        // session failure callback
        if (configMap.containsKey("sessionFailureCallback")) {
            val dartMethodName = configMap["sessionFailureCallback"] as? String
            if (dartMethodName != null) {
                AdjustSdkCallbacks.setupSessionFailureCallback(adjustConfig, dartMethodName, channel)
            }
        }

        // event success callback
        if (configMap.containsKey("eventSuccessCallback")) {
            val dartMethodName = configMap["eventSuccessCallback"] as? String
            if (dartMethodName != null) {
                AdjustSdkCallbacks.setupEventSuccessCallback(adjustConfig, dartMethodName, channel)
            }
        }

        // event failure callback
        if (configMap.containsKey("eventFailureCallback")) {
            val dartMethodName = configMap["eventFailureCallback"] as? String
            if (dartMethodName != null) {
                AdjustSdkCallbacks.setupEventFailureCallback(adjustConfig, dartMethodName, channel)
            }
        }

        // deferred deep link callback
        if (configMap.containsKey("deferredDeeplinkCallback")) {
            val dartMethodName = configMap["deferredDeeplinkCallback"] as? String
            if (dartMethodName != null) {
                AdjustSdkCallbacks.setupDeferredDeeplinkCallback(
                    adjustConfig,
                    dartMethodName,
                    channel,
                    isDeferredDeeplinkOpeningEnabled
                )
            }
        }

        // remote trigger callback
        if (configMap.containsKey("remoteTriggerCallback")) {
            val dartMethodName = configMap["remoteTriggerCallback"] as? String
            if (dartMethodName != null) {
                AdjustSdkCallbacks.setupRemoteTriggerCallback(adjustConfig, dartMethodName, channel)
            }
        }

        // third party sharing settings changed callback
        if (configMap.containsKey("thirdPartySharingSettingsChangedCallback")) {
            val dartMethodName = configMap["thirdPartySharingSettingsChangedCallback"] as? String
            if (dartMethodName != null) {
                AdjustSdkCallbacks.setupThirdPartySharingSettingsChangedCallback(adjustConfig, dartMethodName, channel)
            }
        }

        // initialize SDK
        Adjust.initSdk(adjustConfig)
        onSdkInitialized()
        result.success(null)
    }

    private fun trackEvent(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val eventMap = call.arguments as? Map<*, *> ?: return

        val event = AdjustSdkMappers.buildEventFromMap(eventMap)

        // track event
        Adjust.trackEvent(event)
        result.success(null)
    }

    private fun trackAdRevenue(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val adRevenueMap = call.arguments as? Map<*, *> ?: return

        // ad revenue source
        var source: String? = null
        if (adRevenueMap.containsKey("source")) {
            source = adRevenueMap["source"] as? String
        }

        // create ad revenue object
        val adRevenue = AdjustAdRevenue(source)

        // revenue and currency
        if (adRevenueMap.containsKey("revenue") || adRevenueMap.containsKey("currency")) {
            var revenue = -1.0
            val strRevenue = adRevenueMap["revenue"] as? String
            try {
                revenue = strRevenue?.toDouble() ?: -1.0
                val currency = adRevenueMap["currency"] as? String
                adRevenue.setRevenue(revenue, currency)
            } catch (_: NumberFormatException) {
            }
        }

        // ad impressions count
        if (adRevenueMap.containsKey("adImpressionsCount")) {
            val strAdImpressionsCount = adRevenueMap["adImpressionsCount"] as? String
            val adImpressionsCount = strAdImpressionsCount?.toInt() ?: 0
            adRevenue.setAdImpressionsCount(adImpressionsCount)
        }

        // ad revenue network
        if (adRevenueMap.containsKey("adRevenueNetwork")) {
            val adRevenueNetwork = adRevenueMap["adRevenueNetwork"] as? String
            adRevenue.setAdRevenueNetwork(adRevenueNetwork)
        }

        // ad revenue unit
        if (adRevenueMap.containsKey("adRevenueUnit")) {
            val adRevenueUnit = adRevenueMap["adRevenueUnit"] as? String
            adRevenue.setAdRevenueUnit(adRevenueUnit)
        }

        // ad revenue placement
        if (adRevenueMap.containsKey("adRevenuePlacement")) {
            val adRevenuePlacement = adRevenueMap["adRevenuePlacement"] as? String
            adRevenue.setAdRevenuePlacement(adRevenuePlacement)
        }

        // callback parameters
        if (adRevenueMap.containsKey("callbackParameters")) {
            val strCallbackParametersJson = adRevenueMap["callbackParameters"] as? String
            AdjustSdkMappers.parseJsonParameters(strCallbackParametersJson) { key, value ->
                adRevenue.addCallbackParameter(key, value)
            }
        }

        // partner parameters
        if (adRevenueMap.containsKey("partnerParameters")) {
            val strPartnerParametersJson = adRevenueMap["partnerParameters"] as? String
            AdjustSdkMappers.parseJsonParameters(strPartnerParametersJson) { key, value ->
                adRevenue.addPartnerParameter(key, value)
            }
        }

        // track ad revenue
        Adjust.trackAdRevenue(adRevenue)
        result.success(null)
    }

    private fun trackThirdPartySharing(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val thirdPartySharingMap = call.arguments as? Map<*, *> ?: return

        var isEnabled: Boolean? = null
        if (thirdPartySharingMap.containsKey("isEnabled")) {
            isEnabled = thirdPartySharingMap["isEnabled"] as? Boolean
        }

        // create third party sharing object
        val thirdPartySharing = AdjustThirdPartySharing(isEnabled)

        // granular options
        if (thirdPartySharingMap.containsKey("granularOptions")) {
            val strGranularOptions = thirdPartySharingMap["granularOptions"] as? String
            val arrayGranularOptions = strGranularOptions?.split("__ADJ__", limit = -1) ?: emptyList()
            var i = 0
            while (i < arrayGranularOptions.size) {
                thirdPartySharing.addGranularOption(
                    arrayGranularOptions[i],
                    arrayGranularOptions[i + 1],
                    arrayGranularOptions[i + 2]
                )
                i += 3
            }
        }

        // partner sharing settings
        if (thirdPartySharingMap.containsKey("partnerSharingSettings")) {
            val strPartnerSharingSettings = thirdPartySharingMap["partnerSharingSettings"] as? String
            val arrayPartnerSharingSettings = strPartnerSharingSettings?.split("__ADJ__", limit = -1) ?: emptyList()
            var i = 0
            while (i < arrayPartnerSharingSettings.size) {
                thirdPartySharing.addPartnerSharingSetting(
                    arrayPartnerSharingSettings[i],
                    arrayPartnerSharingSettings[i + 1],
                    arrayPartnerSharingSettings[i + 2].toBoolean()
                )
                i += 3
            }
        }

        // track third party sharing
        Adjust.trackThirdPartySharing(thirdPartySharing)
        result.success(null)
    }

    private fun trackMeasurementConsent(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val measurementConsentMap = call.arguments as? Map<*, *>
        if (measurementConsentMap == null || !measurementConsentMap.containsKey("measurementConsent")) {
            result.error("0", "Arguments null or wrong (missing argument of 'trackMeasurementConsent' method.", null)
            return
        }

        val measurementConsent = measurementConsentMap["measurementConsent"] as Boolean
        Adjust.trackMeasurementConsent(measurementConsent)
        result.success(null)
    }

    private fun processDeeplink(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val deeplinkMap = call.arguments as? Map<*, *> ?: return

        var adjustDeeplink: AdjustDeeplink? = null
        if (deeplinkMap.containsKey("deeplink")) {
            val deeplink = deeplinkMap["deeplink"] as? String
            adjustDeeplink = AdjustDeeplink(Uri.parse(deeplink))
            if (deeplinkMap.containsKey("referrer")) {
                val referrer = deeplinkMap["referrer"] as? String
                adjustDeeplink.setReferrer(Uri.parse(referrer))
            }
        }

        Adjust.processDeeplink(adjustDeeplink, applicationContext)
        result.success(null)
    }

    private fun processAndResolveDeeplink(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val deeplinkMap = call.arguments as? Map<*, *> ?: return

        var adjustDeeplink: AdjustDeeplink? = null
        if (deeplinkMap.containsKey("deeplink")) {
            val deeplink = deeplinkMap["deeplink"] as? String
            adjustDeeplink = AdjustDeeplink(Uri.parse(deeplink))
            if (deeplinkMap.containsKey("referrer")) {
                val referrer = deeplinkMap["referrer"] as? String
                adjustDeeplink.setReferrer(Uri.parse(referrer))
            }
        }

        Adjust.processAndResolveDeeplink(adjustDeeplink, applicationContext) { resolvedLink ->
            result.success(resolvedLink)
        }
    }

    private fun setPushToken(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val tokenParamsMap = call.arguments as? Map<*, *>
        var pushToken: String? = null
        if (tokenParamsMap != null && tokenParamsMap.containsKey("pushToken")) {
            pushToken = tokenParamsMap["pushToken"].toString()
        }
        Adjust.setPushToken(pushToken, applicationContext)
        result.success(null)
    }

    private fun gdprForgetMe(result: Result) {
        Adjust.gdprForgetMe(applicationContext)
        result.success(null)
    }

    private fun enable(result: Result) {
        Adjust.enable()
        result.success(null)
    }

    private fun disable(result: Result) {
        Adjust.disable()
        result.success(null)
    }

    private fun switchToOfflineMode(result: Result) {
        Adjust.switchToOfflineMode()
        result.success(null)
    }

    private fun switchBackToOnlineMode(result: Result) {
        Adjust.switchBackToOnlineMode()
        result.success(null)
    }

    private fun addGlobalCallbackParameter(call: MethodCall, result: Result) {
        var key: String? = null
        var value: String? = null
        if (call.hasArgument("key") && call.hasArgument("value")) {
            key = call.argument<String>("key")
            value = call.argument<String>("value")
        }
        Adjust.addGlobalCallbackParameter(key, value)
        result.success(null)
    }

    private fun addGlobalPartnerParameter(call: MethodCall, result: Result) {
        var key: String? = null
        var value: String? = null
        if (call.hasArgument("key") && call.hasArgument("value")) {
            key = call.argument<String>("key")
            value = call.argument<String>("value")
        }
        Adjust.addGlobalPartnerParameter(key, value)
        result.success(null)
    }

    private fun removeGlobalCallbackParameter(call: MethodCall, result: Result) {
        var key: String? = null
        if (call.hasArgument("key")) {
            key = call.argument<String>("key")
        }
        Adjust.removeGlobalCallbackParameter(key)
        result.success(null)
    }

    private fun removeGlobalPartnerParameter(call: MethodCall, result: Result) {
        var key: String? = null
        if (call.hasArgument("key")) {
            key = call.argument<String>("key")
        }
        Adjust.removeGlobalPartnerParameter(key)
        result.success(null)
    }

    private fun removeGlobalCallbackParameters(result: Result) {
        Adjust.removeGlobalCallbackParameters()
        result.success(null)
    }

    private fun removeGlobalPartnerParameters(result: Result) {
        Adjust.removeGlobalPartnerParameters()
        result.success(null)
    }

    @Suppress("UNUSED_PARAMETER")
    private fun endFirstSessionDelay(call: MethodCall, result: Result) {
        Adjust.endFirstSessionDelay()
        result.success(null)
    }

    @Suppress("UNUSED_PARAMETER")
    private fun enableCoppaComplianceInDelay(call: MethodCall, result: Result) {
        Adjust.enableCoppaComplianceInDelay()
        result.success(null)
    }

    @Suppress("UNUSED_PARAMETER")
    private fun disableCoppaComplianceInDelay(call: MethodCall, result: Result) {
        Adjust.disableCoppaComplianceInDelay()
        result.success(null)
    }

    @Suppress("UNUSED_PARAMETER")
    private fun enablePlayStoreKidsComplianceInDelay(call: MethodCall, result: Result) {
        Adjust.enablePlayStoreKidsComplianceInDelay()
        result.success(null)
    }

    @Suppress("UNUSED_PARAMETER")
    private fun disablePlayStoreKidsComplianceInDelay(call: MethodCall, result: Result) {
        Adjust.disablePlayStoreKidsComplianceInDelay()
        result.success(null)
    }

    private fun setExternalDeviceIdInDelay(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val externalDeviceMap = call.arguments as? Map<*, *>
        var externalDeviceId: String? = null
        if (externalDeviceMap != null && externalDeviceMap.containsKey("externalDeviceId")) {
            externalDeviceId = externalDeviceMap["externalDeviceId"].toString()
        }
        Adjust.setExternalDeviceIdInDelay(externalDeviceId)
        result.success(null)
    }

    private fun isEnabled(result: Result) {
        Adjust.isEnabled(applicationContext) { isEnabled ->
            result.success(isEnabled)
        }
    }

    private fun getAdid(result: Result) {
        Adjust.getAdid { adid ->
            result.success(adid)
        }
    }

    private fun getAdidWithTimeout(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val timeoutMap = call.arguments as? Map<*, *>
        if (timeoutMap == null || !timeoutMap.containsKey("timeoutInMilliseconds")) {
            result.error("INVALID_ARGUMENT", "timeoutInMilliseconds is required", null)
            return
        }

        val timeoutInMilliseconds: Long
        try {
            timeoutInMilliseconds = timeoutMap["timeoutInMilliseconds"].toString().toLong()
        } catch (e: NumberFormatException) {
            result.error("INVALID_ARGUMENT", "timeoutInMilliseconds must be a valid number", null)
            return
        }

        Adjust.getAdidWithTimeout(applicationContext, timeoutInMilliseconds) { adid ->
            result.success(adid)
        }
    }

    private fun getAttribution(result: Result) {
        Adjust.getAttribution { attribution ->
            val adjustAttributionMap = AdjustSdkMappers.attributionToMap(attribution)
            result.success(adjustAttributionMap)
        }
    }

    private fun getAttributionWithTimeout(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val timeoutMap = call.arguments as? Map<*, *>
        if (timeoutMap == null || !timeoutMap.containsKey("timeoutInMilliseconds")) {
            result.error("INVALID_ARGUMENT", "timeoutInMilliseconds is required", null)
            return
        }

        val timeoutInMilliseconds: Long
        try {
            timeoutInMilliseconds = timeoutMap["timeoutInMilliseconds"].toString().toLong()
        } catch (e: NumberFormatException) {
            result.error("INVALID_ARGUMENT", "timeoutInMilliseconds must be a valid number", null)
            return
        }

        Adjust.getAttributionWithTimeout(applicationContext, timeoutInMilliseconds) { attribution ->
            if (attribution == null) {
                result.success(null)
                return@getAttributionWithTimeout
            }
            val adjustAttributionMap = AdjustSdkMappers.attributionToMap(attribution)
            result.success(adjustAttributionMap)
        }
    }

    private fun getThirdPartySharingSettingsWithTimeout(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val timeoutMap = call.arguments as? Map<*, *>
        if (timeoutMap == null || !timeoutMap.containsKey("timeoutInMilliseconds")) {
            result.error("INVALID_ARGUMENT", "timeoutInMilliseconds is required", null)
            return
        }

        val timeoutInMilliseconds: Long
        try {
            timeoutInMilliseconds = timeoutMap["timeoutInMilliseconds"].toString().toLong()
        } catch (e: NumberFormatException) {
            result.error("INVALID_ARGUMENT", "timeoutInMilliseconds must be a valid number", null)
            return
        }

        Adjust.getThirdPartySharingSettingsWithTimeout(applicationContext, timeoutInMilliseconds) { thirdPartySharingResult ->
            if (thirdPartySharingResult == null) {
                result.success(null)
                return@getThirdPartySharingSettingsWithTimeout
            }
            result.success(AdjustSdkMappers.thirdPartySharingResultToMap(thirdPartySharingResult))
        }
    }

    private fun getLastDeeplink(result: Result) {
        Adjust.getLastDeeplink(applicationContext) { deeplink ->
            if (deeplink != null) {
                result.success(deeplink.toString())
            } else {
                result.success("")
            }
        }
    }

    private fun getSdkVersion(result: Result) {
        Adjust.getSdkVersion { sdkVersion ->
            result.success(sdkVersion)
        }
    }

    // android only

    private fun trackPlayStoreSubscription(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val subscriptionMap = call.arguments as? Map<*, *> ?: return

        // price
        var price: Long = -1
        if (subscriptionMap.containsKey("price")) {
            try {
                price = subscriptionMap["price"].toString().toLong()
            } catch (_: NumberFormatException) {
            }
        }

        // currency
        var currency: String? = null
        if (subscriptionMap.containsKey("currency")) {
            currency = subscriptionMap["currency"] as? String
        }

        // SKU
        var sku: String? = null
        if (subscriptionMap.containsKey("sku")) {
            sku = subscriptionMap["sku"] as? String
        }

        // order ID
        var orderId: String? = null
        if (subscriptionMap.containsKey("orderId")) {
            orderId = subscriptionMap["orderId"] as? String
        }

        // Signature
        var signature: String? = null
        if (subscriptionMap.containsKey("signature")) {
            signature = subscriptionMap["signature"] as? String
        }

        // purchase token
        var purchaseToken: String? = null
        if (subscriptionMap.containsKey("purchaseToken")) {
            purchaseToken = subscriptionMap["purchaseToken"] as? String
        }

        // create subscription object
        val subscription = AdjustPlayStoreSubscription(
            price,
            currency,
            sku,
            orderId,
            signature,
            purchaseToken
        )

        // purchase time
        if (subscriptionMap.containsKey("purchaseTime")) {
            try {
                val purchaseTime = subscriptionMap["purchaseTime"].toString().toLong()
                subscription.setPurchaseTime(purchaseTime)
            } catch (_: NumberFormatException) {
            }
        }

        // callback parameters
        if (subscriptionMap.containsKey("callbackParameters")) {
            val strCallbackParametersJson = subscriptionMap["callbackParameters"] as? String
            AdjustSdkMappers.parseJsonParameters(strCallbackParametersJson) { key, value ->
                subscription.addCallbackParameter(key, value)
            }
        }

        // partner parameters
        if (subscriptionMap.containsKey("partnerParameters")) {
            val strPartnerParametersJson = subscriptionMap["partnerParameters"] as? String
            AdjustSdkMappers.parseJsonParameters(strPartnerParametersJson) { key, value ->
                subscription.addPartnerParameter(key, value)
            }
        }

        // track subscription
        Adjust.trackPlayStoreSubscription(subscription)
        result.success(null)
    }

    private fun verifyPlayStorePurchase(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val purchaseMap = call.arguments as? Map<*, *> ?: return

        // product ID
        var productId: String? = null
        if (purchaseMap.containsKey("productId")) {
            productId = purchaseMap["productId"] as? String
        }

        // purchase token
        var purchaseToken: String? = null
        if (purchaseMap.containsKey("purchaseToken")) {
            purchaseToken = purchaseMap["purchaseToken"] as? String
        }

        // create purchase instance
        val purchase = AdjustPlayStorePurchase(productId, purchaseToken)

        // verify purchase
        Adjust.verifyPlayStorePurchase(purchase) { verificationResult ->
            val adjustPurchaseMap = AdjustSdkMappers.verificationResultToMap(verificationResult)
            result.success(adjustPurchaseMap)
        }
    }

    private fun verifyAndTrackPlayStorePurchase(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val eventMap = call.arguments as? Map<*, *> ?: return

        val event = AdjustSdkMappers.buildEventFromMap(eventMap)

        // verify and track purchase
        Adjust.verifyAndTrackPlayStorePurchase(event) { verificationResult ->
            val adjustPurchaseMap = AdjustSdkMappers.verificationResultToMap(verificationResult)
            result.success(adjustPurchaseMap)
        }
    }

    private fun getGoogleAdId(result: Result) {
        Adjust.getGoogleAdId(applicationContext) { googleAdId ->
            result.success(googleAdId)
        }
    }

    private fun getAmazonAdId(result: Result) {
        Adjust.getAmazonAdId(applicationContext) { amazonAdId ->
            result.success(amazonAdId)
        }
    }

    // ios only

    @Suppress("UNUSED_PARAMETER")
    private fun trackAppStoreSubscription(result: Result) {
        result.error("non_existing_method", "trackAppStoreSubscription not available on Android platform!", null)
    }

    @Suppress("UNUSED_PARAMETER")
    private fun verifyAppStorePurchase(call: MethodCall, result: Result) {
        result.error("non_existing_method", "verifyAppStorePurchase not available on Android platform!", null)
    }

    @Suppress("UNUSED_PARAMETER")
    private fun verifyAndTrackAppStorePurchase(call: MethodCall, result: Result) {
        result.error("non_existing_method", "verifyAndTrackAppStorePurchase not available on Android platform!", null)
    }

    @Suppress("UNUSED_PARAMETER")
    private fun requestAppTrackingAuthorization(result: Result) {
        result.error("non_existing_method", "requestAppTrackingAuthorization not available on Android platform!", null)
    }

    @Suppress("UNUSED_PARAMETER")
    private fun updateSkanConversionValue(result: Result) {
        result.error("non_existing_method", "updateSkanConversionValue not available on Android platform!", null)
    }

    @Suppress("UNUSED_PARAMETER")
    private fun getIdfa(result: Result) {
        result.error("non_existing_method", "getIdfa not available on Android platform!", null)
    }

    @Suppress("UNUSED_PARAMETER")
    private fun getIdfv(result: Result) {
        result.error("non_existing_method", "getIdfv not available on Android platform!", null)
    }

    @Suppress("UNUSED_PARAMETER")
    private fun getAppTrackingAuthorizationStatus(call: MethodCall, result: Result) {
        result.error("non_existing_method", "getAppTrackingAuthorizationStatus not available on Android platform!", null)
    }

    // testing only

    private fun onResume(result: Result) {
        Adjust.onResume()
        result.success(null)
    }

    private fun onPause(result: Result) {
        Adjust.onPause()
        result.success(null)
    }

    private fun setTestOptions(call: MethodCall, result: Result) {
        val testOptions = AdjustTestOptions()
        @Suppress("UNCHECKED_CAST")
        val testOptionsMap = call.arguments as? Map<*, *> ?: return

        if (testOptionsMap.containsKey("baseUrl")) {
            testOptions.baseUrl = testOptionsMap["baseUrl"] as? String
        }
        if (testOptionsMap.containsKey("gdprUrl")) {
            testOptions.gdprUrl = testOptionsMap["gdprUrl"] as? String
        }
        if (testOptionsMap.containsKey("subscriptionUrl")) {
            testOptions.subscriptionUrl = testOptionsMap["subscriptionUrl"] as? String
        }
        if (testOptionsMap.containsKey("purchaseVerificationUrl")) {
            testOptions.purchaseVerificationUrl = testOptionsMap["purchaseVerificationUrl"] as? String
        }
        if (testOptionsMap.containsKey("basePath")) {
            testOptions.basePath = testOptionsMap["basePath"] as? String
        }
        if (testOptionsMap.containsKey("gdprPath")) {
            testOptions.gdprPath = testOptionsMap["gdprPath"] as? String
        }
        if (testOptionsMap.containsKey("subscriptionPath")) {
            testOptions.subscriptionPath = testOptionsMap["subscriptionPath"] as? String
        }
        if (testOptionsMap.containsKey("purchaseVerificationPath")) {
            testOptions.purchaseVerificationPath = testOptionsMap["purchaseVerificationPath"] as? String
        }
        if (testOptionsMap.containsKey("noBackoffWait")) {
            testOptions.noBackoffWait = testOptionsMap["noBackoffWait"].toString() == "true"
        }
        if (testOptionsMap.containsKey("teardown")) {
            testOptions.teardown = testOptionsMap["teardown"].toString() == "true"
        }
        if (testOptionsMap.containsKey("tryInstallReferrer")) {
            testOptions.tryInstallReferrer = testOptionsMap["tryInstallReferrer"].toString() == "true"
        }
        if (testOptionsMap.containsKey("timerIntervalInMilliseconds")) {
            testOptions.timerIntervalInMilliseconds = testOptionsMap["timerIntervalInMilliseconds"].toString().toLong()
        }
        if (testOptionsMap.containsKey("timerStartInMilliseconds")) {
            testOptions.timerStartInMilliseconds = testOptionsMap["timerStartInMilliseconds"].toString().toLong()
        }
        if (testOptionsMap.containsKey("sessionIntervalInMilliseconds")) {
            testOptions.sessionIntervalInMilliseconds = testOptionsMap["sessionIntervalInMilliseconds"].toString().toLong()
        }
        if (testOptionsMap.containsKey("subsessionIntervalInMilliseconds")) {
            testOptions.subsessionIntervalInMilliseconds = testOptionsMap["subsessionIntervalInMilliseconds"].toString().toLong()
        }
        if (testOptionsMap.containsKey("deleteState")) {
            testOptions.context = applicationContext
        }
        if (testOptionsMap.containsKey("ignoreSystemLifecycleBootstrap")) {
            testOptions.ignoreSystemLifecycleBootstrap = testOptionsMap["ignoreSystemLifecycleBootstrap"].toString() == "true"
        }

        Adjust.setTestOptions(testOptions)
    }
}
