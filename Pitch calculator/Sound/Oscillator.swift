//
//  Oscillator.swift
//  Pitch calculator
//
//  Created by Austin Fletcher on 3/17/19.
//  Copyright © 2019 Austin Fletcher. All rights reserved.
//

import Foundation

// TODO: consider protocol vs ineheritance here for different oscillator types and maybe test performance of static vs dynamic method dispatch?
class Oscillator {
    
    // constants
    private let PI: Float = Float.pi
    private let twoPI: Float = Float.pi * 2
    
    private var frequency: Float = 440.0 {
        didSet { updatePhaseIncrement() } // update the phase increment on every freq change
    }
    private var phase: Float = 0.0
    private var sampleRate: Float = 48000.0
    private var phaseIncrement: Float = 0
    private var isMuted: Bool = false
    
    // allow passing in config as defaults
    public init(frequency: Float = 440.0,
                phase: Float = 0.0,
                sampleRate: Float = 48000.0,
                phaseIncrement: Float = 0) {
        self.frequency = frequency
        self.phase = phase
        self.sampleRate = sampleRate
        
        updatePhaseIncrement()
    }
    
    // TODO: consider pure functions for these? take in params and return val instead of sideffects....
    
    /// Updates the phase increment (the rate at which the phase increases for each sample) based on the frequency
    private func updatePhaseIncrement(){
        phaseIncrement = (frequency * twoPI) / sampleRate
    }
    
    /// increment the phase to the next sample's value and wrap the unit circle back to 0 if over 2pi
    private func updatePhaseForNextSample() {
        phase += phaseIncrement
        while (phase >= twoPI) {
            phase -= twoPI
        }
    }
    
    public func setFrequency(_ frequency: Float) {
        self.frequency = frequency
    }
    
    
    /// Calculates the next sample and prepares the oscillator for the next call
    ///
    /// - Returns: the sample
    public func nextSample() -> Float {
        let sample = sin(phase)
        updatePhaseForNextSample()
        return sample
    }
    
    // TODO: generate a buffer of samples, maybe taking in a buffer pointer...
}
