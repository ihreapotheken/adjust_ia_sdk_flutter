import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Resolves a pharmacy pre-selection identifier for deferred deep linking.
class DeferredDeeplink {
  DeferredDeeplink._();

  static const String _path = '/partners/api/pharmacy-preselection-identifier';
  static const Duration _graceperiodDuration = Duration(seconds: 3);

  static const List<IpLookupService> _defaultServices = [
    IpLookupService(
      name: 'ipify-v6',
      url: 'https://api6.ipify.org',
    ),
    IpLookupService(
      name: 'ifconfig', 
      url: 'https://ifconfig.me/ip'
    ),
  ];

  /// Resolves the device's public IP address and sends it to the
  /// pharmacy pre-selection endpoint that returns pharmacy id.
  /// 
  /// It runs multiple IP lookup services in parallel, one strictly ipv6 (that fails if ipv6 is unavailable)
  /// and one that returns ipv4 or ipv6. Browsers implement happy eyeballs logic 
  /// to prefer ipv6 but fall back to ipv4 if ipv6 is slow or unavailable, 
  /// and this mimics that approach to get the best results for all users, because
  /// dart doesn't implement happy eyeballs.
  ///
  /// When first IP lookup completes, starts a 3-second
  /// timer for the second. This is done becase ipv6 paths can often (10% of all requests) be much
  /// slower, and we want to return results as fast as possible while still
  /// giving ipv6 a chance to succeed if available.
  ///
  /// The [logCompleter] completer is completed after all services have finished
  /// (including timeouts), allowing you to wait for complete results and logging
  /// even if the main future completes early.
  static Future<DeferredDeeplinkResult> resolve({
    required String apiKey,
    required Duration timeout,
    DeferredDeeplinkEnvironment environment = DeferredDeeplinkEnvironment.prod,
    String? proxy,
    Completer<DeferredDeeplinkResult>? logCompleter,
  }) async {
    final completer = Completer<DeferredDeeplinkResult>();
    final serviceResults = <DeferredDeeplinkServiceResult>[];
    List<IpLookupService> services = _defaultServices;
    var remaining = services.length;
    var isTimerStarted = false;

    // Run all services in parallel
    for (final service in services) {
      _resolveWithService(
        apiKey: apiKey,
        environment: environment,
        service: service,
        proxy: proxy,
        timeout: timeout,
      ).then((result) {
        serviceResults.add(result);
        remaining--;

        // First service finished — start 3-second timer for others. This prevents
        // long ipv6 timeouts from delaying the main future.
        if (remaining > 0 && !isTimerStarted) {
          isTimerStarted = true;

          Future.delayed(_graceperiodDuration, () {
            if (!completer.isCompleted) {
              final finalResult = DeferredDeeplinkResult(
                results: List.unmodifiable(serviceResults),
              );

              // Important: calling the completer but not logCompleter here, 
              // that way the main future returns early but we can still wait 
              // for the logCompleter to get complete results for logging.
              completer.complete(finalResult);
            }
          });
          return;
        }

        // Complete when all services finish, or when 3-second timer fires
        if (remaining == 0 && !completer.isCompleted) {
          final finalResult = DeferredDeeplinkResult(
            results: List.unmodifiable(serviceResults),
          );
          completer.complete(finalResult);
        }

        // Call logCompleter when all services have finished
        if (remaining == 0) {
          if (logCompleter != null && !logCompleter.isCompleted) {
            final finalResult = DeferredDeeplinkResult(
              results: List.unmodifiable(serviceResults)
            );
            logCompleter.complete(finalResult);
          }
        }
      });
    }

    return completer.future;
  }

  static Future<DeferredDeeplinkServiceResult> _resolveWithService({
    required String apiKey,
    required DeferredDeeplinkEnvironment environment,
    required IpLookupService service,
    required Duration timeout,
    String? proxy,
  }) async {
    String? ip;
    int? pharmacyId;
    Duration? ipFetchDuration;
    Duration? backendQueryDuration;

    try {
      // Single timeout covering both IP fetch and backend query. 
      //
      // We are using internal future with timeout instead of wrapping the whole 
      // function in timeout because we want to capture results and errors from 
      // both operations, and return a complete result object with 
      // timings for logging (even in case of timeout).
      await (() async {
        final ipStopwatch = Stopwatch()..start();
        final fetchedIp = await _fetchIp(service.url, proxy: proxy);
        ip = fetchedIp;
        ipFetchDuration = ipStopwatch.elapsed;

        final backendStopwatch = Stopwatch()..start();
        pharmacyId = await _queryBackend(
          apiKey: apiKey,
          environment: environment,
          ipAddress: fetchedIp,
          proxy: proxy,
        );
        backendQueryDuration = backendStopwatch.elapsed;
      }()).timeout(timeout);

      return DeferredDeeplinkServiceResult(
        serviceName: service.name,
        ip: ip,
        pharmacyId: pharmacyId,
        ipFetchDuration: ipFetchDuration,
        backendQueryDuration: backendQueryDuration,
      );
    } catch (e) {
      return DeferredDeeplinkServiceResult(
        serviceName: service.name,
        ip: ip,
        error: e,
        ipFetchDuration: ipFetchDuration,
        backendQueryDuration: backendQueryDuration,
      );
    }
  }

  /// Fetches the device's public IP from [url].
  /// Expects a plain-text response containing the IP address.
  static Future<String> _fetchIp(
    String url, {
    String? proxy,
  }) async {
    final client = HttpClient();
    if (proxy != null) client.findProxy = (_) => proxy;
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('IP lookup failed with status ${response.statusCode}');
      }

      final body = await response.transform(utf8.decoder).join();
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
    final client = HttpClient();
    try {
      final uri = Uri.https(environment.host, _path);
      if (proxy != null) client.findProxy = (_) => proxy;
      final request = await client.getUrl(uri);
      request.headers.set('apiKey', apiKey);
      request.headers.set('pharmacyPreselectionIdentifier', ipAddress);

      final response = await request.close();

      if (response.statusCode != 200) {
        return null;
      }

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;

      if (json.containsKey('pharmacyId')) {
        return json['pharmacyId'] as int;
      }

      return null;
    } finally {
      client.close();
    }
  }
}

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

/// An IP lookup service with a name and URL.
class IpLookupService {
  const IpLookupService({
    required this.name,
    required this.url,
  });

  final String name;
  final String url;
}

/// The result of a single IP lookup service resolution.
class DeferredDeeplinkServiceResult {
  const DeferredDeeplinkServiceResult({
    required this.serviceName,
    this.ip,
    this.pharmacyId,
    this.error,
    this.ipFetchDuration,
    this.backendQueryDuration,
  });

  /// The name of the service that produced this result.
  final String serviceName;

  /// The IP address returned by the service, or `null` if lookup failed.
  final String? ip;

  /// The matched pharmacy ID, or `null` if no match was found.
  final int? pharmacyId;

  /// The error that occurred, or `null` if the service succeeded.
  final Object? error;

  /// The duration of the IP fetch operation.
  final Duration? ipFetchDuration;

  /// The duration of the backend query operation.
  final Duration? backendQueryDuration;

  @override
  String toString() =>
      'DeferredDeeplinkServiceResult(serviceName: $serviceName, ip: $ip, pharmacyId: $pharmacyId, ipFetchDuration: $ipFetchDuration, backendQueryDuration: $backendQueryDuration, error: $error)';
}

/// The result of a deferred deeplink resolution.
class DeferredDeeplinkResult {
  const DeferredDeeplinkResult({
    required this.results,
  });

  /// The individual results from each service that completed.
  final List<DeferredDeeplinkServiceResult> results;

  /// The matched pharmacy ID, preferring IPv6 if multiple results differ.
  /// Returns `null` if no service returned a match.
  int? get pharmacyId {
    int? ipv6PharmacyId;
    int? firstPharmacyId;

    for (final result in results) {
      if (result.pharmacyId != null) {
        firstPharmacyId ??= result.pharmacyId;
        if (result.ip != null && _isIpv6(result.ip!)) {
          ipv6PharmacyId = result.pharmacyId;
        }
      }
    }

    return ipv6PharmacyId ?? firstPharmacyId;
  }

  /// Whether any service encountered an error or timed out.
  bool get hasErrors => results.any((r) => r.error != null);

  /// A human-readable log string summarising what each service returned.
  String get log => results
      .map((r) {
        final ipDuration = r.ipFetchDuration != null ? '${r.ipFetchDuration!.inMilliseconds}ms' : '-';
        final backendDuration = r.backendQueryDuration != null ? '${r.backendQueryDuration!.inMilliseconds}ms' : '-';
        if (r.error != null) {
          if (r.ip != null) return '${r.serviceName}: ip=${r.ip} ($ipDuration), backend error ($backendDuration): ${r.error}';
          return '${r.serviceName}: error ($ipDuration): ${r.error}';
        }
        if (r.pharmacyId != null) return '${r.serviceName}: ip=${r.ip} ($ipDuration), pharmacyId=${r.pharmacyId} ($backendDuration)';
        return '${r.serviceName}: ip=${r.ip} ($ipDuration), no match ($backendDuration)';
      })
      .join('\n');

  @override
  String toString() => 'DeferredDeeplinkResult(pharmacyId: $pharmacyId, results: $results)';

  static bool _isIpv6(String ip) {
    return ip.contains(':');
  }
}
