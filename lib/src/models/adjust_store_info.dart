/// Identifies the store from which the app was distributed.
///
/// Set an [AdjustStoreInfo] instance on [AdjustConfig.storeInfo] before
/// calling [Adjust.initSdk] to let Adjust know which store the user installed
/// the app from. This is useful for apps distributed through multiple
/// third-party stores.
///
/// ```dart
/// final config = AdjustConfig('YourAppToken', AdjustEnvironment.production);
/// config.storeInfo = AdjustStoreInfo('mystore')..storeAppId = 'com.example.app';
/// Adjust.initSdk(config);
/// ```
class AdjustStoreInfo {
  /// The name of the store (e.g. `'amazon'`, `'samsung'`).
  String? storeName;

  /// The app identifier used by the store (e.g. a package name or store-
  /// specific ID). Optional.
  String? storeAppId;

  /// Creates an [AdjustStoreInfo] with the given [storeName].
  AdjustStoreInfo(this.storeName);

  /// The map sent to the native SDK over the platform channel.
  Map<String, String?> get toMap {
    Map<String, String?> storeInfoMap = <String, String?>{};

    if (storeName != null) {
      storeInfoMap['storeName'] = storeName;
    }
    if (storeAppId != null) {
      storeInfoMap['storeAppId'] = storeAppId;
    }

    return storeInfoMap;
  }
}
