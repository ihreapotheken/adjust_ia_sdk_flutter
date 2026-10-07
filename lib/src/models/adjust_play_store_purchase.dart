/// Represents a Play Store in-app purchase for server-side verification.
///
/// **Android only.** Create an instance with the product ID and purchase token
/// from the Google Play Billing Library and pass it to
/// [Adjust.verifyPlayStorePurchase].
///
/// ```dart
/// final purchase = AdjustPlayStorePurchase('product123', 'purchaseToken456');
/// final result = await Adjust.verifyPlayStorePurchase(purchase);
/// ```
class AdjustPlayStorePurchase {
  final String _productId;
  final String _purchaseToken;

  /// Creates an [AdjustPlayStorePurchase] with the given [_productId] and
  /// [_purchaseToken].
  ///
  /// The [_productId] is the product identifier as defined in the Google Play
  /// Console. The [_purchaseToken] is the purchase token returned by the
  /// Google Play Billing Library upon a successful purchase.
  AdjustPlayStorePurchase(this._productId, this._purchaseToken);

  /// The map sent to the native SDK over the platform channel.
  Map<String, String?> get toMap {
    Map<String, String?> purchaseMap = <String, String?>{};

    purchaseMap['productId'] = _productId;
    purchaseMap['purchaseToken'] = _purchaseToken;

    return purchaseMap;
  }
}
