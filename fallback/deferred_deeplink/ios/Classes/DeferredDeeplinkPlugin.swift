import Flutter
import UIKit

@objc(DeferredDeeplinkPlugin)
public class DeferredDeeplinkPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.adjust.deferred_deeplink/methods",
            binaryMessenger: registrar.messenger()
        )
        let instance = DeferredDeeplinkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        switch call.method {
        case "getDeviceInfo":
            let collector = DeviceInfoCollector()
            result(collector.collect())
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
