//
//  ViewController.swift
//  Pitch calculator
//
//  Created by Austin Fletcher on 3/10/19.
//  Copyright © 2019 Austin Fletcher. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var frequencyLabel: UILabel!
    
    private var engine: SoundEngine?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    private func initialSoundSetup() {
        requestMicrophoneAuthorization { [weak self] granted in
            if granted {
                print("\n GRANTED \n")

                self?.engine = SoundEngine()
            }
        }
    }
    
    private func requestMicrophoneAuthorization(_ completion: @escaping (Bool) -> ()) {
        
        let permissionStatus = AVAudioSession.sharedInstance().recordPermission
        
        switch permissionStatus {
        case .granted:
            completion(true)
        case .denied:
            return
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { (granted) in
                // record permission request does not return on the main thread
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        default: break
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        initialSoundSetup()
    }
    
    @IBAction func toggleMicTap(_ sender: Any) {
        frequencyLabel.text = "Frequency: CALCULATING..."
        engine?.captureSampleAndCalculateFrequency({ freq in
            DispatchQueue.main.async {
                self.frequencyLabel.text = "Frequency: \(freq) hz"
            }
        })
    }

}

