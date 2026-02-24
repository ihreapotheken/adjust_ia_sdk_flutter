import 'dart:convert';
import 'dart:io';

import 'package:deferred_deeplink/src/device_info_collector.dart';

/// Resolves a deferred deep link by sending device fingerprint data
/// to a backend endpoint.
///
/// Usage:
/// ```dart
/// final deeplink = await DeferredDeeplink.resolve(
///   'https://example.com/api/v1/deferred-deeplink',
/// );
/// if (deeplink != null) {
///   // Navigate to the deep link destination.
/// }
/// ```
class DeferredDeeplink {
  DeferredDeeplink._();

  /// Default request timeout.
  static const Duration _defaultTimeout = Duration(seconds: 10);

  /// Collects device fingerprint data and sends it to [endpoint]
  /// via HTTP POST.
  ///
  /// Returns the deferred deep link URL string from the backend,
  /// or `null` if the resolution fails or no deep link is found.
  ///
  /// The optional [timeout] parameter controls how long to wait for
  /// the backend response (defaults to 10 seconds).
  static Future<String?> resolve(
    String endpoint, {
    Duration timeout = _defaultTimeout,
  }) async {
    try {
      final deviceInfo = await DeviceInfoCollector.collect();
      final jsonBody = jsonEncode(deviceInfo);

      final uri = Uri.parse(endpoint);
      final client = HttpClient();
      client.connectionTimeout = timeout;

      try {
        final request = await client.postUrl(uri);
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        request.write(jsonBody);

        final response = await request.close().timeout(timeout);
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          final Map<String, dynamic> json = jsonDecode(responseBody);
          return json['deeplink'] as String?;
        }

        return null;
      } finally {
        client.close();
      }
    } catch (_) {
      return null;
    }
  }
}
