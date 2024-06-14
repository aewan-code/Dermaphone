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
    var continuousPlayer: CHHapticAdvancedPatternPlayer?
    
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
    func playHeightHaptic(height: Float, sharpness : Float){
        let hapticDict = [
            CHHapticPattern.Key.pattern: [
                [
                    CHHapticPattern.Key.event: [
                        CHHapticPattern.Key.eventType: CHHapticEvent.EventType.hapticTransient,
                        CHHapticPattern.Key.time: CHHapticTimeImmediate,
                        CHHapticPattern.Key.eventParameters: [
                            [
                                CHHapticPattern.Key.parameterID: CHHapticEvent.ParameterID.hapticIntensity,
                                CHHapticPattern.Key.parameterValue: height
                            ],
                            [
                                CHHapticPattern.Key.parameterID: CHHapticEvent.ParameterID.hapticSharpness,
                                CHHapticPattern.Key.parameterValue: sharpness
                            ]
                        ]
                    ]
                ]
            ]
        ]
        do {
            let pattern = try CHHapticPattern(dictionary: hapticDict)
            do {
                let player = try engine.makeAdvancedPlayer(with: pattern)
         /*       engine.notifyWhenPlayersFinished { error in
                    return .stopEngine
                }*/


                try engine.start()
                try player.start(atTime: 0)
            } catch let error {
                fatalError("Player Creation Error: \(error)")
            }
        } catch let error {
            fatalError("Pattern Creation Error: \(error)")
        }
    }
    
    //from hapticpalette code
    /// - Tag: CreateContinuousPattern
    func createContinuousHapticPlayer(initialIntensity : Float, initialSharpness : Float) {
        do {
                try engine.start()
            } catch let error {
                print("Failed to start haptic engine: \(error)")
                return
            }
        // Create an intensity parameter:
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity,
                                               value: initialIntensity)
        
        // Create a sharpness parameter:
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness,
                                               value: initialSharpness)
        
        // Create a continuous event with a long duration from the parameters.
        let continuousEvent = CHHapticEvent(eventType: .hapticContinuous,
                                            parameters: [intensity, sharpness],
                                            relativeTime: 0,
                                            duration: 100)
        
        do {
            // Create a pattern from the continuous haptic event.
            let pattern = try CHHapticPattern(events: [continuousEvent], parameters: [])
            
            // Create a player from the continuous haptic pattern.
            continuousPlayer = try engine.makeAdvancedPlayer(with: pattern)
            
        } catch let error {
            print("Pattern Player Creation Error: \(error)")
        }
        
        continuousPlayer?.completionHandler = { _ in
            DispatchQueue.main.async {
                // Restore original color.
                //  self.continuousPalette.backgroundColor = self.padColor
            }
        }
    }
}
