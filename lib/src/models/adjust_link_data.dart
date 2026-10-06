/// A parsed view of a link that Adjust delivered to your app.
///
/// The same Adjust link can reach your app in several shapes: as the branded
/// link itself (`https://brand.go.link/path?adj_t=abc123&key=value`), as a
/// resolved short link that wraps the destination in `adj_link`, as a custom
/// scheme deeplink (`yourapp://path?key=value`), or as a platform-specific
/// destination in `adj_deep_link`. [AdjustLinkData.parse] unwraps all of them,
/// so the in-app destination and your custom parameters are read the same way
/// however the link arrived.
///
/// Pass direct deeplinks through [Adjust.processAndResolveDeeplink] first, so
/// short links are resolved to their long form before parsing:
///
/// ```dart
/// config.directDeeplinkCallback = (String? link) async {
///   if (link == null) return;
///   final resolved = await Adjust.processAndResolveDeeplink(AdjustDeeplink(link));
///   final data = AdjustLinkData.parse(resolved ?? link);
///   if (data?.path == 'terminbuchung') {
///     openAppointmentBooking(data!.parameters['apothekeId']);
///   }
/// };
/// ```
class AdjustLinkData {
  static const int _maxUnwrapDepth = 3;

  // Parameters that carry the in-app destination inside another link. The
  // platform-specific deeplink wins over the shared web destination.
  static const List<String> _wrappedLinkParameters = ['adj_deep_link', 'adj_link'];

  // Long-form Adjust parameters, only meaningful on Adjust's own link domains.
  static const Set<String> _longFormParameters = {
    'adgroup',
    'campaign',
    'creative',
    'deep_link',
    'engagement_type',
    'fallback',
    'fallback_click',
    'fallback_lp',
    'label',
    'redirect',
    'redirect_android',
    'redirect_ios',
    'redirect_macos',
    'redirect_windows',
    'redirect_windows-phone',
  };

  /// The link exactly as it was passed to [parse].
  final Uri originalUri;

  /// The in-app destination, after unwrapping `adj_link`, `adj_deep_link` or
  /// `deep_link`.
  ///
  /// Equal to [originalUri] when the link did not wrap another link.
  final Uri destinationUri;

  /// The segments of the destination path.
  ///
  /// For custom scheme links (`yourapp://terminbuchung`) the host is the first
  /// segment, so `yourapp://terminbuchung` and
  /// `https://brand.go.link/terminbuchung` both yield `['terminbuchung']`.
  final List<String> pathSegments;

  /// Query parameters that are not Adjust parameters, such as the custom data
  /// appended to an Adjust link.
  ///
  /// Values are URL-decoded. When both the wrapping link and the destination
  /// carry the same key, the destination's value is used.
  final Map<String, String> parameters;

  /// The value of the label parameter (`adj_label`), if present.
  final String? label;

  /// The Adjust link token (`adj_t`), if present.
  final String? linkToken;

  /// The campaign name (`adj_campaign`), if present.
  final String? campaign;

  /// The adgroup name (`adj_adgroup`), if present.
  final String? adgroup;

  /// The creative name (`adj_creative`), if present.
  final String? creative;

  /// Creates an [AdjustLinkData] with the provided fields.
  ///
  /// Use [parse] to create one from a link string.
  const AdjustLinkData({
    required this.originalUri,
    required this.destinationUri,
    required this.pathSegments,
    required this.parameters,
    this.label,
    this.linkToken,
    this.campaign,
    this.adgroup,
    this.creative,
  });

  /// The destination path without leading or trailing slashes, for example
  /// `terminbuchung` or `apotheke/terminbuchung`.
  String get path => pathSegments.join('/');

  /// Parses [link] into an [AdjustLinkData].
  ///
  /// Returns `null` if [link] is `null`, empty, or not a valid absolute URL.
  static AdjustLinkData? parse(String? link) {
    if (link == null || link.trim().isEmpty) {
      return null;
    }
    final Uri? originalUri = Uri.tryParse(link.trim());
    if (originalUri == null || !originalUri.hasScheme) {
      return null;
    }

    // Collect Adjust and custom parameters from every layer, outermost first,
    // so inner (destination) values take precedence.
    final Map<String, String> parameters = {};
    final Map<String, String> adjustParameters = {};
    Uri destinationUri = originalUri;

    for (int depth = 0; depth <= _maxUnwrapDepth; depth++) {
      final Map<String, String> query = _safeQueryParameters(destinationUri);
      final bool isAdjustDomain = _isAdjustDomain(destinationUri);

      query.forEach((key, value) {
        if (_isAdjustParameter(key, isAdjustDomain)) {
          adjustParameters[_normalizeAdjustKey(key)] = value;
        } else {
          parameters[key] = value;
        }
      });

      final Uri? wrappedUri = depth < _maxUnwrapDepth ? _wrappedLink(query, isAdjustDomain) : null;
      if (wrappedUri == null) {
        break;
      }
      destinationUri = wrappedUri;
    }

    return AdjustLinkData(
      originalUri: originalUri,
      destinationUri: destinationUri,
      pathSegments: _pathSegments(destinationUri),
      parameters: Map.unmodifiable(parameters),
      label: adjustParameters['label'],
      linkToken: adjustParameters['t'],
      campaign: adjustParameters['campaign'],
      adgroup: adjustParameters['adgroup'],
      creative: adjustParameters['creative'],
    );
  }

  static Uri? _wrappedLink(Map<String, String> query, bool isAdjustDomain) {
    final List<String> keys = [
      ..._wrappedLinkParameters,
      if (isAdjustDomain) 'deep_link',
    ];
    for (final String key in keys) {
      final String? value = query[key];
      if (value == null || value.isEmpty) {
        continue;
      }
      final Uri? uri = Uri.tryParse(value);
      if (uri != null && uri.hasScheme) {
        return uri;
      }
    }
    return null;
  }

  static List<String> _pathSegments(Uri uri) {
    final bool isWebLink = uri.scheme == 'http' || uri.scheme == 'https';
    return [
      if (!isWebLink && uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments.where((segment) => segment.isNotEmpty),
    ];
  }

  static Map<String, String> _safeQueryParameters(Uri uri) {
    try {
      return uri.queryParameters;
    } on FormatException {
      return const {};
    }
  }

  static bool _isAdjustParameter(String key, bool isAdjustDomain) {
    return key.startsWith('adj_') || key.startsWith('adjust_') || (isAdjustDomain && _longFormParameters.contains(key));
  }

  static String _normalizeAdjustKey(String key) {
    if (key.startsWith('adj_')) {
      return key.substring('adj_'.length);
    }
    if (key.startsWith('adjust_')) {
      return key.substring('adjust_'.length);
    }
    return key;
  }

  static bool _isAdjustDomain(Uri uri) {
    final String host = uri.host.toLowerCase();
    // Suffixes also cover data residency hosts such as app.eu.adjust.com.
    return const ['.go.link', '.adj.st', '.adjust.com', '.adjust.net.in', '.adjust.world'].any(host.endsWith);
  }

  @override
  String toString() =>
      'AdjustLinkData(path: $path, parameters: $parameters, label: $label, linkToken: $linkToken, destinationUri: $destinationUri)';
}
