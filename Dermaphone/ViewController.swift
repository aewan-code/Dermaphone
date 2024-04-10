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
import SwiftUI

class ViewController: UIViewController {
    
    //MARK -UI
    
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var zScale: UISlider!
    
    @IBOutlet weak var yScale: UISlider!
    
    @IBOutlet weak var xScale: UISlider!
    @IBOutlet weak var zLabel: UILabel!
    @IBOutlet weak var yLabel: UILabel!
    @IBOutlet weak var xLabel: UILabel!
    @IBOutlet weak var completeEdit: UIBarButtonItem!
    @IBOutlet weak var cancelEdit: UIBarButtonItem!
    
    @IBOutlet weak var symptonsButton: UIButton!
    
    @IBOutlet weak var treatmentButton: UIButton!
    @IBOutlet weak var notesButton: UIButton!
    @IBOutlet weak var urgencylabel: UILabel!
    @IBOutlet weak var similarButton: UIButton!

    @IBOutlet var magnifier: [UIImageView]!
    
    @IBOutlet var magnifierText: [UILabel]!
    var currentXVal :Float?
    var currentYVal : Float?
    var currentZVal : Float?
    var arView: ARView!
    var nodeModel: SCNNode!
    let nodeName = "skin"
    var originalOrientation :SCNQuaternion?
    
    var recordHaptics = false
    
     let sceneView = SCNView()
    let cameraNode = SCNNode()
    let scene = SCNScene(named: "testTransform.scn")
    var currentView: UIView!
    var tempHaptics : Haptics?
    var engine: CHHapticEngine!
    var changePivot = false
    var scale : Float?
    var rotationOn = false
    var xAxisNode : SCNNode?
    var yAxisNode : SCNNode?
    var zAxisNode : SCNNode?
  //  let referencePlane = SCNPlane(width: 100, height: 100) // Adjust the size as needed
  //  var referencePlaneNode :SCNNode!
    
    @IBOutlet weak var RotateToggle: UIButton!
 
    @IBOutlet weak var SelectPivot: UIButton!
    
    @IBOutlet weak var recordHaptic: UIButton!
    let hapticAlgorithm = HapticRendering(maxHeight: 0.5, minHeight: -0.5)
    
    var prevTimestamp : TimeInterval?
    override func viewDidLoad() {
        super.viewDidLoad()

        currentView = view
        print(notesButton.frame.minY)
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
     //   scene!.rootNode.addChildNode(cameraNode)
        cameraNode.constraints = [SCNTransformConstraint.positionConstraint(
            inWorldSpace: true,
            with: { (node, position) -> SCNVector3 in
                // Return the original position to prevent any translation
                return node.position
            }
        )]
        sceneView.debugOptions = [.showCreases]
        //self.view = sceneView
        view.addSubview(sceneView)
        print(sceneView.frame)
        sceneView.frame = CGRect(x: 0, y: notesButton.frame.maxY + 10, width: view.frame.width, height: view.frame.height - (notesButton.frame.maxY + 10)) // Adjust the values as needed
        originalOrientation = (sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)!.orientation)!
        urgencylabel.text = "Precancerous"
        

        
    //    let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
      //  sceneView.addGestureRecognizer(panGestureRecognizer)
        
        //Add to function
        view.bringSubviewToFront(RotateToggle)
        view.bringSubviewToFront(SelectPivot)
        view.bringSubviewToFront(recordHaptic)
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
        createAxes()
        hideAxes()
        navBar.title = "Skin Lesion: Actinic Keratosis"
        navBar.titleView?.isHidden = false
        for image in magnifier{
            view.bringSubviewToFront(image)
        }
        for descript in magnifierText{
            view.bringSubviewToFront(descript)
        }

 //       print(sceneView.scene?.rootNode.pivot)
 //       referencePlaneNode = SCNNode(geometry: referencePlane)
  //      scene!.rootNode.addChildNode(referencePlaneNode)
        customizeGestureRecognizers()
        
        // 1
        let vc = UIHostingController(rootView: HapticChart())

        let swiftuiView = vc.view!
        swiftuiView.translatesAutoresizingMaskIntoConstraints = false
        
        // 2
        // Add the view controller to the destination view controller.
        addChild(vc)
        view.addSubview(swiftuiView)
        
        // 3
        // Create and activate the constraints for the swiftui's view.
        NSLayoutConstraint.activate([
            swiftuiView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            swiftuiView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        
        // 4
        // Notify the child view controller that the move is complete.
        vc.didMove(toParent: self)
        
    }
    
    
    
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
        let location = touch.location(in: sceneView)
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
                let previousLocation = touch.previousLocation(in: sceneView)
                        let currentLocation = touch.location(in: sceneView)
                        
                let deltaX = (currentLocation.x - previousLocation.x)*0.01 //cm
                
                let deltaY = (currentLocation.y - previousLocation.y)*0.01
                    //    let deltaZ = currentLocation.z - previousLocation.z // Assuming your touch event provides z-coordinates
                let prevTime = prevTimestamp ?? 0.0
                let timeDelta = touch.timestamp - prevTime
                prevTimestamp = touch.timestamp
                let velocityX = deltaX / CGFloat(timeDelta)
                let velocityY = deltaY / CGFloat(timeDelta)
                let speed = Float(sqrt((velocityX * velocityX) + (velocityY * velocityY)))
                     //   let timeDelta = touch.timestamp - touch.previousLocation(in: self.view).timestamp
                print("Ewan")
        //        print(-heightTemp)
                print(deltaX)
                print(deltaY)
                if scale == nil{
        //             scale = heightTemp.rounded()
                }
           //     print(heightTemp)
            //    let scaledHeight = heightTemp/scale!//scaled between -0.5 to -1.5
            //   print(scaledHeight)
                let intensity = hapticAlgorithm.forceFeedback(height: height, velocity: speed)
                if !rotationOn{
                    //try tempHaptics?.playHeightHaptic(height: height*10)
                    try tempHaptics?.playHeightHaptic(height:intensity/2)
                }
                print(sceneView.cameraControlConfiguration.panSensitivity)
               // print(cameraNode.constraints)
                print(speed)
                print("ALGORITHM")
                print(hapticAlgorithm.forceFeedback(height: height, velocity: speed))
                
            //    print("Check")
              //  print(result.localCoordinates)//localCoordinates shows the x,y,z coordinates of the point cloud
              //  print(height)
                
                return
            }
        }

        
    }
    
    private func customizeGestureRecognizers() {//doesn't work
        // Remove default gesture recognizers for two-finger pan
        if let defaultGestureRecognizers = sceneView.gestureRecognizers
        {
            for recognizer in defaultGestureRecognizers {
                if let panGestureRecognizer = recognizer as? UIPanGestureRecognizer {
                    if panGestureRecognizer.minimumNumberOfTouches == 2 {
                        sceneView.removeGestureRecognizer(panGestureRecognizer)
                    }
                }
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
            sceneView.cameraControlConfiguration.allowsTranslation = false
            print("CHECK CAMERA")
            print(sceneView.gestureRecognizers)
            RotateToggle.tintColor = UIColor.systemGreen
          //  sceneView.defaultCameraController.
          //  sceneView.cameraControlConfiguration.panSensitivity = 0
          //  sceneView.defaultCameraController.interactionMode = .orbitTurntable
          //  scnview.defaultCameraController.inertiaEnabled = true
           // scnview.defaultCameraController.maximumVerticalAngle = 69
            //scnview.defaultCameraController.minimumVerticalAngle = -69
            //s/cnview.autoenablesDefaultLighting = true
        }
        else{
            rotationOn = false
            sceneView.allowsCameraControl = false
            RotateToggle.tintColor = UIColor.systemBlue
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
        notesButton.isHidden = true
        treatmentButton.isHidden = true
        symptonsButton.isHidden = true
        urgencylabel.isHidden = true
        similarButton.isHidden = true
        recordHaptic.isHidden = true
        sceneView.debugOptions = SCNDebugOptions(rawValue: 2048)//shows the grid
        originalOrientation = sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.orientation
        currentXVal = 0
        currentYVal = 0
        currentZVal = 0
        overlayAxes()

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
        notesButton.isHidden = false
        symptonsButton.isHidden = false
        treatmentButton.isHidden = false
        urgencylabel.isHidden = false
        similarButton.isHidden = false
        recordHaptic.isHidden = false
        hideAxes()
        
    }
    @IBAction func cancelPressed(_ sender: Any) {
        sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.orientation = originalOrientation!
        showOriginalView()
    }
    
    @IBAction func completePressed(_ sender: Any) {
        showOriginalView()
    }
    @IBAction func xChanged(_ sender: Any) {
        var newValue = xScale.value
        print(newValue)
        print(currentXVal)
        if newValue > (currentXVal ?? 0){
            currentXVal = newValue
            if newValue == xScale.maximumValue || newValue == xScale.minimumValue{
                newValue = 0.0
            }else{
                newValue = 1
            }
        }
        else if newValue < (currentXVal ?? 0){
            currentXVal = newValue
            if newValue == xScale.maximumValue || newValue == xScale.minimumValue{
                newValue = 0.0
            }else{
                newValue = -1
            }
        }
        else if newValue == currentXVal{
            newValue = 0
        }
        let sinAngle = sin((Float.pi * newValue/180))
        let cosAngle = cos((Float.pi * newValue/180))
        print(cosAngle)
        print(cos((0.0)))
        print(newValue)
        let q = SCNQuaternion(sinAngle, 0, 0, cosAngle)
        print(q)
        
        
         //sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.localTranslate(by: vector)
         sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.localRotate(by: q)
         //print(sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.orientation)
        
    }
    @IBAction func yChanged(_ sender: Any) {
        var newValue = yScale.value
        print(newValue)
        print(currentYVal)
        if newValue > (currentYVal ?? 0){
            currentYVal = newValue
            if newValue == yScale.maximumValue || newValue == yScale.minimumValue{
                newValue = 0.0
            }else{
                newValue = 1
            }
        }
        else if newValue < (currentYVal ?? 0){
            currentYVal = newValue
            if newValue == yScale.maximumValue || newValue == yScale.minimumValue{
                newValue = 0.0
            }else{
                newValue = -1
            }
        }
        else if newValue == currentYVal{
            newValue = 0
        }
        let sinAngle = sin((Float.pi * newValue/180))
        let cosAngle = cos((Float.pi * newValue/180))
        print(cosAngle)
        print(cos((0.0)))
        print(newValue)
        let q = SCNQuaternion(0, sinAngle, 0, cosAngle)
        print(q)
        
        
         //sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.localTranslate(by: vector)
         sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.localRotate(by: q)
         //print(sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.orientation)
        
    }
    @IBAction func zChanged(_ sender: Any) {
        var newValue = zScale.value
        print(newValue)
        print(currentZVal)
        if newValue > (currentZVal ?? 0){
            currentZVal = newValue
            if newValue == zScale.maximumValue || newValue == zScale.minimumValue{
                newValue = 0.0
            }else{
                newValue = 1
            }
        }
        else if newValue < (currentZVal ?? 0){
            currentZVal = newValue
            if newValue == zScale.maximumValue || newValue == zScale.minimumValue{
                newValue = 0.0
            }else{
                newValue = -1
            }
        }
        else if newValue == currentZVal{
            newValue = 0
        }
        let sinAngle = sin((Float.pi * newValue/180))
        let cosAngle = cos((Float.pi * newValue/180))
        print(cosAngle)
        print(cos((0.0)))
        print(newValue)
        let q = SCNQuaternion(0, 0, sinAngle, cosAngle)
        print(q)
        
        
         //sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.localTranslate(by: vector)
         sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.localRotate(by: q)
         //print(sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.orientation)
        
    }
    
    func createAxes(){//fix code for axes - change!
     //   let xaxis = SCNNode(geometry: SCNCylinder(radius: 1, height: 10))//base it on the max of the height/width of the skin lesion
        
        let xAxis = SCNCylinder(radius: 0.001, height: 1)
        xAxis.firstMaterial?.diffuse.contents = UIColor.red
        xAxisNode = SCNNode(geometry: xAxis)
        // by default the middle of the cylinder will be at the origin aligned to the y-axis
        // need to spin around to align with respective axes and shift position so they start at the origin
        xAxisNode?.simdWorldOrientation = simd_quatf.init(angle: .pi/2, axis: simd_float3(0, 0, 1))
        xAxisNode?.simdWorldPosition = simd_float1(1)/2 * simd_float3(1, 0, 0)
       // xaxis.position = SCNVector3(0,0,0)
        scene?.rootNode.addChildNode(xAxisNode!)
        let yAxis = SCNCylinder(radius: 0.001, height: 1)
        yAxis.firstMaterial?.diffuse.contents = UIColor.green
        yAxisNode = SCNNode(geometry: yAxis)
        // by default the middle of the cylinder will be at the origin aligned to the y-axis
        // need to spin around to align with respective axes and shift position so they start at the origin

        yAxisNode?.simdWorldPosition = simd_float1(1)/2 * simd_float3(0, 1, 0)
       // xaxis.position = SCNVector3(0,0,0)
        scene?.rootNode.addChildNode(yAxisNode!)
        let zAxis = SCNCylinder(radius: 0.001, height: 1)
        zAxis.firstMaterial?.diffuse.contents = UIColor.blue
        zAxisNode = SCNNode(geometry: zAxis)
        // by default the middle of the cylinder will be at the origin aligned to the y-axis
        // need to spin around to align with respective axes and shift position so they start at the origin
        zAxisNode?.simdWorldOrientation = simd_quatf.init(angle: .pi/2, axis: simd_float3(1, 0, 0))
        zAxisNode?.simdWorldPosition = simd_float1(1)/2 * simd_float3(0, 0, 1)
       // xaxis.position = SCNVector3(0,0,0)
        scene?.rootNode.addChildNode(zAxisNode!)
        
    }
    
    func hideAxes(){
        xAxisNode?.isHidden = true
        yAxisNode?.isHidden = true
        zAxisNode?.isHidden = true
        
    }
    
    func overlayAxes(){
        xAxisNode?.isHidden = false
        yAxisNode?.isHidden = false
        zAxisNode?.isHidden = false
    }
    
    
    @IBAction func recordPressed(_ sender: Any) {//when rotation turned on, turn off record
        if !recordHaptics {
            recordHaptics = true
            recordHaptic.titleLabel?.text = "Recording"
            recordHaptic.tintColor = UIColor.systemGreen
            
            RotateToggle.tintColor = UIColor.systemBlue
            rotationOn = false
            sceneView.allowsCameraControl = false
            //BEGIN RECORDING 
        }
        else{
            recordHaptics = false
            recordHaptic.titleLabel?.text = "Record"
            recordHaptic.tintColor = UIColor.systemBlue
            //IF IT EXISTS, SHOW GRAPH - LET IT BE POSSIBLE TO BE CLOSED (WITH AN X ON THE TOP)
        }
    }
    
    
    


}

