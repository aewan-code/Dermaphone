//
//  heightMap.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 06/05/2024.
//

import Foundation
import UIKit

class HeightMap{
    
    func calcGradient(prevX : Float, prevZ : Float, currX : Float, currZ : Float){
        
    }
    
    func scaleValue(value: Float, maxValue: Float, minValue: Float) -> Float{
        if maxValue == minValue{
            return maxValue
        }
        return (value - minValue)/(maxValue - minValue)
    }
}
