import 'dart:convert';

/// Represents a Play Store subscription purchase to be tracked with Adjust.
///
/// **Android only.** Create an instance with all required fields from the
/// Google Play Billing Library purchase object, optionally set additional
/// metadata, then pass it to [Adjust.trackPlayStoreSubscription].
///
/// ```dart
/// final subscription = AdjustPlayStoreSubscription(
///   '9.99',
///   'USD',
///   'sku123',
///   'orderId456',
///   'purchaseSignature',
///   'purchaseToken789',
/// );
/// subscription.purchaseTime = '1700000000000';
/// Adjust.trackPlayStoreSubscription(subscription);
/// ```
class AdjustPlayStoreSubscription {
  final String _price;
  final String _currency;
  final String _sku;
  final String _orderId;
  final String _signature;
  final String _purchaseToken;
  String? _billingStore;

  /// The time at which the subscription was purchased.
  ///
  /// Should be a string representation of the purchase time in milliseconds
  /// since epoch, as returned by the Google Play Billing Library
  /// (`Purchase.getPurchaseTime()`).
  String? purchaseTime;

  Map<String, String>? _callbackParameters;
  Map<String, String>? _partnerParameters;

  /// Creates an [AdjustPlayStoreSubscription] with the required fields.
  ///
  /// - [_price]: The subscription price as a string (e.g. `'9.99'`).
  /// - [_currency]: A valid ISO 4217 currency code (e.g. `'USD'`).
  /// - [_sku]: The product SKU as defined in the Google Play Console.
  /// - [_orderId]: The order ID from the Google Play purchase.
  /// - [_signature]: The purchase signature from the Google Play Billing Library.
  /// - [_purchaseToken]: The purchase token from the Google Play Billing Library.
  AdjustPlayStoreSubscription(
    this._price,
    this._currency,
    this._sku,
    this._orderId,
    this._signature,
    this._purchaseToken) {
    _billingStore = 'GooglePlay';
    _callbackParameters = <String, String>{};
    _partnerParameters = <String, String>{};
  }

  /// Adds a callback parameter to this subscription event.
  ///
  /// The [key]-[value] pair is appended to the callback URL sent to your
  /// server. Call this multiple times to add several parameters.
  void addCallbackParameter(String key, String value) {
    _callbackParameters![key] = value;
  }

  /// Adds a partner parameter to this subscription event.
  ///
  /// The [key]-[value] pair is forwarded to enabled partner integrations.
  /// Call this multiple times to add several parameters.
  void addPartnerParameter(String key, String value) {
    _partnerParameters![key] = value;
  }

  /// The map sent to the native SDK over the platform channel.
  Map<String, String?> get toMap {
    Map<String, String?> subscriptionMap = <String, String?>{};

    subscriptionMap['price'] = _price;
    subscriptionMap['currency'] = _currency;
    subscriptionMap['sku'] = _sku;
    subscriptionMap['orderId'] = _orderId;
    subscriptionMap['signature'] = _signature;
    subscriptionMap['purchaseToken'] = _purchaseToken;
    if (_billingStore != null) {
      subscriptionMap['billingStore'] = _billingStore;
    }
    if (purchaseTime != null) {
      subscriptionMap['purchaseTime'] = purchaseTime;
    }
    if (_callbackParameters!.isNotEmpty) {
      subscriptionMap['callbackParameters'] = json.encode(_callbackParameters);
    }
    if (_partnerParameters!.isNotEmpty) {
      subscriptionMap['partnerParameters'] = json.encode(_partnerParameters);
    }

    return subscriptionMap;
  }
}
