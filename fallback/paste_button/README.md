# paste_button

A Flutter plugin that wraps iOS 16+ [`UIPasteControl`](https://developer.apple.com/documentation/uikit/uipastecontrol) as a native platform view. The system-rendered paste button lets users paste clipboard content **without triggering the iOS paste permission prompt**.

## Platform support

| Platform | Supported |
|----------|-----------|
| iOS 16+  | Yes       |
| iOS < 16 | Renders nothing (`SizedBox.shrink`) |
| Android  | Renders nothing (`SizedBox.shrink`) |

## Usage

### Basic paste button

```dart
import 'package:paste_button/paste_button.dart';

PasteButton(
  onPaste: (String text) {
    print('Pasted: $text');
  },
)
```

### Configuration

```dart
PasteButton(
  onPaste: (String text) { /* ... */ },
  cornerStyle: PasteButtonCornerStyle.capsule,  // capsule, large, medium, small
  displayMode: PasteButtonDisplayMode.iconOnly,  // iconAndLabel, iconOnly, labelOnly
  acceptedUTTypes: ['public.utf8-plain-text'],   // UTType identifiers
  width: 130,
  height: 48,
)
```

### Check clipboard content

Returns `true` if the clipboard contains text or a URL. This check does **not** trigger the paste permission prompt.

```dart
final hasContent = await PasteButton.hasClipboardContent();
```

### Clear clipboard

```dart
await PasteButton.clearClipboard();
```

## API reference

### `PasteButton` widget

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `onPaste` | `ValueChanged<String>` | required | Called with the pasted text |
| `cornerStyle` | `PasteButtonCornerStyle` | `capsule` | Corner radius style |
| `displayMode` | `PasteButtonDisplayMode` | `iconAndLabel` | Icon, label, or both |
| `acceptedUTTypes` | `List<String>` | `['public.utf8-plain-text']` | Accepted content types |
| `width` | `double` | `130` | Platform view width |
| `height` | `double` | `48` | Platform view height |

### Static methods

| Method | Returns | Description |
|--------|---------|-------------|
| `hasClipboardContent()` | `Future<bool>` | Check if clipboard has text/URL content (no permission prompt) |
| `clearClipboard()` | `Future<void>` | Clear all clipboard content |

## How it works

`UIPasteControl` is a system-provided button introduced in iOS 16. When the user taps it, iOS grants clipboard access to the app without showing the "App would like to paste" permission dialog. This works because the tap is an explicit user action on a system-controlled UI element.

Under the hood, the plugin:

1. Registers a `FlutterPlatformViewFactory` that creates native `UIPasteControl` instances
2. Embeds them in Flutter via `UiKitView`
3. Communicates paste events back to Dart through per-view `MethodChannel`s
