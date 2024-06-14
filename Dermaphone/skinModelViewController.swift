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
import simd
import SceneKit.ModelIO
import FirebaseFirestore
import FirebaseStorage


enum FilterType: String {
    case none = "None"
    case gaussian = "Gaussian"
    case average = "Weighted Average"
    case edge = "Ricker Wavelet"
    case heightMap = "Height Map"
}

class skinmodel: UIViewController {
    var activityIndicator: UIActivityIndicatorView!
        var modelLoaded = false
    @IBOutlet weak var saveButton: UIButton!
    var filter : FilterType = .none//save type
    var kVal : Int = 5
    var sigmaVal : Float = 1
    var rotationScaleVal : Int = 4
    var condition : SkinCondition?
    var modelName: String?// = "Mesh"
    var modelFile : String?// = "testTransform.scn"
    var currentIntensity : Float?
    var currentSharpness : Float?
    //MARK -UI
    var prevPoint : Float?
    var previousPosition : modelLocation?
    var hapticTransient : Bool?
    var swiftuiView : UIView?
    var closeView : UIButton?
    var firstTimestamp : TimeInterval?
    var modelVertices : [SCNVector3]?
    
    @IBOutlet weak var uiLine1: UIView!
    @IBOutlet weak var uiLine2: UIView!
    var maxPoint : SCNVector3?
    var minPoint : SCNVector3?
    var filterMin : SCNVector3?
    var filterMax : SCNVector3?
    var smoothedCloud : [SCNVector3]?
    var transientCloud : [SCNVector3]?
    var originalHeightMap : [[Float]]?
    
    
    ///UI - Functional Buttons
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var hapticsButton: UIButton!
    @IBOutlet weak var RotateToggle: UIButton!
    @IBOutlet weak var SelectPivot: UIButton!
    @IBOutlet weak var recordHaptic: UIButton!
//    @IBOutlet weak var smoothButton: UIButton!
    @IBOutlet weak var hapticMethod: UISegmentedControl!




///UI - Haptics Settings Mode
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var hapticsSettings: UIView!
    @IBOutlet weak var cancelSettings: UIButton!
    @IBOutlet weak var sigmaSetting: UISlider!
    @IBOutlet weak var filterSetting: UIButton!
    @IBOutlet weak var kSetting: UISlider!
    @IBOutlet weak var gradientHeightMap: UISegmentedControl!
    @IBOutlet weak var doneSettings: UIButton!
    @IBOutlet weak var rotationScale: UISlider!
    @IBOutlet weak var sharpnessToggle: UISegmentedControl!
    @IBOutlet weak var intensitySkirt: UISlider!
    
    ///UI - Coordinate Mode
    @IBOutlet weak var zScale: UISlider!
    @IBOutlet weak var yScale: UISlider!
    @IBOutlet weak var xScale: UISlider!
    @IBOutlet weak var zLabel: UILabel!
    @IBOutlet weak var yLabel: UILabel!
    @IBOutlet weak var xLabel: UILabel!
    @IBOutlet weak var completeEdit: UIButton!
    @IBOutlet weak var cancelEdit: UIButton!
    
    ///UI - Notes
    @IBOutlet weak var symptonsButton: UIButton!
    @IBOutlet weak var treatmentButton: UIButton!
    @IBOutlet weak var notesButton: UIButton!
    @IBOutlet weak var urgencylabel: UILabel!
    @IBOutlet weak var similarButton: UIButton!

    
    var currentXVal :Float?
    var currentYVal : Float?
    var currentZVal : Float?
    var arView: ARView!
    var nodeModel: SCNNode!
    let nodeName = "skin"
    var originalOrientation :SCNQuaternion?
    var hapticsToggle = false
    var originalCameraPosition: SCNVector3?
    var originalCameraOrientation: SCNQuaternion?
    
    var gradientToggle : Bool = false
    var palpationToggle : Bool = false
    //if true -> visual
    //if false -> texture
    
    var recordHaptics = false
    
     let sceneView = SCNView()
    let cameraNode = SCNNode()
    var scene : SCNScene?
    var currentView: UIView!
    var tempHaptics : Haptics?
    var engine: CHHapticEngine!
    var changePivot = false
    var scale : Float?
    var rotationOn = false
    var xAxisNode : SCNNode?
    var yAxisNode : SCNNode?
    var zAxisNode : SCNNode?
    //0 = palpate, 1 = visual
    @IBOutlet weak var palpationOption: UISegmentedControl!

    let hapticAlgorithm = HapticRendering(maxHeight: 0.5, minHeight: -0.5)
    
    var prevTimestamp : TimeInterval?
    
    var chartData : [HapticDataPoint]?
    let smoothedModel = smoothModel()
    var kernel : [[[Double]]]?
    var vertices : [SCNVector3]?
    
    var maxContinuous : Float?
    var minContinuous : Float?
    var maxTransient : Float?
    var minTransient : Float?
    var maxHeight : Float?
    var minHeight : Float?
    
    var enhancedMap : [[Float]]?
    var gradientEffect : Bool = false
    var intensityScale : Float = 1
    var sharpnessParam = false
    
    var sourceType: LesionLibrary.SourceType?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !modelLoaded {
            loadModel()
            
        }
    }
    
    private func setupSceneView() {
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
        sceneView.defaultCameraController.pointOfView?.position = SCNVector3(x: Float.pi/36, y: Float.pi/3, z: Float.pi/24)
        sceneView.defaultCameraController.pointOfView?.orientation = SCNQuaternion(-Float.pi/4, 0.0, 0.0, Float.pi/4)
        sceneView.defaultCameraController.pointOfView?.eulerAngles = SCNVector3(-Float.pi/2, 0.0,0.0)
        cameraNode.constraints = [SCNTransformConstraint.positionConstraint(
            inWorldSpace: true,
            with: { (node, position) -> SCNVector3 in
                // Return the original position to prevent any translation
                return node.position
            }
        )]
      //  originalCameraPosition = cameraNode.position
        originalCameraPosition = sceneView.defaultCameraController.pointOfView?.position
        originalCameraOrientation = sceneView.defaultCameraController.pointOfView?.orientation
        sceneView.debugOptions = [.showCreases]
        //self.view = sceneView
        view.addSubview(sceneView)
        
      //  sceneView.frame = CGRect(x: 0, y: notesButton.frame.maxY + 10, width: view.frame.width, height: view.frame.height - (notesButton.frame.maxY + 10)) // Adjust the values as needed
        sceneView.frame = CGRect(x: 0, y: (urgencylabel.frame.maxY + 10), width: view.frame.width, height: view.frame.height - (urgencylabel.frame.maxY + 30))
        
        view.bringSubviewToFront(RotateToggle)
        view.bringSubviewToFront(palpationOption)
        view.bringSubviewToFront(SelectPivot)
        view.bringSubviewToFront(recordHaptic)
        view.bringSubviewToFront(saveButton)
        view.bringSubviewToFront(xLabel)
        view.bringSubviewToFront(yLabel)
        view.bringSubviewToFront(zLabel)
        view.bringSubviewToFront(xScale)
        view.bringSubviewToFront(yScale)
        view.bringSubviewToFront(zScale)
        view.bringSubviewToFront(hapticsButton)
        view.bringSubviewToFront(uiLine1)
        view.bringSubviewToFront(uiLine2)
        view.bringSubviewToFront(settingsButton)
        view.bringSubviewToFront(hapticsSettings)
        view.bringSubviewToFront(notesButton)
        view.bringSubviewToFront(symptonsButton)
        view.bringSubviewToFront(treatmentButton)
        view.bringSubviewToFront(similarButton)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        hapticMethod.selectedSegmentIndex = 0
        currentView = view
        hapticTransient = true
        

            //   scene = SCNScene(named: modelFile ?? "test2scene.scn")
        let database = DatabaseManagement()

        do {
            engine = try CHHapticEngine()
        } catch let error {
            fatalError("Engine Creation Error: \(error)")
        }
        tempHaptics = Haptics(engine: engine)
        
       // sceneView.scene = scene
      //  getModel()
       // setupSceneView()
        setupActivityIndicator()
        
       //originalOrientation = (sceneView.scene?.rootNode.childNode(withName: "Mesh", recursively: true)!.orientation)!
        urgencylabel.text = self.condition?.urgency ?? ""
        
        //Add to function

        xLabel.isHidden = true
        yLabel.isHidden = true
        zLabel.isHidden = true
        xScale.isHidden = true
        yScale.isHidden = true
        zScale.isHidden = true
        hapticsSettings.isHidden = true

        cancelEdit.isHidden = true
        completeEdit.isHidden = true
        
        changePivot = false
        hapticsToggle = false
        createAxes()
        hideAxes()
        navBar.title = "Skin Lesion: \(self.condition?.name ?? "")"
        navBar.titleView?.isHidden = false
        gradientEffect = false


        setFilters()
        configureBasedOnSource()
        
    }
    
    func setFilters(){
        let optionClosure = {(action : UIAction) in
            print(action.title)
            switch action.title{
            case "None":
                self.filter = .none
            case "Gaussian":
                self.filter = .gaussian
            case "Weighted Average":
                self.filter = .average
            case "Ricker Wavelet":
                self.filter = .edge
            case "Height Map":
                self.filter = .heightMap
            default:
                return
            }
            
            
        }
        
       
        filterSetting.menu = UIMenu(children : [
            UIAction(title : "None", handler : optionClosure),
            UIAction(title : "Gaussian", handler : optionClosure),
            UIAction(title : "Second Derivative", handler : optionClosure),
            UIAction(title : "Sobel Operator", handler : optionClosure),
            UIAction(title : "Peak Detector", handler : optionClosure),
            
        ])
        
        filterSetting.showsMenuAsPrimaryAction = true
        filterSetting.changesSelectionAsPrimaryAction = true
    }
    
    // Assuming text contains lines of space-separated coordinates, e.g., "x y z\n"
    // Function to convert a line of text to SCNVector3
    func convertTextToSCNVector3(text: String) -> [SCNVector3] {
        var vectorList: [SCNVector3] = []
        
        let lines = text.components(separatedBy: .newlines)
        
        // Iterate over each line and convert it to SCNVector3
        for line in lines {
  
            var cleanLine = line.replacingOccurrences(of: "SCNVector3", with: "")
            cleanLine = cleanLine.replacingOccurrences(of: "(", with: "")
            cleanLine = cleanLine.replacingOccurrences(of: ")", with: "")
            

            let components = cleanLine.components(separatedBy: ",")
            
            // Extract x, y, and z values
            guard components.count == 3,
                  let xString = components[0].split(separator: ":").last?.trimmingCharacters(in: .whitespaces),
                  let yString = components[1].split(separator: ":").last?.trimmingCharacters(in: .whitespaces),
                  let zString = components[2].split(separator: ":").last?.trimmingCharacters(in: .whitespaces),
                  let x = Float(xString),
                  let y = Float(yString),
                  let z = Float(zString) else {

                continue
            }
            
            // Create SCNVector3 object and add it to the list
            vectorList.append(SCNVector3(x, y, z))
        }
        
        return vectorList
    }


    func extractVertices(from geometry: SCNGeometry) -> [SCNVector3]? {//returns all the vertices from
       
        guard let vertexSource = geometry.sources.first(where: { $0.semantic == .vertex }) else {return nil}


        let stride = vertexSource.dataStride // in bytes
        let offset = vertexSource.dataOffset // in bytes
        let componentsPerVector = vertexSource.componentsPerVector
        let bytesPerComponent = vertexSource.bytesPerComponent
        let bytesPerVector = componentsPerVector * bytesPerComponent
        let vectorCount = vertexSource.vectorCount

        var vertices = [SCNVector3]()

        // For each vector, read the bytes
        for i in 0..<vectorCount {
            // Assuming that bytes per component is 4 (a float)
            // If it was 8 then it would be a double (aka CGFloat)
            var vectorData = [Float](repeating: 0, count: componentsPerVector)

            let byteRange = i * stride + offset ..< i * stride + offset + bytesPerVector
            
            vertexSource.data.withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) in
                let typedBufferPointer = rawBufferPointer.bindMemory(to: Float.self)

                // Access the base address of the typed buffer pointer
                if let baseAddress = typedBufferPointer.baseAddress {
                    
                    let destinationPointer = UnsafeMutablePointer<Float>.allocate(capacity: bytesPerVector / MemoryLayout<Float>.stride)
              
                    let destinationRawPointer = UnsafeMutableRawPointer(destinationPointer)
                    
     
                    let destinationBufferPointer = UnsafeMutableRawBufferPointer(start: destinationRawPointer, count: bytesPerVector)
                    
 
                    rawBufferPointer.copyBytes(to: destinationBufferPointer, from: byteRange)
                    
                    vectorData = Array(UnsafeBufferPointer(start: destinationPointer, count: bytesPerVector / MemoryLayout<Float>.stride))
                    
    
                    destinationPointer.deallocate()
                }
            }

            let x = vectorData[0]
            let y = vectorData[1]
            let z = vectorData[2]

            // Append the vertex to the array
            vertices.append(SCNVector3(x, y, z))

       
        }

        return vertices
    }
    
    func showVertices(of geometry: SCNGeometry, parentNode: SCNNode) {
        guard let Vertices = extractVertices(from: geometry) else {
            print("Failed to extract vertices.")
            return
        }
        vertices = Vertices
        
        

        // Create a sphere to represent each vertex
        let sphereGeometry = SCNSphere(radius: 0.001)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red // Color of the vertices
        sphereGeometry.materials = [material]


        for vertex in Vertices {
            let vertexNode = SCNNode(geometry: sphereGeometry)

            vertexNode.position = SCNVector3Make(
                vertex.x + (parentNode.childNode(withName: "Mesh", recursively: true)?.position.x ?? 0),
                vertex.y + (parentNode.childNode(withName: "Mesh", recursively: true)?.position.y ?? 0),
                vertex.z + (parentNode.childNode(withName: "Mesh", recursively: true)?.position.z ?? 0)
            )

 
            parentNode.addChildNode(vertexNode)
        }
    }
    
    func showVertices1(of geometry: SCNGeometry, childNode: SCNNode) {
        guard let vertices = extractVertices(from: geometry) else {
            print("Failed to extract vertices.")
            return
        }

        // Create a sphere to represent each vertex
        let sphereGeometry = SCNSphere(radius: 0.001)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red // Color of the vertices
        sphereGeometry.materials = [material]

        // Get the transformation matrix of the child node
        //let childTransform = childNode.worldTransform
        let transf = childNode.transform

      
        for vertex in vertices {
            let vertexPosition = SCNVector3ToGLKVector3(vertex)
            let childTransf = SCNMatrix4ToGLKMatrix4(transf)
            
            let transformedVertexPosition = GLKMatrix4MultiplyVector3(childTransf, vertexPosition)
           // transformedVertexPosition = GLKMatrix4MultiplyVector3(transf, transformedVertexPosition)
            let transformedVertex = SCNVector3FromGLKVector3(transformedVertexPosition)

            let vertexNode = SCNNode(geometry: sphereGeometry)
            vertexNode.position = transformedVertex
       
            childNode.addChildNode(vertexNode)
        }
    }


    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        print("")
        let touch = touches.first!
        let location = touch.location(in: sceneView)
        if touch.view == sceneView{
            self.currentView = sceneView
        }
        // Perform hit test
                let hitTestResults = sceneView.hitTest(location, options: nil)
        if recordHaptics{
            let firstPoint = HapticDataPoint(intensity: 0, time: 0.0)
            chartData?.append(firstPoint)
            firstTimestamp = touch.timestamp
            prevTimestamp = firstTimestamp
        }
                // Check if the desired node is touched
                for result in hitTestResults {
                    
                    if result.node.name == "Mesh"{
                        print("surface normal", result.localNormal)
                        // Node is touched, perform desired action
                        let position = result.localCoordinates
                    

                        prevPoint = position.y
                        previousPosition = modelLocation(xPos: position.x, yPos: position.y, zPos: position.z)
                       // if !(hapticTransient ?? true) && hapticsToggle && !palpationToggle{
                        if hapticsToggle && !palpationToggle{

                            
                        }
                        if hapticsToggle && palpationToggle{
                            let surfaceNormalVector = result.worldNormal
                            var test = sceneView.defaultCameraController.pointOfView?.worldFront ?? SCNVector3(x: 0, y: -1, z: 0)
                            test.y = -(test.y)
                            print(test)
                            guard let currentTransform = sceneView.defaultCameraController.pointOfView?.transform else { return }

                            let rotationQuaternion = SCNQuaternion.fromTwoVectors(surfaceNormalVector, test, scale: self.rotationScaleVal)
                            let newTransform = SCNMatrix4Mult(currentTransform, rotationQuaternion)

                            sceneView.defaultCameraController.pointOfView?.transform = newTransform
          

                        }
                        return
                    }
                }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
     //   print("hello check scene touch")
        if let touch = touches.first, let sceneViewScene = sceneView.scene {
            
            let location = touch.location(in: sceneView)
            let hitTestResults = sceneView.hitTest(location, options: nil)
            // Process hit test results
        
        // Check if the desired node is touched
        for result in hitTestResults {
            if result.node.name == "Mesh" {
                let position = result.localCoordinates
                var height = result.localCoordinates.y
                let tempGradient = gradientMethod()
                let firstTime = Date()
                var approxPoint : SCNVector3 = SCNVector3(0, 0, 0)
                if gradientToggle && (hapticTransient ?? true){
                    approxPoint = tempGradient.closestDistance(points: transientCloud ?? [], inputPoint: position, k: 1)[0]
                    let xChange = (position.x - (previousPosition?.xPos ?? 0.0))
                    let zChange = (position.z - (previousPosition?.zPos ?? 0.0))
                    let nextPoint = tempGradient.closestDistance(points: transientCloud ?? [], inputPoint: SCNVector3(position.x + xChange, position.y, position.z + zChange), k: 1)[0]
                    let changeInGradient = (Float(approxPoint.y - nextPoint.y) + Float(approxPoint.y - (previousPosition?.yPos ?? 0.0)))/2.0
                    
                    height = abs(changeInGradient * 10000)
                }
                else if gradientToggle && !(hapticTransient ?? true){
                    approxPoint = tempGradient.closestDistance(points: smoothedCloud ?? [], inputPoint: position, k: 1)[0]
                    height = HeightMap().scaleValue(value: approxPoint.y, maxValue: maxTransient ?? 1, minValue: minTransient ?? 0)
                 //   height = approxPoint.y
                }
                else{
                    approxPoint = position
                    height = position.y * 10
                }
                print(height)
                //print(Date().timeIntervalSince(firstTime))
                let intersectionPoint = result.worldCoordinates
                let previousLocation = touch.previousLocation(in: sceneView)
                        let currentLocation = touch.location(in: sceneView)
                        
                let deltaX = (currentLocation.x - previousLocation.x)*0.01 //cm
                //This isn't based on the change in height
                let deltaY = (currentLocation.y - previousLocation.y)*0.01
                let prevTime = prevTimestamp ?? 0.0
                let timeDelta = touch.timestamp - prevTime
              //  prevTimestamp = touch.timestamp
                let velocityX = deltaX / CGFloat(timeDelta)
                let velocityY = deltaY / CGFloat(timeDelta)
                let speed = Float(sqrt((velocityX * velocityX) + (velocityY * velocityY)))
                if scale == nil{
        //             scale = heightTemp.rounded()
                }
                //let intensity = hapticAlgorithm.forceFeedback(height: height, velocity: speed)
                let intensity = (((height - (prevPoint ?? 0))*1000)+5)/10

                /*if recordHaptics{
                 //   let dataPoint = HapticDataPoint(intensity: height, time: Float(touch.timestamp - (firstTimestamp ?? touch.timestamp)))
                    let dataPoint = HapticDataPoint(intensity: intensity, time:Float(touch.timestamp - (firstTimestamp ?? touch.timestamp)))
                    chartData?.append(dataPoint)
                }*/
                
                prevPoint = height
                if !rotationOn && hapticsToggle{
                    if !palpationToggle{
                       // if !(hapticTransient ?? true){
                            let tempGradient = gradientMethod()
               //            let approxPoint = tempGradient.closestDistance(points: smoothedCloud ?? [], inputPoint: position, k: 1)[0]
                            //gets scaled height value between 1 and 0
                        var scaledValue = Float(0)  // HeightMap().scaleValue(value: approxPoint.y, maxValue: maxContinuous ?? 1, minValue: minContinuous ?? 0)
                        print("filter name", self.filter)
                        
                      
                        let gridSize = enhancedMap?.endIndex
                        print("grid size", gridSize)
                        let gridPoint = mapPointToHeightMap(hitResult: result, gridSize: 80)//
                        var sharpparameter : Float =  1
                        var value : Float = 0
                        if let map = self.enhancedMap {
                            let (gridX, gridY) = gridPoint
                            if gridY >= 0 && gridY < map.count && gridX >= 0 && gridX < map[gridY].count {
                                value = map[gridY][gridX]
                                print(value)
                                if value.isNaN{
                                    height = 0
                                }
                                else{
                                    let scaledValue = HeightMap().scaleValue(value: value, maxValue: self.maxHeight ?? 1, minValue: self.minHeight ?? 0)
                                    height = scaledValue
                                }
                                
                                print("Height Map Height")
                                print(height)
                                if height.isNaN{
                                    height = 0
                                }
                                height = height * self.intensityScale
                                print(height)
                                print("intensity", self.intensityScale)
                                print(maxHeight)
                                print(minHeight)
                                } else {
                                    // Handle the case where the point is outside the bounds of the height map
                                    print("invalid access")// Returning NaN or another sentinel value to indicate an invalid access
                                }
                            if sharpnessParam{
                                sharpparameter = value
                                
                            }
                            
                        }
                        
                        

                        
                        
                        
                            let intensityParameter = CHHapticDynamicParameter(parameterID: .hapticIntensityControl,
                                                                              value: (scaledValue/(currentIntensity ?? 1)),
                                                                              relativeTime: 0)
                              let sharpnessParameter = CHHapticDynamicParameter(parameterID: .hapticSharpnessControl,
                                   value: (scaledValue - (currentSharpness ?? 0)),
                                    relativeTime: 0)
                        currentIntensity = 0.1
                        currentSharpness = scaledValue
                            // Send dynamic parameters to the haptic player.
                            do {
                              //  try tempHaptics?.continuousPlayer?.sendParameters([intensityParameter, sharpnessParameter],
                               //                                                  atTime: 0)
                            //    try tempHaptics?.continuousPlayer?.sendParameters([intensityParameter],
                             //                                                    atTime: 0)
                                
                                
                            } catch let error {
                                print("Dynamic Parameter Error: \(error)")
                            }
                            let timeChange = touch.timestamp - ((prevTimestamp ?? firstTimestamp) ?? 0)
                            //      let intensityChange = intensity1/Float(timeChange)
                            //try tempHaptics?.playHeightHaptic(height:intensity*10)
                        
                        
                            try tempHaptics?.playHeightHaptic(height:height, sharpness: sharpparameter)
                        
                        
                            //edge detection effect
                        //    print(approxPoint.y * 100)
                            prevTimestamp = touch.timestamp
                            //print(intensity1*100)
                    //    }
                    }
                    else if (hapticsToggle && palpationToggle){
                       let surfaceNormalVector = result.worldNormal
                        var test = sceneView.defaultCameraController.pointOfView?.worldFront ?? SCNVector3(x: 0, y: -1, z: 0)
                        test.y = -(test.y)
                        print(test)
                        guard var currentTransform = sceneView.defaultCameraController.pointOfView?.transform else { return }
                        
                        let rotationQuaternion = SCNQuaternion.fromTwoVectors(surfaceNormalVector,test, scale: self.rotationScaleVal)
                        let newTransform = SCNMatrix4Mult(currentTransform, rotationQuaternion)
                        sceneView.defaultCameraController.pointOfView?.transform = newTransform
                    }
                                if recordHaptics{
                                 //   let dataPoint = HapticDataPoint(intensity: height, time: Float(touch.timestamp - (firstTimestamp ?? touch.timestamp)))
                                    print("recordHeight", height)
                                   // let dataPoint = HapticDataPoint(intensity: height, time:Float(touch.timestamp - (firstTimestamp ?? touch.timestamp)))
                                    let dataPoint = HapticDataPoint(intensity: height, time:Float(touch.timestamp - (firstTimestamp ?? touch.timestamp)))
                                    chartData?.append(dataPoint)
                                }
                        } else {
                            // Handle the case when previousPosition is nil
                        }
                        
                    }
                }
       
                return
        } else {
            print("No touch or sceneView is nil")
            do{
                try tempHaptics?.continuousPlayer?.stop(atTime: CHHapticTimeImmediate)
            }catch{
                return
            }
        }
        
    }
    
    // Function to compute value of the function at a vertex based on the y value of the nearest neighboring vertex
    func functionValue(at vertex: SCNVector3, vertices: [SCNVector3]) -> Float {
        // Find the vertex with the closest x and z values to the current vertex
        var nearestVertex: SCNVector3?
    //    print(vertices)
     //   print(vertex)
    //    print("CIANA")
        var minDistanceSquared: Float = .greatestFiniteMagnitude
       // print("mindistance ", minDistanceSquared)
        for neighborVertex in vertices {
            let dx = vertex.x - neighborVertex.x
            let dz = vertex.z - neighborVertex.z
            let distanceSquared = dx * dx + dz * dz
            
            // Check if the current neighborVertex is closer than the previously found nearestVertex
            if distanceSquared < minDistanceSquared {
                if !((neighborVertex.x == vertex.x) && (neighborVertex.z == vertex.z)){
         //          print("disSqure", distanceSquared)
                    minDistanceSquared = distanceSquared
                    nearestVertex = neighborVertex
           //         print("IS THIS WORKING")
                }
            }
        }
        
        
        // Return the y value of the nearest vertex if found
        return nearestVertex?.y ?? 0
    }

    
    // Function to compute gradient at a vertex using central finite differences
    func computeGradient(at vertex: SCNVector3, in vertices: [SCNVector3]) -> Float{
        // Define a small step size for differentiation
        let h: Float = 0.002
        
        //Compute the change in height value
        let stepPoint = SCNVector3(x: vertex.x + h, y: vertex.y + h, z: vertex.z + h)
        let secondStepPoint = SCNVector3(x: vertex.x - h, y: vertex.y - h, z: vertex.z - h)
       // print("CIAA2")
       // print(functionValue(at: stepPoint, vertices: vertices))
       // print(functionValue(at: secondStepPoint, vertices: vertices))
        let gradient = (functionValue(at: stepPoint, vertices: vertices) - functionValue(at: secondStepPoint, vertices: vertices))/(2*h)
            // print(gradient)
        return gradient
    }
    // Define your point cloud region extraction function
    func extractPointCloudRegionAndGradients(from geometry: SCNGeometry, at position: SCNVector3, radius: Float) -> [(vertex: SCNVector3, gradient: Float)]{
        // Extract vertices from the geometry
        let allVertices = try? extractVertices(from: geometry)
        
        // Filter vertices within the specified radius of the position
        let verticesWithinRadius = allVertices?.filter { vertex in
            let xSquared = (vertex.x - position.x) * (vertex.x - position.x)
            let ySquared = (vertex.y - position.y) * (vertex.y - position.y)
            let zSquared = (vertex.z - position.z) * (vertex.z - position.z)
            let distanceSquared = xSquared + ySquared + zSquared
            return distanceSquared <= radius * radius
        }
        
        // Compute gradients for each vertex within the region
        let gradients = verticesWithinRadius?.compactMap { vertex -> (vertex: SCNVector3, gradient: Float)? in
            guard let allVertices = allVertices else { return nil }
            let gradient = computeGradient(at: vertex, in: allVertices ?? [])
            return (vertex: vertex, gradient: gradient) as! (vertex: SCNVector3, gradient: Float)
        }

        
        return gradients!
    }
    
    func getStationaryPoints(gradients: [(vertex: SCNVector3, gradient: Float)]){
        for point in gradients {
            if point.gradient == 0 {
                print(point.vertex)
                print("STATIONARY POINT")
            }
        }
    }
    
    // Function to compute Hessian at a vertex using central finite differences
    func computeHessian(at vertex: SCNVector3, in vertices: [SCNVector3]) -> Float {
        // Define a small step size for differentiation
        let h: Float = 0.001
        
        // Compute the change in gradient
        let stepPoint = SCNVector3(x: vertex.x + h, y: vertex.y, z: vertex.z)
        let secondStepPoint = SCNVector3(x: vertex.x - h, y: vertex.y, z: vertex.z)
        let gradientX = (computeGradient(at: stepPoint, in: vertices) - computeGradient(at: secondStepPoint, in: vertices)) / (2 * h)
        
        let stepPointY = SCNVector3(x: vertex.x, y: vertex.y + h, z: vertex.z)
        let secondStepPointY = SCNVector3(x: vertex.x, y: vertex.y - h, z: vertex.z)
        let gradientY = (computeGradient(at: stepPointY, in: vertices) - computeGradient(at: secondStepPointY, in: vertices)) / (2 * h)
        
        let stepPointZ = SCNVector3(x: vertex.x, y: vertex.y, z: vertex.z + h)
        let secondStepPointZ = SCNVector3(x: vertex.x, y: vertex.y, z: vertex.z - h)
        let gradientZ = (computeGradient(at: stepPointZ, in: vertices) - computeGradient(at: secondStepPointZ, in: vertices)) / (2 * h)
        
        // Compute the change in gradients to get the Hessian (second derivative)
        let hessian = (gradientX + gradientY + gradientZ) / 3.0 // You may adjust this based on your specific function
        
        return hessian
    }




    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        previousPosition = nil
     //   if(!(hapticTransient ?? true)){
            
            do {
                try tempHaptics?.continuousPlayer?.stop(atTime: CHHapticTimeImmediate)
            } catch /*let error {
                     print("Error stopping the continuous haptic player: \(error)")
                     }*/
            {return}
     //   }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        previousPosition = nil
        do {
            try tempHaptics?.continuousPlayer?.stop(atTime: CHHapticTimeImmediate)
        } catch let error {
            print("Error stopping the continuous haptic player: \(error)")
        }
    }
    @IBAction func buttonPressed(_ sender: Any) {
        if !rotationOn{
            rotationOn = true
            sceneView.allowsCameraControl = true
           // sceneView.cameraControlConfiguration.allowsTranslation = false
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
        hapticsButton.isHidden = true
        treatmentButton.isHidden = true
        symptonsButton.isHidden = true
        urgencylabel.isHidden = true
        similarButton.isHidden = true
        recordHaptic.isHidden = true
        settingsButton.isHidden = true
        saveButton.isHidden = true
   //     smoothButton.isHidden = true
        palpationOption.isHidden = true
        hapticMethod.isHidden = true
        uiLine1.isHidden = true
        uiLine2.isHidden = true

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
        hapticsButton.isHidden = false
        sceneView.debugOptions = [.showCreases]
        
        notesButton.isHidden = false
        symptonsButton.isHidden = false
        treatmentButton.isHidden = false
        urgencylabel.isHidden = false
        similarButton.isHidden = false
        recordHaptic.isHidden = false
        settingsButton.isHidden = false
  //      smoothButton.isHidden = false
        palpationOption.isHidden = false
  //      hapticMethod.isHidden = false
        hideAxes()
        saveButton.isHidden = false
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
    
    ///Rotates model so that surface normal being touched corresponds with camera view?
    func rotatePalpation1(result: SCNHitTestResult){
        let surfaceNormalVector = result.worldNormal
        var test = sceneView.defaultCameraController.pointOfView?.worldFront ?? SCNVector3(x: 0, y: -1, z: 0)
        test.y = -(test.y)
        print(test)
        guard let currentTransform = sceneView.defaultCameraController.pointOfView?.transform else { return }

        let rotationQuaternion = SCNQuaternion.fromTwoVectors(surfaceNormalVector, test, scale: self.rotationScaleVal)
        let identityMatrix = SCNMatrix4Identity
        let blendFactor: Float = 0.1  // Adjust this to make the rotation more or less pronounced
        let interpolatedMatrix = interpolateMatrices(identityMatrix, rotationQuaternion, blendFactor: blendFactor)
        let newTransform = SCNMatrix4Mult(currentTransform, interpolatedMatrix)
        sceneView.defaultCameraController.pointOfView?.transform = newTransform

    }
    func rotatePalpation(result: SCNHitTestResult){
        let surfaceNormalVector = result.worldNormal
        var cameraFront = sceneView.defaultCameraController.pointOfView?.worldFront ?? SCNVector3(x: 0, y: -1, z: 0)
        cameraFront.y = -cameraFront.y // Inverting y if needed based on your coordinate system
        
        guard let currentTransform = sceneView.defaultCameraController.pointOfView?.transform else { return }
        
        let rotationQuaternion = SCNQuaternion.fromTwoVectors(cameraFront, surfaceNormalVector, scale: self.rotationScaleVal)
        let identityMatrix = SCNMatrix4Identity
        let blendFactor: Float = 0.1  // Adjust this to make the rotation more or less pronounced
        let interpolatedMatrix = interpolateTransforms(from: identityMatrix, to: rotationQuaternion, fraction: CGFloat(blendFactor))
        let newTransform = SCNMatrix4Mult(currentTransform, interpolatedMatrix)
        sceneView.defaultCameraController.pointOfView?.transform = newTransform
    }
    // Slerp between two quaternions
    func slerp(from q1: SCNQuaternion, to q2: SCNQuaternion, fraction: CGFloat) -> SCNQuaternion {
        let control1 = GLKQuaternionMake(q1.x, q1.y, q1.z, q1.w)
        let control2 = GLKQuaternionMake(q2.x, q2.y, q2.z, q2.w)
        let result = GLKQuaternionSlerp(control1, control2, Float(fraction))
        return SCNQuaternion(x: result.x, y: result.y, z: result.z, w: result.w)
    }

    // Linear interpolation between two vectors
    func lerp(from v1: SCNVector3, to v2: SCNVector3, fraction: CGFloat) -> SCNVector3 {
        return SCNVector3(
            x: v1.x + (v2.x - v1.x) * Float(fraction),
            y: v1.y + (v2.y - v1.y) * Float(fraction),
            z: v1.z + (v2.z - v1.z) * Float(fraction)
        )
    }

    // Function to interpolate between two transformation matrices using quaternion for rotation and linear interpolation for translation
    func interpolateTransforms(from m1: SCNMatrix4, to m2: SCNMatrix4, fraction: CGFloat) -> SCNMatrix4 {
        let translation1 = SCNVector3(m1.m41, m1.m42, m1.m43)
        let translation2 = SCNVector3(m2.m41, m2.m42, m2.m43)
        let interpolatedTranslation = lerp(from: translation1, to: translation2, fraction: fraction)

        let rotation1 = quaternionFromMatrix(matrix: m1)
        let rotation2 = quaternionFromMatrix(matrix: m2)
        let interpolatedRotation = slerp(from: rotation1, to: rotation2, fraction: fraction)

        var resultMatrix = SCNMatrix4MakeRotation(interpolatedRotation.w, interpolatedRotation.x, interpolatedRotation.y, interpolatedRotation.z)
        resultMatrix.m41 = interpolatedTranslation.x
        resultMatrix.m42 = interpolatedTranslation.y
        resultMatrix.m43 = interpolatedTranslation.z

        return resultMatrix
    }

    // Extract quaternion from SCNMatrix4
    func quaternionFromMatrix(matrix: SCNMatrix4) -> SCNQuaternion {
        let rotation = SCNMatrix4ToGLKMatrix4(matrix)
        let quaternion = GLKQuaternionMakeWithMatrix4(rotation)
        return SCNQuaternion(x: quaternion.x, y: quaternion.y, z: quaternion.z, w: quaternion.w)
    }

    
    func interpolateMatrices1(_ matrix1: SCNMatrix4, _ matrix2: SCNMatrix4, blendFactor: Float) -> SCNMatrix4 {
        let interpolate = { (a: Float, b: Float) -> Float in
            a * (1 - blendFactor) + b * blendFactor
        }

        return SCNMatrix4(
            m11: interpolate(matrix1.m11, matrix2.m11),
            m12: interpolate(matrix1.m12, matrix2.m12),
            m13: interpolate(matrix1.m13, matrix2.m13),
            m14: interpolate(matrix1.m14, matrix2.m14),
            m21: interpolate(matrix1.m21, matrix2.m21),
            m22: interpolate(matrix1.m22, matrix2.m22),
            m23: interpolate(matrix1.m23, matrix2.m23),
            m24: interpolate(matrix1.m24, matrix2.m24),
            m31: interpolate(matrix1.m31, matrix2.m31),
            m32: interpolate(matrix1.m32, matrix2.m32),
            m33: interpolate(matrix1.m33, matrix2.m33),
            m34: interpolate(matrix1.m34, matrix2.m34),
            m41: interpolate(matrix1.m41, matrix2.m41),
            m42: interpolate(matrix1.m42, matrix2.m42),
            m43: interpolate(matrix1.m43, matrix2.m43),
            m44: interpolate(matrix1.m44, matrix2.m44)
        )
    }
    
    func interpolateMatrices(_ matrix1: SCNMatrix4, _ matrix2: SCNMatrix4, blendFactor: Float) -> SCNMatrix4 {
        let interpolate = { (a: Float, b: Float) -> Float in
            a * (1 - blendFactor) + b * blendFactor
        }
        return SCNMatrix4(
            m11: interpolate(matrix1.m11, matrix2.m11),
            m12: interpolate(matrix1.m12, matrix2.m12),
            m13: interpolate(matrix1.m13, matrix2.m13),
            m14: 0,
            m21: interpolate(matrix1.m21, matrix2.m21),
            m22: interpolate(matrix1.m22, matrix2.m22),
            m23: interpolate(matrix1.m23, matrix2.m23),
            m24: 0,
            m31: interpolate(matrix1.m31, matrix2.m31),
            m32: interpolate(matrix1.m32, matrix2.m32),
            m33: interpolate(matrix1.m33, matrix2.m33),
            m34: 0,
            m41: 0,
            m42: 0,
            m43: 0,
            m44: 1
        )
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
                
                
                print(chartData)
                
            }
            chartData = []//DATA DELETED
        }
    }
    
    @objc func closeViewAction(){
        swiftuiView?.removeFromSuperview()
        closeView?.removeFromSuperview()
        
    }
    
    func set(model : SkinCondition){
        self.condition = model
        self.modelFile = model.modelFile
        self.modelName = model.modelName
        self.rotationScaleVal = model.rotationScale
     //   scene = SCNScene(named: model.modelFile)//do i need to deallocate the current scene?

    
    }
    
    @IBAction func hapticMethodChanged(_ sender: Any) {
        if hapticMethod.selectedSegmentIndex == 0{//transient
            hapticTransient = true
        }
        else{
            hapticTransient = false
        }
    }
    
    @IBAction func hapticsPressed(_ sender: Any) {
        if !hapticsToggle{
            hapticsToggle = true
            hapticsButton.tintColor = .systemPink
            print(palpationToggle)
            if let originalPosition = originalCameraPosition {
                sceneView.defaultCameraController.pointOfView?.position = originalPosition
                if !palpationToggle{
                    sceneView.defaultCameraController.pointOfView?.camera?.fieldOfView = 120
                }else{
                    sceneView.defaultCameraController.pointOfView?.camera?.fieldOfView = 45
                }
    
            } else {
                // Handle the case where originalCameraPosition is nil
                // Maybe log an error, provide a default position, or take other appropriate action
                print("Error: originalCameraPosition is nil")
            }
            if let originalCamOrientation = originalCameraOrientation {
                sceneView.defaultCameraController.pointOfView?.orientation = originalCamOrientation
            } else {
                // Handle the case where originalCameraPosition is nil
                // Maybe log an error, provide a default position, or take other appropriate action
                print("Error: originalCameraOrientation is nil")
            }
            sceneView.allowsCameraControl = false
            rotationOn = false
            RotateToggle.isEnabled = false
            
            
          //  sceneView.defaultCameraController.pointOfView?.eulerAngles = SCNVector3(0.5, 0, 0)

        }
        else{
            hapticsToggle = false
            hapticsButton.tintColor = .blue
            sceneView.allowsCameraControl = true
            RotateToggle.isEnabled = true
            sceneView.defaultCameraController.pointOfView?.camera?.fieldOfView = 45
        }
    }
    
    
    @IBAction func touchNotes(_ sender: Any) {
        guard let popUp = storyboard?.instantiateViewController(withIdentifier: "NotesView") as? NotesView else {
            return
        }
        if let skinCondition = self.condition {
            popUp.set(condition: skinCondition, type: "Notes", user: sourceType ?? .consultant)
            
            //navigationController?.pushViewController(popUp, animated: true)
            navigationController?.present(popUp, animated: true, completion: nil)
        }

    }
    
    @IBAction func touchSymptoms(_ sender: Any) {
        guard let popUp = storyboard?.instantiateViewController(withIdentifier: "NotesView") as? NotesView else {
            return
        }
        if let skinCondition = condition {
            popUp.set(condition: skinCondition, type: "Symptoms", user: sourceType ?? .consultant)
            
            //navigationController?.pushViewController(popUp, animated: true)
            navigationController?.present(popUp, animated: true, completion: nil)
        }
    }
    
    @IBAction func touchTreatment(_ sender: Any) {
        guard let popUp = storyboard?.instantiateViewController(withIdentifier: "NotesView") as? NotesView else {
            return
        }
        if let skinCondition = condition {
            popUp.set(condition: skinCondition, type: "Treatment", user: sourceType ?? .consultant)
            
            //navigationController?.pushViewController(popUp, animated: true)
            navigationController?.present(popUp, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func palpateToggle(_ sender: Any) {
        if palpationOption.selectedSegmentIndex == 0{
            //texture method
            palpationToggle = false
            if hapticsToggle{
                sceneView.defaultCameraController.pointOfView?.camera?.fieldOfView = 120
            }
        }
        else{
            //visual method
            print("hello visual")
            palpationToggle = true
            if hapticsToggle{
                sceneView.defaultCameraController.pointOfView?.camera?.fieldOfView = 45
            }
        }
    }
    @IBAction func touchSimilarConditions(_ sender: Any) {
        guard let popUp = storyboard?.instantiateViewController(withIdentifier: "LinkConditions") as? LinkConditions else {
            return
        }
        if let skinCondition = condition {
            popUp.set(linkedModels: self.condition?.similarConditions ?? [])
            
            //navigationController?.pushViewController(popUp, animated: true)
            navigationController?.present(popUp, animated: true, completion: nil)
        }
    }
    
    @IBAction func settingsTouched(_ sender: Any) {
        hapticsSettings.isHidden = false
    }
    
    func rotateCameraToward(normal: SCNVector3) {
        // Current camera orientation
        guard let currentOrientation = sceneView.defaultCameraController.pointOfView?.orientation else { return  }

        let targetOrientation = SCNQuaternion(x: -normal.x, y: -normal.y, z: -normal.z, w: 1)

        // Interpolate between the current orientation and the target orientation
        let slerpQuat = slerp(from: currentOrientation, to: targetOrientation, fraction: 0.1) // Adjust fraction for smoother or faster rotation

        sceneView.defaultCameraController.pointOfView?.orientation = slerpQuat
        
        let lookAtDirection = SCNVector3(-normal.x, -normal.y, -normal.z)
            
            // Assume the world 'up' direction is y-axis
            let upDirection = SCNVector3(0, 1, 0)
            
            // Calculate the necessary rotation to point the camera in the direction of -normal
        sceneView.defaultCameraController.pointOfView?.look(at: SCNVector3(
            (sceneView.defaultCameraController.pointOfView?.position.x ?? 0) + lookAtDirection.x,
            (sceneView.defaultCameraController.pointOfView?.position.y ?? 0) + lookAtDirection.y,
            (sceneView.defaultCameraController.pointOfView?.position.z ?? 0) + lookAtDirection.z),
                up: upDirection, localFront: cameraNode.worldFront)
    }
    func normalize(quaternion: SCNQuaternion) -> SCNQuaternion {
        let norm = sqrt(quaternion.x * quaternion.x + quaternion.y * quaternion.y + quaternion.z * quaternion.z + quaternion.w * quaternion.w)
        guard norm != 0 else {
            return quaternion
        }
        return SCNQuaternion(
            x: quaternion.x / norm,
            y: quaternion.y / norm,
            z: quaternion.z / norm,
            w: quaternion.w / norm
        )
    }

    func slerp1(from: SCNQuaternion, to: SCNQuaternion, fraction: CGFloat) -> SCNQuaternion {

        let lerp = SCNQuaternion(x: from.x + (to.x - from.x) * Float(fraction),
                                 y: from.y + (to.y - from.y) * Float(fraction),
                                 z: from.z + (to.z - from.z) * Float(fraction),
                                 w: from.w + (to.w - from.w) * Float(fraction))
        
        return normalize(quaternion: lerp)
    }

    @IBAction func cancelledSettings(_ sender: Any) {
        hapticsSettings.isHidden = true
    }
    @IBAction func changedSettings(_ sender: Any) {
        hapticsSettings.isHidden = true
        rotationScaleVal = Int(rotationScale.value)
        if gradientHeightMap.selectedSegmentIndex == 0{
            self.gradientEffect = true
        }else{
            self.gradientEffect = false
        }
        self.intensityScale = intensitySkirt.value
        if sharpnessToggle.selectedSegmentIndex == 0{
            self.sharpnessParam = true
        }else{
            self.sharpnessParam = false
        }
        switch filterSetting.currentTitle{
        case "None":
            self.filter = .none
            let tempGradient = gradientMethod()
            if self.gradientEffect{
                let convertGradient = tempGradient.convertHeightMapToGradient(heightMap: originalHeightMap ?? [[]])
                enhancedMap = convertGradient.0
               
            }
            else{
                enhancedMap = originalHeightMap ?? [[]]
            }
        case "Gaussian":
            self.filter = .gaussian
            
            if Int(kSetting.value) % 2 == 0{
                self.kVal = Int(kSetting.value) + 1
            }else{
                self.kVal = Int(kSetting.value)
            }
            self.sigmaVal = sigmaSetting.value
          /*  guard let maxPoint = self.maxPoint, let allVertices = self.modelVertices, let minPoint = self.minPoint else {
                return
            }*/
            let tempGradient = gradientMethod()
         /*   self.filterMax = tempGradient.applyGaussianFilter(to: maxPoint, sigma: sigmaVal, vertices: allVertices, kernelSize: kVal)
            
            self.filterMin = tempGradient.applyGaussianFilter(to: minPoint, sigma: sigmaVal, vertices: allVertices, kernelSize: kVal)*/
            let tempHeightMap = tempGradient.applyGaussianToHeightMap(heightMap: originalHeightMap ?? [[]], k: self.kVal, sigma: self.sigmaVal)
            if self.gradientEffect{
                let gradientGaussian = tempGradient.convertHeightMapToGradient(heightMap: tempHeightMap)
                enhancedMap = gradientGaussian.0
            }else{
                enhancedMap = tempHeightMap
            }
            
        case "Second Derivative":
 
            let tempGradient = gradientMethod()
            let tempHeightMap = tempGradient.convertHeightMapToGradient(heightMap: originalHeightMap ?? [[]])
            let secondTemp = tempGradient.convertHeightMapToGradient(heightMap: tempHeightMap.0)
            enhancedMap = secondTemp.0
            
            
        case "Sobel Operator":
            self.filter = .edge
            self.kVal = Int(kSetting.value)
            self.sigmaVal = sigmaSetting.value
         /*   guard let maxPoint = self.maxPoint, let allVertices = self.modelVertices, let minPoint = self.minPoint else {
                return
            }*/
            let tempGradient = gradientMethod()
       /*     self.filterMax = tempGradient.applyMexicanHatFilter(to: maxPoint, sigma: sigmaVal, vertices: allVertices, kernelSize: kVal)
            self.filterMin = tempGradient.applyMexicanHatFilter(to: minPoint, sigma: sigmaVal, vertices: allVertices, kernelSize: kVal)*/
            let tempHeightMap = tempGradient.applySobelOperator(to: originalHeightMap ?? [[]])
            if self.gradientEffect{
                let gradientGaussian = tempGradient.convertHeightMapToGradient(heightMap: tempHeightMap)
                enhancedMap = gradientGaussian.0
            }else{
                enhancedMap = tempHeightMap
            }
        case "Peak Detector":
            self.filter = .heightMap
            let tempGradient = gradientMethod()
            let map = tempGradient.detectPeaks(heightMap: originalHeightMap ?? [[]])
            enhancedMap = map
        case "Default":
           // self.filter = .heightMap
            enhancedMap = self.originalHeightMap
            
        default:
            break
        }
        self.maxHeight = findMaxElement(in: enhancedMap ?? [[]])
        self.minHeight = findMinElement(in: enhancedMap ?? [[]])
        print("map changed")
  //      print(enhancedMap)
        print(self.minHeight)
        print(self.maxHeight)
    }
    func mapPointToHeightMap1(hitResult: SCNHitTestResult, gridSize: Int) -> (Int, Int) {
        let localPoint = hitResult.localCoordinates
        let (minBounds, maxBounds) = hitResult.node.boundingBox
        
        // Normalize the x and y coordinates
        let normalizedX = (localPoint.x - minBounds.x) / (maxBounds.x - minBounds.x)
        let normalizedY = (localPoint.y - minBounds.y) / (maxBounds.y - minBounds.y)
        
        // Map to grid
        let gridX = Int(normalizedX * Float(gridSize - 1))
        let gridY = Int(normalizedY * Float(gridSize - 1))
        
        return (gridX, gridY)
    }
    func mapPointToHeightMap(hitResult: SCNHitTestResult, gridSize: Int) -> (Int, Int) {
        let localPoint = hitResult.localCoordinates
        let (minBounds, maxBounds) = hitResult.node.boundingBox

        // Normalize the x and z coordinates
        let normalizedX = (localPoint.x - minBounds.x) / (maxBounds.x - minBounds.x)
        let normalizedZ = (localPoint.z - minBounds.z) / (maxBounds.z - minBounds.z)

        // Map to grid
        let gridX = Int(normalizedX * Float(gridSize - 1))
        let gridY = Int(normalizedZ * Float(gridSize - 1))

        // ensure they are within the grid bounds
        let clampedGridX = max(0, min(gridX, gridSize - 1))
        let clampedGridY = max(0, min(gridY, gridSize - 1))

        return (clampedGridX, clampedGridY)
    }
    
    private func configureBasedOnSource() {
        print(sourceType)
            switch sourceType {
            case .consultant:
                // Configuration for when coming from User Login
                settingsButton.isHidden = false
                SelectPivot.isHidden = false
                recordHaptic.isHidden = false
                saveButton.isHidden = false
                hapticMethod.isHidden = true
                print("Came from Consultant Login")
            case .student:
                // Configuration for when coming from Student Login
               // settingsButton.isHidden = true
                SelectPivot.isHidden = true
                recordHaptic.isHidden = true
                saveButton.isHidden = true
                hapticMethod.isHidden = true
                recordHaptic.isHidden = true
                SelectPivot.isHidden = true
                print("Came from Student Login")
            case .none:
                break
            }
        }
    
    func getModel(){
        var fileUrl : String = ""
        if self.condition?.isCreated == true{
            guard let fileName = self.condition?.name else {
                return //print error message
            }
            fileUrl = "models/" + fileName + ".usdz"
        }else{
            guard let fileName = self.condition?.name else {
                return //print error message
            }
            fileUrl = "processingModels/" + fileName + ".usdz"
        }
        let database = DatabaseManagement()
        let sceneURL = database.localFileURL(for: "scene.usdz", directory: .documentDirectory)
        DispatchQueue.global(qos: .background).async{
            database.downloadFile(from: fileUrl, to: sceneURL) { success in
                DispatchQueue.main.async {
                    if success {
                        print("File was successfully downloaded to \(sceneURL)")
                        if let loadedScene = self.loadScene(from: sceneURL) {
                            // Directly use the loaded scene
                            let root = loadedScene.rootNode
                            print("Checking rootnode:", root)
                            
                            // Create and add ambient light to the scene
                            let ambientLight = SCNLight()
                            ambientLight.type = .ambient
                            ambientLight.color = UIColor.white // Adjust the light color as needed
                            let ambientLightNode = SCNNode()
                            ambientLightNode.light = ambientLight
                            root.addChildNode(ambientLightNode) // Adding light to the loaded scene's root
                            
                            // Set the loaded scene to the scene view
                            self.sceneView.scene = loadedScene
                            self.sceneView.allowsCameraControl = true
                            print("ALEERA CHECK HERE")
                            print(self.sceneView.scene)
                            self.view.addSubview(self.sceneView)
                        }
                    } else {
                        print("Failed to download the file.")
                        print("ERROR: HANDLE THIS")
                    }
                }
            }
       }
    }
    
    
    
    private func loadModel() {
        showLoadingIndicator(true)
        var fileUrl : String = ""
        if self.condition?.isCreated == true{
            guard let fileName = self.condition?.name else {
                return //print error message
            }
            fileUrl = "models/" + fileName + ".usdz"
        }else{
            guard let fileName = self.condition?.name else {
                return //print error message
            }
            fileUrl = "processingModels/" + fileName + ".usdz"
        }
        let database = DatabaseManagement()
        let sceneURL = database.localFileURL(for: "scene.usdz", directory: .documentDirectory)
        
        database.downloadFile(from: fileUrl, to: sceneURL) { success in
            DispatchQueue.main.async {
                self.showLoadingIndicator(false)
                if success {
                    print("File was successfully downloaded to \(sceneURL)")
                    self.scene = self.loadScene(from: sceneURL)
                    guard let baseNode = self.scene?.rootNode.childNode(withName: "Mesh", recursively: true) else {
                             fatalError("Unable to find baseNode")
                            }
                    self.sceneView.scene = self.scene
                    self.sceneView.scene?.rootNode.addChildNode(baseNode)
                    print("check node is there")
                    print(self.sceneView.scene?.rootNode)
                    self.setupSceneView()
                    print((self.condition?.heightMap.isEmpty) != nil)
                    print(self.condition?.heightMap)
                    if ((self.condition?.heightMap.isEmpty) != nil){//if there is not a height map ( = [[]])
                        self.hapticsButton.isEnabled = false
                        print("hi")
                        DispatchQueue.global(qos: .background).async{
                            
                                let gradient = gradientMethod()
                                guard let node = self.scene?.rootNode.childNode(withName: "Mesh", recursively: true) else {
                                    self.showError("Failed to get model geometry")
                                    return
                                    //print error message
                                }
                                let transformedVertices = gradient.getTransformedVertices(node: node)
                            
                                var heightMap = gradient.createHeightMap4(from: transformedVertices, resolutionX: 80, resolutionZ: 80)//dynamically change ratio
                            // Determine bounds for normalization
                            let (minX, maxX, minZ, maxZ) =  transformedVertices.reduce((Float.infinity, -Float.infinity, Float.infinity, -Float.infinity)) { (bounds, vertex) in
                                (min(bounds.0, vertex.x), max(bounds.1, vertex.x), min(bounds.2, vertex.z), max(bounds.3, vertex.z))
                            }
                           // print(heightMap)
                            print("original vertices", transformedVertices)
                            var convertedBack = gradient.convertHeightMapToVertices(heightMap: heightMap, resolutionX: 80, resolutionZ: 80, minX: minX, maxX: maxX, minZ: minZ, maxZ: maxZ)
                            print("height map", convertedBack)
                            let difference = gradient.compareVertices(originalVertices: transformedVertices, heightMapVertices: convertedBack)
                            
                      //      print("difference in accuracy: ", difference)
                            let minVal = findMinElement(in: heightMap)
                            let maxVal = findMaxElement(in: heightMap)
                            DispatchQueue.main.async{
                                print("start")
                                print(heightMap)
                                self.originalHeightMap = heightMap
                                self.enhancedMap = heightMap
                                self.maxHeight = maxVal
                                print("max", self.maxHeight)
                                self.minHeight = minVal
                                print("min", self.minHeight)
                                self.hapticsButton.isEnabled = true
                                
                            }
                            
                        }
                    }
                    else{

                        self.originalHeightMap = self.condition?.heightMap

                    }
                } else {
                    print("Failed to download the file.")
                    self.showError("Failed to download the model.")
                }
            }
        }
        
        
    }
    func convertFlatArrayTo2D(flatArray: [Float], rows: Int, columns: Int) -> [[Float]] {
        var heightMap = [[Float]]()
        for row in 0..<rows {
            let start = row * columns
            let end = start + columns
            let rowData = Array(flatArray[start..<end])
            heightMap.append(rowData)
        }
        return heightMap
    }
    
    func flattenHeightMap1(heightMap: [[Float]]) -> [Float] {
        return heightMap.flatMap { $0 }
    }
    func flattenHeightMap(heightMap: [[Float]]) -> [Float] {
        return heightMap.flatMap { row in row.map { $0.isNaN ? 0 : $0 } }
    }

    func storeHeightMap(heightMap: [[Float]]) -> ([Float], Int, Int) {
        let flatArray = flattenHeightMap(heightMap: heightMap)
        let rows = heightMap.count
        let columns = heightMap.first?.count ?? 0

        let data: [String: Any] = [
            "flatHeightMap": flatArray,
            "rows": rows,
            "columns": columns
        ]
        return (flatArray, rows, columns)

    }

    
    @IBAction func savePressed(_ sender: Any) {
        //update model file values on database
        let db = Firestore.firestore()
        guard let conditionName = self.condition?.name else{
            showError("Error saving file")
            return
        }
        guard let map = self.enhancedMap else{
            showError("Error saving haptic data")
            return
        }
        let convertedMap = storeHeightMap(heightMap: map)
        if self.condition?.isCreated == false{
            //create model
            //move file from processingmodels to models
            let lesion = databaseCondition(name: conditionName, urgency: self.condition?.urgency, symptoms: self.condition?.symptoms, clinicalNotes: self.condition?.notes, treatment: self.condition?.treatment, heightmap: convertedMap.0, rows: convertedMap.1, columns: convertedMap.2, rotationScale: rotationScaleVal)
            //also adding similar conditions logic
            do {
                try db.collection("models").document(conditionName).setData(from: lesion)
            } catch let error {
                print("Error writing skin lesion to Firestore: \(error)")
                showError("Error saving file")
                
            }
            DispatchQueue.global(qos: .background).async{
                self.moveModelStorage()
            }

        }else{
            //update existing values -> height map, rotationscale
            let modelRef = db.collection("models").document(conditionName)
            DispatchQueue.global(qos: .background).async {
 
                modelRef.updateData([
                    "heightmap": convertedMap.0,
                    "rows": convertedMap.1,
                    "columns": convertedMap.2,
                    "rotationScale": self.rotationScaleVal
                ]) { error in
                    if let error = error {
                        print("Error updating document: \(error.localizedDescription)")
                        
                    } else {
                        print("Document successfully updated")
                    }
                }
            }

        }
        
    }
    
    func moveModelStorage(){
        let storage = Storage.storage()
        let storageRef = storage.reference()
        // File located on disk
   //     let localFile = URL(string: "path/to/image")!
        let database = DatabaseManagement()
        let localFile = database.localFileURL(for: "scene.usdz", directory: .documentDirectory)
        let newUrl = "models/" + (self.condition?.name ?? "") + ".usdz"

        let modelRef = storageRef.child(newUrl)

        let uploadTask = modelRef.putFile(from: localFile, metadata: nil) { metadata, error in
          guard let metadata = metadata else {
            // Uh-oh, an error occurred!
              self.showError("Error uploading model")
            return
          }
          // Metadata contains file metadata such as size, content-type.
          let size = metadata.size
     
          modelRef.downloadURL { (url, error) in
            guard let downloadURL = url else {

                self.showError("Error creating model")
              return
            }
          }
        }
        
        // Create a reference to the file to delete
        let oldUrl = "processingModels/" + (self.condition?.name ?? "") + ".usdz"
        let oldFileRef = storageRef.child(oldUrl)

        oldFileRef.delete { error in
            if let error = error {
                self.showError("Error deleting old file: \(error.localizedDescription)")
            } else {
                print("Old file deleted successfully.")
            }
        }
    }

    func showLoadingIndicator(_ show: Bool) {
        if show {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    
    private func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = self.view.center
        view.addSubview(activityIndicator)
    }
    
    func showError(_ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    func completeDownload(completion: Bool){
        print("Download complete!")
    }
    

    func loadScene(from localURL: URL) -> SCNScene? {
        do {
            let scene1 = try SCNScene(url: localURL, options: nil)
            return scene1
        } catch {
            print("Failed to load SceneKit scene: \(error)")
            return nil
        }
    }
    
    func notesViewController(_ controller: NotesView, didUpdateNotes notes: String, type: String) {
        if type == "Notes"{
            
            self.condition?.notes = notes
        }else if type == "Treatment"{
            self.condition?.treatment = notes
        }else if type == "Symptoms"{
            self.condition?.symptoms = notes
            print(self.condition?.symptoms)
        }
    

    }

    
    
}

extension SCNQuaternion {
    static func fromTwoVectors(_ vectorA: SCNVector3, _ vectorB: SCNVector3, scale : Int) -> SCNMatrix4  {
        // Calculate the cross product
        let axis = SCNVector3(
            x: vectorA.y * vectorB.z - vectorA.z * vectorB.y,
            y: vectorA.z * vectorB.x - vectorA.x * vectorB.z,
            z: vectorA.x * vectorB.y - vectorA.y * vectorB.x
        )
        print("axis", axis)
        // Calculate the dot product
        let dotProduct = vectorA.x * vectorB.x + vectorA.y * vectorB.y + vectorA.z * vectorB.z
        
        // Calculate the magnitudes
        let magnitudeA = sqrt(vectorA.x * vectorA.x + vectorA.y * vectorA.y + vectorA.z * vectorA.z)
        let magnitudeB = sqrt(vectorB.x * vectorB.x + vectorB.y * vectorB.y + vectorB.z * vectorB.z)
        print("magnitudeA", magnitudeA)
        print("magnitudeB", magnitudeB)
        // Calculate the angle
        var angle = acos(dotProduct / (magnitudeA * magnitudeB))
        print("angle", angle)
        print(dotProduct / (magnitudeA * magnitudeB))
        angle = angle/Float(11-scale)
        if angle > 15.0 * Float.pi / 180.0{
            angle = 15.0 * Float.pi / 180.0
        }
        print("changed angle", angle)

        if(abs(1 - (dotProduct / (magnitudeA * magnitudeB))) < 0.1){
            return SCNMatrix4Identity
        }
        
        let maxAngle = Float.pi
        
        angle = min(angle, Float(maxAngle))

            // If the calculated angle is too small (approaching 0), return identity matrix to avoid unnecessary rotation
            if angle.isNaN || angle < 1e-4 {
                return SCNMatrix4Identity
            }
        // Construct the rotation axis
        let rotationAxis = SCNQuaternion(x: axis.x, y: axis.y, z: axis.z, w: angle)
        //return SCNMatrix4Identity
        let axisLength = sqrt(axis.x * axis.x + axis.y * axis.y + axis.z * axis.z)
        let normalizedAxis = SCNVector3(x: axis.x / axisLength, y: axis.y / axisLength, z: axis.z / axisLength)
        //SCNMatrix4MakeRotation(rotationAxis.w, rotationAxis.x, rotationAxis.y, rotationAxis.z)
        // Create and return the quaternion
        return SCNMatrix4MakeRotation(angle, normalizedAxis.x, normalizedAxis.y, normalizedAxis.z)
    }
}

extension SCNQuaternion {
    static func QfromTwoVectors(_ vectorA: SCNVector3, _ vectorB: SCNVector3) -> SCNQuaternion  {
        // Calculate the cross product
        let axis = SCNVector3(
            x: vectorA.y * vectorB.z - vectorA.z * vectorB.y,
            y: vectorA.z * vectorB.x - vectorA.x * vectorB.z,
            z: vectorA.x * vectorB.y - vectorA.y * vectorB.x
        )
        print("axis", axis)
        // Calculate the dot product
        let dotProduct = vectorA.x * vectorB.x + vectorA.y * vectorB.y + vectorA.z * vectorB.z
        
        // Calculate the magnitudes
        let magnitudeA = sqrt(vectorA.x * vectorA.x + vectorA.y * vectorA.y + vectorA.z * vectorA.z)
        let magnitudeB = sqrt(vectorB.x * vectorB.x + vectorB.y * vectorB.y + vectorB.z * vectorB.z)
        print("magnitudeA", magnitudeA)
        print("magnitudeB", magnitudeB)
        // Calculate the angle
        let angle = acos(dotProduct / (magnitudeA * magnitudeB))
        print("angle", angle)
        
        print(dotProduct / (magnitudeA * magnitudeB))
        if(abs(1 - (dotProduct / (magnitudeA * magnitudeB))) < 0.15){
            return SCNQuaternion(x: 0, y: 0, z: 0, w: 1)
        }
        // Construct the rotation axis
        let rotationAxis = SCNQuaternion(x: axis.x, y: axis.y, z: axis.z, w: angle)
        //return SCNMatrix4Identity
        // Create and return the quaternion
        return rotationAxis
    }
    
}



func findMaxElement1(in array: [[Float]]) -> Float? {
    // Flatten the 2D array to a 1D array and find the max element
    return array.flatMap { $0 }.max()
}
func findMaxElement(in matrix: [[Float]]) -> Float? {
    // Flatten the matrix and remove any NaN values
    let flattenedArray = matrix.flatMap { $0 }.filter { !$0.isNaN }
    // Return the maximum element, if any exist
    return flattenedArray.max()
}

func findMinElement1(in array: [[Float]]) -> Float? {
    // Flatten the 2D array to a 1D array and find the max element
    return array.flatMap { $0 }.min()
}

func findMinElement(in matrix: [[Float]]) -> Float? {
    // Flatten the matrix and remove any NaN values
    let flattenedArray = matrix.flatMap { $0 }.filter { !$0.isNaN }
    // Return the maximum element, if any exist
    return flattenedArray.min()
}

public struct databaseCondition: Codable {

  let name: String?
  let urgency: String?
  let symptoms: String?
  let clinicalNotes: String?
  let treatment: String?
    let heightmap: [Float]?
    let rows: Int?
    let columns: Int?
    let rotationScale: Int?

  enum CodingKeys: String, CodingKey {
    case name
    case urgency
    case symptoms
    case clinicalNotes
    case treatment
      case heightmap
      case rows
      case columns
      case rotationScale
  }

}
