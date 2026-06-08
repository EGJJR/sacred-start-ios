//
//  SpeechTranscriptionService.swift
//  DevotionLock
//

import AVFoundation
import Speech

enum SpeechTranscriptionError: LocalizedError {
    case recognizerUnavailable
    case authorizationDenied
    case audioSessionFailed

    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable: "Speech recognition is not available on this device."
        case .authorizationDenied: "Microphone and speech recognition access are required for voice sessions."
        case .audioSessionFailed: "Could not start the audio session."
        }
    }
}

@MainActor
@Observable
final class SpeechTranscriptionService {
    var transcript = ""
    var isListening = false
    var authorizationDenied = false

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func requestAuthorization() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            authorizationDenied = true
            return false
        }

        let micGranted: Bool
        if #available(iOS 17.0, *) {
            micGranted = await AVAudioApplication.requestRecordPermission()
        } else {
            micGranted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }

        authorizationDenied = !micGranted
        return micGranted
    }

    func start() throws {
        guard speechRecognizer?.isAvailable == true else {
            throw SpeechTranscriptionError.recognizerUnavailable
        }
        stop()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else {
            throw SpeechTranscriptionError.recognizerUnavailable
        }
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || result?.isFinal == true {
                    self.stopCaptureOnly()
                }
            }
        }

        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isListening = true
    }

    @discardableResult
    func stop() -> String {
        stopCaptureOnly()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isListening = false
        return transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func stopCaptureOnly() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
    }
}
