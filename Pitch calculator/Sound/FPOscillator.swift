//
//  FPOscillator.swift
//  Pitch calculator
//
//  Created by Austin Fletcher on 3/24/19.
//  Copyright © 2019 Austin Fletcher. All rights reserved.
//

import Foundation

public typealias Signal = (Int) -> Float

class SignalFactory {
    
    public func build(waveType: OscillatorWaveType, freq: Float) -> Signal {
        return sineWave(frequency: freq)
    }
    
    private func sineWave(frequency: Float) -> Signal {
        let phi = frequency / Sound.sampleRate
        return { i in
            return sin(2.0 * Float(i) * phi * Sound.PI)
        }
    }
    
}

// A more functional-programming approach to oscillator, wrapper of a Signal essentially

class FPOscillator {
    
    private var oscillatorWaveType: OscillatorWaveType = .sine {
        didSet { updateSignalFunc(frequency, oscillatorWaveType: oscillatorWaveType) }
    }
    private var frequency: Float {
        didSet { updateSignalFunc(frequency, oscillatorWaveType: oscillatorWaveType) }
    }
    private var signal: Signal
    
    public init(frequency: Float = 440.0,
                oscillatorWaveType: OscillatorWaveType = .sine) {
        self.frequency = frequency
        self.oscillatorWaveType = oscillatorWaveType
        self.signal = SignalFactory().build(waveType: oscillatorWaveType, freq: frequency)
    }
    
    private func updateSignalFunc(_ frequency: Float, oscillatorWaveType: OscillatorWaveType) {
        signal = SignalFactory().build(waveType: oscillatorWaveType, freq: frequency)
    }
}
