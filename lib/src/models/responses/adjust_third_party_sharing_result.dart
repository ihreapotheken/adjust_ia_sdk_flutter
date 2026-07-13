/// The current third-party-sharing settings read from the Adjust backend.
///
/// Returned by [Adjust.getThirdPartySharingSettingsWithTimeout] and delivered
/// to [AdjustConfig.thirdPartySharingSettingsChangedCallback] whenever the
/// backend reports a change.
class AdjustThirdPartySharingResult {
  /// The third-party-sharing settings, encoded as a JSON string.
  final String thirdPartySharingSettingsJson;

  /// Creates an [AdjustThirdPartySharingResult] with the provided fields.
  AdjustThirdPartySharingResult({
    required this.thirdPartySharingSettingsJson,
  });

  /// Creates an [AdjustThirdPartySharingResult] from a raw map received from
  /// the native SDK.
  factory AdjustThirdPartySharingResult.fromMap(dynamic map) {
    try {
      final dynamic settingsJson = map['thirdPartySharingSettingsJson'];

      return AdjustThirdPartySharingResult(
        thirdPartySharingSettingsJson: settingsJson is String && settingsJson.isNotEmpty ? settingsJson : '{}',
      );
    } catch (e) {
      throw Exception(
          '[AdjustFlutter]: Failed to create AdjustThirdPartySharingResult object from given map object. Details: ' +
              e.toString());
    }
  }
}
