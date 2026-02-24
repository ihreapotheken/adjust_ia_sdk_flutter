import Flutter
import UIKit

@objc(PasteButtonPlugin)
public class PasteButtonPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let factory = PasteButtonViewFactory(messenger: registrar.messenger())
        registrar.register(
            factory,
            withId: "com.adjust.paste_button/view"
        )
        let channel = FlutterMethodChannel(
            name: "com.adjust.paste_button/methods",
            binaryMessenger: registrar.messenger()
        )
        let instance = PasteButtonPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        switch call.method {
        case "hasClipboardContent":
            let pasteboard = UIPasteboard.general
            result(pasteboard.hasStrings || pasteboard.hasURLs)
        case "clearClipboard":
            UIPasteboard.general.items = []
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
