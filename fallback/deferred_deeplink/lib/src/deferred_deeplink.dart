import 'dart:async';
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

/// An IP lookup service with a name and URL.
class IpLookupService {
  const IpLookupService({
    required this.name,
    required this.url,
    this.isIpV6 = false,
  });

  final String name;
  final String url;
  final bool isIpV6;
}

/// The result of a deferred deeplink resolution.
class DeferredDeeplinkResult {
  const DeferredDeeplinkResult({
    required this.pharmacyId,
    required this.log,
  });

  /// The matched pharmacy ID, or `null` if no service returned a match.
  final int? pharmacyId;

  /// A log string describing what each service returned.
  final String log;

  @override
  String toString() => 'DeferredDeeplinkResult(pharmacyId: $pharmacyId, log: $log)';
}

/// Resolves a pharmacy pre-selection identifier for deferred deep linking.
class DeferredDeeplink {
  DeferredDeeplink._();

  static const String _path = '/partners/api/pharmacy-preselection-identifier';

  static const List<IpLookupService> _defaultServices = [
    IpLookupService(name: 'ipify-v6', url: 'https://api6.ipify.org', isIpV6: true),
    IpLookupService(name: 'ipify-v4', url: 'https://api.ipify.org'),
    IpLookupService(name: 'ifconfig', url: 'https://ifconfig.me/ip'),
  ];

  /// Resolves the device's public IP address and sends it to the
  /// pharmacy pre-selection endpoint.
  ///
  /// Runs all [services] in parallel. IPv6 services return immediately
  /// when they find a pharmacy ID. IPv4 services wait for all IPv6
  /// services to finish before returning.
  static Future<DeferredDeeplinkResult> resolve({
    required String apiKey,
    DeferredDeeplinkEnvironment environment = DeferredDeeplinkEnvironment.prod,
    List<IpLookupService> services = _defaultServices,
  }) async {
    final completer = Completer<DeferredDeeplinkResult>();
    final logLines = <String>[];
    var remaining = services.length;
    var remainingV6 = services.where((s) => s.isIpV6).length;
    int? foundPharmacyId;

    for (final service in services) {
      _resolveWithService(
        apiKey: apiKey,
        environment: environment,
        service: service,
      ).then((result) {
        if (completer.isCompleted) return;

        logLines.add(result.logLine);
        if (result.pharmacyId != null) foundPharmacyId ??= result.pharmacyId;
        if (service.isIpV6) remainingV6--;
        remaining--;

        // IPv6 match wins immediately.
        if (service.isIpV6 && result.pharmacyId != null) {
          completer.complete(
            DeferredDeeplinkResult(
              pharmacyId: result.pharmacyId,
              log: logLines.join('\n'),
            ),
          );
          return;
        }

        // All IPv6 done — complete with best IPv4 result if available.
        if (remainingV6 == 0 && foundPharmacyId != null) {
          completer.complete(
            DeferredDeeplinkResult(
              pharmacyId: foundPharmacyId,
              log: logLines.join('\n'),
            ),
          );
          return;
        }

        // All done, no match found anywhere.
        if (remaining == 0) {
          completer.complete(
            DeferredDeeplinkResult(
              pharmacyId: null,
              log: logLines.join('\n'),
            ),
          );
        }
      });
    }

    return completer.future;
  }

  static Future<_ServiceResult> _resolveWithService({
    required String apiKey,
    required DeferredDeeplinkEnvironment environment,
    required IpLookupService service,
  }) async {
    String? ip;
    try {
      ip = await _fetchIp(service.url);
    } catch (e) {
      return _ServiceResult(
        logLine: '${service.name}: IP lookup failed ($e)',
      );
    }

    try {
      final pharmacyId = await _queryBackend(
        apiKey: apiKey,
        environment: environment,
        ipAddress: ip,
      );
      if (pharmacyId != null) {
        return _ServiceResult(
          pharmacyId: pharmacyId,
          logLine: '${service.name}: ip=$ip, pharmacyId=$pharmacyId',
        );
      }
      return _ServiceResult(
        logLine: '${service.name}: ip=$ip, no match',
      );
    } catch (e) {
      return _ServiceResult(
        logLine: '${service.name}: ip=$ip, backend error ($e)',
      );
    }
  }

  /// Fetches the device's public IP from [url].
  /// Expects a plain-text response containing the IP address.
  static Future<String> _fetchIp(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception('IP lookup failed with status ${response.statusCode}');
      }

      final ip = body.trim();
      if (ip.isEmpty) {
        throw Exception('IP lookup returned empty result');
      }
      return ip;
    } finally {
      client.close();
    }
  }

  /// Sends [ipAddress] to the backend and returns the matched pharmacyId,
  /// or `null` if the backend found no match.
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

class _ServiceResult {
  const _ServiceResult({this.pharmacyId, required this.logLine});

  final int? pharmacyId;
  final String logLine;
}
