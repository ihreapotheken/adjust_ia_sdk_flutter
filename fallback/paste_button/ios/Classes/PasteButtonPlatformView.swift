import Flutter
import UIKit
import UniformTypeIdentifiers

class PasteButtonViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return PasteButtonPlatformView(
            frame: frame,
            viewId: viewId,
            arguments: args as? [String: Any],
            messenger: messenger
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class PasteButtonPlatformView: NSObject, FlutterPlatformView {
    private let containerView: UIView
    private let channel: FlutterMethodChannel

    init(
        frame: CGRect,
        viewId: Int64,
        arguments args: [String: Any]?,
        messenger: FlutterBinaryMessenger
    ) {
        channel = FlutterMethodChannel(
            name: "com.adjust.paste_button/view/\(viewId)",
            binaryMessenger: messenger
        )

        if #available(iOS 16.0, *) {
            containerView = PasteTargetView(channel: channel)
        } else {
            containerView = UIView(frame: frame)
        }

        super.init()

        if #available(iOS 16.0, *) {
            setupPasteControl(args: args)
        } else {
            channel.invokeMethod("unsupported", arguments: nil)
        }
    }

    func view() -> UIView {
        return containerView
    }

    @available(iOS 16.0, *)
    private func setupPasteControl(args: [String: Any]?) {
        let utTypeStrings = args?["acceptedUTTypes"] as? [String]
            ?? ["public.utf8-plain-text"]

        containerView.pasteConfiguration = UIPasteConfiguration(
            acceptableTypeIdentifiers: utTypeStrings
        )

        var cornerStyle: UIButton.Configuration.CornerStyle = .capsule
        if let cornerIndex = args?["cornerStyle"] as? Int {
            switch cornerIndex {
            case 0: cornerStyle = .capsule
            case 1: cornerStyle = .large
            case 2: cornerStyle = .medium
            case 3: cornerStyle = .small
            default: cornerStyle = .capsule
            }
        }

        var displayMode: UIPasteControl.DisplayMode = .iconAndLabel
        if let modeIndex = args?["displayMode"] as? Int {
            switch modeIndex {
            case 0: displayMode = .iconAndLabel
            case 1: displayMode = .iconOnly
            case 2: displayMode = .labelOnly
            default: displayMode = .iconAndLabel
            }
        }

        var config = UIPasteControl.Configuration()
        config.cornerStyle = cornerStyle
        config.displayMode = displayMode
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white

        let pasteControl = UIPasteControl(configuration: config)
        pasteControl.target = containerView

        pasteControl.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(pasteControl)
        NSLayoutConstraint.activate([
            pasteControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            pasteControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            pasteControl.topAnchor.constraint(equalTo: containerView.topAnchor),
            pasteControl.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
    }
}

@available(iOS 16.0, *)
class PasteTargetView: UIView {
    private let channel: FlutterMethodChannel

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func canPaste(_ itemProviders: [NSItemProvider]) -> Bool {
        return true
    }

    override func paste(itemProviders: [NSItemProvider]) {
        // UIPasteControl already grants clipboard access without a prompt,
        // so reading directly from UIPasteboard is safe and reliable here.
        if let string = UIPasteboard.general.string {
            channel.invokeMethod("onPaste", arguments: string)
            return
        }

        if let url = UIPasteboard.general.url {
            channel.invokeMethod("onPaste", arguments: url.absoluteString)
            return
        }
    }
}
