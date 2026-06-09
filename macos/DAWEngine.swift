import Foundation
import AVFoundation

final class DAWEngine {

    static let shared = DAWEngine()

    private let engine = AVAudioEngine()
    private var playerNodes: [AVAudioPlayerNode] = []
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

        stop()

        playerNodes.removeAll()
        audioFiles.removeAll()

        for path in paths {

            let node = AVAudioPlayerNode()
            engine.attach(node)

            guard let url = URL(string: path),
                  let file = try? AVAudioFile(forReading: url) else {
                continue
            }

            engine.connect(node, to: engine.mainMixerNode, format: file.processingFormat)

            playerNodes.append(node)
            audioFiles.append(file)
        }

        try? engine.start()
    }

    // MARK: PLAY
    func play() {
        for (index, node) in playerNodes.enumerated() {
            let file = audioFiles[index]
            node.scheduleFile(file, at: nil, completionHandler: nil)
            node.play()
        }
    }

    // MARK: STOP
    func stop() {
        playerNodes.forEach { $0.stop() }
        engine.stop()
    }
}