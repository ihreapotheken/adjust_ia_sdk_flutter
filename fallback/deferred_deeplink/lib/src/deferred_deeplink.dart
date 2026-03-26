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

/// The result of a single IP lookup service resolution.
class DeferredDeeplinkServiceResult {
  const DeferredDeeplinkServiceResult({
    required this.serviceName,
    this.ip,
    this.pharmacyId,
    this.error,
  });

  /// The name of the service that produced this result.
  final String serviceName;

  /// The IP address returned by the service, or `null` if lookup failed.
  final String? ip;

  /// The matched pharmacy ID, or `null` if no match was found.
  final int? pharmacyId;

  /// The error that occurred, or `null` if the service succeeded.
  final Object? error;

  @override
  String toString() =>
      'DeferredDeeplinkServiceResult(serviceName: $serviceName, ip: $ip, pharmacyId: $pharmacyId, error: $error)';
}

/// The result of a deferred deeplink resolution.
class DeferredDeeplinkResult {
  const DeferredDeeplinkResult({
    required this.pharmacyId,
    required this.results,
  });

  /// The matched pharmacy ID, or `null` if no service returned a match.
  final int? pharmacyId;

  /// The individual results from each service that completed.
  final List<DeferredDeeplinkServiceResult> results;

  /// Whether any service encountered an error or timed out.
  bool get hasErrors => results.any((r) => r.error != null);

  /// A human-readable log string summarising what each service returned.
  String get log => results.map((r) {
        if (r.error != null) {
          if (r.ip != null) return '${r.serviceName}: ip=${r.ip}, backend error (${r.error})';
          return '${r.serviceName}: ${r.error}';
        }
        if (r.pharmacyId != null) return '${r.serviceName}: ip=${r.ip}, pharmacyId=${r.pharmacyId}';
        return '${r.serviceName}: ip=${r.ip}, no match';
      }).join('\n');

  @override
  String toString() =>
      'DeferredDeeplinkResult(pharmacyId: $pharmacyId, results: $results)';
}

/// Resolves a pharmacy pre-selection identifier for deferred deep linking.
class DeferredDeeplink {
  DeferredDeeplink._();

  static const String _path = '/partners/api/pharmacy-preselection-identifier';

  static const List<IpLookupService> _defaultServices = [
    IpLookupService(
      name: 'ipify-v6',
      url: 'https://api6.ipify.org',
      isIpV6: true,
    ),
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
    required Duration timeout,
    DeferredDeeplinkEnvironment environment = DeferredDeeplinkEnvironment.prod,
    List<IpLookupService> services = _defaultServices,
    String? proxy,
  }) async {
    final completer = Completer<DeferredDeeplinkResult>();
    final serviceResults = <DeferredDeeplinkServiceResult>[];
    var remaining = services.length;
    var remainingV6 = services.where((s) => s.isIpV6).length;
    int? foundPharmacyId;

    for (final service in services) {
      _resolveWithService(
        apiKey: apiKey,
        environment: environment,
        service: service,
        proxy: proxy,
      ).timeout(timeout, onTimeout: () {
        return DeferredDeeplinkServiceResult(serviceName: service.name, error: TimeoutException('timeout', timeout));
      }).then((result) {
        if (completer.isCompleted) return;

        serviceResults.add(result);
        if (result.pharmacyId != null) foundPharmacyId ??= result.pharmacyId;
        if (service.isIpV6) remainingV6--;
        remaining--;

        // IPv6 match wins immediately.
        if (service.isIpV6 && result.pharmacyId != null) {
          completer.complete(
            DeferredDeeplinkResult(
              pharmacyId: result.pharmacyId,
              results: List.unmodifiable(serviceResults),
            ),
          );
          return;
        }

        // All IPv6 done — complete with best result if available.
        if (remainingV6 == 0 && foundPharmacyId != null) {
          completer.complete(
            DeferredDeeplinkResult(
              pharmacyId: foundPharmacyId,
              results: List.unmodifiable(serviceResults),
            ),
          );
          return;
        }

        // All done, no match found anywhere.
        if (remaining == 0) {
          completer.complete(
            DeferredDeeplinkResult(
              pharmacyId: null,
              results: List.unmodifiable(serviceResults),
            ),
          );
        }
      });
    }

    return completer.future;
  }

  static Future<DeferredDeeplinkServiceResult> _resolveWithService({
    required String apiKey,
    required DeferredDeeplinkEnvironment environment,
    required IpLookupService service,
    String? proxy,
  }) async {
    String? ip;
    try {
      ip = await _fetchIp(service.url, proxy: proxy);
    } catch (e) {
      return DeferredDeeplinkServiceResult(serviceName: service.name, error: e);
    }

    try {
      final pharmacyId = await _queryBackend(
        apiKey: apiKey,
        environment: environment,
        ipAddress: ip,
        proxy: proxy,
      );
      return DeferredDeeplinkServiceResult(serviceName: service.name, ip: ip, pharmacyId: pharmacyId);
    } catch (e) {
      return DeferredDeeplinkServiceResult(serviceName: service.name, ip: ip, error: e);
    }
  }

  /// Fetches the device's public IP from [url].
  /// Expects a plain-text response containing the IP address.
  static Future<String> _fetchIp(String url, {String? proxy}) async {
    final client = HttpClient();
    if (proxy != null) client.findProxy = (_) => proxy;
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
    String? proxy,
  }) async {
    final uri = Uri.https(environment.host, _path);
    final client = HttpClient();
    if (proxy != null) client.findProxy = (_) => proxy;

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

