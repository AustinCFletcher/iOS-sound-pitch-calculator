//
//  SoundOutputManager.swift
//  Pitch calculator
//
//  Created by Austin Fletcher on 3/17/19.
//  Copyright © 2019 Austin Fletcher. All rights reserved.
//

import Foundation
import AVFoundation

/// Manages writing samples to the speaker's output buffer
class SoundOutputManager {
    
    public static let shared: SoundOutputManager = SoundOutputManager()
    
    public var samplesHook: ( ([Float]) -> Void )?
    
    // The maximum number of audio buffers in flight. Setting to two allows one
    // buffer to be played while the next is being written.
    private var inFlightAudioBuffers: Int = 2
    
    // The number of audio samples per buffer. A lower value reduces latency for
    // changes but requires more processing but increases the risk of being unable
    // to fill the buffers in time. A setting of 1024 represents about 23ms of
    // samples.
    private let samplesPerBuffer: AVAudioFrameCount = 1024
    
    // The audio engine manages the sound system.
    private let audioEngine: AVAudioEngine = AVAudioEngine()
    
    // The player node schedules the playback of the audio buffers.
    private let playerNode: AVAudioPlayerNode = AVAudioPlayerNode()
    
    // Use standard non-interleaved PCM audio.
    private let audioFormat = AVAudioFormat(standardFormatWithSampleRate: Double(Sound.sampleRate), channels: 1)
    
    // A circular queue of audio buffers.
    private var audioBuffers: [AVAudioPCMBuffer] = [AVAudioPCMBuffer]()
    
    // The index of the next buffer to fill.
    private var bufferIndex: Int = 0
    
    // The dispatch queue to render audio samples.
    private let audioQueue: DispatchQueue = DispatchQueue(label: "SoundOutputQueue", attributes: [])
    
    // A semaphore to gate the number of buffers processed.
    private let audioSemaphore: DispatchSemaphore
    
    // If the player node is currently playing or not
    private var isPlaying = false
    
    /// Callback for SoundOutputManager to call to ask for the next sample (should be asking orchestrator
    public var getNextSample: () -> Float = { return 0 }
    
    public init() {
        // init the semaphore
        audioSemaphore = DispatchSemaphore(value: inFlightAudioBuffers)
        
        // Create a pool of audio buffers.
        for _ in 0..<inFlightAudioBuffers {
            audioBuffers.append(AVAudioPCMBuffer(pcmFormat: audioFormat!, frameCapacity: samplesPerBuffer)!)
        }
        
        // Attach and connect the player node.
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFormat)
        
        do {
            try audioEngine.start()
        } catch {
            print("AudioEngine didn't start")
        }
    }
    
    /// Starts and stops the output of sound to the speaker
    public func togglePlaying() {
        isPlaying = !isPlaying
        if isPlaying {
            play()
        } else {
            stop()
        }
    }
    
    // MARK: - Managing the playing of the sound to the speaker
    
    private func stop() {
        playerNode.stop()
    }
    
    private func play() {
        
        audioQueue.async {
            var sampleTime: Float32 = 0
            
            while self.isPlaying {
                // Wait for a buffer to become available.
                self.audioSemaphore.wait(timeout: DispatchTime.distantFuture)
                
                // get the correct buffer from the pool of ones not being played
                let audioBuffer = self.audioBuffers[self.bufferIndex]
                var capturedFloats = [Float]()
                // Fill the buffer with new samples.
                let leftChannel = audioBuffer.floatChannelData?[0]
                let rightChannel = audioBuffer.floatChannelData?[1]
                for sampleIndex in 0 ..< Int(self.samplesPerBuffer) {
                    let sample = self.getNextSample()
                    leftChannel?[sampleIndex] = sample
                    rightChannel?[sampleIndex] = sample
                    capturedFloats.append(sample)
                    sampleTime = sampleTime + 1.0
                }
                audioBuffer.frameLength = self.samplesPerBuffer
                
                // Schedule the buffer for playback and release it for reuse after
                // playback has finished.
                
                // TODO: call hook here
                self.samplesHook?(capturedFloats)
                
                self.playerNode.scheduleBuffer(audioBuffer) {
                    self.audioSemaphore.signal()
                    return
                }
                
                self.bufferIndex = (self.bufferIndex + 1) % self.audioBuffers.count
            }
        }
        
        playerNode.pan = 0.8
        playerNode.play()
    }
    
}
