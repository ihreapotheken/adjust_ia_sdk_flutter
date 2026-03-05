import 'dart:convert';
import 'dart:io';

/// The backend environment to use for deeplink resolution.
enum DeferredDeeplinkEnvironment {
  /// Development environment (`dev.ihreapotheken.de`).
  dev('dev.ihreapotheken.de'),

  /// QA environment (`qa.ihreapotheken.de`).
  qa('qa.ihreapotheken.de'),

  /// Production environment (`ihreapotheken.de`).
  prod('ihreapotheken.de')
  ;

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
  static const String _ipLookupUrl = 'https://ifconfig.me/all.json';

  /// Resolves the device's public IP address and sends it to the
  /// pharmacy pre-selection endpoint.
  ///
  /// Returns the matched `pharmacyId` on success.
  /// Throws an [Exception] on failure — the message is taken from the
  /// backend's `message` field if present, otherwise from the caught error.
  ///
  /// [apiKey] is required for authenticating with the backend.
  /// [environment] selects the backend environment
  /// (defaults to [DeferredDeeplinkEnvironment.prod]).
  static Future<int> resolve({
    required String apiKey,
    DeferredDeeplinkEnvironment environment = DeferredDeeplinkEnvironment.prod,
  }) async {
    final ipAddress = await _fetchIpAddress();
    if (ipAddress == null) {
      throw Exception('Could not determine public IP address.');
    }

    final uri = Uri.https(environment.host, _path);
    final client = HttpClient();

    try {
      final request = await client.getUrl(uri);
      request.headers.set('apiKey', apiKey);
      request.headers.set('pharmacyPreselectionIdentifier', ipAddress);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      final Map<String, dynamic> json;
      try {
        json = jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        throw Exception('[IP: $ipAddress] ${e.toString()}');
      }

      if (response.statusCode == 200 && json.containsKey('pharmacyId')) {
        return json['pharmacyId'] as int;
      }

      final message = json['message'] as String? ?? body;
      throw Exception('[IP: $ipAddress] $message');
    } finally {
      client.close();
    }
  }

  static Future<String?> _fetchIpAddress() async {
    try {
      final uri = Uri.parse(_ipLookupUrl);
      final addresses = await InternetAddress.lookup(
        uri.host,
        type: InternetAddressType.IPv6,
      );
      if (addresses.isEmpty) {
        throw Exception(
          'No IPV6 address found.',
        );
      }
      final client = HttpClient();
      try {
        final request = await client.getUrl(
          addresses.isEmpty ? uri : uri.replace(host: addresses.first.host),
        );
        request.headers.set(HttpHeaders.hostHeader, uri.host);
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          final Map<String, dynamic> json = jsonDecode(body);
          return json['ip_addr'] as String?;
        }
      } finally {
        client.close();
      }
    } catch (_) {}
    return null;
  }
}
