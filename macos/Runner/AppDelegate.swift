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

            case "pause":
                DAWEngine.shared.pause()
                result(nil)

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

            case "setTranspose":
                if let args = call.arguments as? [String: Any],
                let semitones = args["semitones"] as? Int {

                    DAWEngine.shared.setTranspose(
                        semitones: semitones
                    )

                    result(true)

                } else {
                    result(
                        FlutterError(
                            code: "INVALID_ARGUMENT",
                            message: "Se requiere semitones para establecer la transposición",
                            details: nil
                        )
                    )
                }

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

            case "setLoopStart":
                if let args = call.arguments as? [String: Any],
                let seconds = args["seconds"] as? Double {

                    DAWEngine.shared.setLoopStart(seconds: seconds)
                    result(true)
                } else {
                    result(
                        FlutterError(
                            code: "INVALID_ARGUMENT",
                            message: "Se requiere seconds para establecer el inicio del loop",
                            details: nil
                        )
                    )
                }

            case "setLoopEnd":
                if let args = call.arguments as? [String: Any],
                let seconds = args["seconds"] as? Double {

                    DAWEngine.shared.setLoopEnd(seconds: seconds)
                    result(true)
                } else {
                    result(
                        FlutterError(
                            code: "INVALID_ARGUMENT",
                            message: "Se requiere seconds para establecer el final del loop",
                            details: nil
                        )
                    )
                }

            case "setLoopEnabled":
                if let args = call.arguments as? [String: Any],
                let enabled = args["enabled"] as? Bool {

                    DAWEngine.shared.setLoopEnabled(enabled: enabled)
                    result(true)
                } else {
                    result(
                        FlutterError(
                            code: "INVALID_ARGUMENT",
                            message: "Se requiere enabled para activar o desactivar el loop",
                            details: nil
                        )
                    )
                }
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