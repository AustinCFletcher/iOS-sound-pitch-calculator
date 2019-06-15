//
//  OscillatorViewController.swift
//  Pitch calculator
//
//  Created by Austin Fletcher on 3/17/19.
//  Copyright © 2019 Austin Fletcher. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftUI
import Combine

class IdentifiableSamples: BindableObject {
    var moduloCounterHack = 0
    var didChange = PassthroughSubject<IdentifiableSamples, Never>()
    
    var samples: [Float] = [Float]() {
        didSet {
            if self.moduloCounterHack % 2 == 0 {
                 DispatchQueue.main.async { self.didChange.send(self) }
            }
            moduloCounterHack += 1
        }
    }

    var sampleIDs: [Int] = {
        var thing = [Int]()
        for id in 0..<1024 {
            thing.append(id)
        }
        return thing
    }()
}

class OscillatorViewController: UIViewController {
    
    @IBOutlet weak var childContentView: UIView!
    
    // MARK: - Properties
    private let oscillator = Oscillator(frequency: 880)
    private let functionalOscillator = FPOscillator(frequency: 880, oscillatorWaveType: .sine)
    
    private let waveTypes: [OscillatorWaveType] = [.sine, .saw, .square, .triangle]
    private var oopWaveTypeIndex = 0
    private var fpWaveTypeIndex = 0
    
    private var fpOscIsPlaying = false
    private var oopOscIsPlaying = false
    
    private var test = IdentifiableSamples()
    
    var moduloCounterHack = 0
    
    public func samplesCallback(samples: [Float]) {
        // print("\n \(samples[0]) \n")

        
        DispatchQueue.main.async {
////            self.test.didChange.debounce(for: .milliseconds(500), scheduler: Scheduler())
//            print("\n \(self.test.samples.count) \n")

            self.test.samples = samples
//            if self.moduloCounterHack % 2 == 0 {
//                self.test.didChange.send(Void())
//            }
//            self.moduloCounterHack += 1
        }
    }
    
    var samples2 = [Float]()
    
    // MARK: - View lifecycle
    
    private var index: Int = 0
    private func getIndex() -> Int {
        index += 1
        if index >= Int.max { index = 0 } // index loop of smaller numbers caused spectral leakage
        return index
    }
    
    // MARK: - View Lifecylce

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var thing = [Float]()
        for _ in 0..<1024 {
            thing.append(0)
        }
        test.samples = thing
        
        //test.didChange.receive(on: RunLoop.main)
        
        // TODO: Clean up the creation of this child VC, just POC'ing at the moment
        
            let vc = UIHostingController(rootView: WaveVisualization(samples: test, frame1: childContentView.bounds))
        
            // addChildViewController(childVC)
            //Or, you could add auto layout constraint instead of relying on AutoResizing contraints
            vc.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            vc.view.frame = childContentView.bounds
            
            childContentView.addSubview(vc.view)
            vc.didMove(toParent: self)
            
            //Some property on ChildVC that needs to be set
            // childVC.dataSource = self
        
        SoundOutputManager.shared.samplesHook = self.samplesCallback
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        SoundOutputManager.shared.getNextSample = {
            
            return self.getFpOscSample() + self.getOopOscSample()
        }
        
        SoundOutputManager.shared.togglePlaying()
    }
    
    // MARK: - FP Oscillator Actions
    
    @IBAction func fpAmpSliderChanged(_ sender: UISlider) {
        functionalOscillator.setAmplitude(sender.value)
    }
    
    @IBAction func fpFreqSliderChanged(_ sender: UISlider) {
        functionalOscillator.setFrequency(sender.value * 880.0)
    }
    
    @IBAction func fpPlayTouched(_ sender: Any) {
        fpOscIsPlaying = !fpOscIsPlaying
    }
    
    @IBAction func fpWaveChangeTouched(_ sender: Any) {
        fpWaveTypeIndex = (fpWaveTypeIndex + 1) % waveTypes.count
        functionalOscillator.setWaveType(waveTypes[fpWaveTypeIndex])
    }
    
    
    // MARK: - OOP Oscillator Actions
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        oscillator.setFrequency(sender.value * 880.0)
    }
    @IBAction func amplitudeSliderChanged(_ sender: UISlider) {
        oscillator.setAmplitude(sender.value)
    }
    
    @IBAction func changeWaveTypePressed(_ sender: Any) {
        oopWaveTypeIndex = (oopWaveTypeIndex + 1) % waveTypes.count
        oscillator.setWaveType(waveTypes[oopWaveTypeIndex])
    }
    
    
    @IBAction func playTouched(_ sender: Any) {
        oopOscIsPlaying = !oopOscIsPlaying
    }
    
    // MARK: - Terribly unintelligent oscillator toggling
    
    private func getFpOscSample() -> Float {
        // getIndex() func into pur fucntion call is a little weird here..
        return fpOscIsPlaying ? functionalOscillator.sample(getIndex()) : 0
    }
    
    private func getOopOscSample() -> Float {
        return oopOscIsPlaying ? oscillator.nextSample() : 0
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


