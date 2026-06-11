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
                print("🔥 MUTE RECEIVED")
                if let args = call.arguments as? [String: Any],
                let index = args["index"] as? Int,
                let enabled = args["enabled"] as? Bool {

                    DAWEngine.shared.mute(
                        track: index,
                        muted: enabled
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

            case "seek":

                if let args = call.arguments as? [String: Any],
                let seconds = args["seconds"] as? Double {

                    DAWEngine.shared.seek(
                        seconds: seconds
                    )
                }

                result(true)
            case "position":
                result(
                    DAWEngine.shared.position()
                )
            case "duration":
                result(
                    DAWEngine.shared.duration()
                )
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        super.applicationDidFinishLaunching(notification)
    }
}