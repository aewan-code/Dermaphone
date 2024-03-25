//
//  ViewController.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 22/03/2024.
//

import UIKit
import SceneKit
import RealityKit
import CoreHaptics

class ViewController: UIViewController {
    
    var arView: ARView!
    var nodeModel: SCNNode!
    let nodeName = "skin"

     let sceneView = SCNView()
    let scene = SCNScene(named: "baked_mesh.scn")
    var currentView: UIView!
    var tempHaptics : Haptics?
    var engine: CHHapticEngine!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentView = view
        
        guard let baseNode = scene?.rootNode.childNode(withName: "baked_mesh", recursively: true) else {
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
       // _level = TutorialLevel1()
       
            /*  let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene!.rootNode.addChildNode(cameraNode)

        // Adjust camera position
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 10) // Move camera 10 units along the z-axis

        // Set camera orientation (optional)
        cameraNode.eulerAngles = SCNVector3(x: 0, y: 0, z: 0) // Adjust the rotation if needed

        */
        sceneView.scene = scene
        
        sceneView.allowsCameraControl = false//add button to move the model
        sceneView.showsStatistics = false
        //sceneView.backgroundColor = UIColor.black
        sceneView.debugOptions = .showWireframe
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor.white // Adjust the light color as needed
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        scene!.rootNode.addChildNode(ambientLightNode)
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        sceneView.cameraControlConfiguration.allowsTranslation = false
     //   sceneView.scene?.rootNode.eulerAngles = SCNVector3(x: 0, y: 0, z: 0)
        scene!.rootNode.addChildNode(cameraNode)
        //self.view = sceneView
        view.addSubview(sceneView)
        inspectMaterials(in: scene!.rootNode)
        print(sceneView.frame)
        sceneView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height) // Adjust the values as needed

        
    //    let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
      //  sceneView.addGestureRecognizer(panGestureRecognizer)
    }
    
    func inspectMaterials(in node: SCNNode) {
        for childNode in node.childNodes {
            // Check if the node has geometry
            if let geometry = childNode.geometry {
                // Iterate through the materials applied to the geometry
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
            if result.node.name == "baked_mesh" {
                // Node is touched, perform desired action
         //       print("Node is touched!")
                // Example: Change color of the node
          //      result.node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
               // try tempHaptics?.playTransient()
                let height = result.localCoordinates.z
                try tempHaptics?.playHeightHaptic(height: height)
                print(result.localCoordinates)//localCoordinates shows the x,y,z coordinates of the point cloud
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
    


}

