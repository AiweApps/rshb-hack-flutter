import AVFoundation
import Speech
import SwiftUI

/// Transcribes a short microphone recording on the device into the assistant draft.
/// Audio never enters the shared component or the assistant service.
@MainActor
final class AssistantSpeechInput: ObservableObject {
    enum Phase: Equatable {
        case idle
        case authorizing
        case recording
        case finishing
        case failed
    }

    enum Failure: Equatable {
        case speechPermissionDenied
        case microphonePermissionDenied
        case onDeviceUnavailable
        case unavailable
        case recordingFailed
        case recognitionFailed
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var failure: Failure?

    var isBusy: Bool {
        phase == .authorizing || phase == .recording || phase == .finishing
    }

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var draftBeforeRecording = ""
    private var onTranscript: ((String) -> Void)?
    private var generation = 0

    func start(draft: String, locale: Locale, onTranscript: @escaping (String) -> Void) {
        guard !isBusy else { return }
        tearDown()
        generation += 1
        let currentGeneration = generation
        draftBeforeRecording = draft
        self.onTranscript = onTranscript
        failure = nil
        phase = .authorizing

        Task { [weak self] in
            let speechStatus = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
            }
            guard let self, self.generation == currentGeneration else { return }
            guard speechStatus == .authorized else {
                self.fail(.speechPermissionDenied)
                return
            }

            let microphoneAllowed = await AVAudioApplication.requestRecordPermission()
            guard self.generation == currentGeneration else { return }
            guard microphoneAllowed else {
                self.fail(.microphonePermissionDenied)
                return
            }
            self.beginRecording(locale: locale, generation: currentGeneration)
        }
    }

    func stop() {
        guard phase == .recording else { return }
        phase = .finishing
        stopMicrophone()
        recognitionRequest?.endAudio()
        recognitionTask?.finish()

        let currentGeneration = generation
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard let self, self.generation == currentGeneration, self.phase == .finishing else { return }
            self.finish()
        }
    }

    /// Explicit cancellation discards this recording. Leaving the screen keeps partial draft text.
    func cancel(discardTranscript: Bool) {
        guard phase != .idle else { return }
        generation += 1
        if discardTranscript { onTranscript?(draftBeforeRecording) }
        tearDown()
        failure = nil
        phase = .idle
    }

    private func beginRecording(locale: Locale, generation currentGeneration: Int) {
        guard let recognizer = SFSpeechRecognizer(locale: locale) else {
            fail(.unavailable)
            return
        }
        guard recognizer.supportsOnDeviceRecognition else {
            fail(.onDeviceUnavailable)
            return
        }
        guard recognizer.isAvailable else {
            fail(.unavailable)
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = true
        let engine = AVAudioEngine()
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            fail(.recordingFailed)
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement)
            try AVAudioSession.sharedInstance().setActive(true)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                request.append(buffer)
            }
            audioEngine = engine
            recognitionRequest = request
            engine.prepare()
            try engine.start()
        } catch {
            fail(.recordingFailed)
            return
        }

        phase = .recording
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self, self.generation == currentGeneration else { return }
                if let result {
                    let spokenText = result.bestTranscription.formattedString
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !spokenText.isEmpty {
                        let separator = self.draftBeforeRecording.isEmpty ||
                            self.draftBeforeRecording.hasSuffix(" ") ? "" : " "
                        self.onTranscript?(self.draftBeforeRecording + separator + spokenText)
                    }
                    if result.isFinal {
                        self.finish()
                        return
                    }
                }
                if error != nil {
                    if self.phase == .finishing {
                        self.finish()
                    } else {
                        self.fail(.recognitionFailed)
                    }
                }
            }
        }

        // A single tap starts a short dictation, never an open-ended listening session.
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(45))
            guard let self, self.generation == currentGeneration, self.phase == .recording else { return }
            self.stop()
        }
    }

    private func finish() {
        generation += 1
        tearDown()
        phase = .idle
    }

    private func fail(_ reason: Failure) {
        generation += 1
        tearDown()
        failure = reason
        phase = .failed
    }

    private func stopMicrophone() {
        if audioEngine?.isRunning == true { audioEngine?.stop() }
        audioEngine?.inputNode.removeTap(onBus: 0)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func tearDown() {
        stopMicrophone()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        audioEngine = nil
        onTranscript = nil
    }
}
