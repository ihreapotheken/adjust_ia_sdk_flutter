import 'dart:convert';

/// Represents an App Store subscription purchase to be tracked with Adjust.
///
/// **iOS only.** Create an instance with the price, currency, and transaction
/// ID from the StoreKit subscription, optionally set additional metadata,
/// then pass it to [Adjust.trackAppStoreSubscription].
///
/// ```dart
/// final subscription = AdjustAppStoreSubscription('9.99', 'USD', 'txn456');
/// subscription.transactionDate = '2024-01-15T10:00:00Z';
/// subscription.salesRegion = 'US';
/// Adjust.trackAppStoreSubscription(subscription);
/// ```
class AdjustAppStoreSubscription {
  final String _price;
  final String _currency;
  final String _transactionId;

  /// The date of the subscription transaction.
  ///
  /// Should be a string representation of the transaction date as provided
  /// by StoreKit (e.g. an ISO 8601 formatted date string).
  String? transactionDate;

  /// The sales region in which the subscription was purchased.
  ///
  /// Typically a two-letter country code (e.g. `'US'`, `'GB'`).
  String? salesRegion;

  String? _billingStore;
  Map<String, String>? _callbackParameters;
  Map<String, String>? _partnerParameters;

  /// Creates an [AdjustAppStoreSubscription] with the required fields.
  ///
  /// - [_price]: The subscription price as a string (e.g. `'9.99'`).
  /// - [_currency]: A valid ISO 4217 currency code (e.g. `'USD'`).
  /// - [_transactionId]: The transaction identifier from StoreKit.
  AdjustAppStoreSubscription(this._price, this._currency, this._transactionId) {
    _billingStore = 'iOS';
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
    subscriptionMap['transactionId'] = _transactionId;
    if (transactionDate != null) {
      subscriptionMap['transactionDate'] = transactionDate;
    }
    if (salesRegion != null) {
      subscriptionMap['salesRegion'] = salesRegion;
    }
    if (_billingStore != null) {
      subscriptionMap['billingStore'] = _billingStore;
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
