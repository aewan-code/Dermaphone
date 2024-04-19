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

class skinmodel1: UIViewController {
    
    //MARK -UI
    var prevPoint : Float?
    
    var swiftuiView : UIView?
    var closeView : UIButton?
    var firstTimestamp : TimeInterval?
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
    
    @IBOutlet weak var RotateToggle: UIButton!
 
    @IBOutlet weak var SelectPivot: UIButton!
    
    @IBOutlet weak var recordHaptic: UIButton!
    let hapticAlgorithm = HapticRendering(maxHeight: 0.5, minHeight: -0.5)
    
    var prevTimestamp : TimeInterval?
    
    var chartData : [HapticDataPoint]?
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
        sceneView.frame = CGRect(x: 0, y: notesButton.frame.maxY + 10, width: view.frame.width, height: view.frame.height - (notesButton.frame.maxY + 10)) // Adjust the values as needed
        originalOrientation = (sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)!.orientation)!
        urgencylabel.text = "Precancerous"
        
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
        

        
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let touch = touches.first!
        let location = touch.location(in: sceneView)
        if touch.view == sceneView{
            self.currentView = sceneView
        }
        // Perform hit test
                let hitTestResults = sceneView.hitTest(location, options: nil)

                // Check if the desired node is touched
                for result in hitTestResults {
                    if result.node.name == "Mesh" {
                        // Node is touched, perform desired action
                        let position = result.localCoordinates
                        //later remove so that first point is only added if continued onto touches moved
                        if recordHaptics{
                            let firstPoint = HapticDataPoint(intensity: position.y, time: 0.0)
                            chartData?.append(firstPoint)
                            firstTimestamp = touch.timestamp
                        }
                        prevPoint = position.y
                        return
                    }
                }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        let touch = touches.first!
        let location = touch.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(location, options: nil)
        
        // Check if the desired node is touched
        for result in hitTestResults {
            if result.node.name == "Mesh" {
                let height = result.localCoordinates.y
                
                let intersectionPoint = result.worldCoordinates
                let previousLocation = touch.previousLocation(in: sceneView)
                        let currentLocation = touch.location(in: sceneView)
                        
                let deltaX = (currentLocation.x - previousLocation.x)*0.01 //cm
                
                let deltaY = (currentLocation.y - previousLocation.y)*0.01
                let prevTime = prevTimestamp ?? 0.0
                let timeDelta = touch.timestamp - prevTime
                prevTimestamp = touch.timestamp
                let velocityX = deltaX / CGFloat(timeDelta)
                let velocityY = deltaY / CGFloat(timeDelta)
                let speed = Float(sqrt((velocityX * velocityX) + (velocityY * velocityY)))
                if scale == nil{
        //             scale = heightTemp.rounded()
                }
                //let intensity = hapticAlgorithm.forceFeedback(height: height, velocity: speed)
                let intensity = (((height - (prevPoint ?? 0))*1000)+5)/10
                print(intensity)
                if recordHaptics{
                 //   let dataPoint = HapticDataPoint(intensity: height, time: Float(touch.timestamp - (firstTimestamp ?? touch.timestamp)))
                    let dataPoint = HapticDataPoint(intensity: intensity, time:Float(touch.timestamp - (firstTimestamp ?? touch.timestamp)))
                    chartData?.append(dataPoint)
                }
                
                prevPoint = height
                if !rotationOn{
                    try tempHaptics?.playHeightHaptic(height:intensity)
                }
                return
            }
        }

        
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
    }
    @IBAction func buttonPressed(_ sender: Any) {
        if !rotationOn{
            rotationOn = true
            sceneView.allowsCameraControl = true
            sceneView.cameraControlConfiguration.allowsTranslation = false
            RotateToggle.tintColor = UIColor.systemGreen
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
        let q = SCNQuaternion(sinAngle, 0, 0, cosAngle)
         sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.localRotate(by: q)
        
    }
    @IBAction func yChanged(_ sender: Any) {
        var newValue = yScale.value
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
        let q = SCNQuaternion(0, sinAngle, 0, cosAngle)

         sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.localRotate(by: q)
        
    }
    @IBAction func zChanged(_ sender: Any) {
        var newValue = zScale.value
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
        let q = SCNQuaternion(0, 0, sinAngle, cosAngle)
         sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)?.localRotate(by: q)
        
    }
    
    func createAxes(){//fix code for axes - change!
        
        let xAxis = SCNCylinder(radius: 0.001, height: 1)
        xAxis.firstMaterial?.diffuse.contents = UIColor.red
        xAxisNode = SCNNode(geometry: xAxis)
        xAxisNode?.simdWorldOrientation = simd_quatf.init(angle: .pi/2, axis: simd_float3(0, 0, 1))
        xAxisNode?.simdWorldPosition = simd_float1(1)/2 * simd_float3(1, 0, 0)
        scene?.rootNode.addChildNode(xAxisNode!)
        let yAxis = SCNCylinder(radius: 0.001, height: 1)
        yAxis.firstMaterial?.diffuse.contents = UIColor.green
        yAxisNode = SCNNode(geometry: yAxis)

        yAxisNode?.simdWorldPosition = simd_float1(1)/2 * simd_float3(0, 1, 0)
        scene?.rootNode.addChildNode(yAxisNode!)
        let zAxis = SCNCylinder(radius: 0.001, height: 1)
        zAxis.firstMaterial?.diffuse.contents = UIColor.blue
        zAxisNode = SCNNode(geometry: zAxis)
        zAxisNode?.simdWorldOrientation = simd_quatf.init(angle: .pi/2, axis: simd_float3(1, 0, 0))
        zAxisNode?.simdWorldPosition = simd_float1(1)/2 * simd_float3(0, 0, 1)
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
            chartData = []
            //BEGIN RECORDING
        }
        else{
            recordHaptics = false
            recordHaptic.titleLabel?.text = "Record"
            recordHaptic.tintColor = UIColor.systemBlue
            if chartData != nil || ((chartData?.isEmpty) != nil) == false{
                // 1
                let vc = UIHostingController(rootView: HapticChart(data: chartData ?? []))

                swiftuiView = vc.view!
                swiftuiView?.translatesAutoresizingMaskIntoConstraints = false
                
                // 2
                // Add the view controller to the destination view controller.
                addChild(vc)
                view.addSubview(swiftuiView!)
                
                // 3
                // Create and activate the constraints for the swiftui's view.
                NSLayoutConstraint.activate([
                    //swiftuiView!.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    swiftuiView!.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                    swiftuiView!.widthAnchor.constraint(equalTo: view.widthAnchor),
                    swiftuiView!.leftAnchor.constraint(equalTo: view.leftAnchor)
                    ])
                // Notify the child view controller that the move is complete.
                vc.didMove(toParent: self)
                
                closeView = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 50))
                closeView?.backgroundColor = UIColor.systemRed
                
                closeView?.setTitle("Close", for: [])
                closeView?.addTarget(self, action: #selector(closeViewAction), for: .touchUpInside)

                self.view.addSubview(closeView!)
                NSLayoutConstraint.activate([
                    closeView!.bottomAnchor.constraint(equalTo: swiftuiView!.topAnchor)
                ])
                view.bringSubviewToFront(closeView!)
                
            }
            chartData = []//DATA DELETED
        }
    }
    
    @objc func closeViewAction(){
        swiftuiView?.removeFromSuperview()
        closeView?.removeFromSuperview()
        
    }
    
    
    


}

