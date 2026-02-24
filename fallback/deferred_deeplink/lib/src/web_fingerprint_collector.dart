import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Cached fingerprint JS loaded from the asset bundle.
String? _cachedFingerprintJs;

/// Loads `web/fingerprint.js` from the package assets.
Future<String> _loadFingerprintJs() async {
  _cachedFingerprintJs ??= await rootBundle.loadString(
    'packages/deferred_deeplink/web/fingerprint.js',
  );
  return _cachedFingerprintJs!;
}

/// Builds the HTML page that runs fingerprint collection and sends
/// the result back to Dart via a `FlutterFingerprint` JavaScript channel.
String _buildHtml(String js, {String? endpoint}) {
  final resolveSnippet = endpoint != null
      ? '''
    let deeplink = null;
    try {
      const resp = await fetch("$endpoint", {
        method: "POST",
        headers: {"Content-Type": "application/json", "Accept": "application/json"},
        body: JSON.stringify(data),
      });
      if (resp.ok) {
        const json = await resp.json();
        deeplink = json.deeplink || null;
      }
    } catch (_) {}
    data._resolvedDeeplink = deeplink;'''
      : '';

  return '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body>
<script>
$js

(async function() {
  try {
    const data = await DeviceFingerprint.collect();
    $resolveSnippet
    FlutterFingerprint.postMessage(JSON.stringify(data));
  } catch (e) {
    FlutterFingerprint.postMessage(JSON.stringify({error: e.message}));
  }
})();
</script>
</body>
</html>
''';
}

/// Collects browser-side device fingerprint signals using a WebView.
///
/// This widget renders an invisible WebView that loads the shared
/// `web/fingerprint.js` asset to collect the same signals a browser
/// would produce on the same device. The collected data is returned
/// via the [onCollected] callback.
///
/// Usage:
/// ```dart
/// WebFingerprintCollector(
///   onCollected: (data) {
///     print(data); // {userAgent: ..., screenWidth: ..., ...}
///   },
/// )
/// ```
class WebFingerprintCollector extends StatefulWidget {
  /// Creates a [WebFingerprintCollector] widget.
  const WebFingerprintCollector({
    super.key,
    required this.onCollected,
    this.onError,
    this.endpoint,
  });

  /// Called when the web fingerprint data has been collected.
  final ValueChanged<Map<String, dynamic>> onCollected;

  /// Called if an error occurs during collection.
  final ValueChanged<String>? onError;

  /// If provided, the fingerprint data is also POSTed to this endpoint
  /// and the response deeplink (if any) is included in the result under
  /// the key `_resolvedDeeplink`.
  final String? endpoint;

  /// Collects web fingerprint data using a temporary WebView.
  ///
  /// Returns the fingerprint as a [Map], or `null` on failure.
  static Future<Map<String, dynamic>?> collect() async {
    final js = await _loadFingerprintJs();
    final html = _buildHtml(js);
    final completer = Completer<Map<String, dynamic>?>();

    // Stored in the closure so it is retained until the completer fires.
    late final WebViewController controller;
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterFingerprint',
        onMessageReceived: (message) {
          if (!completer.isCompleted) {
            try {
              final data =
                  jsonDecode(message.message) as Map<String, dynamic>;
              completer.complete(data);
            } catch (e) {
              completer.complete(null);
            }
          }
          // Reference controller to prevent GC.
          assert(controller.hashCode >= 0);
        },
      )
      ..loadHtmlString(html);

    // Timeout after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      // Reference controller to prevent GC.
      assert(controller.hashCode >= 0);
    });

    return completer.future;
  }

  @override
  State<WebFingerprintCollector> createState() =>
      _WebFingerprintCollectorState();
}

class _WebFingerprintCollectorState extends State<WebFingerprintCollector> {
  WebViewController? _controller;
  bool _collected = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    final js = await _loadFingerprintJs();
    if (!mounted) return;

    final html = _buildHtml(js, endpoint: widget.endpoint);

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterFingerprint',
        onMessageReceived: (message) {
          if (_collected) return;
          _collected = true;
          try {
            final data =
                jsonDecode(message.message) as Map<String, dynamic>;
            widget.onCollected(data);
          } catch (e) {
            widget.onError?.call('Failed to parse fingerprint: $e');
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            if (!_collected) {
              widget.onError?.call(error.description);
            }
          },
        ),
      )
      ..loadHtmlString(html);

    if (mounted) {
      setState(() {
        _controller = controller;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }
    // Zero-size WebView — invisible but functional.
    return SizedBox(
      width: 0,
      height: 0,
      child: WebViewWidget(controller: controller),
    );
  }
}
