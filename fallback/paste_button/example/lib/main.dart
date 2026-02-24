import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paste_button/paste_button.dart';

void main() {
  runApp(const PasteButtonExampleApp());
}

class PasteButtonExampleApp extends StatelessWidget {
  const PasteButtonExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paste Button Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const PasteButtonDemo(),
    );
  }
}

class PasteButtonDemo extends StatefulWidget {
  const PasteButtonDemo({super.key});

  @override
  State<PasteButtonDemo> createState() => _PasteButtonDemoState();
}

class _PasteButtonDemoState extends State<PasteButtonDemo> {
  final _copyController = TextEditingController(text: 'Hello from clipboard!');
  String _pastedContent = '';
  bool _hasClipboardContent = false;

  @override
  void initState() {
    super.initState();
    _checkClipboard();
  }

  @override
  void dispose() {
    _copyController.dispose();
    super.dispose();
  }

  Future<void> _checkClipboard() async {
    final hasContent = await PasteButton.hasClipboardContent();
    setState(() {
      _hasClipboardContent = hasContent;
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _copyController.text));
    _checkClipboard();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  Future<void> _clearClipboard() async {
    await PasteButton.clearClipboard();
    await _checkClipboard();
    if (mounted) {
      setState(() {
        _pastedContent = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paste Button Demo')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _copyController,
                decoration: InputDecoration(
                  labelText: 'Text to copy',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(icon: const Icon(Icons.copy), onPressed: _copyToClipboard),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Tap the system Paste button below to paste\n'
                'clipboard content without a permission prompt.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_hasClipboardContent) ...[
                PasteButton(
                  onPaste: (String text) {
                    setState(() {
                      _pastedContent = text;
                    });
                  },
                  cornerStyle: PasteButtonCornerStyle.capsule,
                  displayMode: PasteButtonDisplayMode.iconOnly,
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _clearClipboard,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear clipboard'),
                ),
              ] else ...[
                Text('No clipboard content', style: TextStyle(color: Colors.grey.shade500)),
              ],
              const SizedBox(height: 32),
              if (_pastedContent.isNotEmpty) ...[
                const Text('Pasted content:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SelectableText(_pastedContent),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
