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
    
    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        SoundOutputManager.shared.getNextSample = { [weak self] in
            return self?.oscillator.nextSample() ?? 0
        }
    }
    
    // MARK: - Actions
    
    @IBAction func playTouched(_ sender: Any) {
        SoundOutputManager.shared.togglePlaying()
    }
    
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        oscillator.setFrequency(sender.value * 880.0)
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


