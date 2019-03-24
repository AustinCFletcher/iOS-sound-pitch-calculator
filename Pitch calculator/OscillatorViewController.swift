//
//  OscillatorViewController.swift
//  Pitch calculator
//
//  Created by Austin Fletcher on 3/17/19.
//  Copyright © 2019 Austin Fletcher. All rights reserved.
//

import UIKit
import AVFoundation

class OscillatorViewController: UIViewController {
    
    // MARK: - Properties
    private let oscillator = Oscillator(frequency: 880)
    private let waveTypes: [OscillatorWaveType] = [.sine, .saw, .square, .triangle]
    private var currentWaveTypeIndex = 0
    
    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        SoundOutputManager.shared.getNextSample = { [weak self] in
            return self?.oscillator.nextSample() ?? 0
        }
    }
    
    // MARK: - Actions
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        oscillator.setFrequency(sender.value * 880.0)
    }
    @IBAction func amplitudeSliderChanged(_ sender: UISlider) {
        oscillator.setAmplitude(sender.value)
    }
    
    @IBAction func changeWaveTypePressed(_ sender: Any) {
        currentWaveTypeIndex = (currentWaveTypeIndex + 1) % waveTypes.count
        oscillator.setWaveType(waveTypes[currentWaveTypeIndex])
    }
    
    
    @IBAction func playTouched(_ sender: Any) {
        SoundOutputManager.shared.togglePlaying()
    }
    
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


