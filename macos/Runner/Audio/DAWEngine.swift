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

    private var currentFrame: AVAudioFramePosition = 0
    private var totalFrames: AVAudioFramePosition = 0
    private var isPlaying = false

    private init() {}

    // MARK: - INIT ENGINE
    func initEngine() {
        engine.mainMixerNode.outputVolume = 1.0

        do {
            try engine.start()
            print("🔥 DAWEngine started")
        } catch {
            print("❌ Engine start error: \(error)")
        }
    }

    // MARK: - LOAD TRACKS

    func loadTracks(paths: [String]) {

        print("🎧 Loading \(paths.count) tracks")

        stop()

        playerNodes.removeAll()
        mixerNodes.removeAll()
        audioFiles.removeAll()

        trackVolumes.removeAll()
        trackMuted.removeAll()
        trackSolo.removeAll()

        for path in paths {

            let node = AVAudioPlayerNode()
            let mixer = AVAudioMixerNode()

           let url = URL(fileURLWithPath: path)
            guard let file = try? AVAudioFile(forReading: url) else {
                print("❌ Cannot load file: \(path)")
                continue
            }
            if totalFrames == 0 {
                totalFrames = file.length
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

            print("✅ Loaded: \(url.lastPathComponent)")
        }

        do {
            try engine.start()
        } catch {
            print("❌ Engine restart error: \(error)")
        }

        updateMix()
    }

    // MARK: - PLAY

    func play() {
        isPlaying = true
        print("▶️ PLAY")

        for (index, node) in playerNodes.enumerated() {

            let file = audioFiles[index]

            node.stop()

            let framesRemaining =
                AVAudioFrameCount(
                    file.length - currentFrame
                )

            node.scheduleSegment(
                file,
                startingFrame: currentFrame,
                frameCount: framesRemaining,
                at: nil
            )

            node.play()
        }
    }

    // MARK: - STOP

    func stop() {
        isPlaying = false
        currentFrame = 0
        playerNodes.forEach {
            $0.stop()
        }

        engine.stop()

        print("⏹ STOP")
    }

    // MARK: - VOLUME

    func setVolume(
        track: Int,
        volume: Float
    ) {

        guard track >= 0,
              track < mixerNodes.count else {
            return
        }

        trackVolumes[track] = volume

        updateMix()
    }

    // MARK: - MUTE

    func mute(
        track: Int,
        muted: Bool
    ) {

        print("🎚 MUTE \(track) -> \(muted)")

        guard track >= 0,
            track < mixerNodes.count else {
            return
        }

        trackMuted[track] = muted

        updateMix()
    }

    // MARK: - SOLO

    func solo(
        track: Int,
        enabled: Bool
    ) {

        guard track >= 0,
              track < trackSolo.count else {
            return
        }

        trackSolo[track] = enabled

        updateMix()
    }

    // MARK: - MIX UPDATE

private func updateMix() {

    let hasSolo = trackSolo.contains(true)

    print("🎚 HAS SOLO: \(hasSolo)")
    print("🎚 MUTES: \(trackMuted)")
    print("🎚 SOLOS: \(trackSolo)")

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

        print("TRACK \(i) VOL = \(mixerNodes[i].outputVolume)")
    }
}

func seek(seconds: Double) {

    guard audioFiles.count > 0 else {
        return
    }

    let sampleRate = audioFiles[0].processingFormat.sampleRate

    currentFrame =
        AVAudioFramePosition(seconds * sampleRate)

    if isPlaying {
        play()
    }
}

func duration() -> Double {

    guard audioFiles.count > 0 else {
        return 0
    }

    return Double(totalFrames) /
           audioFiles[0].processingFormat.sampleRate
}

func position() -> Double {

    guard playerNodes.count > 0 else {
        return 0
    }

    guard let nodeTime =
        playerNodes[0].lastRenderTime,
        let playerTime =
        playerNodes[0].playerTime(forNodeTime: nodeTime)
    else {
        return Double(currentFrame) /
            audioFiles[0].processingFormat.sampleRate
    }

    return Double(playerTime.sampleTime + currentFrame)
        / playerTime.sampleRate
}
}