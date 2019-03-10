//
//  ViewController.swift
//  Pitch calculator
//
//  Created by Austin Fletcher on 3/10/19.
//  Copyright © 2019 Austin Fletcher. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    private var audioEngine: AVAudioEngine!
    private var mic: AVAudioInputNode!
    private var micTapped = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    private func initialSoundSetup() {
        requestMicrophoneAuthorization { [weak self] granted in
            if granted {
                self?.configureAudioSession()
                self?.audioEngine = AVAudioEngine()
                self?.mic = self?.audioEngine.inputNode
            }
        }
    }
    
    private func requestMicrophoneAuthorization(_ completion: @escaping (Bool) -> ()) {
        
        let permissionStatus = AVAudioSession.sharedInstance().recordPermission
        
        switch permissionStatus {
        case .granted:
            completion(true)
        case .denied:
            return
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { (granted) in
                // record permission request does not return on the main thread
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        default: break
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        initialSoundSetup()
    }
    
    @IBAction func toggleMicTap(_ sender: Any) {
        if micTapped {
            mic.removeTap(onBus: 0)
            micTapped = false
            return
        }
        
        let micFormat = mic.inputFormat(forBus: 0)
        mic.installTap(onBus: 0, bufferSize: 2048, format: micFormat) { (buffer, when) in
            

            let sampleData = UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength))
            
            print("\n \(sampleData.first) \n")
        }
        micTapped = true
        startEngine()
    }
    
    @IBAction func playAudioFile(_ sender: Any) {
        stopAudioPlayback()
        let playerNode = AVAudioPlayerNode()
        
        let audioUrl = Bundle.main.url(forResource: "test_audio", withExtension: "wav")!
        let audioFile = readableAudioFileFrom(url: audioUrl)
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.outputNode, format: audioFile.processingFormat)
        startEngine()
        
        playerNode.scheduleFile(audioFile, at: nil) {
            playerNode .removeTap(onBus: 0)
        }
        playerNode.installTap(onBus: 0, bufferSize: 4096, format: playerNode.outputFormat(forBus: 0)) { (buffer, when) in
            let sampleData = UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength))
        }
        playerNode.play()
    }
    
    // MARK: Internal Methods
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: AVAudioSession.Mode.default, options: [.mixWithOthers, .defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { }
    }
    
    private func readableAudioFileFrom(url: URL) -> AVAudioFile {
        var audioFile: AVAudioFile!
        do {
            try audioFile = AVAudioFile(forReading: url)
        } catch { }
        return audioFile
    }
    
    private func startEngine() {
        guard !audioEngine.isRunning else {
            return
        }
        
        do {
            try audioEngine.start()
        } catch { }
    }
    
    private func stopAudioPlayback() {
        audioEngine.stop()
        audioEngine.reset()
    }


}

