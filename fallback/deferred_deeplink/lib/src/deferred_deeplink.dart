import 'dart:convert';
import 'dart:io';

import 'package:deferred_deeplink/src/device_info_collector.dart';

/// Resolves a deferred deep link by sending device fingerprint data
/// to the backend endpoint.
///
/// Usage:
/// ```dart
/// final deeplink = await DeferredDeeplink.resolve();
/// if (deeplink != null) {
///   // Navigate to the deep link destination.
/// }
/// ```
class DeferredDeeplink {
  DeferredDeeplink._();

  static const String _endpoint =
      'https://example.com/api/v1/deferred-deeplink';

  static const String _ipLookupUrl = 'https://ifconfig.me/all.json';

  /// Collects device fingerprint data, resolves the device's public IP
  /// address, and sends both to the backend via HTTP POST.
  ///
  /// Returns the deferred deep link URL string from the backend,
  /// or `null` if the resolution fails or no deep link is found.
  static Future<String?> resolve() async {
    try {
      final results = await Future.wait([
        DeviceInfoCollector.collect(),
        _fetchIpAddress(),
      ]);

      final deviceInfo = results[0] as Map<String, dynamic>;
      final ipAddress = results[1] as String?;

      if (ipAddress != null) {
        deviceInfo['ipAddress'] = ipAddress;
      }

      final jsonBody = jsonEncode(deviceInfo);

      final uri = Uri.parse(_endpoint);
      final client = HttpClient();

      try {
        final request = await client.postUrl(uri);
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        request.write(jsonBody);

        final response = await request.close();
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

  static Future<String?> _fetchIpAddress() async {
    try {
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(_ipLookupUrl));
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
