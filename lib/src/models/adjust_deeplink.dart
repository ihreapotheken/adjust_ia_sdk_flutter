/// Represents a deeplink URL to be processed by the Adjust SDK.
///
/// Create an instance with the deeplink URL string received by your app and
/// pass it to [Adjust.processDeeplink] or [Adjust.processAndResolveDeeplink].
///
/// ```dart
/// final deeplink = AdjustDeeplink('yourapp://path?param=value');
/// Adjust.processDeeplink(deeplink);
/// ```
class AdjustDeeplink {
  /// The deeplink URL string to be processed.
  String deeplink;

  /// An optional referrer URL associated with the deeplink.
  ///
  /// **Android only.** Provide the referrer URL when available (e.g. from
  /// the Play Install Referrer API) to improve attribution accuracy.
  String? referrer;

  /// Creates an [AdjustDeeplink] with the given [deeplink] URL string.
  AdjustDeeplink(this.deeplink);

  /// The map sent to the native SDK over the platform channel.
  Map<String, String?> get toMap {
    Map<String, String?> deeplinkMap = <String, String?>{};

    deeplinkMap['deeplink'] = deeplink;
    if (referrer != null) {
      deeplinkMap['referrer'] = referrer;
    }

    return deeplinkMap;
  }
}
