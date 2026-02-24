package com.adjust.deferred_deeplink

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class DeferredDeeplinkPlugin : FlutterPlugin, MethodCallHandler {
    private var channel: MethodChannel? = null
    private var collector: DeviceInfoCollector? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.adjust.deferred_deeplink/methods")
        collector = DeviceInfoCollector(binding.applicationContext)
        channel!!.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        collector = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getDeviceInfo" -> {
                val info = collector?.collect() ?: emptyMap()
                result.success(info)
            }
            else -> result.notImplemented()
        }
    }
}
