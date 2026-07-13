//
//  AdjustSdkPlugin.swift
//  Adjust SDK
//
//  Created by Adjust SDK Team on 20th February 2026.
//  Copyright (c) 2018-Present Adjust GmbH. All rights reserved.
//

import Flutter

@objc(AdjustSdk)
public class AdjustSdkPlugin: NSObject, FlutterPlugin {
    private static let directDeeplinkCallbackName = "adj-direct-deeplink"

    private var channel: FlutterMethodChannel?
    private var methodHandler: AdjustSdkMethodHandler?
    private var isSdkInitialized = false
    private var cachedDirectDeeplinks: [[String: String]] = []

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.adjust.sdk/api",
            binaryMessenger: registrar.messenger()
        )
        let instance = AdjustSdkPlugin()
        instance.channel = channel
        instance.methodHandler = AdjustSdkMethodHandler(channel: channel) { [weak instance] in
            instance?.isSdkInitialized = true
            instance?.flushCachedDirectDeeplinks()
        }
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        methodHandler?.handle(call, result: result)
    }

    // MARK: - App lifecycle (direct deeplinks)

    public func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        dispatchOrCacheDirectDeeplink(url)
        return false
    }

    public func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([Any]) -> Void
    ) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
            dispatchOrCacheDirectDeeplink(url)
        }
        return false
    }

    // MARK: - Private helper methods

    private func dispatchOrCacheDirectDeeplink(_ url: URL) {
        let deeplinkMap = ["deeplink": url.absoluteString]
        guard isSdkInitialized, let channel = channel else {
            cachedDirectDeeplinks.append(deeplinkMap)
            return
        }
        channel.invokeMethod(Self.directDeeplinkCallbackName, arguments: deeplinkMap)
    }

    private func flushCachedDirectDeeplinks() {
        guard isSdkInitialized, let channel = channel, !cachedDirectDeeplinks.isEmpty else {
            return
        }

        for deeplinkMap in cachedDirectDeeplinks {
            channel.invokeMethod(Self.directDeeplinkCallbackName, arguments: deeplinkMap)
        }
        cachedDirectDeeplinks.removeAll()
    }
}
