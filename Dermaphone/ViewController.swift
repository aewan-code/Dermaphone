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
    
    
    @IBOutlet weak var zScale: UISlider!
    
    @IBOutlet weak var yScale: UISlider!
    
    @IBOutlet weak var xScale: UISlider!
    @IBOutlet weak var zLabel: UILabel!
    @IBOutlet weak var yLabel: UILabel!
    @IBOutlet weak var xLabel: UILabel!
    @IBOutlet weak var completeEdit: UIBarButtonItem!
    var currentXVal :Float?
    var currentYVal : Float?
    var currentZVal : Float?
    @IBOutlet weak var cancelEdit: UIButton!
    var arView: ARView!
    var nodeModel: SCNNode!
    let nodeName = "skin"
    var originalOrientation :SCNQuaternion?
    

     let sceneView = SCNView()
    let cameraNode = SCNNode()
    let scene = SCNScene(named: "testTransform.scn")
    var currentView: UIView!
    var tempHaptics : Haptics?
    var engine: CHHapticEngine!
    var changePivot = false
    var scale : Float?
    var rotationOn = false
  //  let referencePlane = SCNPlane(width: 100, height: 100) // Adjust the size as needed
  //  var referencePlaneNode :SCNNode!
    
    @IBOutlet weak var RotateToggle: UIButton!
 
    @IBOutlet weak var SelectPivot: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        currentView = view
        
        guard let baseNode = scene?.rootNode.childNode(withName: "Mesh", recursively: true) else {
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
        
        cameraNode.camera = SCNCamera()
        sceneView.cameraControlConfiguration.allowsTranslation = false
     //   sceneView.scene?.rootNode.eulerAngles = SCNVector3(x: 0, y: 0, z: 0)
        scene!.rootNode.addChildNode(cameraNode)
        sceneView.debugOptions = [.showCreases]
        //self.view = sceneView
        view.addSubview(sceneView)
        inspectMaterials(in: scene!.rootNode)
        print(sceneView.frame)
        sceneView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height) // Adjust the values as needed
        originalOrientation = (sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)!.orientation)!

        
    //    let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
      //  sceneView.addGestureRecognizer(panGestureRecognizer)
        
        //Add to function
        view.bringSubviewToFront(RotateToggle)
        view.bringSubviewToFront(SelectPivot)

        view.bringSubviewToFront(xLabel)
        view.bringSubviewToFront(yLabel)
        view.bringSubviewToFront(zLabel)
        view.bringSubviewToFront(xScale)
        view.bringSubviewToFront(yScale)
        view.bringSubviewToFront(zScale)
        xLabel.isHidden = true
        yLabel.isHidden = true
        zLabel.isHidden = true
        xScale.isHidden = true
        yScale.isHidden = true
        zScale.isHidden = true

        cancelEdit.isHidden = true
        completeEdit.isHidden = true
        
        changePivot = false
        print("ALEERA")
 //       print(sceneView.scene?.rootNode.pivot)
 //       referencePlaneNode = SCNNode(geometry: referencePlane)
  //      scene!.rootNode.addChildNode(referencePlaneNode)
        
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
                    if result.node.name == "Mesh" {
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
            if result.node.name == "Mesh" {
                // Node is touched, perform desired action
         //       print("Node is touched!")
                // Example: Change color of the node
          //      result.node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
               // try tempHaptics?.playTransient()
                let height = result.localCoordinates.y
                print(height)
                
                let intersectionPoint = result.worldCoordinates
                        // Calculate the height using the intersection point and the plane
       //         let heightTemp = calculateHeight(referencePlaneNode, atPoint: intersectionPoint)
            //    print(intersectionPoint)
                print("Ewan")
        //        print(-heightTemp)
                if scale == nil{
        //             scale = heightTemp.rounded()
                }
           //     print(heightTemp)
            //    let scaledHeight = heightTemp/scale!//scaled between -0.5 to -1.5
            //   print(scaledHeight)
                if !rotationOn{
                    try tempHaptics?.playHeightHaptic(height: height*10)
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
    @IBAction func pivotButtonPressed(_ sender: Any) {
        cancelEdit.isHidden = false
        completeEdit.isHidden = false
        xLabel.isHidden = false
        yLabel.isHidden = false
        zLabel.isHidden = false
        xScale.isHidden = false
        yScale.isHidden = false
        zScale.isHidden = false
        RotateToggle.isHidden = true
        SelectPivot.isHidden = true
        sceneView.debugOptions = SCNDebugOptions(rawValue: 2048)//shows the grid
        originalOrientation = sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.orientation
        currentXVal = 0
        currentYVal = 0
        currentZVal = 0
       /* let q = SCNQuaternion(0, 0, (sqrt(2)/2), (sqrt(2)/2))
        //sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.localTranslate(by: vector)
        sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.localRotate(by: q)
        print(sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.orientation)
        */
  /*      if !changePivot{
            changePivot = true
            rotationOn = false
            sceneView.allowsCameraControl = false
            if let cameraNode = sceneView.pointOfView {
                let cameraRotation = cameraNode.rotation
                let cameraEulerAngles = cameraNode.eulerAngles
                
                print("Camera Rotation: \(cameraRotation)")
                print("Camera Euler Angles: \(cameraEulerAngles)")
                let objectOrientation = cameraEulerAngles
          //      print(objectOrientation)
                    //        referencePlaneNode.eulerAngles = objectOrientation
            }
            
            
            
            //let referencePlaneNormal = SCNVector3(0, 1, 0) // Assuming the plane is aligned with the Y-axis
         //   print(sceneView.scene?.rootNode.rotation)
       
            
            

            
            
            
        }
        else{
            changePivot = false
        }*/
    }
    
    func calculateHeight(_ plane: SCNNode, atPoint point: SCNVector3) -> Float {
        let worldTransform = plane.worldTransform
        
        //let planePosition = SCNVector3(worldTransform.m41, worldTransform.m42, worldTransform.m43)
        let planePosition = plane.position
       // print("position")
        //print(planePosition)
       // print(worldTransform)
        let planeNormal = SCNVector3(worldTransform.m31, worldTransform.m32, worldTransform.m33)
        let D = -(planeNormal.x * planePosition.x + planeNormal.y * planePosition.y + planeNormal.z * planePosition.z)
        //print(D)
        let A = planeNormal.x
        let B = planeNormal.y
        let C = planeNormal.z
        let x = point.x
        let y = point.y
        let z = point.z
        var numerator = A * x
        numerator = numerator + (B * y)
        numerator = numerator + (C * z)
        numerator = numerator + D
        numerator = numerator * numerator
        numerator = sqrt(numerator)
        
        var denominator = A * A
        denominator = denominator + (B * B)
        denominator = denominator + (C * C)
        denominator = sqrt(denominator)
        //+ B^2 + C^2)
     //   print(numerator)
       // print(denominator)
        let distance = numerator/denominator //|Axo + Byo+ Czo + D|/√(A2 + B2 + C2)
       // let distance = 1.0// Calculate distance between point and plane using plane equation
        return distance
    }
    func showOriginalView(){
        cancelEdit.isHidden = true
        completeEdit.isHidden = true
        xLabel.isHidden = true
        yLabel.isHidden = true
        xScale.isHidden = true
        yScale.isHidden = true
        zScale.isHidden = true
        zLabel.isHidden = true
        xScale.value = 0
        yScale.value = 0
        zScale.value = 0
        RotateToggle.isHidden = false
        SelectPivot.isHidden = false
        sceneView.debugOptions = [.showCreases]
        
    }
    @IBAction func cancelPressed(_ sender: Any) {
        sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.orientation = originalOrientation!
        showOriginalView()
    }
    
    @IBAction func completePressed(_ sender: Any) {
        showOriginalView()
    }
    @IBAction func xChanged(_ sender: Any) {//FIX SO THAT DIRECTION OF USER'S FINGER ON THE SLIDER IS WHAT AFFECTS THE SPINNING DIRECTION
        var newValue = xScale.value
        print(currentXVal)
        print(newValue)
        if newValue > currentXVal ?? 0{
            currentXVal = newValue
            newValue = 0.5
        }
        else if newValue < currentXVal ?? 0 {
            currentXVal = newValue
            newValue = -0.5
        }
        let sinAngle = sin((Float.pi * newValue/180))
        let cosAngle = cos((Float.pi * newValue/180))
        let q = SCNQuaternion(sinAngle, 0, 0, cosAngle)
         //sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.localTranslate(by: vector)
         sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.localRotate(by: q)
      //   print(sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.orientation)
        
        
    }
    @IBAction func yChanged(_ sender: Any) {
        var newValue = yScale.value
        if newValue > currentYVal ?? 0{
            currentYVal = newValue
            newValue = 1
        }
        else if newValue < currentYVal ?? 0  {
            currentYVal = newValue
            newValue = -1
        }
        let sinAngle = sin((Float.pi * newValue/180))
        let cosAngle = cos((Float.pi * newValue/180))
        let q = SCNQuaternion(0, sinAngle, 0, cosAngle)
         //sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.localTranslate(by: vector)
         sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.localRotate(by: q)
       //  print(sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.orientation)
        
    }
    @IBAction func zChanged(_ sender: Any) {
        var newValue = zScale.value
        print(newValue)
        print(currentZVal)
        if newValue > 1 + (currentZVal ?? 0){
            currentZVal = newValue
            newValue = 1
        }
        else if newValue < -1 + (currentZVal ?? 0){
            currentZVal = newValue
            newValue = -1
        }
        let sinAngle = sin((Float.pi * newValue/180))
        let cosAngle = cos((Float.pi * newValue/180))
        let q = SCNQuaternion(0, 0, sinAngle, cosAngle)
        print(q)
        
        
         //sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.localTranslate(by: vector)
         sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.localRotate(by: q)
         //print(sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.orientation)
        
    }
    
    


}

