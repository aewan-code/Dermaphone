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


class skinmodel: UIViewController {
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
    var allVertices : [SCNVector3]?

    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var zScale: UISlider!
    
    @IBOutlet weak var yScale: UISlider!
    
    @IBOutlet weak var xScale: UISlider!
    @IBOutlet weak var zLabel: UILabel!
    @IBOutlet weak var yLabel: UILabel!
    @IBOutlet weak var xLabel: UILabel!
    @IBOutlet weak var completeEdit: UIButton!
    @IBOutlet weak var cancelEdit: UIButton!
    @IBOutlet weak var symptonsButton: UIButton!
    
    @IBOutlet weak var hapticsButton: UIButton!
    @IBOutlet weak var treatmentButton: UIButton!
    @IBOutlet weak var notesButton: UIButton!
    @IBOutlet weak var urgencylabel: UILabel!
    @IBOutlet weak var similarButton: UIButton!

    @IBOutlet var magnifier: [UIImageView]!
    
    @IBOutlet var magnifierText: [UILabel]!
    @IBOutlet weak var hapticMethod: UISegmentedControl!
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
    
    @IBOutlet weak var RotateToggle: UIButton!
 
    @IBOutlet weak var SelectPivot: UIButton!
    
    @IBOutlet weak var recordHaptic: UIButton!
    @IBOutlet weak var smoothButton: UIButton!
    let hapticAlgorithm = HapticRendering(maxHeight: 0.5, minHeight: -0.5)
    
    var prevTimestamp : TimeInterval?
    
    var chartData : [HapticDataPoint]?
    let smoothedModel = smoothModel()
    var kernel : [[[Double]]]?
    var vertices : [SCNVector3]?
    override func viewDidLoad() {
        super.viewDidLoad()
        hapticMethod.selectedSegmentIndex = 0
        print(modelName)
        print(modelFile)
        currentView = view
        hapticTransient = true
        scene = SCNScene(named: modelFile ?? "test2scene.scn")
        
        guard let baseNode = scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true) else {
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
        sceneView.frame = CGRect(x: 0, y: notesButton.frame.maxY + 10, width: view.frame.width, height: view.frame.height - (notesButton.frame.maxY + 10)) // Adjust the values as needed
        originalOrientation = (sceneView.scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)!.orientation)!
        urgencylabel.text = self.condition?.urgency ?? ""
        
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
        view.bringSubviewToFront(smoothButton)
        view.bringSubviewToFront(hapticsButton)
        xLabel.isHidden = true
        yLabel.isHidden = true
        zLabel.isHidden = true
        xScale.isHidden = true
        yScale.isHidden = true
        zScale.isHidden = true

        cancelEdit.isHidden = true
        completeEdit.isHidden = true
        
        changePivot = false
        hapticsToggle = false
        createAxes()
        hideAxes()
        navBar.title = "Skin Lesion: \(self.condition?.name ?? "")"
        navBar.titleView?.isHidden = false
        for image in magnifier{
            view.bringSubviewToFront(image)
        }
        for descript in magnifierText{
            view.bringSubviewToFront(descript)
        }
      //  allVertices = try extractVertices(from: (scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.geometry)!)
     //   print("before")
      //  print(allVertices)
        //try print(extractVertices(from: (scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.geometry)!))
        let point1 = SCNVector3(x: 0.0, y: 6.0, z: 0.0)
        let points = [point1, SCNVector3(x: 0.1, y: 5.7, z: 0.0), SCNVector3(x: -0.1, y: 5.7, z: 0.0)]
       // let points2 = []
        let gaussMethod = gradientMethod()
        print(gaussMethod.averageValues(closestPoints: points, inputPoint: point1))
       // vertices = extractVertices(from: (scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.geometry)!)
        print("gaussian")
        


        //let normalisedKernel = smoothedModel.normaliseKernel(kernel)
      //  let gaussianModel = smoothedModel.applyGaussianSmoothing(pointcloud: newCoordinates!, kernel: kernel)
        
      //  print(gaussianModel)
       /* print("PRINTING NUMBER OF VERTICES")
        print(scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.geometry?.sources.first(where: { $0.semantic == .vertex }))
        try print(extractVertices(from: (scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.geometry)!))
        try showVertices1(of: (scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.geometry)!, childNode: scene!.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)! )
        
        print(scene!.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.transform)
        print(scene!.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.worldTransform)*/
       // try showVertices1(of: (scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.geometry)!, childNode: scene!.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)! )
        print("check", vertices)
        kernel = smoothedModel.generateKernel(kernelSize: 3, sigma: 0.5)
    }
    @IBAction func applyGaussian(_ sender: Any) {
       // var newCoordinates : [[[Float]]]
       /* Task { @MainActor in
            newCoordinates = await smoothedModel.convertToPointCloud(coordinates: extractVertices(from: (scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.geometry)!)!) ?? [[[0]]]

        }
        let gaussianModel =  smoothedModel.applyGaussianSmoothing(pointcloud: newCoordinates, kernel: kernel ?? [[[0]]])
        print(gaussianModel)*/
        Task {
            // Asynchronously fetch new coordinates
            /*guard let vertices = extractVertices(from: (scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.geometry)!) else {
                print("Failed to extract vertices")
                return
            }*/

            let newCoordinates = smoothedModel.convertToPointCloud(coordinates: vertices ?? [SCNVector3(x: 0, y: 0, z: 0)]) ?? [[[0]]]
            print("new coordinates", vertices)
            // Once new coordinates are obtained, apply Gaussian smoothing
            let gaussianModel = smoothedModel.applyGaussianSmoothing(pointcloud: newCoordinates, kernel: kernel ?? [[[0]]])
            print(gaussianModel)
        }
    }
  /*  func applyGaussian(){

    }*/
    

    func extractVertices(from geometry: SCNGeometry) -> [SCNVector3]? {//returns all the vertices from
        // Get vertex sources
        guard let vertexSource = geometry.sources.first(where: { $0.semantic == .vertex }) else {return nil}


        let stride = vertexSource.dataStride // in bytes
        let offset = vertexSource.dataOffset // in bytes
        let componentsPerVector = vertexSource.componentsPerVector
        let bytesPerComponent = vertexSource.bytesPerComponent
        let bytesPerVector = componentsPerVector * bytesPerComponent
        let vectorCount = vertexSource.vectorCount

        var vertices = [SCNVector3]() // A new array for vertices

        // For each vector, read the bytes
        for i in 0..<vectorCount {
            // Assuming that bytes per component is 4 (a float)
            // If it was 8 then it would be a double (aka CGFloat)
            var vectorData = [Float](repeating: 0, count: componentsPerVector)

            // The range of bytes for this vector
            let byteRange = i * stride + offset ..< i * stride + offset + bytesPerVector
            
            vertexSource.data.withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) in//explain code
                // Bind the raw buffer pointer to the desired type (Float)
                let typedBufferPointer = rawBufferPointer.bindMemory(to: Float.self)

                // Access the base address of the typed buffer pointer
                if let baseAddress = typedBufferPointer.baseAddress {
                    // Calculate the destination pointer for the copy operation
                    let destinationPointer = UnsafeMutablePointer<Float>.allocate(capacity: bytesPerVector / MemoryLayout<Float>.stride)
                    
                    // Convert destinationPointer to UnsafeMutableRawPointer
                    let destinationRawPointer = UnsafeMutableRawPointer(destinationPointer)
                    
                    // Convert destinationRawPointer to UnsafeMutableRawBufferPointer
                    let destinationBufferPointer = UnsafeMutableRawBufferPointer(start: destinationRawPointer, count: bytesPerVector)
                    
                    // Copy bytes from the byte range to the destination buffer pointer
                    rawBufferPointer.copyBytes(to: destinationBufferPointer, from: byteRange)
                    
                    // Convert the copied bytes to an array of Float (vectorData)
                    vectorData = Array(UnsafeBufferPointer(start: destinationPointer, count: bytesPerVector / MemoryLayout<Float>.stride))
                    
                    // Deallocate the memory allocated for the destination pointer
                    destinationPointer.deallocate()
                }
            }


            // At this point you can read the data from the float array
            let x = vectorData[0]
            let y = vectorData[1]
            let z = vectorData[2]

            // Append the vertex to the array
            vertices.append(SCNVector3(x, y, z))

            // ... or just log it
            print("x: \(x), y: \(y), z: \(z)")
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

        // Create nodes for each vertex and position them
        for vertex in Vertices {
            let vertexNode = SCNNode(geometry: sphereGeometry)
           // vertexNode.position = vertex
            // Adjust the position to be relative to the parent node
          //  vertexNode.position = vertex + parentNode.position // Adjusted position
            // Optionally, you can add some customization to the nodes
            vertexNode.position = SCNVector3Make(
                vertex.x + (parentNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.position.x ?? 0),
                vertex.y + (parentNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.position.y ?? 0),
                vertex.z + (parentNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.position.z ?? 0)
            )

            // Add the vertex node to the scene
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

        // Create nodes for each vertex and position them relative to the child's transformed position
        for vertex in vertices {
            let vertexPosition = SCNVector3ToGLKVector3(vertex)
            let childTransf = SCNMatrix4ToGLKMatrix4(transf)
            
            let transformedVertexPosition = GLKMatrix4MultiplyVector3(childTransf, vertexPosition)
           // transformedVertexPosition = GLKMatrix4MultiplyVector3(transf, transformedVertexPosition)
            let transformedVertex = SCNVector3FromGLKVector3(transformedVertexPosition)

            let vertexNode = SCNNode(geometry: sphereGeometry)
            vertexNode.position = transformedVertex
            // Optionally, you can add some customization to the nodes

            // Add the vertex node to the scene
            childNode.addChildNode(vertexNode)
        }
    }

    func inverseQuaternion(_ q: SCNQuaternion) -> SCNQuaternion {
        let conjugate = SCNQuaternion(x: -q.x, y: -q.y, z: -q.z, w: q.w)
        let squaredMagnitude = q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w
        return SCNQuaternion(x: conjugate.x / squaredMagnitude, y: conjugate.y / squaredMagnitude, z: conjugate.z / squaredMagnitude, w: conjugate.w / squaredMagnitude)
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

                // Check if the desired node is touched
                for result in hitTestResults {
                    if result.node.name == modelName{
                        // Node is touched, perform desired action
                        let position = result.localCoordinates
                        //later remove so that first point is only added if continued onto touches moved
                        if recordHaptics{
                            let firstPoint = HapticDataPoint(intensity: 0, time: 0.0)
                            chartData?.append(firstPoint)
                            firstTimestamp = touch.timestamp
                            prevTimestamp = firstTimestamp
                        }
                        prevPoint = position.y
                        previousPosition = modelLocation(xPos: position.x, yPos: position.y, zPos: position.z)
                        if !(hapticTransient ?? true) && hapticsToggle{
                            //continuous mode
                            tempHaptics?.createContinuousHapticPlayer(initialIntensity: position.y*10, initialSharpness: position.y*10)
                            currentIntensity = position.y*10
                            currentSharpness = currentIntensity
                          //  tempHaptics?.continuousPlayer.start(atTime: <#T##TimeInterval#>)
                            // Warm engine.
                            do {
                                // Begin playing continuous pattern.
                                try tempHaptics?.continuousPlayer.start(atTime: CHHapticTimeImmediate)
                                print("STARTED CONTINUOUS PLAYER")
                            } catch let error {
                                print("Error starting the continuous haptic player: \(error)")
                            }

                           // let rotation = SCNQuaternion(x: 0.0, y: (position.y * Float.pi)/180, z: 0.0, w: (position.y * Float.pi)/180)

                            
                        }
                        if hapticsToggle{
                            let angle = (position.y * Float.pi)/180
                            print("angle", angle)
                            // Calculate the half angle and its sine and cosine
                            let halfAngle = angle/2.0
                            let sinHalfAngle = sin(halfAngle)
                            let cosHalfAngle = cos(halfAngle)
                            // Create the quaternion with y-component representing the rotation
                            let rotation = SCNQuaternion(x: 0.0, y: sinHalfAngle, z: 0.0, w: cosHalfAngle)
                           // sceneView.scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.rot
                            
                            //let deltaX: Float = 0.1 // Adjust this value as needed for horizontal rotation
                            //let deltaY: Float = 1.0 // Adjust this value as needed for vertical rotation
                            //need to get average x/z to find centre position? for now just base on value
                            print(position.x)
                            print(position.z)
                            let angleInRadians: Float = 1 * (Float.pi / 180) // Convert 1 degree to radians

                            // Create a rotation matrix for rotation around the z-axis
                            let rotationMatrix = SCNMatrix4MakeRotation(angleInRadians, 0, 0, -1)

                            // Get the current transform of the camera's point of view
                            var currentTransform = sceneView.defaultCameraController.pointOfView?.transform ?? SCNMatrix4Identity

                            // Apply the rotation to the current transform
                            currentTransform = SCNMatrix4Mult(currentTransform, rotationMatrix)

                            // Set the new transform to the camera's point of view
                          //  sceneView.defaultCameraController.pointOfView?.transform = currentTransform
                            if position.z > 0{
                               //sceneView.defaultCameraController.rotateBy(x: -position.y*100, y: 0.0)
                               // sceneView.defaultCameraController.rollAroundTarget(-position.y*100)
                               // sceneView.defaultCameraController.pointOfView?.eulerAngles.z += position.y
                             //   sceneView.defaultCameraController.pointOfView?.transform = currentTransform
                            }
                            else{
                               // sceneView.defaultCameraController.rotateBy(x: position.y*100, y: 0.0)
                                //sceneView.defaultCameraController.rollAroundTarget(position.y*100)
                               // sceneView.defaultCameraController.pointOfView?.transform += position.y
                              //  sceneView.defaultCameraController.pointOfView?.transform = currentTransform
                            }
                            //sceneView.defaultCameraController.rot//.pointOfView?.orientation = inverseQuaternion(rotation)
                        //    Calculate the new position of the camera node based on the object's position
                            // and desired distance from the object
                         //   let distanceFromObject: Float = 10.0 // Adjust this value as needed
                         //   let newPosition = sceneView.scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.position + SCNVector3(0, 0, distanceFromObject)
                            
                            // Set the camera node's position to the new position
                          //  sceneView.defaultCameraController.pointOfView?.position = newPosition
                        }
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
            if result.node.name == modelName {
                let position = result.localCoordinates
                let height = result.localCoordinates.y
                
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
                    if !(hapticTransient ?? true){
                        let intensityParameter = CHHapticDynamicParameter(parameterID: .hapticIntensityControl,
                                                                          value: (height*10/(currentIntensity ?? 1)),
                                                                          relativeTime: 0)
                        let sharpnessParameter = CHHapticDynamicParameter(parameterID: .hapticSharpnessControl,
                                                                          value: (height*10 - (currentSharpness ?? 0)),
                                                                          relativeTime: 0)
                        print("continuous")
                        currentIntensity = height*10
                        currentSharpness = height*10
                        print(currentIntensity)
                        //print(currentSharpness)
                        //print(height*10)
                        // Send dynamic parameters to the haptic player.
                        do {
                            try tempHaptics?.continuousPlayer.sendParameters([intensityParameter, sharpnessParameter],
                                                                atTime: 0)
                            
                        } catch let error {
                            print("Dynamic Parameter Error: \(error)")
                        }
                    }
                    else{
                     //   try tempHaptics?.playHeightHaptic(height:intensity)
                        print("new point")
                       // print(intensity)
                      //  print(intensity1)
                      //  print(result.localCoordinates.x)
                      //  print(result.localCoordinates.z)

                    }
                    
                    /MARK - TRYING GRADIENT POINT CLOUD METHOD/
                 //   let allVertices = try extractVertices(from: (scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.geometry)!)
                        
                    
                    // Filter vertices within the specified radius of the touch location
                 /*   let verticesWithinRadius = (allVertices?.filter { vertex in
                        let xSquared = sqrt((vertex.x - position.x)*(vertex.x - position.x))
                        let ySquared = sqrt((vertex.y - position.y)*(vertex.y - position.y))
                        let zSquared = sqrt((vertex.z - position.z)*(vertex.z - position.z))
                        let distanceSquared = xSquared + ySquared + zSquared
                        return distanceSquared <= 0.01//radius
                    })! */
                    
                    
                    
                    //gives me all the points in the point cloud within the radius
                    //let gradients = extractPointCloudRegionAndGradients(from scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.geometry)!, at position, radius: 0.01)
                  //  let gradients = extractPointCloudRegionAndGradients(from: (scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.geometry)!, at: position, radius: 0.01)
                    
                   /* if let previousPosition = previousPosition {
                        if sqrt((previousPosition.xPos - position.x)*(previousPosition.xPos - position.x)) > 0.001 || sqrt((previousPosition.zPos - position.z)*(previousPosition.zPos - position.z)) > 0.001 {
                            print("check here")
                          //  let gradient = computeGradient(at: position, in: verticesWithinRadius)
                            // Compute gradients for each vertex within the region
                            let gradients = verticesWithinRadius.compactMap { vertex -> (vertex: SCNVector3, gradient: Float)? in
                           //     guard let allVertices = allVertices else { return nil }
                                let gradient = computeGradient(at: vertex, in: allVertices ?? [])
                                return (vertex: vertex, gradient: gradient) as! (vertex: SCNVector3, gradient: Float)
                            }
                            if computeGradient(at: position, in: verticesWithinRadius) <= 0.001{
                                print("STATIONARY POINT")
                                //let hessian = computeHessian(at: position, in: verticesWithinRadius)
                                let gradVals = gradients.map { $0.gradient }
                                var pos = SCNVector3(x: position.x + 0.001, y: position.y, z: position.z)
                              //  print(functionValue(at: pos, vertices: verticesWithinRadius))
                                let grad2 = computeGradient(at: pos, in: verticesWithinRadius)
                                pos = SCNVector3(x: position.x - 0.001, y: position.y, z: position.z)
                              //  print(functionValue(at: pos, vertices: verticesWithinRadius))
                                let grad1 = computeGradient(at: pos, in: verticesWithinRadius)
                                pos = SCNVector3(x: position.x, y: position.y, z: position.z + 0.001)
                               // print(functionValue(at: pos, vertices: verticesWithinRadius))
                                let grad4 = computeGradient(at: pos, in: verticesWithinRadius)
                                pos = SCNVector3(x: position.x, y: position.y, z: position.z - 0.001)
                              //  print(functionValue(at: pos, vertices: verticesWithinRadius))
                                let grad3 = computeGradient(at: pos, in: verticesWithinRadius)
                                var hessianAttempt = sqrt((grad2-grad1)*(grad2-grad1))//
                                hessianAttempt = hessianAttempt*sqrt((grad4-grad3)*(grad4-grad3))//[grad2, grad1, grad4, grad3]//dependent on the direction the user is moving
                                print(grad2)
                                print(grad1)
                                print(grad3)
                                print(grad4)
                                
                                print(hessianAttempt)
                            //
                                
                                try tempHaptics?.playHeightHaptic(height:hessianAttempt*10)
                            }
                            else{
                                print("gradient")
                                print(computeGradient(at: position, in: verticesWithinRadius))
                            }*/
                       // for point in gradients {
                          //  if point.gradient == 0 {
                           //     print(point.vertex)
                           //     print("STATIONARY POINT")
                             //   let hessian = computeHessian(at: position, in: verticesWithinRadius)
                        //    print(hessian)
                    //        print("end")
                               // try tempHaptics?.playHeightHaptic(height:height)
                        //    }
                     //   }
                    /END MARK/

                        

                                print(position.y)
                             /*   let intensity1 = sqrt((height - previousPosition.yPos)*(height - previousPosition.yPos))
                                previousPosition.xPos = position.x
                                previousPosition.yPos = position.y
                                previousPosition.zPos = position.z*/
                                let timeChange = touch.timestamp - ((prevTimestamp ?? firstTimestamp) ?? 0)
                        //      let intensityChange = intensity1/Float(timeChange)
                                try tempHaptics?.playHeightHaptic(height:intensity*10)
                                prevTimestamp = touch.timestamp
                                //print(intensity1*100)
                    let angleInRadians: Float = (position.y - (previousPosition?.yPos ?? 0.0)) * 100 * (Float.pi / 180) // Convert 1 degree to radians
                    let xChange = position.x - (previousPosition?.xPos ?? 0.0)
                    let zChange = position.z - (previousPosition?.zPos ?? 0.0)
                    let newX = xChange/(abs(xChange) + abs(zChange))
                    let newZ = zChange/(abs(xChange) + abs(zChange))
                    
                    // Create a rotation matrix for rotation around the z-axis
                    //let rotationMatrix = SCNMatrix4MakeRotation(angleInRadians, 1, 0, 0)
                    let rotationMatrix = SCNMatrix4MakeRotation(angleInRadians, newX, 0, newZ)

                    // Get the current transform of the camera's point of view
                    var currentTransform = sceneView.defaultCameraController.pointOfView?.transform ?? SCNMatrix4Identity

                    // Apply the rotation to the current transform
                    currentTransform = SCNMatrix4Mult(currentTransform, rotationMatrix)
                    previousPosition?.xPos = position.x
                    previousPosition?.yPos = position.y
                    previousPosition?.zPos = position.z
                    sceneView.defaultCameraController.pointOfView?.transform = currentTransform
                    print("currentTransform")
                    print(angleInRadians)
                    print(newX)
                    print(newZ)
                    if position.z > 0{
                        //sceneView.defaultCameraController.rotateBy(x: -position.y*10, y: 0.0)
                     //   sceneView.defaultCameraController.rollAroundTarget(-position.y*100)
                       // sceneView.defaultCameraController.pointOfView?.eulerAngles.y += position.y
                       // sceneView.defaultCameraController.pointOfView?.transform = currentTransform
                    }
                    else{
                        //sceneView.defaultCameraController.rotateBy(x: position.y*10, y: 0.0)
                    //    sceneView.defaultCameraController.rollAroundTarget(position.y*100)
                        //sceneView.defaultCameraController.pointOfView?.eulerAngles.y += position.y
                    //    sceneView.defaultCameraController.pointOfView?.transform = currentTransform
                    }
                                if recordHaptics{
                                 //   let dataPoint = HapticDataPoint(intensity: height, time: Float(touch.timestamp - (firstTimestamp ?? touch.timestamp)))
                                    let dataPoint = HapticDataPoint(intensity: intensity*10, time:Float(touch.timestamp - (firstTimestamp ?? touch.timestamp)))
                                    chartData?.append(dataPoint)
                                }
                        } else {
                            // Handle the case when previousPosition is nil
                        }
                        
                    }
                }
                return
        
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
        if(!(hapticTransient ?? true)){
            
            do {
                try tempHaptics?.continuousPlayer?.stop(atTime: CHHapticTimeImmediate)
            } catch /*let error {
                     print("Error stopping the continuous haptic player: \(error)")
                     }*/
            {return}
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        previousPosition = nil
        do {
            try tempHaptics?.continuousPlayer.stop(atTime: CHHapticTimeImmediate)
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
        sceneView.debugOptions = SCNDebugOptions(rawValue: 2048)//shows the grid
        originalOrientation = sceneView.scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.orientation
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
        hideAxes()
        
    }
    @IBAction func cancelPressed(_ sender: Any) {
        sceneView.scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.orientation = originalOrientation!
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
        sceneView.scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.localRotate(by: q)
        
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

        sceneView.scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.localRotate(by: q)
        
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
        sceneView.scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.localRotate(by: q)
        
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
        scene = SCNScene(named: model.modelFile)//do i need to deallocate the current scene?

    
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
            hapticsButton.tintColor = .green
            print(sceneView.defaultCameraController.pointOfView?.position)
            print(sceneView.defaultCameraController.pointOfView?.orientation)
            print(sceneView.defaultCameraController.pointOfView?.eulerAngles)
            if let originalPosition = originalCameraPosition {
           //     cameraNode.position = originalPosition
                sceneView.defaultCameraController.pointOfView?.position = originalPosition
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
        }
    }
    
    
    @IBAction func touchNotes(_ sender: Any) {
        guard let popUp = storyboard?.instantiateViewController(withIdentifier: "NotesView") as? NotesView else {
            return
        }
        if let skinCondition = condition {
            popUp.set(condition: skinCondition, type: "Notes")
            
            //navigationController?.pushViewController(popUp, animated: true)
            navigationController?.present(popUp, animated: true, completion: nil)
        }

    }
    
    @IBAction func touchSymptoms(_ sender: Any) {
        guard let popUp = storyboard?.instantiateViewController(withIdentifier: "NotesView") as? NotesView else {
            return
        }
        if let skinCondition = condition {
            popUp.set(condition: skinCondition, type: "Symptoms")
            
            //navigationController?.pushViewController(popUp, animated: true)
            navigationController?.present(popUp, animated: true, completion: nil)
        }
    }
    
    @IBAction func touchTreatment(_ sender: Any) {
        guard let popUp = storyboard?.instantiateViewController(withIdentifier: "NotesView") as? NotesView else {
            return
        }
        if let skinCondition = condition {
            popUp.set(condition: skinCondition, type: "Treatment")
            
            //navigationController?.pushViewController(popUp, animated: true)
            navigationController?.present(popUp, animated: true, completion: nil)
        }
    }
    
}

