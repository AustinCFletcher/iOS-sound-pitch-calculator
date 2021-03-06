//
//  Oscillator.swift
//  Pitch calculator
//
//  Created by Austin Fletcher on 3/17/19.
//  Copyright © 2019 Austin Fletcher. All rights reserved.
//

import Foundation

public enum OscillatorWaveType {
    case sine
    case square
    case saw
    case triangle
}

// TODO: consider protocol vs ineheritance here for different oscillator types and maybe test performance of static vs dynamic method dispatch?
class Oscillator {
    
    // TODO: Next tasks:
    // 1. wavetables
    // 2. additive synthesis for sine wave, and other waves
    // 3. filters
    // 4. envelopes
    //
    
    private var frequency: Float = 440.0 {
        didSet { updatePhaseIncrement() } // update the phase increment on every freq change
    }
    private var phase: Float = 0.0
    private var phaseIncrement: Float = 0
    private var isMuted: Bool = false
    private var oscillatorWaveType: OscillatorWaveType = .sine
    private var amplitude: Float = 1
    
    // allow passing in config as defaults
    public init(frequency: Float = 440.0,
                phase: Float = 0.0,
                phaseIncrement: Float = 0,
                oscillatorWaveType: OscillatorWaveType = .sine) {
        self.frequency = frequency
        self.phase = phase
        self.oscillatorWaveType = oscillatorWaveType
        
        updatePhaseIncrement()
    }
    
    // MARK: - Setters
    
    public func setFrequency(_ frequency: Float) {
        self.frequency = frequency
    }
    
    
    
    public func setWaveType(_ oscillatorWaveType: OscillatorWaveType) {
        self.oscillatorWaveType = oscillatorWaveType
    }
    
    // MARK: - Public API
    
    
    /// Calculates the next sample and prepares the oscillator for the next call
    ///
    /// - Returns: the sample
    public func nextSample() -> Float {
        let sample = applyAmplitude( getSampleBasedOnWaveType() )
        updatePhaseForNextSample()
        return sample
    }
    
    // MARK: - Amplitude
    // Need to really apply this somewhere else like a mixer/orchestrator, wave shouldnt know its ampitude..
    
    public func setAmplitude(_ amplitude: Float) {
        self.amplitude = amplitude
    }
    
    private func applyAmplitude(_ sample: Float) -> Float {
        return sample * amplitude
    }
    
    // TODO: generate a buffer of samples, maybe taking in a buffer pointer...
    
    // MARK: - Phase management
    
    // TODO: consider pure functions for these? take in params and return val instead of sideffects....
    
    /// Updates the phase increment (the rate at which the phase increases for each sample) based on the frequency
    private func updatePhaseIncrement(){
        phaseIncrement = (frequency * Sound.twoPI) / Sound.sampleRate
    }
    
    /// increment the phase to the next sample's value and wrap the unit circle back to 0 if over 2pi
    private func updatePhaseForNextSample() {
        phase += phaseIncrement
        while (phase >= Sound.twoPI) {
            phase -= Sound.twoPI
        }
    }
    
    // MARK: - Sample generation
    
    private func getSampleBasedOnWaveType() -> Float {
        switch (oscillatorWaveType) {
        case .sine:
            return sin(phase)
        case .saw:
            return 1.0 - (2.0 * phase / Sound.twoPI);
        case .square:
            return (phase <= Sound.PI) ? 1.0 : -1.0
        case .triangle:
            var value = -1.0 + (2.0 * phase / Sound.twoPI);
            value = 2.0 * (abs(value) - 0.5)
            return value
        }
    }
}
