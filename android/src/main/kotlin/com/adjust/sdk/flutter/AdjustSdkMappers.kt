//
//  AdjustSdkMappers.kt
//  Adjust SDK
//
//  Copyright (c) 2018-Present Adjust GmbH. All rights reserved.
//

package com.adjust.sdk.flutter

import android.util.Log
import com.adjust.sdk.AdjustAttribution
import com.adjust.sdk.AdjustEvent
import com.adjust.sdk.AdjustPurchaseVerificationResult
import com.adjust.sdk.AdjustRemoteTrigger
import com.adjust.sdk.AdjustThirdPartySharingResult
import org.json.JSONException
import org.json.JSONObject

object AdjustSdkMappers {

    private const val TAG = "AdjustBridge"

    fun buildEventFromMap(eventMap: Map<*, *>): AdjustEvent {
        // event token
        val eventToken = eventMap["eventToken"] as? String

        // create event object
        val event = AdjustEvent(eventToken)

        // revenue and currency
        if (eventMap.containsKey("revenue") || eventMap.containsKey("currency")) {
            var revenue = -1.0
            val strRevenue = eventMap["revenue"] as? String
            try {
                revenue = strRevenue?.toDouble() ?: -1.0
            } catch (_: NumberFormatException) {
            }
            val currency = eventMap["currency"] as? String
            event.setRevenue(revenue, currency)
        }

        // event deduplication
        if (eventMap.containsKey("deduplicationId")) {
            val deduplicationId = eventMap["deduplicationId"] as? String
            event.setDeduplicationId(deduplicationId)
        }

        // product ID
        if (eventMap.containsKey("productId")) {
            val productId = eventMap["productId"] as? String
            event.setProductId(productId)
        }

        // purchase token
        if (eventMap.containsKey("purchaseToken")) {
            val purchaseToken = eventMap["purchaseToken"] as? String
            event.setPurchaseToken(purchaseToken)
        }

        // callback ID
        if (eventMap.containsKey("callbackId")) {
            val callbackId = eventMap["callbackId"] as? String
            event.setCallbackId(callbackId)
        }

        // callback parameters
        if (eventMap.containsKey("callbackParameters")) {
            val strCallbackParametersJson = eventMap["callbackParameters"] as? String
            parseJsonParameters(strCallbackParametersJson) { key, value ->
                event.addCallbackParameter(key, value)
            }
        }

        // partner parameters
        if (eventMap.containsKey("partnerParameters")) {
            val strPartnerParametersJson = eventMap["partnerParameters"] as? String
            parseJsonParameters(strPartnerParametersJson) { key, value ->
                event.addPartnerParameter(key, value)
            }
        }

        return event
    }

    fun attributionToMap(attribution: AdjustAttribution): HashMap<String, String> {
        val adjustAttributionMap = HashMap<String, String>()
        adjustAttributionMap["trackerToken"] = attribution.trackerToken ?: ""
        adjustAttributionMap["trackerName"] = attribution.trackerName ?: ""
        adjustAttributionMap["network"] = attribution.network ?: ""
        adjustAttributionMap["campaign"] = attribution.campaign ?: ""
        adjustAttributionMap["adgroup"] = attribution.adgroup ?: ""
        adjustAttributionMap["creative"] = attribution.creative ?: ""
        adjustAttributionMap["clickLabel"] = attribution.clickLabel ?: ""
        adjustAttributionMap["costType"] = attribution.costType ?: ""
        adjustAttributionMap["costAmount"] = attribution.costAmount?.toString() ?: ""
        adjustAttributionMap["costCurrency"] = attribution.costCurrency ?: ""
        adjustAttributionMap["fbInstallReferrer"] = attribution.fbInstallReferrer ?: ""
        if (attribution.jsonResponse != null) {
            adjustAttributionMap["jsonResponse"] = attribution.jsonResponse
        }
        return adjustAttributionMap
    }

    fun verificationResultToMap(result: AdjustPurchaseVerificationResult): HashMap<String, String> {
        val map = HashMap<String, String>()
        map["code"] = result.code.toString()
        map["verificationStatus"] = result.verificationStatus
        map["message"] = result.message
        return map
    }

    fun remoteTriggerToMap(remoteTrigger: AdjustRemoteTrigger): HashMap<String, String> {
        val map = HashMap<String, String>()
        map["label"] = remoteTrigger.label ?: ""
        map["payloadJson"] = remoteTrigger.payload?.toString() ?: "{}"
        return map
    }

    fun thirdPartySharingResultToMap(result: AdjustThirdPartySharingResult): HashMap<String, String> {
        val map = HashMap<String, String>()
        map["thirdPartySharingSettingsJson"] = result.thirdPartySharingSettingsJson ?: "{}"
        return map
    }

    fun parseJsonParameters(jsonString: String?, addParam: (String, String) -> Unit) {
        if (jsonString == null) return
        try {
            val jsonObject = JSONObject(jsonString)
            val keys = jsonObject.names() ?: return
            for (i in 0 until keys.length()) {
                val key = keys.getString(i)
                val value = jsonObject.getString(key)
                addParam(key, value)
            }
        } catch (e: JSONException) {
            Log.e(TAG, "Failed to parse JSON parameters! Details: $e")
        }
    }
}
