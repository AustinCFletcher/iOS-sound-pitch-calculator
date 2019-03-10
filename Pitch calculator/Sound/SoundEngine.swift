//
//  SoundEngine.swift
//  Pitch calculator
//
//  Created by Austin Fletcher on 3/10/19.
//  Copyright © 2019 Austin Fletcher. All rights reserved.
//

import Foundation
import AVFoundation

class SoundEngine {
    
    private let audioEngine: AVAudioEngine
    
    // consider mic manager class instead of engine doing it all
    private let mic: AVAudioInputNode
    private var micTapped = false
    private var micStartTime: Date?
    private var micEndTime: Date?
    
    private var currentSamples = [Float]()
    
    init() {
        SoundEngine.configureAudioSession()
        audioEngine = AVAudioEngine()
        // input is set to microphone via the <> in configureAudioSession()
        mic = audioEngine.inputNode
    }
    
    // MARK: - Public API
    
    public func calculateFrequencyOfCurrentBuffer() {
    
        let filtered = currentSamples.filter { sample in
            return (sample < 0.0001) && (sample > -0.0001)
        }
        print("\n \(filtered.count) \n")
        print("\n \(currentSamples) \n")
    }
    
    public func toggleMic() {
        if micTapped {
            
            mic.removeTap(onBus: 0)
            micTapped = false
            return
        }
        
        let micFormat = mic.inputFormat(forBus: 0)
        mic.installTap(onBus: 0, bufferSize: 2048, format: micFormat) { [weak self] (buffer, when) in
            
            
            let sampleData = UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength))
            self?.currentSamples.append(contentsOf: sampleData)
            print("\n \(sampleData.first) \n")
        }
        micTapped = true
        startEngine()
    }
    
    public func playAudioFile() {
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
    
    // MARK: - Private API
    
    private func startEngine() {
        guard !audioEngine.isRunning else {
            return
        }
        
        do {
            try audioEngine.start()
        } catch { }
    }
    
    private static func configureAudioSession() {
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
    
    private func stopAudioPlayback() {
        audioEngine.stop()
        audioEngine.reset()
    }
    
}
