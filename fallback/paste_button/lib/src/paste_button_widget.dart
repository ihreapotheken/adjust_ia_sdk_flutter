import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The visual style of the corners on the paste button.
enum PasteButtonCornerStyle {
  /// Capsule-shaped corners.
  capsule,

  /// Large rounded corners.
  large,

  /// Medium rounded corners.
  medium,

  /// Small rounded corners.
  small,
}

/// Controls what content the paste button displays.
enum PasteButtonDisplayMode {
  /// Shows both an icon and a label.
  iconAndLabel,

  /// Shows only an icon.
  iconOnly,

  /// Shows only a label.
  labelOnly,
}

/// A Flutter widget that embeds the native iOS UIPasteControl (iOS 16+).
///
/// On iOS versions earlier than 16 or on non-iOS platforms, this widget
/// renders as a zero-sized [SizedBox] (effectively invisible).
///
/// Example usage:
/// ```dart
/// PasteButton(
///   onPaste: (String text) {
///     print('Pasted: $text');
///   },
/// )
/// ```
class PasteButton extends StatefulWidget {
  /// Creates a paste button.
  const PasteButton({
    super.key,
    required this.onPaste,
    this.acceptedUTTypes = const ['public.utf8-plain-text'],
    this.cornerStyle = PasteButtonCornerStyle.capsule,
    this.displayMode = PasteButtonDisplayMode.iconAndLabel,
    this.width = 130,
    this.height = 48,
  });

  static const MethodChannel _methodChannel = MethodChannel('com.adjust.paste_button/methods');

  /// Returns `true` if the system clipboard contains text or URL content.
  ///
  /// This check does **not** trigger the iOS paste permission prompt.
  /// On non-iOS platforms this always returns `false`.
  static Future<bool> hasClipboardContent() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }
    final result = await _methodChannel.invokeMethod<bool>('hasClipboardContent');
    return result ?? false;
  }

  /// Clears all content from the system clipboard.
  ///
  /// On non-iOS platforms this is a no-op.
  static Future<void> clearClipboard() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    await _methodChannel.invokeMethod<void>('clearClipboard');
  }

  /// Called when the user taps the paste button and the system delivers
  /// the clipboard content.
  final ValueChanged<String> onPaste;

  /// The Uniform Type Identifiers accepted by this paste button.
  ///
  /// Defaults to `['public.utf8-plain-text']`.
  final List<String> acceptedUTTypes;

  /// The corner style of the paste button.
  final PasteButtonCornerStyle cornerStyle;

  /// The display mode of the paste button.
  final PasteButtonDisplayMode displayMode;

  /// The width allocated for the platform view.
  final double width;

  /// The height allocated for the platform view.
  final double height;

  @override
  State<PasteButton> createState() => _PasteButtonState();
}

class _PasteButtonState extends State<PasteButton> {
  static const String _viewType = 'com.adjust.paste_button/view';

  bool _isUnsupported = false;

  void _onPlatformViewCreated(int viewId) {
    final channel = MethodChannel('$_viewType/$viewId');
    channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPaste':
        final String pastedText = call.arguments as String;
        widget.onPaste(pastedText);
      case 'unsupported':
        setState(() {
          _isUnsupported = true;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS || _isUnsupported) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: UiKitView(
        viewType: _viewType,
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParams: <String, dynamic>{
          'acceptedUTTypes': widget.acceptedUTTypes,
          'cornerStyle': widget.cornerStyle.index,
          'displayMode': widget.displayMode.index,
        },
        creationParamsCodec: const StandardMessageCodec(),
      ),
    );
  }
}
