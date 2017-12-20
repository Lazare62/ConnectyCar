//
//  CustomSlider.swift
//  ConnectyCar
//
//  Created by Remy Krysztofiak on 12/11/2017.
//  Copyright © 2017 Remy Krysztofiak. All rights reserved.
//

import UIKit

class CustomSlider: UISlider {

    @IBInspectable open var trackWidth:CGFloat = 2 {
        didSet {setNeedsDisplay()}
    }
    
    override open func trackRect(forBounds bounds: CGRect) -> CGRect {
        let defaultBounds = super.trackRect(forBounds: bounds)
        return CGRect(
            x: defaultBounds.origin.x,
            y: defaultBounds.origin.y + defaultBounds.size.height/2 - trackWidth/2,
            width: defaultBounds.size.width,
            height: trackWidth
        )
    }

}
