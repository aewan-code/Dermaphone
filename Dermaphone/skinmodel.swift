//
//  skinmodel.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 01/04/2024.
//



import UIKit
import SceneKit
import RealityKit
import CoreHaptics
import SwiftUI

class skinmodel1: UIViewController{
   // @StateObject var currentModelName = currentModel()
    var modelName: String = "baked_mesh"
    var modelFile : String = "baked_mesh.scn"



    let sceneView = SCNView()
    let cameraNode = SCNNode()
    var scene : SCNScene?
    var currentView: UIView!
    var tempHaptics : Haptics?
    var engine: CHHapticEngine!
    var changePivot = false
    var scale : Float?
    var rotationOn = false

    
    @IBOutlet weak var RotateToggle: UIButton!
 
    override func viewDidLoad() {
        super.viewDidLoad()
        print("hi")
        currentView = view
        //self.modelName = currentModelName.name
        print(self.modelName)
        print(self.modelFile)
        scene = SCNScene(named: self.modelFile)

        print(scene?.rootNode.name)
        //print(scene?.rootNode.name)
        guard let baseNode = scene?.rootNode.childNode(withName: modelName, recursively: true) else {
                    fatalError("Unable to find baseNode")
                }
        // Create and configure a haptic engine.
        
        sceneView.scene?.rootNode.addChildNode(baseNode)
        do {
            engine = try CHHapticEngine()
        } catch let error {
            fatalError("Engine Creation Error: \(error)")
        }
        tempHaptics = Haptics(engine: engine)
 
        sceneView.scene = scene
        print("ALEERA HERE")
        print(sceneView.debugOptions)
        sceneView.debugOptions = [.showCreases]
        print(sceneView.debugOptions)
        sceneView.allowsCameraControl = false//add button to move the model
        sceneView.showsStatistics = false
        //sceneView.backgroundColor = UIColor.black
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor.white // Adjust the light color as needed
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        scene?.rootNode.addChildNode(ambientLightNode)
        
        cameraNode.camera = SCNCamera()
        //cameraNode.position =
        sceneView.cameraControlConfiguration.allowsTranslation = false
     //   sceneView.scene?.rootNode.eulerAngles = SCNVector3(x: 0, y: 0, z: 0)
        scene?.rootNode.addChildNode(cameraNode)
        //self.view = sceneView
        view.addSubview(sceneView)
        inspectMaterials(in: scene!.rootNode)
        print(sceneView.frame)
        sceneView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height) // Adjust the values as needed

        
    //    let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
      //  sceneView.addGestureRecognizer(panGestureRecognizer)
        
        view.bringSubviewToFront(RotateToggle)
        
        changePivot = false
        print("ALEERA")

        
    }
    
    func inspectMaterials(in node: SCNNode) {
        for childNode in node.childNodes {
            // Check if the node has geometry
            if let geometry = childNode.geometry {
                // Iterate through the materials applied to the geometry
                print("temp: \(geometry.boundingSphere)")
                for material in geometry.materials {
                    // Print material properties
                    print("Material properties for node: \(childNode.name ?? "Unnamed")")
                    print("Diffuse color: \(material.diffuse.contents ?? "No diffuse color")")
                    print("Specular color: \(material.specular.contents ?? "No specular color")")
                    print("Shininess: \(material.shininess)")
                    // You can inspect other material properties as needed
                }
            }
            // Recursively inspect child nodes
            inspectMaterials(in: childNode)
        }
    }
    
 /*   @objc private func didPan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            print(sender.location(in: sceneView))
            print(sender.location(in: view))
        case .changed:
          //  print(sender.location(in: view))
            break
        default:
            break
        }
    }*/
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let touch = touches.first!
        let location = touch.location(in: sceneView)
        if touch.view == sceneView{
            print("sceneView")
            self.currentView = sceneView
        }
        // Perform hit test
                let hitTestResults = sceneView.hitTest(location, options: nil)

                // Check if the desired node is touched
                for result in hitTestResults {
                    if result.node.name == "baked_mesh" {
                        // Node is touched, perform desired action
                        print("Node is touched!")
                        // Example: Change color of the node
                      //  result.node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                        let position = result.localCoordinates
                      
                        /*    if changePivot{
                            sceneView.scene?.rootNode.pivot = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
                            
                        }*/
                        return
                    }
                }
        print("touch began")
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
     //   print("touch moved")
        let touch = touches.first!
        let location = touch.location(in: view)
        let hitTestResults = sceneView.hitTest(location, options: nil)

        // Check if the desired node is touched
        for result in hitTestResults {
            if result.node.name == self.modelName {
                // Node is touched, perform desired action
         //       print("Node is touched!")
                // Example: Change color of the node
          //      result.node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
               // try tempHaptics?.playTransient()
                let height = result.localCoordinates.z
                if !rotationOn{
                    try tempHaptics?.playHeightHaptic(height: height)
                }
                
            //    print("Check")
              //  print(result.localCoordinates)//localCoordinates shows the x,y,z coordinates of the point cloud
              //  print(height)
                
                return
            }
        }

        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        print("touch ended")
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        print("touch cancelled")
    }
    @IBAction func buttonPressed(_ sender: Any) {
        if !rotationOn{
            rotationOn = true
            sceneView.allowsCameraControl = true
        }
        else{
            rotationOn = false
            sceneView.allowsCameraControl = false
        }
        
        
    }
    
    func set(name : String){
        self.modelName = name
        self.modelFile = name + ".scn"
        scene = SCNScene(named: self.modelFile)//do i need to deallocate the current scene?
    }
            
            


}


