//
//  WaveVisualization.swift
//  Pitch calculator
//
//  Created by Austin Fletcher on 6/8/19.
//  Copyright © 2019 Austin Fletcher. All rights reserved.
//

import SwiftUI

struct WaveVisualization : View {
    @ObjectBinding var samples: IdentifiableSamples
    let frame1: CGRect
    private var zeroLinePoint: CGFloat {
        return frame1.height/2
    }
    private let renderedSamples = 200
    
    var body: some View {
        ZStack {
            
            ForEach(samples.sampleIDs[0..<self.renderedSamples]) { id in
                Path { path in
                    let height: CGFloat = self.zeroLinePoint * CGFloat( self.samples.samples[id] )
                    let y = self.zeroLinePoint + height
                    let x = CGFloat(CGFloat(id) * (self.frame1.width / CGFloat(self.renderedSamples)))
                    
                    path.move(to: CGPoint(x: x, y: self.zeroLinePoint) )
                    path.addLine( to: .init( x: x+1, y: y) )
                    path.addLine( to: .init( x: x+2, y: self.zeroLinePoint) )
                }
            }
        }.drawingGroup()
        
        
    }
}



#if DEBUG
struct WaveVisualization_Previews : PreviewProvider {
    static var previews: some View {
        WaveVisualization(samples: IdentifiableSamples(), frame1: CGRect(x: 0, y: 0, width: 1, height: 1))
    }
}
#endif
