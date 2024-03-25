//
//  Haptics.swift
//  FYPTestingTemp
//
//  Created by Ewan, Aleera C on 11/01/2024.
//

import UIKit
import CoreHaptics

class Haptics{
    //haptics start
    //haptics end
    //haptics parameters
    let engine :  CHHapticEngine
    
    init(engine: CHHapticEngine) {
        self.engine = engine
        
    }
    func playTransient(){
        let hapticDict = [
            CHHapticPattern.Key.pattern: [
                [CHHapticPattern.Key.event: [
                    CHHapticPattern.Key.eventType: CHHapticEvent.EventType.hapticTransient,
                    CHHapticPattern.Key.time: CHHapticTimeImmediate,
                    CHHapticPattern.Key.eventDuration: 1.0]
                ]
            ]
        ]
        do {
            let pattern = try CHHapticPattern(dictionary: hapticDict)
            do {
                let player = try engine.makePlayer(with: pattern)
                engine.notifyWhenPlayersFinished { error in
                    return .stopEngine
                }


                try engine.start()
                try player.start(atTime: 0)
            } catch let error {
                fatalError("Player Creation Error: \(error)")
            }
        } catch let error {
            fatalError("Pattern Creation Error: \(error)")
        }
        
        
    }
    
    func playTexture(filename: String){//later wont have files like this: change dynamically?
        
        // Express the path to the AHAP file before attempting to load it.
        guard let path = Bundle.main.path(forResource: filename, ofType: "ahap") else {
            return
        }
            do {
                engine.notifyWhenPlayersFinished { error in
                    return .stopEngine
                }


                try engine.start()
                try engine.playPattern(from: URL(fileURLWithPath: path))
            } catch let error {
                fatalError("Player Creation Error: \(error)")
            }
    }
    func playHeightHaptic(height: Float){
        //HEIGHT needs to be scaled proportional to range of heights, to be between 0 and 1
        let scaledHeight = height - 12
        print(scaledHeight)
        let hapticDict = [
            CHHapticPattern.Key.pattern: [
                [
                    CHHapticPattern.Key.event: [
                        CHHapticPattern.Key.eventType: CHHapticEvent.EventType.hapticTransient,
                        CHHapticPattern.Key.time: CHHapticTimeImmediate,
                        CHHapticPattern.Key.eventDuration: 0.001,
                        CHHapticPattern.Key.eventParameters: [
                            [
                                CHHapticPattern.Key.parameterID: CHHapticEvent.ParameterID.hapticIntensity,
                                CHHapticPattern.Key.parameterValue: scaledHeight
                            ],
                            [
                                CHHapticPattern.Key.parameterID: CHHapticEvent.ParameterID.hapticSharpness,
                                CHHapticPattern.Key.parameterValue: 0.6
                            ]
                        ]
                    ]
                ]
            ]
        ]
        do {
            let pattern = try CHHapticPattern(dictionary: hapticDict)
            do {
                let player = try engine.makePlayer(with: pattern)
                engine.notifyWhenPlayersFinished { error in
                    return .stopEngine
                }


                try engine.start()
                try player.start(atTime: 0)
            } catch let error {
                fatalError("Player Creation Error: \(error)")
            }
        } catch let error {
            fatalError("Pattern Creation Error: \(error)")
        }
    }
}
