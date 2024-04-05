//
//  HapticRendering.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 05/04/2024.
//

import UIKit

class HapticRendering {
    private let k : Float = 0.9//skin stiffness
    private let frictionConst = 0.6 //skin surface friction constant
    var maxHeight : Float
    var minHeight : Float
    
    init(maxHeight: Float, minHeight: Float) {
        self.maxHeight = maxHeight
        self.minHeight = minHeight
    }
    func forceFeedback(height : Float){
        //F = P*k - (F_t * frictionConst)//why is it negative?
        //intensity needs to be scaled between 0 and 1
        //do friction later
        let depth = height/(self.maxHeight - self.minHeight)//if finger is touching the same level (the bottom of the surface level - there would be more resistance touching a higher plane than a lower one
        let F = depth*k
    }
    
    func changePlane(newMax : Float, newMin : Float){
        self.maxHeight = newMax
        self.minHeight = newMin
    }
}
