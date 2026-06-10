import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {

    override func applicationDidFinishLaunching(
        _ notification: Notification
    ) {

        guard let controller =
            mainFlutterWindow?.contentViewController
                as? FlutterViewController
        else {
            return
        }

        let channel = FlutterMethodChannel(
            name: "daw_engine",
            binaryMessenger: controller.engine.binaryMessenger
        )

        channel.setMethodCallHandler { call, result in

            switch call.method {

            case "init":
                DAWEngine.shared.initEngine()
                result(true)

            case "play":
                DAWEngine.shared.play()
                result(true)

            case "stop":
                DAWEngine.shared.stop()
                result(true)

            case "loadTracks":

                if let args = call.arguments as? [String: Any],
                   let paths = args["paths"] as? [String] {

                    DAWEngine.shared.loadTracks(paths: paths)
                }

                result(true)

            case "setVolume":
                if let args = call.arguments as? [String: Any],
                let index = args["index"] as? Int,
                let volume = args["volume"] as? Double {

                    DAWEngine.shared.setVolume(
                        track: index,
                        volume: Float(volume)
                    )
                }
                result(true)
            case "mute":
                if let args = call.arguments as? [String: Any],
                let index = args["index"] as? Int,
                let enabled = args["enabled"] as? Bool {

                    DAWEngine.shared.mute(
                        track: index,
                        enabled: enabled
                    )
                }

                result(true)
            case "solo":
                if let args = call.arguments as? [String: Any],
                let index = args["index"] as? Int,
                let enabled = args["enabled"] as? Bool {

                    DAWEngine.shared.solo(
                        track: index,
                        enabled: enabled
                    )
                }

                result(true)

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        super.applicationDidFinishLaunching(notification)
    }
}