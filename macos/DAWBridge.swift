import Foundation
import FlutterMacOS

public class DAWBridge: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {

        let channel = FlutterMethodChannel(
            name: "daw_engine",
            binaryMessenger: registrar.messenger
        )

        let instance = DAWBridge()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

        switch call.method {

        case "loadTracks":
            if let args = call.arguments as? [String: Any],
               let paths = args["paths"] as? [String] {

                DAWEngine.shared.loadTracks(paths: paths)
                result(true)
            } else {
                result(false)
            }

        case "play":
            DAWEngine.shared.play()
            result(true)

        case "stop":
            DAWEngine.shared.stop()
            result(true)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}