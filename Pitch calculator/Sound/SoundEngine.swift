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
    
    // TASKS TO DO NEXT: (for the monophonic frequency calc'ing at least)
    // TODO: Move frequency calculation to its own object
    // TODO: fix rudimentary autocorrelation array copt performance issues with clever array indexing
    // TODO: use FFT to calc the autocorrelation performantly but keep the rudimentary one for reference
    // TODO: Make this class a MicInputManager
    // TODO: return the frequency result to the
    
    private let audioEngine = AVAudioEngine()
    
    private let mic: AVAudioInputNode
    private var micTapped = false
    private var micStartTime: AVAudioTime?
    
    private var currentSamples = [Float]()
    
    /// TODO: let the mic class register a callback func on mic tap that gets called continously while sampling
    /// let receiver of those samples process them... cyclical buffer? need to think throuhg this API
    
    // consider writing a wrapper for this? is just a fancy array
    private var cyclicalBuffer = [Float]()
    
    init() {
        SoundEngine.configureAudioSession()
        // input is set to microphone via the <> in configureAudioSession()
        mic = audioEngine.inputNode
    }
    
    private static func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: AVAudioSession.Mode.default, options: [.mixWithOthers, .defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { }
    }

    // MARK: - Mic control
    
    /// Untap the mic
    private func turnMicOff() {
        mic.removeTap(onBus: 0)
        micTapped = false
    }
    
    private func trimLeadingZeroSamplesFromMicStartupIfNeeded(_ samples: [Float]) -> [Float] {
        // find the first non-zero sampple and return the portion of the array that comes after that
        for (i, sample) in samples.enumerated() {
            if sample != 0 {
                return Array( samples.suffix(from: i) )
            }
        }
        
        return samples
    }
    
    // MARK: - Frequency calculation
    
    /// Turns on the mic for a single buffer to capture sound from the mic and returns the frequency of the captured sound
    /// Uses concepts:  (from: https://www.objc.io/issues/24-audio/audio-dog-house/)
    /// - dot products of the original buffer and offset buffer
    /// - autocorrelation to find frequency of pitch
    ///
    /// - Returns: the calculated frequency
    private func calculateFrequencyOfCurrentBuffer() -> Float {
        // when mic is turned on, results in like 600 samples of 0 which throw off the collected freq
        // TODO: make this sampling and calculations continuous so guitar-tuner effect is possible( continously sample and provide real time pitch)
        let samples = Array( trimLeadingZeroSamplesFromMicStartupIfNeeded(currentSamples).prefix(2048) )

        // calculated all the dot products of the original buffer and the lag-offset buffers, resulting in the autocorrelation
        //let dotProducts = calculateDotProducts(samples: samples)
        let dotProducts = calculateDotProductsPerformant(samples: samples)
        // find the peaks in the autocorrelation
        let peaks = findPeaksOfAutocorrelation(dotProducts: dotProducts)
        // use the peaks to caclulate the frequency of the original buffer :)
        return calculateFrequencyFrom(peaks: peaks, sampleRate: Sound.sampleRate)
    }
    
    private func dotProduct(signalA: [Float], signalB: [Float]) -> Float {
        return zip(signalA, signalB).map(*).reduce(0.0, { (result, value) in
            return result + value
        })
    }
    
    /// calculate dotproducts of all lag offsets of the buffer
    private func calculateDotProducts(samples: [Float]) -> [Float] {
        
        var dotProducts = [Float]()
        
        for value in 0..<samples.count {
            let outOfPhaseSignal = Array(samples.suffix(from: value)) + Array(samples.prefix(upTo: value))
            dotProducts.append( dotProduct(signalA: samples, signalB: outOfPhaseSignal) )
        }
        
        return dotProducts
    }
    
    private func calculateDotProductsPerformant(samples: [Float]) -> [Float] {
        var dotProducts = [Float]()
        
        for offset in 0..<samples.count {
            var dotProduct: Float = 0
            for index in 0..<samples.count {
                dotProduct += (samples[index] * samples[(index + offset) % samples.count])
            }
           dotProducts.append(dotProduct)
        }
        
        return dotProducts
    }
    
    /// Find peaks of autocorrelation (array of dotproducts of all lag offsets of the buffer)
    private func findPeaksOfAutocorrelation(dotProducts: [Float]) -> [Int] {
        
        var isGoingUp = false
        var peaks = [0]
        
        var prev = dotProducts.first ?? 0.0
        
        for (i, dp) in dotProducts.enumerated() {
            
            if isGoingUp, prev > dp {
                peaks.append(i - 1) // grab index of peak
                isGoingUp = false
            }
            
            if dp > prev {
                isGoingUp = true
            }
            
            prev = dp
        }
        
        return peaks
    }
    
    private func calculateFrequencyFrom( peaks: [Int], sampleRate: Float ) -> Float {
        // calculate the differences in between each peak index
        var differences = [Int]()
        for i in 1..<peaks.count {
            differences.append( (peaks[i] - peaks[i - 1]) )
        }
        
        // take the average number of samples in between peaks
        let numberOfSamplesBetweenPeaks = Float( differences.reduce(0) { $0 + $1 }  / (peaks.count - 1) )
        
        return sampleRate / Float(numberOfSamplesBetweenPeaks)
    }
    
    // MARK: - Public API
    
    /// Turns on the mic for a single buffer to capture sound from the mic and returns the frequency of the captured sound
    ///
    /// - Parameter completion: callback provided with the frequency
    public func captureSampleAndCalculateFrequency(_ completion: @escaping (Float) -> Void ) {
        
        // Reset the samples in the current buffer
        currentSamples.removeAll()
        
        let micFormat = mic.inputFormat(forBus: 0)
        
        mic.installTap(onBus: 0, bufferSize: 2048, format: micFormat) { [weak self] (buffer, when) in
            if self?.micStartTime == nil { self?.micStartTime = when }
            
            let samplesInBuffer = Int(buffer.frameLength)
            let sampleData = Array( UnsafeBufferPointer(start: buffer.floatChannelData![0], count: samplesInBuffer) )
            
            self?.currentSamples = sampleData
            // self?.buffers.append(sampleData)
            self?.turnMicOff()
            if let frequency = self?.calculateFrequencyOfCurrentBuffer() {
                completion(frequency)
            }
            
            // TODO: need to bring back toggle function
            // implement the buffering of the buffers... array of arrays for easy manipulation? not sure if faster/cleaner than one buffer and do 1024-size windows (a true cyclic buffer)
            
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
