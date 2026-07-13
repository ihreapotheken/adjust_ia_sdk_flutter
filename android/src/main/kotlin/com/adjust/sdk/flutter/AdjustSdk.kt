//
//  AdjustSdk.kt
//  Adjust SDK
//
//  Copyright (c) 2018-Present Adjust GmbH. All rights reserved.
//

package com.adjust.sdk.flutter

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry.NewIntentListener

class AdjustSdk : FlutterPlugin, ActivityAware, NewIntentListener {
    private var channel: MethodChannel? = null
    private var methodHandler: AdjustSdkMethodHandler? = null
    private var activityPluginBinding: ActivityPluginBinding? = null
    private var isSdkInitialized = false
    private val cachedDirectDeeplinks = mutableListOf<Map<String, String>>()

    companion object {
        private const val DIRECT_DEEPLINK_CALLBACK_NAME = "adj-direct-deeplink"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.adjust.sdk/api")
        methodHandler = AdjustSdkMethodHandler(binding.applicationContext, channel!!) {
            isSdkInitialized = true
            flushCachedDirectDeeplinks()
        }
        channel!!.setMethodCallHandler(methodHandler)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        detachFromActivity()
        isSdkInitialized = false
        cachedDirectDeeplinks.clear()
        channel?.setMethodCallHandler(null)
        channel = null
        methodHandler = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityPluginBinding = binding
        binding.addOnNewIntentListener(this)
        processDeeplinkFromIntent(binding.activity.intent)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachFromActivity()
    }

    override fun onNewIntent(intent: Intent): Boolean {
        processDeeplinkFromIntent(intent)
        return false
    }

    private fun detachFromActivity() {
        activityPluginBinding?.removeOnNewIntentListener(this)
        activityPluginBinding = null
    }

    private fun processDeeplinkFromIntent(intent: Intent?) {
        val deeplinkUri: Uri = intent?.data ?: return
        dispatchOrCacheDirectDeeplink(deeplinkUri)
    }

    private fun dispatchOrCacheDirectDeeplink(deeplinkUri: Uri) {
        val uriParamsMap = mapOf("deeplink" to deeplinkUri.toString())
        val currentChannel = channel
        if (!isSdkInitialized || currentChannel == null) {
            cachedDirectDeeplinks.add(uriParamsMap)
            return
        }
        currentChannel.invokeMethod(DIRECT_DEEPLINK_CALLBACK_NAME, uriParamsMap)
    }

    private fun flushCachedDirectDeeplinks() {
        val currentChannel = channel
        if (!isSdkInitialized || currentChannel == null || cachedDirectDeeplinks.isEmpty()) {
            return
        }

        cachedDirectDeeplinks.forEach { deeplinkMap ->
            currentChannel.invokeMethod(DIRECT_DEEPLINK_CALLBACK_NAME, deeplinkMap)
        }
        cachedDirectDeeplinks.clear()
    }
}
