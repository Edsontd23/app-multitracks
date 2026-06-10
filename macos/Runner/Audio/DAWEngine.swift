import Foundation
import AVFoundation

final class DAWEngine {

    static let shared = DAWEngine()

    private let engine = AVAudioEngine()
    private var playerNodes: [AVAudioPlayerNode] = []
    private var mixerNodes: [AVAudioMixerNode] = []
    private var audioFiles: [AVAudioFile] = []
    private var trackVolumes: [Float] = []
    private var trackMuted: [Bool] = []
    private var trackSolo: [Bool] = []

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
        playerNodes.removeAll()

        trackVolumes.removeAll()
        trackMuted.removeAll()
        trackSolo.removeAll()

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
            trackVolumes.append(1.0)
            trackMuted.append(false)
            trackSolo.append(false)
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

    func setVolume(track: Int,volume: Float) {
        guard track < trackVolumes.count else {
            return
        }

        trackVolumes[track] = volume

        updateMix()
    }

    func mute(track: Int,enabled: Bool) {

        guard track < trackMuted.count else {
            return
        }

        trackMuted[track] = enabled

        updateMix()
    }

    func solo(track: Int,enabled: Bool) {

        guard track < trackSolo.count else {
            return
        }

        trackSolo[track] = enabled

        updateMix()
    }

    private func updateMix() {

        let hasSolo = trackSolo.contains(true)

        for i in 0..<mixerNodes.count {

            if hasSolo {

                mixerNodes[i].outputVolume =
                    trackSolo[i]
                    ? trackVolumes[i]
                    : 0.0

            } else {

                mixerNodes[i].outputVolume =
                    trackMuted[i]
                    ? 0.0
                    : trackVolumes[i]
            }
        }
    }
}