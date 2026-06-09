import Foundation
import AVFoundation

final class DAWEngine {

    static let shared = DAWEngine()

    private let engine = AVAudioEngine()
    private var playerNodes: [AVAudioPlayerNode] = []
    private var mixerNodes: [AVAudioMixerNode] = []
    private var audioFiles: [AVAudioFile] = []

    private init() {}

    // MARK: INIT ENGINE
    func initEngine() {
        engine.mainMixerNode.outputVolume = 1.0
        try? engine.start()
        print("DAWEngine started")
    }

    // MARK: LOAD TRACKS (dinámico)
    func loadTracks(paths: [String]) {
        print("Loading \(paths.count) tracks")
        stop()

        playerNodes.removeAll()
        audioFiles.removeAll()
        mixerNodes.removeAll()

        for path in paths {

            let node = AVAudioPlayerNode()
            let mixer = AVAudioMixerNode()

            guard let url = URL(string: path),
                let file = try? AVAudioFile(forReading: url) else {
                continue
            }

            engine.attach(node)
            engine.attach(mixer)

            engine.connect(
                node,
                to: mixer,
                format: file.processingFormat
            )

            engine.connect(
                mixer,
                to: engine.mainMixerNode,
                format: file.processingFormat
            )

            mixer.outputVolume = 1.0

            playerNodes.append(node)
            mixerNodes.append(mixer)
            audioFiles.append(file)
        }

        try? engine.start()
    }

    // MARK: PLAY
    func play() {

        print("▶️ PLAY")

        for (index, node) in playerNodes.enumerated() {
            let file = audioFiles[index]

            node.scheduleFile(
                file,
                at: nil,
                completionHandler: nil
            )

            node.play()
        }
    }

    // MARK: STOP
    func stop() {
        playerNodes.forEach { $0.stop() }
        engine.stop()
    }

    func setVolume(track: Int, volume: Float) {
        guard track >= 0,
            track < mixerNodes.count else {
            return
        }
        mixerNodes[track].outputVolume = volume
    }

    func mute(track: Int, enabled: Bool) {

        guard track >= 0,
            track < mixerNodes.count else {
            return
        }

        mixerNodes[track].outputVolume = enabled ? 0 : 1
    }
}