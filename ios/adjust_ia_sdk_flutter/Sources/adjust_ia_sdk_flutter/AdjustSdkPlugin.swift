//
//  AdjustSdkPlugin.swift
//  Adjust SDK
//
//  Created by Adjust SDK Team on 20th February 2026.
//  Copyright (c) 2018-Present Adjust GmbH. All rights reserved.
//

import Flutter

@objc(AdjustSdk)
public class AdjustSdkPlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
    private static let directDeeplinkCallbackName = "adj-direct-deeplink"
    private static let launchUrlRepeatWindow: TimeInterval = 10

    private var channel: FlutterMethodChannel?
    private var methodHandler: AdjustSdkMethodHandler?
    private var isSdkInitialized = false
    private var cachedDirectDeeplinks: [[String: String]] = []
    // URLs the app was launched with. iOS can deliver the same URL again through
    // scene(_:openURLContexts:) or scene(_:continue:) shortly after launch.
    private var launchUrls: Set<URL> = []

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
        registrar.addSceneDelegate(instance)
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
        if let url = Self.webpageUrl(of: userActivity) {
            dispatchOrCacheDirectDeeplink(url)
        }
        return false
    }

    // MARK: - Scene lifecycle (direct deeplinks)
    //
    // Apps using the UIScene lifecycle receive URLs through these instead of the
    // app delegate methods above. Return false so other plugins still get them.

    public func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions?
    ) -> Bool {
        guard let connectionOptions = connectionOptions else {
            return false
        }
        let urls = connectionOptions.urlContexts.map { $0.url }
            + connectionOptions.userActivities.compactMap { Self.webpageUrl(of: $0) }
        guard !urls.isEmpty else {
            return false
        }
        for url in urls {
            launchUrls.insert(url)
            dispatchOrCacheDirectDeeplink(url)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.launchUrlRepeatWindow) { [weak self] in
            self?.launchUrls.removeAll()
        }
        return false
    }

    public func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
        for urlContext in URLContexts {
            dispatchUnlessLaunchRepeat(urlContext.url)
        }
        return false
    }

    public func scene(_ scene: UIScene, continue userActivity: NSUserActivity) -> Bool {
        if let url = Self.webpageUrl(of: userActivity) {
            dispatchUnlessLaunchRepeat(url)
        }
        return false
    }

    // MARK: - Private helper methods

    private static func webpageUrl(of userActivity: NSUserActivity) -> URL? {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb else {
            return nil
        }
        return userActivity.webpageURL
    }

    private func dispatchUnlessLaunchRepeat(_ url: URL) {
        if launchUrls.remove(url) != nil {
            return
        }
        dispatchOrCacheDirectDeeplink(url)
    }

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
