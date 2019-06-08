//
//  WaveVisualization.swift
//  Pitch calculator
//
//  Created by Austin Fletcher on 6/8/19.
//  Copyright © 2019 Austin Fletcher. All rights reserved.
//

import SwiftUI

struct WaveVisualization : View {
    let samples: IdentifiableSamples
    
    var body: some View {
        VStack {
            ForEach(samples.sampleIDs) { id in
                Text("\(self.samples.samples[id])")
                Spacer()
            }
        }
        
        
    }
}

#if DEBUG
struct WaveVisualization_Previews : PreviewProvider {
    static var previews: some View {
        WaveVisualization(samples: IdentifiableSamples())
    }
}
#endif
