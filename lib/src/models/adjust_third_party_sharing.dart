/// Represents a third-party data sharing preference for the current user.
///
/// Use this to enable or disable sharing of user data with third parties, and
/// to provide granular options or partner-specific sharing settings. Pass the
/// configured instance to [Adjust.trackThirdPartySharing].
///
/// ```dart
/// // Disable all third-party sharing
/// final tps = AdjustThirdPartySharing(false);
/// Adjust.trackThirdPartySharing(tps);
///
/// // Enable sharing with a granular option for a specific partner
/// final tps = AdjustThirdPartySharing(true);
/// tps.addGranularOption('PartnerA', 'myOption', 'myValue');
/// Adjust.trackThirdPartySharing(tps);
/// ```
class AdjustThirdPartySharing {
  final bool? _isEnabled;
  late List<String> _granularOptions;
  late List<String> _partnerSharingSettings;

  /// Creates an [AdjustThirdPartySharing] object.
  ///
  /// Set [isEnabled] to `true` to enable third-party sharing, `false` to
  /// disable it, or `null` to update only granular options without changing
  /// the enabled state.
  AdjustThirdPartySharing(this._isEnabled) {
    _granularOptions = <String>[];
    _partnerSharingSettings = <String>[];
  }

  /// Adds a granular option for a specific partner.
  ///
  /// Granular options allow fine-grained control over what data is shared
  /// with a particular partner. The [partnerName] identifies the partner,
  /// [key] is the option name, and [value] is the option value.
  ///
  /// Call this multiple times to set several options for one or more partners.
  void addGranularOption(String partnerName, String key, String value) {
    _granularOptions.add(partnerName);
    _granularOptions.add(key);
    _granularOptions.add(value);
  }

  /// Adds a partner-level sharing setting.
  ///
  /// Partner sharing settings override the global enabled state for a
  /// specific partner. The [partnerName] identifies the partner, [key] is
  /// the setting name, and [value] enables or disables that setting.
  ///
  /// Call this multiple times to configure several settings for one or more
  /// partners.
  void addPartnerSharingSetting(String partnerName, String key, bool value) {
    _partnerSharingSettings.add(partnerName);
    _partnerSharingSettings.add(key);
    _partnerSharingSettings.add(value.toString());
  }

  /// The map sent to the native SDK over the platform channel.
  Map<String, Object?> get toMap {
    Map<String, Object?> thirdPartySharingMap = {'isEnabled': _isEnabled};
    if (_granularOptions.isNotEmpty) {
      thirdPartySharingMap['granularOptions'] =
          _granularOptions.join('__ADJ__');
    }
    if (_partnerSharingSettings.isNotEmpty) {
      thirdPartySharingMap['partnerSharingSettings'] =
          _partnerSharingSettings.join('__ADJ__');
    }

    return thirdPartySharingMap;
  }
}
