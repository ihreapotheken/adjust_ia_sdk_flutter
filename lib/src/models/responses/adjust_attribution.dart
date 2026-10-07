/// Contains attribution information for the current device.
///
/// An instance of this class is delivered to the [AdjustConfig.attributionCallback]
/// whenever attribution data changes, and is also returned by
/// [Adjust.getAttribution] and [Adjust.getAttributionWithTimeout].
///
/// All properties are nullable because not every attribution source provides
/// all fields.
class AdjustAttribution {
  /// The tracker token of the campaign that attributed this install.
  final String? trackerToken;

  /// The human-readable name of the tracker that attributed this install.
  final String? trackerName;

  /// The ad network name associated with the attribution.
  final String? network;

  /// The campaign name associated with the attribution.
  final String? campaign;

  /// The ad group name associated with the attribution.
  final String? adgroup;

  /// The creative name associated with the attribution.
  final String? creative;

  /// The click label associated with the attribution.
  final String? clickLabel;

  /// The cost type for the attributed campaign (e.g. `'cpi'`, `'cpm'`).
  ///
  /// Only populated when [AdjustConfig.isCostDataInAttributionEnabled] is
  /// `true`.
  final String? costType;

  /// The cost amount for the attributed campaign.
  ///
  /// Only populated when [AdjustConfig.isCostDataInAttributionEnabled] is
  /// `true`.
  final num? costAmount;

  /// The currency of the cost amount (ISO 4217 code, e.g. `'USD'`).
  ///
  /// Only populated when [AdjustConfig.isCostDataInAttributionEnabled] is
  /// `true`.
  final String? costCurrency;

  /// The raw JSON response from the Adjust attribution server.
  final String? jsonResponse;

  /// The Facebook install referrer string.
  ///
  /// **Android only.** Populated when the install is attributed via the
  /// Facebook install referrer.
  final String? fbInstallReferrer;

  /// Creates an [AdjustAttribution] with the provided fields.
  AdjustAttribution({
    this.trackerToken,
    this.trackerName,
    this.network,
    this.campaign,
    this.adgroup,
    this.creative,
    this.clickLabel,
    this.costType,
    this.costAmount,
    this.costCurrency,
    this.jsonResponse,
    this.fbInstallReferrer,
  });

  /// Creates an [AdjustAttribution] from a raw map received from the native
  /// SDK.
  factory AdjustAttribution.fromMap(dynamic map) {
    try {
      final double parsedCostAmount = double.tryParse(map['costAmount']?.toString() ?? '') ?? -1;

      return AdjustAttribution(
        trackerToken: map['trackerToken'],
        trackerName: map['trackerName'],
        network: map['network'],
        campaign: map['campaign'],
        adgroup: map['adgroup'],
        creative: map['creative'],
        clickLabel: map['clickLabel'],
        costType: map['costType'],
        costAmount: parsedCostAmount != -1 ? parsedCostAmount : null,
        costCurrency: map['costCurrency'],
        jsonResponse: map['jsonResponse'],
        fbInstallReferrer: map['fbInstallReferrer'],
      );
    } catch (e) {
      throw Exception(
          '[AdjustFlutter]: Failed to create AdjustAttribution object from given map object. Details: ' +
              e.toString());
    }
  }
}
