import 'dart:convert';

/// Represents an event to be tracked with the Adjust SDK.
///
/// Create an instance with the event token from your Adjust dashboard, then
/// optionally set revenue, deduplication ID, product ID, and callback or
/// partner parameters before passing it to [Adjust.trackEvent].
///
/// ```dart
/// final event = AdjustEvent('abc123');
/// event.setRevenue(9.99, 'USD');
/// event.addCallbackParameter('key', 'value');
/// Adjust.trackEvent(event);
/// ```
class AdjustEvent {
  final String _eventToken;
  num? _revenue;
  String? _currency;

  /// An optional identifier sent back in event callbacks to correlate
  /// Adjust callbacks with your own internal events.
  String? callbackId;

  /// An optional identifier used to deduplicate events.
  ///
  /// If the same [deduplicationId] has been seen within the most recent
  /// [AdjustConfig.eventDeduplicationIdsMaxSize] events, the event is
  /// discarded. Use this to prevent double-counting retried purchases.
  String? deduplicationId;

  /// The product identifier associated with this event.
  ///
  /// Required when calling [Adjust.verifyAndTrackAppStorePurchase] or
  /// [Adjust.verifyAndTrackPlayStorePurchase].
  String? productId;

  Map<String, String>? _callbackParameters;
  Map<String, String>? _partnerParameters;

  /// The App Store transaction ID for purchase verification.
  ///
  /// **iOS only.** Set this when using [Adjust.verifyAndTrackAppStorePurchase].
  String? transactionId;

  /// The Play Store purchase token for purchase verification.
  ///
  /// **Android only.** Set this when using
  /// [Adjust.verifyAndTrackPlayStorePurchase].
  String? purchaseToken;

  /// Creates an [AdjustEvent] with the given [_eventToken].
  ///
  /// The [_eventToken] is the unique four- or six-character token for the
  /// event as shown in your Adjust dashboard.
  AdjustEvent(this._eventToken) {
    _callbackParameters = <String, String>{};
    _partnerParameters = <String, String>{};
  }

  /// Sets the revenue amount and currency for this event.
  ///
  /// The [revenue] must be a non-negative number and [currency] must be a
  /// valid ISO 4217 currency code (e.g. `'USD'`, `'EUR'`).
  ///
  /// ```dart
  /// event.setRevenue(4.99, 'EUR');
  /// ```
  void setRevenue(num revenue, String currency) {
    _revenue = revenue;
    _currency = currency;
  }

  /// Adds a callback parameter to this event.
  ///
  /// The [key]-[value] pair is appended to the callback URL sent to your
  /// server for this event. Call this multiple times to add several
  /// parameters.
  void addCallbackParameter(String key, String value) {
    _callbackParameters![key] = value;
  }

  /// Adds a partner parameter to this event.
  ///
  /// The [key]-[value] pair is forwarded to enabled partner integrations
  /// for this event. Call this multiple times to add several parameters.
  void addPartnerParameter(String key, String value) {
    _partnerParameters![key] = value;
  }

  /// The map sent to the native SDK over the platform channel.
  Map<String, String?> get toMap {
    Map<String, String?> eventMap = {'eventToken': _eventToken};

    if (_revenue != null) {
      eventMap['revenue'] = _revenue.toString();
    }
    if (_currency != null) {
      eventMap['currency'] = _currency;
    }
    if (deduplicationId != null) {
      eventMap['deduplicationId'] = deduplicationId;
    }
    if (transactionId != null) {
      eventMap['transactionId'] = transactionId;
    }
    if (productId != null) {
      eventMap['productId'] = productId;
    }
    if (purchaseToken != null) {
      eventMap['purchaseToken'] = purchaseToken;
    }
    if (callbackId != null) {
      eventMap['callbackId'] = callbackId;
    }
    if (_callbackParameters!.isNotEmpty) {
      eventMap['callbackParameters'] = json.encode(_callbackParameters);
    }
    if (_partnerParameters!.isNotEmpty) {
      eventMap['partnerParameters'] = json.encode(_partnerParameters);
    }

    return eventMap;
  }
}
