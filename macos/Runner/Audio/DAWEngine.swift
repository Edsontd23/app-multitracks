import Foundation
import AVFoundation

final class DAWEngine {
    static let shared = DAWEngine()

    private let engine = AVAudioEngine()

    private var playerNodes: [AVAudioPlayerNode] = []
    private var mixerNodes: [AVAudioMixerNode] = []
    private var pitchNodes: [AVAudioUnitTimePitch] = []
    private var transposeSemitones: Int = 0
    private var audioFiles: [AVAudioFile] = []

    private var trackVolumes: [Float] = []
    private var trackMuted: [Bool] = []
    private var trackSolo: [Bool] = []

    private var currentFrame: AVAudioFramePosition = 0
    private var totalFrames: AVAudioFramePosition = 0
    private var isPlaying = false
    private var isPaused = false

    // Posición y referencia temporal de reproducción
    private var pausedFrame: AVAudioFramePosition = 0
    private var playbackStartFrame: AVAudioFramePosition = 0
    private var playbackStartSampleTime: AVAudioFramePosition?

    // MARK: - LOOP
    private var loopEnabled = false
    private var loopStartFrame: AVAudioFramePosition = 0
    private var loopEndFrame: AVAudioFramePosition = 0

    private var loopBuffers: [AVAudioPCMBuffer] = []
    private var loopFrameCount: AVAudioFrameCount = 0

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

        // Liberar nodos de la canción anterior.
        for index in playerNodes.indices {
            let node = playerNodes[index]
            let pitchNode = pitchNodes[index]
            let mixer = mixerNodes[index]

            engine.disconnectNodeOutput(node)

            engine.disconnectNodeInput(pitchNode)
            engine.disconnectNodeOutput(pitchNode)

            engine.disconnectNodeInput(mixer)
            engine.disconnectNodeOutput(mixer)

            engine.detach(node)
            engine.detach(pitchNode)
            engine.detach(mixer)
        }

        // Liberar buffers del loop anterior.
        loopBuffers.removeAll(keepingCapacity: false)
        loopFrameCount = 0;

        totalFrames = 0
        currentFrame = 0

        loopEnabled = false
        loopStartFrame = 0
        loopEndFrame = 0

        playerNodes.removeAll()
        mixerNodes.removeAll()
        pitchNodes.removeAll()
            transposeSemitones = 0
        audioFiles.removeAll()

        trackVolumes.removeAll()
        trackMuted.removeAll()
        trackSolo.removeAll()

        for path in paths {

            let node = AVAudioPlayerNode()
            let pitchNode = AVAudioUnitTimePitch()
            let mixer = AVAudioMixerNode()

            pitchNode.pitch = Float(transposeSemitones * 100)

           let url = URL(fileURLWithPath: path)
            guard let file = try? AVAudioFile(forReading: url) else {
                print("❌ Cannot load file: \(path)")
                continue
            }
            if totalFrames == 0 {
                totalFrames = file.length
            }

            engine.attach(node)
            engine.attach(pitchNode)
            engine.attach(mixer)

            engine.connect(
                node,
                to: pitchNode,
                format: file.processingFormat
            )

            engine.connect(
                pitchNode,
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
            pitchNodes.append(pitchNode)
            audioFiles.append(file)

            trackVolumes.append(1.0)
            trackMuted.append(false)
            trackSolo.append(false)
        }

        do {
            try engine.start()
        } catch {
            print("❌ Engine restart error: \(error)")
        }

        updateMix()
    }

    func play() {
        guard !audioFiles.isEmpty else { return }

        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("❌ Error iniciando engine: \(error)")
                return
            }
        }

        // Reanudar una reproducción pausada.
        // No volver a programar los buffers.
        if isPaused {
            isPaused = false
            isPlaying = true

            playbackStartFrame = pausedFrame
            playbackStartSampleTime = nil

            playerNodes.forEach { $0.play() }

            print("▶️ RESUME - \(Double(pausedFrame) / audioFiles[0].processingFormat.sampleRate)")
            return
        }

        if loopEnabled {
            guard loopBuffers.count == playerNodes.count,
                loopFrameCount > 0 else {
                return
            }

            currentFrame = loopStartFrame
        }

        playbackStartFrame = currentFrame
        playbackStartSampleTime = nil

        isPlaying = true

        for (index, node) in playerNodes.enumerated() {
            node.stop()

            if loopEnabled {
                node.scheduleBuffer(
                    loopBuffers[index],
                    at: nil,
                    options: [.loops]
                )
            } else {
                let file = audioFiles[index]
                let startFrame = max(0, min(currentFrame, file.length))
                let framesRemaining = file.length - startFrame

                guard framesRemaining > 0 else { continue }

                node.scheduleSegment(
                    file,
                    startingFrame: startFrame,
                    frameCount: AVAudioFrameCount(framesRemaining),
                    at: nil
                )
            }

            node.play()
        }
    }

    func pause() {
        guard isPlaying else { return }

        guard let firstFile = audioFiles.first else { return }

        let sampleRate = firstFile.processingFormat.sampleRate

        // Capturar la posición exacta antes de pausar.
        pausedFrame = AVAudioFramePosition(position() * sampleRate)

        playerNodes.forEach { $0.pause() }

        isPlaying = false
        isPaused = true

        print("⏸ PAUSE - \(Double(pausedFrame) / sampleRate)")
    }

    // MARK: - STOP
    func stop() {
        isPlaying = false
        isPaused = false

        currentFrame = 0
        pausedFrame = 0
        playbackStartFrame = 0
        playbackStartSampleTime = nil

        playerNodes.forEach { $0.stop() }
        engine.stop()
    }

    // MARK: - VOLUME
    func setVolume(track: Int,volume: Float) {
        guard track >= 0, track < mixerNodes.count else { return }
        trackVolumes[track] = volume
        updateMix()
    }

    // MARK: - MUTE
    func mute(track: Int,muted: Bool) {
        print("🎚 MUTE \(track) -> \(muted)")

        guard track >= 0,
            track < mixerNodes.count else {
            return
        }

        trackMuted[track] = muted

        updateMix()
    }

    // MARK: - SOLO
    func solo(track: Int,enabled: Bool) {

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

    // MARK: - TRANSPOSE
    func setTranspose(semitones: Int) {
        guard (-12...12).contains(semitones) else {
            print("⚠️ Transposición fuera de rango")
            return
        }

        transposeSemitones = semitones

        let pitchInCents = Float(semitones * 100)

        for pitchNode in pitchNodes {
            pitchNode.pitch = pitchInCents
        }

        print("🎹 TRANSPOSE: \(semitones) semitonos")
    }

    // MARK: - SEEK
    func seek(seconds: Double) {
        guard let file = audioFiles.first else { return }

        let sampleRate = file.processingFormat.sampleRate

        let requestedFrame = AVAudioFramePosition(
            max(0, seconds) * sampleRate
        )

        currentFrame = min(requestedFrame, totalFrames)

        if loopEnabled &&
            (currentFrame < loopStartFrame || currentFrame >= loopEndFrame) {
            currentFrame = loopStartFrame
        }

        if isPlaying {
            play()
            return
        }

        if isPaused {
            playerNodes.forEach { $0.stop() }

            isPaused = false
            pausedFrame = currentFrame
            playbackStartFrame = currentFrame
            playbackStartSampleTime = nil
        }
    }

    // MARK: - POSITION
    func position() -> Double {
        guard let firstFile = audioFiles.first else { return 0 }

        let sampleRate = firstFile.processingFormat.sampleRate

        // Durante la pausa nunca consultar el tiempo del nodo.
        if isPaused {
            return Double(pausedFrame) / sampleRate
        }

        guard isPlaying,
            let firstNode = playerNodes.first,
            let nodeTime = firstNode.lastRenderTime,
            let playerTime = firstNode.playerTime(forNodeTime: nodeTime) else {
            return Double(currentFrame) / sampleRate
        }

        let sampleTime = AVAudioFramePosition(playerTime.sampleTime)

        // Establecer la referencia al comenzar cada reproducción/reanudación.
        if playbackStartSampleTime == nil {
            playbackStartSampleTime = sampleTime
        }

        let elapsedFrames = max(
            0,
            sampleTime - playbackStartSampleTime!
        )

        if loopEnabled {
            let loopLength = loopEndFrame - loopStartFrame

            guard loopLength > 0 else {
                return Double(loopStartFrame) / sampleRate
            }

            let initialOffset = playbackStartFrame - loopStartFrame
            let offset = (initialOffset + elapsedFrames) % loopLength

            return Double(loopStartFrame + offset) / sampleRate
        }

        let absoluteFrame = min(
            playbackStartFrame + elapsedFrames,
            totalFrames
        )

        return Double(absoluteFrame) / sampleRate
    }

    // MARK: - DURATION
    func duration() -> Double {
        guard let file = audioFiles.first else {
            return 0
        }

        let sampleRate = file.processingFormat.sampleRate

        guard sampleRate > 0 else {
            return 0
        }

        return Double(totalFrames) / sampleRate
    }

    // MARK: - LOOP START
    func setLoopStart(seconds: Double) {
        guard let file = audioFiles.first else { return }

        let sampleRate = file.processingFormat.sampleRate
        let frame = AVAudioFramePosition(seconds * sampleRate)

        loopStartFrame = max(0, min(frame, totalFrames))

        rebuildLoopBuffers()
        invalidatePausedScheduleForLoopChange()

        if isPlaying {
            play()
        }

        print("🔁 LOOP START: \(seconds)s")
    }

    // MARK: - LOOP END
    func setLoopEnd(seconds: Double) {
        guard let file = audioFiles.first else { return }

        let sampleRate = file.processingFormat.sampleRate
        let frame = AVAudioFramePosition(seconds * sampleRate)

        loopEndFrame = max(0, min(frame, totalFrames))

        rebuildLoopBuffers()
        invalidatePausedScheduleForLoopChange()

        if isPlaying {
            play()
        }

        print("🔁 LOOP END: \(seconds)s")
    }

    // MARK: - LOOP ENABLED
    func setLoopEnabled(enabled: Bool) {
        loopEnabled = enabled

        if enabled {
            rebuildLoopBuffers()
            invalidatePausedScheduleForLoopChange()

            guard !loopBuffers.isEmpty else {
                loopEnabled = false
                print("⚠️ No se pudo activar el loop")
                return
            }

            if currentFrame < loopStartFrame ||
                currentFrame >= loopEndFrame {
                currentFrame = loopStartFrame
            }
        }

        if isPlaying {
            play()
        }

        print("🔁 LOOP ENABLED: \(loopEnabled)")
    }

    // MARK: - BUILD LOOP BUFFERS
    private func rebuildLoopBuffers() {
        loopBuffers.removeAll()
        loopFrameCount = 0

        guard !audioFiles.isEmpty,
            loopEndFrame > loopStartFrame else {
            return
        }

        guard let referenceFile = audioFiles.first else {
            return
        }

        let referenceSampleRate =
            referenceFile.processingFormat.sampleRate

        let startSeconds =
            Double(loopStartFrame) / referenceSampleRate

        let endSeconds =
            Double(loopEndFrame) / referenceSampleRate

        var buffers: [AVAudioPCMBuffer] = []

        for file in audioFiles {
            let sampleRate = file.processingFormat.sampleRate

            let startFrame = AVAudioFramePosition(
                startSeconds * sampleRate
            )

            let endFrame = AVAudioFramePosition(
                endSeconds * sampleRate
            )

            let frameCount = endFrame - startFrame

            guard frameCount > 0,
                endFrame <= file.length,
                frameCount <= AVAudioFramePosition(UInt32.max) else {
                print("❌ Intervalo de loop inválido")
                return
            }

            let originalPosition = file.framePosition

            do {
                guard let buffer = AVAudioPCMBuffer(
                    pcmFormat: file.processingFormat,
                    frameCapacity: AVAudioFrameCount(frameCount)
                ) else {
                    print("❌ No se pudo crear el buffer")
                    return
                }

                file.framePosition = startFrame

                try file.read(
                    into: buffer,
                    frameCount: AVAudioFrameCount(frameCount)
                )

                file.framePosition = originalPosition

                guard buffer.frameLength > 0 else {
                    print("❌ Buffer de loop vacío")
                    return
                }

                buffers.append(buffer)

            } catch {
                file.framePosition = originalPosition
                print("❌ Error preparando loop: \(error)")
                return
            }
        }

        guard buffers.count == audioFiles.count else {
            return
        }

        loopBuffers = buffers

        if let firstBuffer = buffers.first {
            loopFrameCount = firstBuffer.frameLength
        }

        print("✅ LOOP BUFFERS: \(loopBuffers.count)")
    }

    private func invalidatePausedScheduleForLoopChange() {
        guard isPaused else { return }

        playerNodes.forEach { $0.stop() }

        isPaused = false

        if loopEnabled {
            currentFrame = loopStartFrame
        } else {
            currentFrame = pausedFrame
        }

        pausedFrame = currentFrame
        playbackStartFrame = currentFrame
        playbackStartSampleTime = nil
    }
}