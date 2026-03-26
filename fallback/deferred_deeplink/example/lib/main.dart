import 'dart:convert';

import 'package:deferred_deeplink/deferred_deeplink.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const DeferredDeeplinkExampleApp());
}

class DeferredDeeplinkExampleApp extends StatelessWidget {
  const DeferredDeeplinkExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deferred Deeplink Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const DeferredDeeplinkDemo(),
    );
  }
}

class DeferredDeeplinkDemo extends StatefulWidget {
  const DeferredDeeplinkDemo({super.key});

  @override
  State<DeferredDeeplinkDemo> createState() => _DeferredDeeplinkDemoState();
}

class _DeferredDeeplinkDemoState extends State<DeferredDeeplinkDemo> {
  final _apiKeyController = TextEditingController();
  DeferredDeeplinkEnvironment _environment = DeferredDeeplinkEnvironment.qa;

  String _deviceInfoJson = '';
  String _webFingerprintJson = '';
  String _resolvedDeeplink = '';
  bool _isLoading = false;
  bool _showWebView = false;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _collectDeviceInfo() async {
    final info = await DeviceInfoCollector.collect();
    setState(() {
      _deviceInfoJson = const JsonEncoder.withIndent('  ').convert(info);
    });
  }

  void _collectWebFingerprint() {
    setState(() {
      _webFingerprintJson = '';
      _showWebView = true;
    });
  }

  Future<void> _resolveDeeplink() async {
    setState(() {
      _isLoading = true;
      _resolvedDeeplink = '';
    });

    await _collectDeviceInfo();

    try {
      final pharmacyId = await DeferredDeeplink.resolve(apiKey: _apiKeyController.text, timeout: const Duration(seconds: 10), environment: _environment);
      setState(() => _resolvedDeeplink = 'Pharmacy ID: $pharmacyId');
    } on Exception catch (e) {
      setState(() => _resolvedDeeplink = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deferred Deeplink Demo')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _apiKeyController,
                  decoration: const InputDecoration(labelText: 'API Key', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                SegmentedButton<DeferredDeeplinkEnvironment>(
                  segments: const [
                    ButtonSegment(value: DeferredDeeplinkEnvironment.dev, label: Text('Dev')),
                    ButtonSegment(value: DeferredDeeplinkEnvironment.qa, label: Text('QA')),
                    ButtonSegment(value: DeferredDeeplinkEnvironment.prod, label: Text('Prod')),
                  ],
                  selected: {_environment},
                  onSelectionChanged: (selection) => setState(() => _environment = selection.first),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _collectDeviceInfo,
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Native Info'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _collectWebFingerprint,
                        icon: const Icon(Icons.web),
                        label: const Text('Web Info'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _resolveDeeplink,
                  icon: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.link),
                  label: const Text('Resolve Deeplink'),
                ),
                const SizedBox(height: 24),
                if (_deviceInfoJson.isNotEmpty) ...[
                  JsonSection(title: 'Native Device Info (JSON):', json: _deviceInfoJson),
                  const SizedBox(height: 24),
                ],
                if (_webFingerprintJson.isNotEmpty) ...[
                  JsonSection(title: 'Web Fingerprint (JSON):', json: _webFingerprintJson),
                  const SizedBox(height: 24),
                ],
                if (_resolvedDeeplink.isNotEmpty) ...[
                  const Text('Pharmacy Pre-selection Identifier:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _resolvedDeeplink.startsWith('http') ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _resolvedDeeplink.startsWith('http') ? Colors.green.shade300 : Colors.orange.shade300),
                    ),
                    child: SelectableText(
                      _resolvedDeeplink,
                      style: TextStyle(
                        fontSize: 14,
                        color: _resolvedDeeplink.startsWith('http') ? Colors.green.shade900 : Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Invisible WebView for fingerprint collection
          if (_showWebView)
            WebFingerprintCollector(
              onCollected: (data) {
                setState(() {
                  _showWebView = false;
                  _webFingerprintJson = const JsonEncoder.withIndent('  ').convert(data);
                });
              },
              onError: (error) {
                setState(() {
                  _showWebView = false;
                  _webFingerprintJson = 'Error: $error';
                });
              },
            ),
        ],
      ),
    );
  }
}

class JsonSection extends StatelessWidget {
  const JsonSection({super.key, required this.title, required this.json});

  final String title;
  final String json;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'Copy JSON',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: json));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)));
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SingleChildScrollView(
            child: SelectableText(json, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
        ),
      ],
    );
  }
}
