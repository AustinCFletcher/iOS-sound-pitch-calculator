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
        
        switch(waveType) {
        case .sine: return sineWave(frequency: freq)
        case .square: return squareWave(frequency: freq)
        case .triangle: return triangleWave(frequency: freq)
        case .saw: return sawWave(frequency: freq)
        }
    }
    
    private func sineWave(frequency: Float) -> Signal {
        let phi = frequency / Sound.sampleRate
        return { i in
            return sin(2.0 * Float(i) * phi * Sound.PI)
        }
    }
    
    private func sawWave(frequency: Float) -> Signal {
        let phi = frequency / Sound.sampleRate
        return { i in
            let phase = (Float(i) * phi).truncatingRemainder(dividingBy: Sound.twoPI)
            return 1.0 - (2.0 * phase )
        }
    }
    
    private func squareWave(frequency: Float) -> Signal {
        let phi = frequency / Sound.sampleRate
        return { i in
            let phase = (Float(i) * phi).truncatingRemainder(dividingBy: Sound.twoPI)
            return (phase <= Sound.PI) ? 1.0 : -1.0
        }
    }
    
    private func triangleWave(frequency: Float) -> Signal {
        let phi = frequency / Sound.sampleRate
        return { i in
            let phase = (Float(i) * phi).truncatingRemainder(dividingBy: Sound.twoPI)
            var value = -1.0 + (2.0 * phase / Sound.twoPI);
            value = 2.0 * (abs(value) - 0.5)
            return value
        }
    }
}

// A more functional-programming approach to oscillator, wrapper of a Signal essentially

class FPOscillator {
    
    // MARK: - Properties
    
    private var oscillatorWaveType: OscillatorWaveType = .sine {
        didSet { updateSignalFunc(frequency, oscillatorWaveType: oscillatorWaveType) }
    }
    private var frequency: Float {
        didSet { updateSignalFunc(frequency, oscillatorWaveType: oscillatorWaveType) }
    }
    private var signal: Signal
    private var amplitude: Float = 1
    
    public init(frequency: Float = 440.0,
                oscillatorWaveType: OscillatorWaveType = .sine) {
        self.frequency = frequency
        self.oscillatorWaveType = oscillatorWaveType
        self.signal = SignalFactory().build(waveType: oscillatorWaveType, freq: frequency)
    }
    
    public func setAmplitude(_ amplitude: Float) {
        self.amplitude = amplitude
    }
    
    public func setFrequency(_ frequency: Float) {
        self.frequency = frequency
    }
    
    public func setWaveType(_ oscillatorWaveType: OscillatorWaveType) {
        self.oscillatorWaveType = oscillatorWaveType
    }
    
    public func sample(_ index: Int) -> Float {
        return signal(index) * amplitude
    }
    
    private func updateSignalFunc(_ frequency: Float, oscillatorWaveType: OscillatorWaveType) {
        signal = SignalFactory().build(waveType: oscillatorWaveType, freq: frequency)
    }
}
