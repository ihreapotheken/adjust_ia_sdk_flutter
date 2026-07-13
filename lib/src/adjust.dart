import 'dart:async';

import 'package:adjust_ia_sdk_flutter/src/models/adjust_ad_revenue.dart';
import 'package:adjust_ia_sdk_flutter/src/models/adjust_app_store_subscription.dart';
import 'package:adjust_ia_sdk_flutter/src/models/adjust_app_store_purchase.dart';
import 'package:adjust_ia_sdk_flutter/src/models/responses/adjust_attribution.dart';
import 'package:adjust_ia_sdk_flutter/src/config/adjust_config.dart';
import 'package:adjust_ia_sdk_flutter/src/models/adjust_event.dart';
import 'package:adjust_ia_sdk_flutter/src/models/adjust_play_store_purchase.dart';
import 'package:adjust_ia_sdk_flutter/src/models/adjust_play_store_subscription.dart';
import 'package:adjust_ia_sdk_flutter/src/models/responses/adjust_purchase_verification_result.dart';
import 'package:adjust_ia_sdk_flutter/src/models/responses/adjust_third_party_sharing_result.dart';
import 'package:adjust_ia_sdk_flutter/src/models/adjust_third_party_sharing.dart';
import 'package:adjust_ia_sdk_flutter/src/models/adjust_deeplink.dart';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

/// The main entry point for the Adjust Flutter SDK.
///
/// All methods are static and communicate with the native Adjust SDK on iOS
/// and Android via a Flutter platform channel.
///
/// **Basic usage:**
/// ```dart
/// final config = AdjustConfig('YourAppToken', AdjustEnvironment.production);
/// Adjust.initSdk(config);
/// ```
class Adjust {
  static const _sdkPrefix = 'flutter5.5.0';
  static const _channel = MethodChannel('com.adjust.sdk/api');

  /// Initialises the Adjust SDK with the provided [config].
  ///
  /// Must be called once, as early as possible in the app lifecycle (e.g. in
  /// `main()` or inside the first `initState`). Calling this method more than
  /// once has no effect.
  ///
  /// ```dart
  /// final config = AdjustConfig('YourAppToken', AdjustEnvironment.production);
  /// Adjust.initSdk(config);
  /// ```
  static void initSdk(AdjustConfig config) {
    config.sdkPrefix = _sdkPrefix;
    _channel.invokeMethod(
      'initSdk',
      config.toMap,
    );
  }

  /// Tracks an event defined by the [event] object.
  ///
  /// Create an [AdjustEvent] with the event token from your Adjust dashboard
  /// and optionally attach revenue, callback parameters, or partner parameters
  /// before calling this method.
  ///
  /// ```dart
  /// final event = AdjustEvent('abc123');
  /// event.setRevenue(9.99, 'USD');
  /// Adjust.trackEvent(event);
  /// ```
  static void trackEvent(AdjustEvent event) {
    _channel.invokeMethod(
      'trackEvent',
      event.toMap,
    );
  }

  /// Tracks ad revenue using the provided [adRevenue] object.
  ///
  /// Use [AdjustAdRevenue] to specify the ad revenue source and optionally
  /// set revenue amount, impression count, network, unit, and placement.
  static void trackAdRevenue(AdjustAdRevenue adRevenue) {
    _channel.invokeMethod(
      'trackAdRevenue',
      adRevenue.toMap,
    );
  }

  /// Sends a third-party sharing decision to Adjust.
  ///
  /// Use [AdjustThirdPartySharing] to specify whether data sharing with
  /// third parties is enabled, and to add granular options or partner-level
  /// sharing settings.
  static void trackThirdPartySharing(AdjustThirdPartySharing thirdPartySharing) {
    _channel.invokeMethod(
      'trackThirdPartySharing',
      thirdPartySharing.toMap,
    );
  }

  /// Communicates the user's measurement consent to Adjust.
  ///
  /// Pass `true` when the user consents to data measurement, or `false` to
  /// withdraw consent. This affects whether Adjust collects and processes
  /// measurement data for this device.
  static void trackMeasurementConsent(
    bool measurementConsent,
  ) {
    _channel.invokeMethod(
      'trackMeasurementConsent',
      {
        'measurementConsent': measurementConsent,
      },
    );
  }

  /// Sends the provided [deeplink] to Adjust for processing.
  ///
  /// Call this method when your app receives a deeplink URL so that Adjust
  /// can attribute it and trigger any related deferred-deeplink callbacks.
  /// Use [processAndResolveDeeplink] if you need the resolved URL returned.
  static void processDeeplink(
    AdjustDeeplink deeplink,
  ) {
    _channel.invokeMethod(
      'processDeeplink',
      deeplink.toMap,
    );
  }

  /// Sends the provided [deeplink] to Adjust for processing and returns the
  /// resolved URL string.
  ///
  /// Returns the resolved deeplink URL, or `null` if Adjust was unable to
  /// resolve the link. Use [processDeeplink] if you don't need the resolved
  /// URL.
  static Future<String?> processAndResolveDeeplink(
    AdjustDeeplink deeplink,
  ) async {
    final resolvedLink = await _channel.invokeMethod(
      'processAndResolveDeeplink',
      deeplink.toMap,
    );
    return resolvedLink;
  }

  /// Sets the device push notification [token] on the Adjust SDK.
  ///
  /// Call this method whenever your app receives a new push token so that
  /// Adjust can use it for uninstall and reinstall measurement.
  static void setPushToken(String token) {
    _channel.invokeMethod(
      'setPushToken',
      {
        'pushToken': token,
      },
    );
  }

  /// Sends a GDPR "forget me" request for the current user to Adjust.
  ///
  /// Once called, the Adjust SDK will stop all activity for this device and
  /// will not send any further data to Adjust servers. This action is
  /// irreversible for the current install.
  static void gdprForgetMe() {
    _channel.invokeMethod(
      'gdprForgetMe',
    );
  }

  /// Enables the Adjust SDK after it has been disabled.
  ///
  /// The SDK is enabled by default. Call this only after a prior call to
  /// [disable].
  static void enable() {
    _channel.invokeMethod(
      'enable',
    );
  }

  /// Disables the Adjust SDK.
  ///
  /// When disabled, the SDK stops all tracking activity. Call [enable] to
  /// resume tracking. Use this to honour a user's opt-out preference.
  static void disable() {
    _channel.invokeMethod(
      'disable',
    );
  }

  /// Switches the Adjust SDK to offline mode.
  ///
  /// While in offline mode, the SDK continues to record events locally but
  /// does not send any data to Adjust servers. Call [switchBackToOnlineMode]
  /// to resume sending.
  static void switchToOfflineMode() {
    _channel.invokeMethod(
      'switchToOfflineMode',
    );
  }

  /// Switches the Adjust SDK back to online mode after [switchToOfflineMode]
  /// was called.
  ///
  /// Any data that was recorded while offline will be sent to Adjust servers.
  static void switchBackToOnlineMode() {
    _channel.invokeMethod(
      'switchBackToOnlineMode',
    );
  }

  /// Adds a global callback parameter that will be appended to every event
  /// and session sent to Adjust.
  ///
  /// The [key]-[value] pair is included in every callback URL sent to your
  /// server. Call [removeGlobalCallbackParameter] or
  /// [removeGlobalCallbackParameters] to remove them later.
  static void addGlobalCallbackParameter(
    String key,
    String value,
  ) {
    _channel.invokeMethod(
      'addGlobalCallbackParameter',
      {
        'key': key,
        'value': value,
      },
    );
  }

  /// Adds a global partner parameter that will be appended to every event
  /// and session sent to Adjust.
  ///
  /// The [key]-[value] pair is forwarded to all enabled partner integrations.
  /// Call [removeGlobalPartnerParameter] or [removeGlobalPartnerParameters]
  /// to remove them later.
  static void addGlobalPartnerParameter(
    String key,
    String value,
  ) {
    _channel.invokeMethod(
      'addGlobalPartnerParameter',
      {
        'key': key,
        'value': value,
      },
    );
  }

  /// Removes the global callback parameter identified by [key].
  ///
  /// Has no effect if the [key] was never added.
  static void removeGlobalCallbackParameter(
    String key,
  ) {
    _channel.invokeMethod(
      'removeGlobalCallbackParameter',
      {
        'key': key,
      },
    );
  }

  /// Removes the global partner parameter identified by [key].
  ///
  /// Has no effect if the [key] was never added.
  static void removeGlobalPartnerParameter(
    String key,
  ) {
    _channel.invokeMethod(
      'removeGlobalPartnerParameter',
      {
        'key': key,
      },
    );
  }

  /// Removes all global callback parameters that were previously added via
  /// [addGlobalCallbackParameter].
  static void removeGlobalCallbackParameters() {
    _channel.invokeMethod(
      'removeGlobalCallbackParameters',
    );
  }

  /// Removes all global partner parameters that were previously added via
  /// [addGlobalPartnerParameter].
  static void removeGlobalPartnerParameters() {
    _channel.invokeMethod(
      'removeGlobalPartnerParameters',
    );
  }

  /// Ends the first-session delay that was enabled via
  /// [AdjustConfig.isFirstSessionDelayEnabled].
  ///
  /// Call this after you have finished configuring any properties that must be
  /// set before the first session is sent (e.g. external device ID, COPPA
  /// compliance). Once called the SDK sends the delayed first session
  /// immediately.
  static void endFirstSessionDelay() {
    _channel.invokeMethod(
      'endFirstSessionDelay',
    );
  }

  /// Enables COPPA compliance during the first-session delay window.
  ///
  /// Must be called before [endFirstSessionDelay]. Has no effect if
  /// [AdjustConfig.isFirstSessionDelayEnabled] was not set to `true`.
  static void enableCoppaComplianceInDelay() {
    _channel.invokeMethod(
      'enableCoppaComplianceInDelay',
    );
  }

  /// Disables COPPA compliance during the first-session delay window.
  ///
  /// Must be called before [endFirstSessionDelay]. Has no effect if
  /// [AdjustConfig.isFirstSessionDelayEnabled] was not set to `true`.
  static void disableCoppaComplianceInDelay() {
    _channel.invokeMethod(
      'disableCoppaComplianceInDelay',
    );
  }

  /// Sets the external device ID during the first-session delay window.
  ///
  /// The [externalDeviceId] is a custom identifier you can assign to a device.
  /// Must be called before [endFirstSessionDelay]. Has no effect if
  /// [AdjustConfig.isFirstSessionDelayEnabled] was not set to `true`.
  static void setExternalDeviceIdInDelay(
    String externalDeviceId,
  ) {
    _channel.invokeMethod(
      'setExternalDeviceIdInDelay',
      {
        'externalDeviceId': externalDeviceId,
      },
    );
  }

  /// Returns whether the Adjust SDK is currently enabled.
  ///
  /// Returns `true` if the SDK is enabled, `false` if it has been disabled via
  /// [disable].
  static Future<bool> isEnabled() async {
    final bool isEnabled = await _channel.invokeMethod(
      'isEnabled',
    );
    return isEnabled;
  }

  /// Returns the Adjust device identifier (ADID) for the current device.
  ///
  /// Returns `null` if the ADID is not yet available (e.g. before the first
  /// session has been sent). Use [getAdidWithTimeout] to wait up to a given
  /// duration for the value to become available.
  static Future<String?> getAdid() async {
    final String? adid = await _channel.invokeMethod(
      'getAdid',
    );
    return adid;
  }

  /// Returns the Adjust device identifier (ADID), waiting up to
  /// [timeoutInMilliseconds] milliseconds for it to become available.
  ///
  /// Returns `null` if the ADID is still not available after the timeout
  /// elapses. Use [getAdid] if you do not need to wait.
  static Future<String?> getAdidWithTimeout(
    int timeoutInMilliseconds,
  ) async {
    final String? adid = await _channel.invokeMethod(
      'getAdidWithTimeout',
      {
        'timeoutInMilliseconds': timeoutInMilliseconds,
      },
    );
    return adid;
  }

  /// Returns the current attribution information for the device.
  ///
  /// The returned [AdjustAttribution] object contains tracker token, network,
  /// campaign, ad group, creative, and optional cost data. Use
  /// [getAttributionWithTimeout] to wait up to a given duration for the value
  /// to become available.
  static Future<AdjustAttribution> getAttribution() async {
    final dynamic attributionMap = await _channel.invokeMethod(
      'getAttribution',
    );
    return AdjustAttribution.fromMap(attributionMap);
  }

  /// Returns the current attribution information, waiting up to
  /// [timeoutInMilliseconds] milliseconds for it to become available.
  ///
  /// Returns `null` if attribution is still not available after the timeout
  /// elapses. Use [getAttribution] if you do not need to wait.
  static Future<AdjustAttribution?> getAttributionWithTimeout(
    int timeoutInMilliseconds,
  ) async {
    final dynamic attributionMap = await _channel.invokeMethod(
      'getAttributionWithTimeout',
      {
        'timeoutInMilliseconds': timeoutInMilliseconds,
      },
    );
    if (attributionMap == null) {
      return null;
    }
    return AdjustAttribution.fromMap(attributionMap);
  }

  /// Returns the last deeplink URL that was processed by the Adjust SDK.
  ///
  /// Returns `null` if no deeplink has been processed yet.
  static Future<String?> getLastDeeplink() async {
    final String? deeplink = await _channel.invokeMethod(
      'getLastDeeplink',
    );
    return deeplink;
  }

  /// Returns the current third-party-sharing settings, waiting up to
  /// [timeoutInMilliseconds] milliseconds for them to become available.
  ///
  /// Returns `null` if the settings are still not available after the
  /// timeout elapses.
  static Future<AdjustThirdPartySharingResult?> getThirdPartySharingSettingsWithTimeout(
    int timeoutInMilliseconds,
  ) async {
    final dynamic thirdPartySharingResultMap = await _channel.invokeMethod(
      'getThirdPartySharingSettingsWithTimeout',
      {
        'timeoutInMilliseconds': timeoutInMilliseconds,
      },
    );
    if (thirdPartySharingResultMap == null) {
      return null;
    }
    return AdjustThirdPartySharingResult.fromMap(thirdPartySharingResultMap);
  }

  /// Returns the full SDK version string, including the Flutter SDK prefix.
  ///
  /// The format is `flutter<version>@<native-version>`, e.g.
  /// `flutter5.5.0@5.5.0`.
  static Future<String> getSdkVersion() async {
    final String sdkVersion = await _channel.invokeMethod(
      'getSdkVersion',
    );
    return _sdkPrefix + '@' + sdkVersion;
  }

  // ios only

  /// Tracks an App Store subscription defined by the [subscription] object.
  ///
  /// **iOS only.** Use [AdjustAppStoreSubscription] to provide the price,
  /// currency, and transaction ID of the subscription purchase.
  static void trackAppStoreSubscription(
    AdjustAppStoreSubscription subscription,
  ) {
    _channel.invokeMethod(
      'trackAppStoreSubscription',
      subscription.toMap,
    );
  }

  /// Verifies an App Store in-app purchase with Adjust.
  ///
  /// **iOS only.** Returns an [AdjustPurchaseVerificationResult] containing
  /// the verification status and a descriptive message, or `null` if
  /// verification could not be performed.
  static Future<AdjustPurchaseVerificationResult?> verifyAppStorePurchase(
    AdjustAppStorePurchase purchase,
  ) async {
    final dynamic appStorePurchaseMap = await _channel.invokeMethod(
      'verifyAppStorePurchase',
      purchase.toMap,
    );
    return AdjustPurchaseVerificationResult.fromMap(appStorePurchaseMap);
  }

  /// Verifies an App Store in-app purchase and tracks the associated [event]
  /// if verification succeeds.
  ///
  /// **iOS only.** Combines purchase verification and event tracking into a
  /// single call. Returns an [AdjustPurchaseVerificationResult] with the
  /// outcome, or `null` if verification could not be performed.
  static Future<AdjustPurchaseVerificationResult?> verifyAndTrackAppStorePurchase(
    AdjustEvent event,
  ) async {
    final dynamic appStorePurchaseMap = await _channel.invokeMethod(
      'verifyAndTrackAppStorePurchase',
      event.toMap,
    );
    return AdjustPurchaseVerificationResult.fromMap(appStorePurchaseMap);
  }

  /// Requests App Tracking Transparency authorisation from the user.
  ///
  /// **iOS only.** Presents the ATT authorisation dialog and returns the
  /// resulting status as a numeric value:
  /// - `0` – Not determined
  /// - `1` – Restricted
  /// - `2` – Denied
  /// - `3` – Authorised
  static Future<num> requestAppTrackingAuthorization() async {
    final num status = await _channel.invokeMethod(
      'requestAppTrackingAuthorization',
    );
    return status;
  }

  /// Updates the SKAdNetwork conversion value for the current user.
  ///
  /// **iOS only.** The [conversionValue] must be between 0 and 63. The
  /// [coarseValue] should be one of `'low'`, `'medium'`, or `'high'`. Set
  /// [lockWindow] to `true` to lock the postback window.
  ///
  /// Returns an error message string if the update failed, or `null` on
  /// success.
  static Future<String?> updateSkanConversionValue(
    int conversionValue,
    String coarseValue,
    bool lockWindow,
  ) async {
    final String? error = await _channel.invokeMethod('updateSkanConversionValue', {
      'conversionValue': conversionValue,
      'coarseValue': coarseValue,
      'lockWindow': lockWindow,
    });
    return error;
  }

  /// Returns the device's Identifier for Advertisers (IDFA).
  ///
  /// **iOS only.** Returns `null` if the IDFA is not available (e.g. the user
  /// has limited ad tracking or ATT authorisation has not been granted).
  static Future<String?> getIdfa() async {
    final String? idfa = await _channel.invokeMethod('getIdfa');
    return idfa;
  }

  /// Returns the device's Identifier for Vendors (IDFV).
  ///
  /// **iOS only.** Returns `null` if the IDFV cannot be retrieved.
  static Future<String?> getIdfv() async {
    final String? idfv = await _channel.invokeMethod('getIdfv');
    return idfv;
  }

  /// Returns the current App Tracking Transparency authorisation status.
  ///
  /// **iOS only.** Returns an integer status code:
  /// - `0` – Not determined
  /// - `1` – Restricted
  /// - `2` – Denied
  /// - `3` – Authorised
  static Future<int> getAppTrackingAuthorizationStatus() async {
    final int authorizationStatus = await _channel.invokeMethod('getAppTrackingAuthorizationStatus');
    return authorizationStatus;
  }

  // android only

  /// Tracks a Play Store subscription defined by the [subscription] object.
  ///
  /// **Android only.** Use [AdjustPlayStoreSubscription] to provide the price,
  /// currency, SKU, order ID, signature, and purchase token of the
  /// subscription.
  static void trackPlayStoreSubscription(
    AdjustPlayStoreSubscription subscription,
  ) {
    _channel.invokeMethod('trackPlayStoreSubscription', subscription.toMap);
  }

  /// Verifies a Play Store in-app purchase with Adjust.
  ///
  /// **Android only.** Returns an [AdjustPurchaseVerificationResult]
  /// containing the verification status and a descriptive message, or `null`
  /// if verification could not be performed.
  static Future<AdjustPurchaseVerificationResult?> verifyPlayStorePurchase(
    AdjustPlayStorePurchase purchase,
  ) async {
    final dynamic playStorePurchaseMap = await _channel.invokeMethod('verifyPlayStorePurchase', purchase.toMap);
    return AdjustPurchaseVerificationResult.fromMap(playStorePurchaseMap);
  }

  /// Verifies a Play Store in-app purchase and tracks the associated [event]
  /// if verification succeeds.
  ///
  /// **Android only.** Combines purchase verification and event tracking into
  /// a single call. Returns an [AdjustPurchaseVerificationResult] with the
  /// outcome, or `null` if verification could not be performed.
  static Future<AdjustPurchaseVerificationResult?> verifyAndTrackPlayStorePurchase(
    AdjustEvent event,
  ) async {
    final dynamic playStorePurchaseMap = await _channel.invokeMethod(
      'verifyAndTrackPlayStorePurchase',
      event.toMap,
    );
    return AdjustPurchaseVerificationResult.fromMap(playStorePurchaseMap);
  }

  /// Enables Play Store Kids compliance during the first-session delay window.
  ///
  /// **Android only.** Must be called before [endFirstSessionDelay]. Has no
  /// effect if [AdjustConfig.isFirstSessionDelayEnabled] was not set to
  /// `true`.
  static void enablePlayStoreKidsComplianceInDelay() {
    _channel.invokeMethod(
      'enablePlayStoreKidsComplianceInDelay',
    );
  }

  /// Disables Play Store Kids compliance during the first-session delay window.
  ///
  /// **Android only.** Must be called before [endFirstSessionDelay]. Has no
  /// effect if [AdjustConfig.isFirstSessionDelayEnabled] was not set to
  /// `true`.
  static void disablePlayStoreKidsComplianceInDelay() {
    _channel.invokeMethod(
      'disablePlayStoreKidsComplianceInDelay',
    );
  }

  /// Returns the Amazon Advertising ID for the current device.
  ///
  /// **Android only.** Returns `null` if the Amazon Ad ID is not available.
  static Future<String?> getAmazonAdId() async {
    final String? amazonAdId = await _channel.invokeMethod(
      'getAmazonAdId',
    );
    return amazonAdId;
  }

  /// Returns the Google Advertising ID (GAID) for the current device.
  ///
  /// **Android only.** Returns `null` if the Google Ad ID is not available
  /// (e.g. the user has opted out of ad personalisation).
  static Future<String?> getGoogleAdId() async {
    final String? googleAdId = await _channel.invokeMethod(
      'getGoogleAdId',
    );
    return googleAdId;
  }

  // For testing purposes only, do not use in production!

  /// Simulates the app coming to the foreground.
  ///
  /// **For testing purposes only. Do not use in production.**
  @visibleForTesting
  static void onResume() {
    _channel.invokeMethod('onResume');
  }

  /// Simulates the app going to the background.
  ///
  /// **For testing purposes only. Do not use in production.**
  @visibleForTesting
  static void onPause() {
    _channel.invokeMethod('onPause');
  }

  /// Passes test options to the native Adjust SDK for integration testing.
  ///
  /// **For testing purposes only. Do not use in production.**
  @visibleForTesting
  static void setTestOptions(final dynamic testOptions) {
    _channel.invokeMethod('setTestOptions', testOptions);
  }
}
