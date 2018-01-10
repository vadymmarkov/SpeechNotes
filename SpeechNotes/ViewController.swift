//
//  ViewController.swift
//  SpeechNotes
//
//  Created by Vadym Markov on 09/01/2018.
//  Copyright © 2018 Vadym Markov. All rights reserved.
//

import UIKit
import Speech

final class ViewController: UIViewController {
  private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "nb-NO"))!
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var recognitionTask: SFSpeechRecognitionTask?
  private let audioEngine = AVAudioEngine()
  private let audioSession = AVAudioSession.sharedInstance()

  private lazy var textView: UITextView = self.makeTextView()
  private lazy var button: UIButton = self.makeButton()

  // MARK: - View lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Speech Notes"
    view.backgroundColor = .white
    speechRecognizer.delegate = self
    button.addTarget(self, action: #selector(handleRecordButtonTap), for: .touchUpInside)

    view.addSubview(textView)
    view.addSubview(button)
    setupConstraints()
    showStartButton()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    requestAuthorization()
  }

  // MARK: - Permissions

  private func requestAuthorization() {
    // Ask for speech recognition permissions
    SFSpeechRecognizer.requestAuthorization { authStatus in
      DispatchQueue.main.async { [weak self] in
        self?.setupSubviews(with: authStatus)
      }
    }
  }

  private func setupSubviews(with authStatus: SFSpeechRecognizerAuthorizationStatus) {
    let isAuthorized = authStatus == .authorized
    button.isEnabled = isAuthorized
    textView.text = authStatus.message
  }

  // MARK: - Actions

  @objc private func handleRecordButtonTap() {
    if audioEngine.isRunning {
      audioEngine.stop()
      recognitionRequest?.endAudio()
      showStartButton()
    } else {
      do {
        try startRecording()
        showStopButton()
      } catch {
        textView.text = error.localizedDescription
      }
    }
  }
}

// MARK: - Recognition

extension ViewController {
  private func startRecording() throws {
    // Cancel the previous task
    recognitionTask?.cancel()
    recognitionTask = nil

    try setupAudioSession()
    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

    guard let request = recognitionRequest else {
      throw Error.noRequest
    }

    // Create recognition task
    recognitionRequest?.shouldReportPartialResults = true
    recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
      self?.handleRecognition(result: result, error: error)
    }

    // Create a "tap" to observe the output of the node
    let outputFormat = audioEngine.inputNode.outputFormat(forBus: 0)
    audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: outputFormat) { buffer, _ in
      self.recognitionRequest?.append(buffer)
    }

    audioEngine.prepare()
    try audioEngine.start()

    textView.text = Text.listening
  }

  private func handleRecognition(result: SFSpeechRecognitionResult?, error: Swift.Error?) {
    if let result = result {
      textView.text = result.bestTranscription.formattedString
    }

    guard error != nil || result?.isFinal ?? false else {
      return
    }

    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    recognitionRequest = nil
    recognitionTask = nil
  }

  private func setupAudioSession() throws {
    try audioSession.setCategory(AVAudioSessionCategoryRecord)
    try audioSession.setMode(AVAudioSessionModeMeasurement)
    try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
  }
}

// MARK: - SFSpeechRecognizerDelegate

extension ViewController: SFSpeechRecognizerDelegate {
  func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
    button.isEnabled = available
  }
}

// MARK: - UI

private extension ViewController {
  func makeButton() -> UIButton {
    let button = UIButton(type: .system)
    button.isEnabled = false
    button.titleLabel?.font = UIFont.systemFont(ofSize: 24)
    button.setTitleColor(.blue, for: .normal)
    return button
  }

  func makeTextView() -> UITextView {
    let textView = UITextView()
    textView.font = UIFont.systemFont(ofSize: 18)
    textView.textColor = .black
    textView.isEditable = false
    textView.isScrollEnabled = true
    textView.backgroundColor = .lightText
    return textView
  }

  func showStartButton() {
    button.setTitle("Start Recording", for: .normal)
    if textView.text == Text.listening {
      textView.text = Text.startDictating
    }
  }

  func showStopButton() {
    button.setTitle("Stop recording", for: .normal)
  }

  func setupConstraints() {
    textView.translatesAutoresizingMaskIntoConstraints = false
    button.translatesAutoresizingMaskIntoConstraints = false

    let layoutGuide = view.safeAreaLayoutGuide
    let padding: CGFloat = 14

    let constraints = [
      textView.topAnchor.constraint(equalTo: layoutGuide.topAnchor, constant: padding),
      textView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor, constant: padding),
      textView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: -padding),
      textView.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -padding),

      button.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor, constant: -padding),
      button.centerXAnchor.constraint(equalTo: layoutGuide.centerXAnchor)
    ]

    NSLayoutConstraint.activate(constraints)
  }
}

// MARK: - Private types

private enum Error: Swift.Error, LocalizedError {
  case noRequest

  var errorDescription: String? {
    switch self {
    case .noRequest:
      return "Unable to create a speech recognition request"
    }
  }
}

private struct Text {
  static let startDictating = "Tap the button and start dictating 🗣"
  static let listening = "Listening...👂"
}

// MARK: - Private extensions

private extension SFSpeechRecognizerAuthorizationStatus {
  var message: String {
    switch self {
    case .authorized:
      return Text.startDictating
    case .denied:
      return "User denied access to speech recognition"
    case .restricted:
      return "Speech recognition restricted on this device"
    case .notDetermined:
      return "Speech recognition not yet authorized"
    }
  }
}
