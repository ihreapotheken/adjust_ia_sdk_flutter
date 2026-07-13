import 'dart:convert';

import 'package:adjust_ia_sdk_flutter/src/models/responses/adjust_attribution.dart';
import 'package:adjust_ia_sdk_flutter/src/models/responses/adjust_event_failure.dart';
import 'package:adjust_ia_sdk_flutter/src/models/responses/adjust_event_success.dart';
import 'package:adjust_ia_sdk_flutter/src/models/responses/adjust_remote_trigger.dart';
import 'package:adjust_ia_sdk_flutter/src/models/responses/adjust_session_failure.dart';
import 'package:adjust_ia_sdk_flutter/src/models/responses/adjust_session_success.dart';
import 'package:adjust_ia_sdk_flutter/src/models/responses/adjust_third_party_sharing_result.dart';
import 'package:adjust_ia_sdk_flutter/src/models/adjust_store_info.dart';
import 'package:flutter/services.dart';

/// The verbosity of SDK log output.
enum AdjustLogLevel {
  /// All log messages, including very fine-grained debug output.
  verbose,

  /// Debug-level messages and above.
  debug,

  /// Informational messages and above (default).
  info,

  /// Warning messages and above.
  warn,

  /// Error messages only.
  error,

  /// No log output.
  suppress,
}

/// The environment in which the Adjust SDK is running.
///
/// Use [sandbox] during development and testing, and [production] for
/// App Store / Play Store releases. Attribution data is separated by
/// environment on the Adjust dashboard.
enum AdjustEnvironment {
  /// Production environment – use for App Store / Play Store releases.
  production,

  /// Sandbox environment – use during development and testing.
  sandbox,
}

/// Callback invoked when the device's attribution data changes.
///
/// The [attributionData] parameter contains the updated [AdjustAttribution].
typedef AttributionCallback = void Function(AdjustAttribution attributionData);

/// Callback invoked when a session is tracked successfully.
///
/// The [successData] parameter contains session metadata such as timestamp
/// and ADID.
typedef SessionSuccessCallback = void Function(AdjustSessionSuccess successData);

/// Callback invoked when a session tracking attempt fails.
///
/// The [failureData] parameter contains error details and whether the SDK
/// will retry sending.
typedef SessionFailureCallback = void Function(AdjustSessionFailure failureData);

/// Callback invoked when an event is tracked successfully.
///
/// The [successData] parameter contains event metadata such as event token,
/// timestamp, and ADID.
typedef EventSuccessCallback = void Function(AdjustEventSuccess successData);

/// Callback invoked when an event tracking attempt fails.
///
/// The [failureData] parameter contains error details and whether the SDK
/// will retry sending.
typedef EventFailureCallback = void Function(AdjustEventFailure failureData);

/// Callback invoked when a deferred deeplink is received.
///
/// The [deeplink] parameter is the URL string of the deferred deeplink, or
/// `null` if no URL is available.
typedef DeferredDeeplinkCallback = void Function(String? deeplink);

/// Callback invoked when SKAdNetwork conversion values are updated.
///
/// **iOS only.** The [skanUpdateData] map contains the updated SKAN values
/// reported by the native SDK.
typedef SkanUpdatedCallback = void Function(Map<String, String> skanUpdateData);

/// Callback invoked when a direct deeplink opens the app.
///
/// Unlike [DeferredDeeplinkCallback], this fires for deeplinks that open the
/// app directly (cold start or while running), not deeplinks resolved by
/// Adjust after a deferred attribution. The [deeplink] parameter is the URL
/// string of the direct deeplink, or `null` if no URL is available.
typedef DirectDeeplinkCallback = void Function(String? deeplink);

/// Callback invoked when a remote trigger is received from the backend.
///
/// The SDK invokes this once per trigger contained in a backend response, in
/// the order received.
typedef RemoteTriggerCallback = void Function(AdjustRemoteTrigger remoteTrigger);

/// Callback invoked when the third-party-sharing settings change.
///
/// Assign to receive updates whenever the Adjust backend reports a change to
/// the third-party-sharing settings for this device.
typedef ThirdPartySharingSettingsChangedCallback = void Function(
    AdjustThirdPartySharingResult thirdPartySharingResult);

/// Configuration object for the Adjust SDK.
///
/// Create an [AdjustConfig] instance, set the desired properties, and pass it
/// to [Adjust.initSdk] to initialise the SDK.
///
/// **Minimum required setup:**
/// ```dart
/// final config = AdjustConfig('YourAppToken', AdjustEnvironment.production);
/// Adjust.initSdk(config);
/// ```
class AdjustConfig {
  static const MethodChannel _channel =
      MethodChannel('com.adjust.sdk/api');
  static const String _attributionCallbackName = 'adj-attribution-changed';
  static const String _sessionSuccessCallbackName = 'adj-session-success';
  static const String _sessionFailureCallbackName = 'adj-session-failure';
  static const String _eventSuccessCallbackName = 'adj-event-success';
  static const String _eventFailureCallbackName = 'adj-event-failure';
  static const String _deferredDeeplinkCallbackName = 'adj-deferred-deeplink';
  static const String _directDeeplinkCallbackName = 'adj-direct-deeplink';
  static const String _remoteTriggerCallbackName = 'adj-remote-trigger';
  static const String _skanUpdatedCallbackName = 'adj-skan-updated';
  static const String _thirdPartySharingSettingsChangedCallbackName =
      'adj-third-party-sharing-settings-changed';

  final String _appToken;
  final AdjustEnvironment _environment;

  /// Whether SKAdNetwork attribution is enabled.
  ///
  /// **iOS only.** When set to `true`, the SDK registers with SKAdNetwork
  /// and updates conversion values. Defaults to the native SDK default when
  /// `null`.
  bool? isSkanAttributionEnabled;

  /// Whether the SDK can send data while the app is running in the background.
  ///
  /// When set to `true`, the SDK continues to send requests even when the app
  /// is backgrounded. Defaults to `false` when `null`.
  bool? isSendingInBackgroundEnabled;

  /// Whether Apple Ads attribution via AdServices is enabled.
  ///
  /// **iOS only.** When set to `true`, the SDK reads the AdServices token and
  /// sends it to Adjust for attribution. Defaults to the native SDK default
  /// when `null`.
  bool? isAdServicesEnabled;

  /// Whether the SDK is allowed to read the IDFA.
  ///
  /// **iOS only.** Set to `false` to prevent the SDK from accessing the
  /// Identifier for Advertisers. Defaults to the native SDK default when
  /// `null`.
  bool? isIdfaReadingEnabled;

  /// Whether the SDK is allowed to read the IDFV.
  ///
  /// **iOS only.** Set to `false` to prevent the SDK from accessing the
  /// Identifier for Vendors. Defaults to the native SDK default when `null`.
  bool? isIdfvReadingEnabled;

  /// Whether cost data (CPI, CPM, etc.) is included in attribution callbacks.
  ///
  /// When set to `true`, the [AdjustAttribution] object delivered to
  /// [attributionCallback] will contain [AdjustAttribution.costType],
  /// [AdjustAttribution.costAmount], and [AdjustAttribution.costCurrency].
  bool? isCostDataInAttributionEnabled;

  /// Whether preinstall tracking is enabled.
  ///
  /// **Android only.** When set to `true`, the SDK attempts to detect
  /// preinstalled apps and attribute them accordingly.
  bool? isPreinstallTrackingEnabled;

  /// Whether the LinkMe deeplink solution is enabled.
  ///
  /// **iOS only.** LinkMe allows deferred deeplinking without requiring a
  /// universal link domain. Set to `true` to enable it.
  bool? isLinkMeEnabled;

  /// Whether device identifiers are read only once during the SDK lifetime.
  ///
  /// When set to `true`, the SDK reads device identifiers a single time and
  /// caches them. Useful for apps that need consistent identifier values
  /// across the session.
  bool? isDeviceIdsReadingOnceEnabled;

  /// Whether the SDK runs in COPPA-compliant mode.
  ///
  /// When set to `true`, the SDK disables third-party sharing and prevents
  /// the use of certain device identifiers in accordance with the Children's
  /// Online Privacy Protection Act.
  bool? isCoppaComplianceEnabled;

  /// Whether the Play Store Kids policy is enforced.
  ///
  /// **Android only.** When set to `true`, the SDK operates in compliance
  /// with the Google Play Families Policy for child-directed apps.
  bool? isPlayStoreKidsComplianceEnabled;

  /// Whether the SDK automatically opens deferred deeplinks.
  ///
  /// When set to `false`, the SDK delivers the deferred deeplink URL to
  /// [deferredDeeplinkCallback] without opening it. Defaults to `true` (the
  /// native SDK will open the deeplink automatically) when `null`.
  bool? isDeferredDeeplinkOpeningEnabled;

  /// Whether the first session should be delayed until [Adjust.endFirstSessionDelay]
  /// is called.
  ///
  /// Use this to configure properties that must be set before the first
  /// session is sent (e.g. external device ID, COPPA compliance).
  bool? isFirstSessionDelayEnabled;

  /// Whether App Tracking Transparency (ATT) usage is enabled.
  ///
  /// **iOS only.** When set to `true`, the SDK uses the ATT framework to
  /// request user authorisation before accessing the IDFA.
  bool? isAppTrackingTransparencyUsageEnabled;

  /// Whether the Android App Set ID is read and sent to Adjust.
  ///
  /// **Android only.** When set to `true`, the SDK reads the App Set ID
  /// provided by Google Play Services and includes it in requests.
  bool? isAppSetIdReadingEnabled;

  /// The time (in seconds) the SDK waits for an ATT consent response before
  /// sending the first session.
  ///
  /// **iOS only.** If the user does not respond within this interval, the SDK
  /// sends the first session without an ATT status.
  num? attConsentWaitingInterval;

  /// The maximum number of event deduplication IDs to keep in memory.
  ///
  /// Events whose [AdjustEvent.deduplicationId] matches a previously seen ID
  /// within this list are ignored. Increase this value if your app generates
  /// many unique events in quick succession.
  num? eventDeduplicationIdsMaxSize;

  /// Internal SDK prefix set automatically by [Adjust.initSdk].
  ///
  /// Do not set this manually.
  String? sdkPrefix;

  /// An optional tracker token to attribute new installs to a specific
  /// campaign or partner by default.
  String? defaultTracker;

  /// An optional external device identifier to associate with this device.
  ///
  /// If set, Adjust uses this value as an additional device identifier in
  /// attribution. Must be unique per device.
  String? externalDeviceId;

  /// The name of the Android process in which the SDK should run.
  ///
  /// **Android only.** Required only for apps that use multiple processes.
  String? processName;

  /// The path to a preinstall file on the device.
  ///
  /// **Android only.** Used when [isPreinstallTrackingEnabled] is `true`.
  String? preinstallFilePath;

  /// The Facebook App ID used for Meta Install Referrer attribution.
  ///
  /// **Android only.** Set this to enable Meta Install Referrer support.
  String? fbAppId;

  bool? _isDataResidency;
  bool? _useSubdomains;
  final List<String> _urlStrategyDomains = [];

  /// The log verbosity level for SDK output.
  ///
  /// Set to [AdjustLogLevel.suppress] to disable all logging.
  AdjustLogLevel? logLevel;

  /// Called when the device's attribution data changes.
  ///
  /// Assign an [AttributionCallback] to receive [AdjustAttribution] updates
  /// whenever Adjust detects a change in the device's attribution.
  AttributionCallback? attributionCallback;

  /// Store information used to identify which app store the app was installed
  /// from.
  ///
  /// Set an [AdjustStoreInfo] instance to provide the store name and optional
  /// store app ID.
  AdjustStoreInfo? storeInfo;

  /// Called when a session is tracked successfully.
  ///
  /// Assign a [SessionSuccessCallback] to receive [AdjustSessionSuccess]
  /// objects after each successfully tracked session.
  SessionSuccessCallback? sessionSuccessCallback;

  /// Called when a session tracking attempt fails.
  ///
  /// Assign a [SessionFailureCallback] to receive [AdjustSessionFailure]
  /// objects when a session cannot be sent.
  SessionFailureCallback? sessionFailureCallback;

  /// Called when an event is tracked successfully.
  ///
  /// Assign an [EventSuccessCallback] to receive [AdjustEventSuccess] objects
  /// after each successfully tracked event.
  EventSuccessCallback? eventSuccessCallback;

  /// Called when an event tracking attempt fails.
  ///
  /// Assign an [EventFailureCallback] to receive [AdjustEventFailure] objects
  /// when an event cannot be sent.
  EventFailureCallback? eventFailureCallback;

  /// Called when a deferred deeplink is received from Adjust.
  ///
  /// Assign a [DeferredDeeplinkCallback] to handle the deferred deeplink URL.
  /// When [isDeferredDeeplinkOpeningEnabled] is `false`, you must open the
  /// deeplink manually inside this callback.
  DeferredDeeplinkCallback? deferredDeeplinkCallback;

  /// Called when a direct deeplink opens the app.
  ///
  /// Assign a [DirectDeeplinkCallback] to receive the deeplink URL whenever
  /// the app is opened directly via a deeplink.
  DirectDeeplinkCallback? directDeeplinkCallback;

  /// Called when a remote trigger is received from the backend.
  ///
  /// Assign a [RemoteTriggerCallback] to receive [AdjustRemoteTrigger]
  /// objects whenever the backend sends one.
  RemoteTriggerCallback? remoteTriggerCallback;

  /// Called when SKAdNetwork conversion values are updated.
  ///
  /// **iOS only.** Assign a [SkanUpdatedCallback] to receive the SKAN
  /// conversion value map whenever the native SDK updates it.
  SkanUpdatedCallback? skanUpdatedCallback;

  /// Called when the third-party-sharing settings change.
  ///
  /// Assign a [ThirdPartySharingSettingsChangedCallback] to receive
  /// [AdjustThirdPartySharingResult] updates whenever the Adjust backend
  /// reports a change.
  ThirdPartySharingSettingsChangedCallback? thirdPartySharingSettingsChangedCallback;

  /// Creates an [AdjustConfig] for the app identified by [_appToken] running
  /// in [_environment].
  ///
  /// The [_appToken] is the unique identifier for your app in the Adjust
  /// dashboard. The [_environment] must be [AdjustEnvironment.production] for
  /// production builds and [AdjustEnvironment.sandbox] during development.
  AdjustConfig(this._appToken, this._environment) {
    _initCallbackHandlers();
  }

  /// Configures the URL strategy for network requests.
  ///
  /// [urlStrategyDomains] is the list of domains the SDK should use when
  /// sending requests (e.g. data-residency endpoints). Set [useSubdomains] to
  /// `true` if Adjust should use subdomains of the provided domains. Set
  /// [isDataResidency] to `true` if the domains are data-residency endpoints.
  void setUrlStrategy(List<String> urlStrategyDomains, bool useSubdomains, bool isDataResidency) {
    _urlStrategyDomains.addAll(urlStrategyDomains);
    _useSubdomains = useSubdomains;
    _isDataResidency = isDataResidency;
  }

  void _initCallbackHandlers() {
    _channel.setMethodCallHandler((MethodCall call) async {
      try {
        switch (call.method) {
          case _attributionCallbackName:
            if (attributionCallback != null) {
              AdjustAttribution attribution = AdjustAttribution.fromMap(call.arguments);
              attributionCallback!(attribution);
            }
            break;
          case _sessionSuccessCallbackName:
            if (sessionSuccessCallback != null) {
              AdjustSessionSuccess sessionSuccess = AdjustSessionSuccess.fromMap(call.arguments);
              sessionSuccessCallback!(sessionSuccess);
            }
            break;
          case _sessionFailureCallbackName:
            if (sessionFailureCallback != null) {
              AdjustSessionFailure sessionFailure = AdjustSessionFailure.fromMap(call.arguments);
              sessionFailureCallback!(sessionFailure);
            }
            break;
          case _eventSuccessCallbackName:
            if (eventSuccessCallback != null) {
              AdjustEventSuccess eventSuccess = AdjustEventSuccess.fromMap(call.arguments);
              eventSuccessCallback!(eventSuccess);
            }
            break;
          case _eventFailureCallbackName:
            if (eventFailureCallback != null) {
              AdjustEventFailure eventFailure = AdjustEventFailure.fromMap(call.arguments);
              eventFailureCallback!(eventFailure);
            }
            break;
          case _deferredDeeplinkCallbackName:
            if (deferredDeeplinkCallback != null) {
              String? deeplink = call.arguments['deeplink'];
              if (deferredDeeplinkCallback != null) {
                deferredDeeplinkCallback!(deeplink);
              }
            }
            break;
          case _directDeeplinkCallbackName:
            if (directDeeplinkCallback != null) {
              String? deeplink = call.arguments['deeplink'];
              directDeeplinkCallback!(deeplink);
            }
            break;
          case _remoteTriggerCallbackName:
            if (remoteTriggerCallback != null) {
              AdjustRemoteTrigger remoteTrigger = AdjustRemoteTrigger.fromMap(call.arguments);
              remoteTriggerCallback!(remoteTrigger);
            }
            break;
          case _skanUpdatedCallbackName:
            if (skanUpdatedCallback != null) {
              skanUpdatedCallback!(Map<String, String>.from(call.arguments));
            }
            break;
          case _thirdPartySharingSettingsChangedCallbackName:
            if (thirdPartySharingSettingsChangedCallback != null) {
              AdjustThirdPartySharingResult thirdPartySharingResult =
                  AdjustThirdPartySharingResult.fromMap(call.arguments);
              thirdPartySharingSettingsChangedCallback!(thirdPartySharingResult);
            }
            break;
          default:
            throw UnsupportedError(
                '[AdjustFlutter]: Received unknown native method: ${call.method}');
        }
      } catch (e) {
        print(e.toString());
      }
    });
  }

  Map<String, String?> get toMap {
    Map<String, String?> configMap = {
      'sdkPrefix': sdkPrefix,
      'appToken': _appToken,
      'environment': _environment
          .toString()
          .substring(_environment.toString().indexOf('.') + 1),
    };

    if (processName != null) {
      configMap['processName'] = processName;
    }
    if (logLevel != null) {
      configMap['logLevel'] =
          logLevel.toString().substring(logLevel.toString().indexOf('.') + 1);
    }
    if (defaultTracker != null) {
      configMap['defaultTracker'] = defaultTracker;
    }
    if (externalDeviceId != null) {
      configMap['externalDeviceId'] = externalDeviceId;
    }
    if (eventDeduplicationIdsMaxSize != null) {
      configMap['eventDeduplicationIdsMaxSize'] = eventDeduplicationIdsMaxSize.toString();
    }
    if (preinstallFilePath != null) {
      configMap['preinstallFilePath'] = preinstallFilePath;
    }
    if (fbAppId != null) {
      configMap['fbAppId'] = fbAppId;
    }
    if (storeInfo != null) {
      configMap['storeInfo'] = json.encode(storeInfo!.toMap);
    }
    if (_urlStrategyDomains.isEmpty != true ) {
      configMap['urlStrategyDomains'] = json.encode(_urlStrategyDomains);
    }
    if (_isDataResidency != null) {
      configMap['isDataResidency'] = _isDataResidency.toString();
    }
    if (_useSubdomains != null) {
      configMap['useSubdomains'] = _useSubdomains.toString();
    }
    if (isCostDataInAttributionEnabled != null) {
      configMap['isCostDataInAttributionEnabled'] = isCostDataInAttributionEnabled.toString();
    }
    if (isSendingInBackgroundEnabled != null) {
      configMap['isSendingInBackgroundEnabled'] = isSendingInBackgroundEnabled.toString();
    }
    if (isCostDataInAttributionEnabled != null) {
      configMap['isCostDataInAttributionEnabled'] = isCostDataInAttributionEnabled.toString();
    }
    if (isPreinstallTrackingEnabled != null) {
      configMap['isPreinstallTrackingEnabled'] = isPreinstallTrackingEnabled.toString();
    }
    if (isPlayStoreKidsComplianceEnabled != null) {
      configMap['isPlayStoreKidsComplianceEnabled'] = isPlayStoreKidsComplianceEnabled.toString();
    }
    if (isCoppaComplianceEnabled != null) {
      configMap['isCoppaComplianceEnabled'] = isCoppaComplianceEnabled.toString();
    }
    if (isFirstSessionDelayEnabled != null) {
      configMap['isFirstSessionDelayEnabled'] = isFirstSessionDelayEnabled.toString();
    }
    if (isAppTrackingTransparencyUsageEnabled != null) {
      configMap['isAppTrackingTransparencyUsageEnabled'] = isAppTrackingTransparencyUsageEnabled.toString();
    }
    if (isDeviceIdsReadingOnceEnabled != null) {
      configMap['isDeviceIdsReadingOnceEnabled'] = isDeviceIdsReadingOnceEnabled.toString();
    }
    if (isLinkMeEnabled != null) {
      configMap['isLinkMeEnabled'] = isLinkMeEnabled.toString();
    }
    if (isAdServicesEnabled != null) {
      configMap['isAdServicesEnabled'] = isAdServicesEnabled.toString();
    }
    if (isIdfaReadingEnabled != null) {
      configMap['isIdfaReadingEnabled'] = isIdfaReadingEnabled.toString();
    }
    if (isIdfvReadingEnabled != null) {
      configMap['isIdfvReadingEnabled'] = isIdfvReadingEnabled.toString();
    }
    if (isSkanAttributionEnabled != null) {
      configMap['isSkanAttributionEnabled'] = isSkanAttributionEnabled.toString();
    }
    if (isDeferredDeeplinkOpeningEnabled != null) {
      configMap['isDeferredDeeplinkOpeningEnabled'] = isDeferredDeeplinkOpeningEnabled.toString();
    }
    if (isAppSetIdReadingEnabled != null) {
      configMap['isAppSetIdReadingEnabled'] = isAppSetIdReadingEnabled.toString();
    }
    if (attConsentWaitingInterval != null) {
      configMap['attConsentWaitingInterval'] = attConsentWaitingInterval.toString();
    }
    if (attributionCallback != null) {
      configMap['attributionCallback'] = _attributionCallbackName;
    }
    if (sessionSuccessCallback != null) {
      configMap['sessionSuccessCallback'] = _sessionSuccessCallbackName;
    }
    if (sessionFailureCallback != null) {
      configMap['sessionFailureCallback'] = _sessionFailureCallbackName;
    }
    if (eventSuccessCallback != null) {
      configMap['eventSuccessCallback'] = _eventSuccessCallbackName;
    }
    if (eventFailureCallback != null) {
      configMap['eventFailureCallback'] = _eventFailureCallbackName;
    }
    if (deferredDeeplinkCallback != null) {
      configMap['deferredDeeplinkCallback'] = _deferredDeeplinkCallbackName;
    }
    if (remoteTriggerCallback != null) {
      configMap['remoteTriggerCallback'] = _remoteTriggerCallbackName;
    }
    if (skanUpdatedCallback != null) {
      configMap['skanUpdatedCallback'] = _skanUpdatedCallbackName;
    }
    if (thirdPartySharingSettingsChangedCallback != null) {
      configMap['thirdPartySharingSettingsChangedCallback'] = _thirdPartySharingSettingsChangedCallbackName;
    }

    return configMap;
  }
}
