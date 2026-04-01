import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Resolves a pharmacy pre-selection identifier for deferred deep linking.
class DeferredDeeplink {
  DeferredDeeplink._();

  static const String _path = '/partners/api/pharmacy-preselection-identifier';
  static const Duration _graceperiodDuration = Duration(seconds: 4);

  /// Notes:
  /// - https://api6.ipify.org was very slow (out of 9000 events, 2000 were longer than 3 seconds).
  /// - we were using dedicated IPv4 (api4.ipify.org) endpoint but none ever had pharmacy. In most cases it had same ip as ifconfig.me and when ifconfig returns IPv6 then IPv6 had the pharmacy.
  /// - IPv6 options: https://v6.ipinfo.io/ip, https://ipv6.seeip.org, https://api6.ipify.org (slow)
  /// - IPv4/IPv6 options: https://ipquery.io/
  static const List<IpLookupService> _defaultServices = [
    IpLookupService(
      name: 'v6.ipinfo.io',
      url: 'https://v6.ipinfo.io/ip',
      isIpV6Only: true,
    ),
    IpLookupService(
      name: '6.ident.me',
      url: 'https://6.ident.me',
      isIpV6Only: true,
    ),
    IpLookupService(name: 'ifconfig', url: 'https://ifconfig.me/ip'),
  ];

  /// Resolves the device's public IP address and sends it to the
  /// pharmacy pre-selection endpoint that returns pharmacy id. Prefers IPv6.
  ///
  /// IMPORTANT: This function has mainCompleter and logCompleter. The mainCompleter 
  /// is completed as soon as we have results from all services or if
  /// we get a pharmacy id from IPv6, while the logCompleter is completed only
  /// after all services have finished (including timeouts).
  ///
  /// We need to get same IP address here as frontend gets when installation link is
  /// tapped. Browsers implement happy eyeballs logic to prefer IPv6 (250ms ahead time for IPv6),
  /// dart doesn't have that, it often happens that browser gets IPv6 and dart
  /// gets IPv4 (from ifconfig.me) on the same device. That is why we do following:
  /// - Call ifconfig.me and IPv6 endpoints in parallel, so we get IPv6 and IPv4 
  ///   (assuming ifconfig returns IPv4)
  /// - When first IP lookup completes (usually IPv4), start a graceperiod timer 
  ///   (_graceperiodDuration) for others. This is done becase IPv6 paths can 
  ///   often fail (10% of all requests), and we want to return results as fast 
  ///   as possible while still giving IPv6 a chance to succeed if available. We 
  ///   don't want to wait for timeout that is passed into the function because 
  ///   that is usually 10 seconds which is too much.
  /// - If some service returns ipv6 and we get pharmacy id, we return immediately.
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
    final mainCompleter = Completer<DeferredDeeplinkResult>();
    final serviceResults = <DeferredDeeplinkServiceResult>[];
    // Track IPs that have been queried to avoid duplicate backend queries
    final queriedIps = <String>{};
    List<IpLookupService> services = _defaultServices;
    var remaining = services.length;
    var isTimerStarted = false;

    DeferredDeeplinkResult _finalResult() =>
        DeferredDeeplinkResult(results: List.unmodifiable(List.from(serviceResults)));

    // Run all services in parallel
    for (final service in services) {
      _resolveWithService(
        apiKey: apiKey,
        environment: environment,
        service: service,
        proxy: proxy,
        timeout: timeout,
        queriedIps: queriedIps,
      ).then((result) {
        serviceResults.add(result);
        remaining--;

        // Finish main completer if any of this is true: 
        //   - all services finished
        //   - got a pharmacy from IPv6
        //   - successfully queried backend for IPv4 and IPv6 services
        final hasResultFromIpV6Service = serviceResults.any((r) => r.hasResultFromIpV6Service);
        final hasResultFromIpV4Service = serviceResults.any((r) => r.hasResultFromIpV4Service);
        final hasResultsFromIpV4AndIpV6Services = hasResultFromIpV6Service && hasResultFromIpV4Service;
        final shouldFinishMainCompleter = (remaining == 0 || result.hasPharmacyFromIpV6 || hasResultsFromIpV4AndIpV6Services) && !mainCompleter.isCompleted;

        // First service finished — start 3-second timer for others
        if (!shouldFinishMainCompleter && !isTimerStarted) {
          isTimerStarted = true;

          Future.delayed(_graceperiodDuration, () {
            if (!mainCompleter.isCompleted) {
              // Important: calling the completer but not logCompleter here,
              // that way the main future returns early but we can still wait
              // for the logCompleter to get complete results for logging.
              mainCompleter.complete(_finalResult());
            }
          });
        }

        if (shouldFinishMainCompleter) {
          mainCompleter.complete(_finalResult());
        }

        // Call logCompleter when all services have finished
        if (remaining == 0) {
          if (logCompleter != null && !logCompleter.isCompleted) {
            logCompleter.complete(_finalResult());
          }
        }
      });
    }

    return mainCompleter.future;
  }

  static Future<DeferredDeeplinkServiceResult> _resolveWithService({
    required String apiKey,
    required DeferredDeeplinkEnvironment environment,
    required IpLookupService service,
    required Duration timeout,
    required Set<String> queriedIps,
    String? proxy,
  }) async {
    String? ip;
    int? pharmacyId;
    Duration? ipFetchDuration;
    Duration? backendQueryDuration;
    bool isDuplicate = false;
    final ipStopwatch = Stopwatch()..start();
    final backendStopwatch = Stopwatch();

    try {
      // Single timeout covering both IP fetch and backend query.
      //
      // We are using internal future with timeout instead of wrapping the whole
      // function in timeout because we want to capture results and errors from
      // both operations, and return a complete result object with
      // timings for logging (even in case of timeout).
      await (() async {
        final fetchedIp = await _fetchIp(service.url, proxy: proxy);
        ip = fetchedIp;
        ipFetchDuration = ipStopwatch.elapsed;

        // Check if we already queried backend with this IP, prevent multiple fetches.
        if (queriedIps.contains(fetchedIp)) {
          isDuplicate = true;
          pharmacyId = null;
        } else {
          // Mark as being fetched
          queriedIps.add(fetchedIp);

          backendStopwatch.start();
          pharmacyId = await _queryBackend(
            apiKey: apiKey,
            environment: environment,
            ipAddress: fetchedIp,
            proxy: proxy,
          );
          backendQueryDuration = backendStopwatch.elapsed;
        }
      }()).timeout(timeout);

      return DeferredDeeplinkServiceResult(
        serviceName: service.name,
        isIpV6Only: service.isIpV6Only,
        ip: ip,
        pharmacyId: pharmacyId,
        isDuplicate: isDuplicate,
        ipFetchDuration: ipFetchDuration,
        backendQueryDuration: backendQueryDuration,
      );
    } catch (e) {
      return DeferredDeeplinkServiceResult(
        serviceName: service.name,
        isIpV6Only: service.isIpV6Only,
        ip: ip,
        isDuplicate: isDuplicate,
        error: e,
        ipFetchDuration: ipFetchDuration ?? ipStopwatch.elapsed,
        backendQueryDuration: backendQueryDuration ?? backendStopwatch.elapsed,
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
    try {
      if (proxy != null) client.findProxy = (_) => proxy;
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
  /// or `null` if the backend found no match. Every other outcome will throw.
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

      if (response.statusCode == 404) {
        return null;  // No match found, valid response
      }

      if (response.statusCode != 200) {
        throw Exception('Backend ${response.statusCode}');
      }

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['pharmacyId'] as int;
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
    this.isIpV6Only = false,
  });

  final String name;
  final String url;
  final bool isIpV6Only;
}

/// The result of a single IP lookup service resolution.
class DeferredDeeplinkServiceResult {
  const DeferredDeeplinkServiceResult({
    required this.serviceName,
    required this.isIpV6Only,
    this.ip,
    this.pharmacyId,
    this.isDuplicate = false,
    this.error,
    this.ipFetchDuration,
    this.backendQueryDuration,
  });

  /// The name of the service that produced this result.
  final String serviceName;

  /// Whether this service is IPv6-only.
  final bool isIpV6Only;

  /// The IP address returned by the service, or `null` if lookup failed.
  final String? ip;

  /// The matched pharmacy ID, or `null` if no match was found.
  final int? pharmacyId;

  /// Whether this IP was already queried or being queried by another service.
  final bool isDuplicate;

  /// The error that occurred, or `null` if the service succeeded.
  final Object? error;

  /// The duration of the IP fetch operation.
  final Duration? ipFetchDuration;

  /// The duration of the backend query operation.
  final Duration? backendQueryDuration;

  /// Whether we successfully queried an IPv6-only service (regardless of pharmacy result).
  bool get hasResultFromIpV6Service => isIpV6Only && ip != null && error == null;

  /// Whether we successfully queried an IPv4 service (regardless of pharmacy result).
  bool get hasResultFromIpV4Service => !isIpV6Only && ip != null && error == null;

  /// Whether this result successfully obtained a pharmacy from an IPv6 address.
  bool get hasPharmacyFromIpV6 => ip != null && ip!.isIpv6 && error == null && pharmacyId != null;

  @override
  String toString() =>
      'DeferredDeeplinkServiceResult(serviceName: $serviceName, ip: $ip, pharmacyId: $pharmacyId, isDuplicate: $isDuplicate, ipFetchDuration: $ipFetchDuration, backendQueryDuration: $backendQueryDuration, error: $error)';
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
    int? pharmacyId;

    for (final result in results) {
      if (result.hasPharmacyFromIpV6) {
        return result.pharmacyId;  // IPv6 match found, prefer it immediately
      }
      if (pharmacyId == null && result.error == null && result.pharmacyId != null) {
        pharmacyId = result.pharmacyId;
      }
    }

    return pharmacyId;
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
        if (r.isDuplicate) return '${r.serviceName}: ip=${r.ip} ($ipDuration), pharmacyId=duplicate';
        if (r.pharmacyId != null) return '${r.serviceName}: ip=${r.ip} ($ipDuration), pharmacyId=${r.pharmacyId} ($backendDuration)';
        return '${r.serviceName}: ip=${r.ip} ($ipDuration), no match ($backendDuration)';
      })
      .join(';\n');

  @override
  String toString() => 'DeferredDeeplinkResult(pharmacyId: $pharmacyId, results: $results)';
}

extension _IsIpV6 on String {
  bool get isIpv6 => contains(':');
}