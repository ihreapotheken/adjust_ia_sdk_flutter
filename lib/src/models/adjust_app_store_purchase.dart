/// Represents an App Store in-app purchase for server-side verification.
///
/// **iOS only.** Create an instance with the product ID and transaction ID
/// from the App Store receipt and pass it to [Adjust.verifyAppStorePurchase].
///
/// ```dart
/// final purchase = AdjustAppStorePurchase('product123', 'txn456');
/// final result = await Adjust.verifyAppStorePurchase(purchase);
/// ```
class AdjustAppStorePurchase {
  final String _productId;
  final String _transactionId;

  /// Creates an [AdjustAppStorePurchase] with the given [_productId] and
  /// [_transactionId].
  ///
  /// The [_productId] is the product identifier as defined in App Store
  /// Connect. The [_transactionId] is the transaction identifier from the
  /// StoreKit payment transaction.
  AdjustAppStorePurchase(this._productId, this._transactionId);

  /// The map sent to the native SDK over the platform channel.
  Map<String, String?> get toMap {
    Map<String, String?> purchaseMap = <String, String?>{};

    purchaseMap['productId'] = _productId;
    purchaseMap['transactionId'] = _transactionId;

    return purchaseMap;
  }
}
