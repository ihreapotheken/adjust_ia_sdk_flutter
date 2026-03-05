import 'dart:convert';
import 'dart:io';

/// The backend environment to use for deeplink resolution.
enum DeferredDeeplinkEnvironment {
  /// Development environment (`dev.ihreapotheken.de`).
  dev('dev.ihreapotheken.de'),

  /// QA environment (`qa.ihreapotheken.de`).
  qa('qa.ihreapotheken.de'),

  /// Production environment (`ihreapotheken.de`).
  prod('ihreapotheken.de');

  const DeferredDeeplinkEnvironment(this.host);

  /// The hostname for this environment.
  final String host;
}

/// Resolves a pharmacy pre-selection identifier for deferred deep linking.
///
/// Usage:
/// ```dart
/// try {
///   final pharmacyId = await DeferredDeeplink.resolve(
///     apiKey: 'your-api-key',
///     environment: DeferredDeeplinkEnvironment.prod,
///   );
///   // Navigate to the pharmacy.
/// } on Exception catch (e) {
///   // Handle error: e.toString() contains the message.
/// }
/// ```
class DeferredDeeplink {
  DeferredDeeplink._();

  static const String _path = '/partners/api/pharmacy-preselection-identifier';

  /// IPv6-only IP lookup endpoint.
  static const String _ipv6LookupUrl = 'https://api6.ipify.org?format=json';

  /// IPv4-only IP lookup endpoint.
  static const String _ipv4LookupUrl = 'https://api.ipify.org?format=json';

  /// Resolves the device's public IP address and sends it to the
  /// pharmacy pre-selection endpoint.
  ///
  /// Tries IPv6 first. If the backend doesn't find a match, retries
  /// with IPv4 as a fallback.
  ///
  /// Returns the matched `pharmacyId` on success.
  /// Throws an [Exception] on failure.
  static Future<int> resolve({
    required String apiKey,
    DeferredDeeplinkEnvironment environment = DeferredDeeplinkEnvironment.prod,
  }) async {
    String? ipv6;
    String? ipv4;
    Object? ipv6Error;
    Object? ipv4Error;

    // Try IPv6 first.
    try {
      ipv6 = await _fetchIp(_ipv6LookupUrl);
      final result = await _queryBackend(
        apiKey: apiKey,
        environment: environment,
        ipAddress: ipv6,
      );
      if (result != null) return result;
    } catch (e) {
      ipv6Error = e;
    }

    // Fallback to IPv4.
    try {
      ipv4 = await _fetchIp(_ipv4LookupUrl);
      final result = await _queryBackend(
        apiKey: apiKey,
        environment: environment,
        ipAddress: ipv4,
      );
      if (result != null) return result;
    } catch (e) {
      ipv4Error = e;
    }

    throw Exception(
      'Could not resolve pharmacy. '
      'IPv6: ${ipv6 ?? 'n/a'}${ipv6Error != null ? ' (error: $ipv6Error)' : ''}, '
      'IPv4: ${ipv4 ?? 'n/a'}${ipv4Error != null ? ' (error: $ipv4Error)' : ''}',
    );
  }

  /// Fetches the device's public IP from [url].
  /// Throws on network or parse errors.
  static Future<String> _fetchIp(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception('IP lookup failed with status ${response.statusCode}');
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final ip = json['ip'] as String?;
      if (ip == null || ip.isEmpty) {
        throw Exception('IP lookup returned empty result');
      }
      return ip;
    } finally {
      client.close();
    }
  }

  /// Sends [ipAddress] to the backend and returns the matched pharmacyId,
  /// or `null` if the backend found no match.
  /// Throws on network or parse errors.
  static Future<int?> _queryBackend({
    required String apiKey,
    required DeferredDeeplinkEnvironment environment,
    required String ipAddress,
  }) async {
    final uri = Uri.https(environment.host, _path);
    final client = HttpClient();

    try {
      final request = await client.getUrl(uri);
      request.headers.set('apiKey', apiKey);
      request.headers.set('pharmacyPreselectionIdentifier', ipAddress);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;

      if (response.statusCode == 200 && json.containsKey('pharmacyId')) {
        return json['pharmacyId'] as int;
      }

      return null;
    } finally {
      client.close();
    }
  }
}
