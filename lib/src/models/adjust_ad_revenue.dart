import 'dart:convert';

/// Represents ad revenue data to be tracked with the Adjust SDK.
///
/// Create an instance with the ad revenue source, set the revenue amount and
/// optional metadata, then pass it to [Adjust.trackAdRevenue].
///
/// ```dart
/// final adRevenue = AdjustAdRevenue('admob_sdk');
/// adRevenue.setRevenue(0.01, 'USD');
/// adRevenue.adImpressionsCount = 1;
/// Adjust.trackAdRevenue(adRevenue);
/// ```
class AdjustAdRevenue {
  final String _source;
  num? _revenue;
  String? _currency;

  /// The number of ad impressions recorded in this revenue event.
  num? adImpressionsCount;

  /// The name of the ad network that generated this revenue.
  String? adRevenueNetwork;

  /// The ad unit identifier that generated this revenue.
  String? adRevenueUnit;

  /// The placement of the ad that generated this revenue.
  String? adRevenuePlacement;

  Map<String, String>? _callbackParameters;
  Map<String, String>? _partnerParameters;

  /// Creates an [AdjustAdRevenue] for the specified ad revenue [_source].
  ///
  /// The [_source] must be a valid Adjust ad revenue source string as
  /// provided in the Adjust documentation (e.g. `'admob_sdk'`,
  /// `'applovin_max_sdk'`).
  AdjustAdRevenue(this._source) {
    _callbackParameters = <String, String>{};
    _partnerParameters = <String, String>{};
  }

  /// Sets the revenue amount and currency for this ad revenue event.
  ///
  /// The [revenue] must be a non-negative number and [currency] must be a
  /// valid ISO 4217 currency code (e.g. `'USD'`, `'EUR'`).
  void setRevenue(num revenue, String currency) {
    _revenue = revenue;
    _currency = currency;
  }

  /// Adds a callback parameter to this ad revenue event.
  ///
  /// The [key]-[value] pair is appended to the callback URL sent to your
  /// server. Call this multiple times to add several parameters.
  void addCallbackParameter(String key, String value) {
    _callbackParameters![key] = value;
  }

  /// Adds a partner parameter to this ad revenue event.
  ///
  /// The [key]-[value] pair is forwarded to enabled partner integrations.
  /// Call this multiple times to add several parameters.
  void addPartnerParameter(String key, String value) {
    _partnerParameters![key] = value;
  }

  /// The map sent to the native SDK over the platform channel.
  Map<String, String?> get toMap {
    Map<String, String?> adRevenueMap = {'source': _source};

    if (_revenue != null) {
      adRevenueMap['revenue'] = _revenue.toString();
    }
    if (_currency != null) {
      adRevenueMap['currency'] = _currency;
    }
    if (adImpressionsCount != null) {
      adRevenueMap['adImpressionsCount'] = adImpressionsCount.toString();
    }
    if (adRevenueNetwork != null) {
      adRevenueMap['adRevenueNetwork'] = adRevenueNetwork;
    }
    if (adRevenueUnit != null) {
      adRevenueMap['adRevenueUnit'] = adRevenueUnit;
    }
    if (adRevenuePlacement != null) {
      adRevenueMap['adRevenuePlacement'] = adRevenuePlacement;
    }
    if (_callbackParameters!.isNotEmpty) {
      adRevenueMap['callbackParameters'] = json.encode(_callbackParameters);
    }
    if (_partnerParameters!.isNotEmpty) {
      adRevenueMap['partnerParameters'] = json.encode(_partnerParameters);
    }

    return adRevenueMap;
  }
}
