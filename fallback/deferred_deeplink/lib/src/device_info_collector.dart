import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Collects device fingerprint data from both Dart and native iOS.
///
/// Dart-side fields are collected directly. iOS-native fields are
/// fetched via the `com.adjust.deferred_deeplink/methods` MethodChannel.
class DeviceInfoCollector {
  /// The MethodChannel shared with the plugin.
  static const MethodChannel _channel = MethodChannel(
    'com.adjust.deferred_deeplink/methods',
  );

  /// Collects all device fingerprint data and returns it as a [Map].
  ///
  /// On non-iOS platforms, only Dart-side fields are populated.
  static Future<Map<String, dynamic>> collect() async {
    final dartInfo = _collectDartInfo();

    Map<String, dynamic> nativeInfo = {};
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android) {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getDeviceInfo',
      );
      nativeInfo = result ?? {};
    }

    return {
      ...dartInfo,
      ...nativeInfo,
    };
  }

  static Map<String, dynamic> _collectDartInfo() {
    final dispatcher = PlatformDispatcher.instance;
    final view = dispatcher.views.first;
    final locale = dispatcher.locale;
    final locales = dispatcher.locales;

    return {
      'screenWidthPx': view.physicalSize.width,
      'screenHeightPx': view.physicalSize.height,
      'devicePixelRatio': view.devicePixelRatio,
      'screenWidthDp': view.physicalSize.width / view.devicePixelRatio,
      'screenHeightDp': view.physicalSize.height / view.devicePixelRatio,
      'platform': defaultTargetPlatform.name,
      'locale': locale.toString(),
      'languageCode': locale.languageCode,
      'countryCode': locale.countryCode,
      'preferredLocales': locales.map((l) => l.toString()).toList(),
      'textScaleFactor': dispatcher.textScaleFactor,
      'deviceTimestamp': DateTime.now().toUtc().toIso8601String(),
      'deviceLocalTimestamp': DateTime.now().toIso8601String(),

      // -- Accessibility --
      'accessibleNavigation': dispatcher.accessibilityFeatures.accessibleNavigation,
      'boldText': dispatcher.accessibilityFeatures.boldText,
      'highContrast': dispatcher.accessibilityFeatures.highContrast,
      'reduceMotion': dispatcher.accessibilityFeatures.reduceMotion,
      'disableAnimations': dispatcher.accessibilityFeatures.disableAnimations,
      'invertColors': dispatcher.accessibilityFeatures.invertColors,
      'semanticsEnabled': dispatcher.semanticsEnabled,
      'alwaysUse24HourFormat': dispatcher.alwaysUse24HourFormat,

      // -- Platform brightness --
      'platformBrightness': dispatcher.platformBrightness.name,

      // -- View insets (notch / safe area) --
      'viewPaddingTop': view.viewPadding.top / view.devicePixelRatio,
      'viewPaddingBottom': view.viewPadding.bottom / view.devicePixelRatio,
      'viewPaddingLeft': view.viewPadding.left / view.devicePixelRatio,
      'viewPaddingRight': view.viewPadding.right / view.devicePixelRatio,
    };
  }

  /// Returns the collected info as a JSON-encoded string.
  static Future<String> collectAsJson() async {
    final info = await collect();
    return jsonEncode(info);
  }
}
