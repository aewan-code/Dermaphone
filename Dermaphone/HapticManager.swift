import CoreHaptics
import UIKit
class HapticManager{
    
    // Haptic Engine & Player State:
 /*   private var engine: CHHapticEngine!
    private var engineNeedsStart = true
    private var continuousPlayer: CHHapticAdvancedPatternPlayer!
    
    private lazy var supportsHaptics: Bool = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.supportsHaptics
    }()
    
    //private let initialIntensity: Float = 1.0
    //private let initialSharpness: Float = 0.5
    
    /// - Tag: CreateAndStartEngine
    func createAndStartHapticEngine() {
        
        // Create and configure a haptic engine.
        do {
            engine = try CHHapticEngine()
        } catch let error {
            fatalError("Engine Creation Error: \(error)")
        }
        
        // Mute audio to reduce latency for collision haptics.
        engine.playsHapticsOnly = true
        
        // The stopped handler alerts you of engine stoppage.
        engine.stoppedHandler = { reason in
            print("Stop Handler: The engine stopped for reason: \(reason.rawValue)")
            switch reason {
            case .audioSessionInterrupt:
                print("Audio session interrupt")
            case .applicationSuspended:
                print("Application suspended")
            case .idleTimeout:
                print("Idle timeout")
            case .systemError:
                print("System error")
            case .notifyWhenFinished:
                print("Playback finished")
            case .gameControllerDisconnect:
                print("Controller disconnected.")
            case .engineDestroyed:
                print("Engine destroyed.")
            @unknown default:
                print("Unknown error")
            }
        }
        
        // The reset handler provides an opportunity to restart the engine.
        engine.resetHandler = {
            
            print("Reset Handler: Restarting the engine.")
            
            do {
                // Try restarting the engine.
                try self.engine.start()
                
                // Indicate that the next time the app requires a haptic, the app doesn't need to call engine.start().
                self.engineNeedsStart = false
                
                // Recreate the continuous player.
                self.createContinuousHapticPlayer()
                
            } catch {
                print("Failed to start the engine")
            }
        }
        
        // Start the haptic engine for the first time.
        do {
            try self.engine.start()
        } catch {
            print("Failed to start the engine: \(error)")
        }
    }
    
    private func addObservers() {
        /*  .  backgroundToken = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
         object: nil,
         queue: nil)
         { _ in
         guard self.supportsHaptics else {
         return
         }
         // Stop the haptic engine.
         self.engine.stop(completionHandler: { error in
         if let error = error {
         print("Haptic Engine Shutdown Error: \(error)")
         return
         }
         self.engineNeedsStart = true
         })
         }*/
        /*  foregroundToken = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification,
         object: nil,
         queue: nil)
         { _ in
         guard self.supportsHaptics else {
         return
         }
         // Restart the haptic engine.
         self.engine.start(completionHandler: { error in
         if let error = error {
         print("Haptic Engine Startup Error: \(error)")
         return
         }
         self.engineNeedsStart = false
         })
         }
         }*/
    }
        
        private func continuousPalettePressed(_ press: UILongPressGestureRecognizer) {
            
            if supportsHaptics {
                // Create dynamic parameters for the updated intensity & sharpness.
                let intensityParameter = CHHapticDynamicParameter(parameterID: .hapticIntensityControl,
                                                                  value: dynamicIntensity,
                                                                  relativeTime: 0)
                
                let sharpnessParameter = CHHapticDynamicParameter(parameterID: .hapticSharpnessControl,
                                                                  value: dynamicSharpness,
                                                                  relativeTime: 0)
                let attackParameter = CHHapticDynamicParameter(parameterID: .hapticAttackTimeControl,
                                                               value: 0.5,
                                                               relativeTime: 1)
                let decayParameter = CHHapticDynamicParameter(parameterID: .hapticDecayTimeControl,
                                                              value: 0.5,
                                                              relativeTime: 1)
                // Send dynamic parameters to the haptic player.
                do {
                    try continuousPlayer.sendParameters([intensityParameter, sharpnessParameter, attackParameter, decayParameter],
                                                        atTime: 0)
                } catch let error {
                    print("Dynamic Parameter Error: \(error)")
                }
            }
            
        }
        /// - Tag: CreateContinuousPattern
        func createContinuousHapticPlayer(initialIntensity : Float, initialSharpness : Float) {
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
            
            continuousPlayer.completionHandler = { _ in
                DispatchQueue.main.async {
                    // Restore original color.
                    //  self.continuousPalette.backgroundColor = self.padColor
                }
            }
        }*/
    }

