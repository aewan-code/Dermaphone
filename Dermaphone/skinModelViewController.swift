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


enum FilterType: String {
    case none = "None"
    case gaussian = "Gaussian"
    case average = "Weighted Average"
    case edge = "Ricker Wavelet"
    case heightMap = "Height Map"
}

class skinmodel: UIViewController {
    var filter : FilterType = .none//save type
    var kVal : Int = 5
    var sigmaVal : Float = 1
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
    

    override func viewDidLoad() {
        super.viewDidLoad()
        hapticMethod.selectedSegmentIndex = 0
        currentView = view
        hapticTransient = true
        scene = SCNScene(named: modelFile ?? "test2scene.scn")
        
        guard let baseNode = scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true) else {
                    fatalError("Unable to find baseNode")
                }
        // Create and configure a haptic engine.
        // Create a Cone Geometry
         let coneGeometry = SCNCone(topRadius: 10, bottomRadius: 40, height: 10.0)
        let gradient1 = gradientMethod()
        
        
         // Optionally, set materials for the cone
         let material = SCNMaterial()
        material.diffuse.contents = UIColor.blue
         coneGeometry.materials = [material]

         // Create a Node with the Cone Geometry
         let coneNode = SCNNode(geometry: coneGeometry)
        if (modelName == "triangle"){
            sceneView.scene?.rootNode.addChildNode(coneNode)
            coneNode.position = SCNVector3(0, 0, 0)
            print("ALEERA")
          //  print(gradient1.extractHeightMap(from: coneNode.geometry!, gridSizeX: 30, gridSizeZ: 30))
            print("hi")
            
        }
        else{
            sceneView.scene?.rootNode.addChildNode(baseNode)
            print("model name", modelName)
        }
      //
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
        view.bringSubviewToFront(palpationOption)
        view.bringSubviewToFront(SelectPivot)
        view.bringSubviewToFront(recordHaptic)
        view.bringSubviewToFront(xLabel)
        view.bringSubviewToFront(yLabel)
        view.bringSubviewToFront(zLabel)
        view.bringSubviewToFront(xScale)
        view.bringSubviewToFront(yScale)
        view.bringSubviewToFront(zScale)
        view.bringSubviewToFront(hapticsButton)
        view.bringSubviewToFront(settingsButton)
        view.bringSubviewToFront(hapticsSettings)
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
      /*  for image in magnifier{
            view.bringSubviewToFront(image)
        }
        for descript in magnifierText{
            view.bringSubviewToFront(descript)
        }*/
      //  allVertices = try extractVertices(from: (scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.geometry)!)
     //   print("before")
      //  print(allVertices)
        //try print(extractVertices(from: (scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.geometry)!))
        print("HELLO 1")
        let point1 = SCNVector3(x: 0.0, y: 6.0, z: 0.0)
        let indices: [Int32] = [
            0, 1, 2 // Triangle with vertices 0, 1, 2
        ]
        let points = [point1, SCNVector3(x: 0.1, y: 5.7, z: 0.0), SCNVector3(x: -0.1, y: 5.7, z: 0.0), SCNVector3(x: 0.2, y: 6.2, z: 0.0)]
       // let points2 = []
        let gaussMethod = gradientMethod()
        let testSource = SCNGeometrySource(vertices: points)
        let testElement = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        let testShape = SCNGeometry(sources: [testSource], elements: [testElement])
            // -0.1293827, y: 0.019729614, z: 0.14373043
       // let url = URL.documentsDirectory.appendingPathComponent("coordinates.txt")
      //  let url2 = URL.documentsDirectory.appendingPathComponent("tra.txt")
        let url = URL.documentsDirectory.appendingPathComponent("smoothCloud.txt")
       let url2 = URL.documentsDirectory.appendingPathComponent("transientCloud.txt")
        let url3 = URL.documentsDirectory.appendingPathComponent("vertices.txt")
        let url4 = URL.documentsDirectory.appendingPathComponent("vertices5.txt")
        
        do {
            print("HELLO 2")
            let fileHandle = try FileHandle(forReadingFrom: url)
            let data = fileHandle.readDataToEndOfFile()
            fileHandle.closeFile()
            
            // Assuming the file contains text data, you can convert it to a String
            if let text = String(data: data, encoding: .utf8) {
                print("Smoothed cloud")
                smoothedCloud = convertTextToSCNVector3(text: text)
                print(smoothedCloud?[0])
                let yValues = smoothedCloud?.map { $0.y }
                maxContinuous = yValues?.max()
                minContinuous = yValues?.min()
            } else {
                print("Unable to convert data to text.")
            }
        } catch {
            print("Error: \(error)")
        }
        
        var readingUrl = url3
        if self.modelName == "Basal Cell Carcinoma"{
            readingUrl = url4
        }
        else if (self.modelName == "Test Model"){


        }
   /*     do {
            print("HELLO 3")
            let fileHandle = try FileHandle(forReadingFrom: readingUrl)
            let data = fileHandle.readDataToEndOfFile()
            fileHandle.closeFile()
            
            // Assuming the file contains text data, you can convert it to a String
            if let text = String(data: data, encoding: .utf8) {
                print("Vertices")
                modelVertices = convertTextToSCNVector3(text: text)
              //  print(modelVertices)
            let gradient = gradientMethod()
                print("height map")
                let height : [[Float]] = [[0.0, 0.0, 0.0, 0.0, 0.25, 0.0, 0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.25, 0.75, 1.25, 1.25, 0.75, 0.25, 0.0, 0.0], [0.0, 0.25, 1.25, 2.25, 3.25, 3.25, 2.25, 1.25, 0.25, 0.0], [0.0, 0.75, 2.25, 3.75, 4.75, 4.75, 3.75, 2.25, 0.75, 0.0], [0.0, 1.25, 3.25, 4.75, 5.0, 5.0, 4.75, 3.25, 1.25, 0.0], [0.25, 1.25, 3.25, 4.75, 5.0, 5.0, 4.75, 3.25, 1.25, 0.25], [0.0, 0.75, 2.25, 3.75, 4.75, 4.75, 3.75, 2.25, 0.75, 0.0], [0.0, 0.25, 1.25, 2.25, 3.25, 3.25, 2.25, 1.25, 0.25, 0.0], [0.0, 0.0, 0.25, 0.75, 1.25, 1.25, 0.75, 0.25, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0, 0.25, 0.0, 0.0, 0.0, 0.0, 0.0]]
//gradient.createHeightMap(from: modelVertices ?? [], gridSize: 5)//113)
                originalHeightMap = height
                // Example usage
                let sigma: Float = 1  // Adjust sigma as needed
                let kernelSize = 7  // Ensure this is an odd number
                let kernel = gradient.mexicanHatKernel(size: kernelSize, sigma: sigma)
                enhancedMap = gradient.applyKernel(kernel: kernel, to: height)
                //print(gradient.applySobelOperator(to: height))
                print(enhancedMap)
                
                
                maxPoint = modelVertices?.max(by: { $0.y < $1.y })
                minPoint = modelVertices?.min(by: { $0.y < $1.y })
             //   let yValues = smoothedCloud?.map { $0.y }
             //   maxContinuous = yValues?.max()
             //   minContinuous = yValues?.min()
            } else {
                print("Unable to convert data to text.")
            }
        } catch {
            print("Error: \(error)")
        }*/
        
        /*do {
            print("HELLO 4")
            let fileHandle = try FileHandle(forReadingFrom: url2)
            let data = fileHandle.readDataToEndOfFile()
            fileHandle.closeFile()
            
            // Assuming the file contains text data, you can convert it to a String
            if let text = String(data: data, encoding: .utf8) {
                print("transientCloud.txt:")
                transientCloud = convertTextToSCNVector3(text: text)
                let yValues = smoothedCloud?.map { $0.y }
                print(transientCloud)
                maxTransient = yValues?.max()
                minTransient = yValues?.min()
            } else {
                print("Unable to convert data to text.")
            }
        } catch {
            print("Error: \(error)")
        }*/
     /*   do {
            try FileManager.default.removeItem(at: url)
        }catch{
            print("error deleting file")
        }*/
        gradientEffect = false
        DispatchQueue.global(qos: .background).async{
           // let clouds = gaussMethod.smoothPointCloud(from: (self.scene?.rootNode.childNode(withName: self.modelName ?? "Mesh", recursively: true)?.geometry)!)
          //  let allVertex = gaussMethod.storeExtractVertices(from: coneNode.geometry!)
            
            
            DispatchQueue.main.async{
                let gradient = gradientMethod()
              //  print("smoothed:")
            //    print(clouds.smoothed)
            //    print("transient")
                
       /*         let gradient = gradientMethod()
                let height : [[Float]] = [[0.0, 0.0, 0.0, 0.0, 0.25, 0.0, 0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.25, 0.75, 1.25, 1.25, 0.75, 0.25, 0.0, 0.0], [0.0, 0.25, 1.25, 2.25, 3.25, 3.25, 2.25, 1.25, 0.25, 0.0], [0.0, 0.75, 2.25, 3.75, 4.75, 4.75, 3.75, 2.25, 0.75, 0.0], [0.0, 1.25, 3.25, 4.75, 5.0, 5.0, 4.75, 3.25, 1.25, 0.0], [0.25, 1.25, 3.25, 4.75, 5.0, 5.0, 4.75, 3.25, 1.25, 0.25], [0.0, 0.75, 2.25, 3.75, 4.75, 4.75, 3.75, 2.25, 0.75, 0.0], [0.0, 0.25, 1.25, 2.25, 3.25, 3.25, 2.25, 1.25, 0.25, 0.0], [0.0, 0.0, 0.25, 0.75, 1.25, 1.25, 0.75, 0.25, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0, 0.25, 0.0, 0.0, 0.0, 0.0, 0.0]]
//gradient.createHeightMap(from: allVertex ?? [], gridSize: 20)//113)
                print("height map cone")
                print(height)
                let sigma: Float = 5  // Adjust sigma as needed
                let kernelSize = 3  // Ensure this is an odd number
                let kernel = gradient.mexicanHatKernel(size: kernelSize, sigma: sigma)
                print("ricker wavelet")
                print(gradient.applyKernel(kernel: kernel, to: height))
                
                print("gaussian")
                print(gradient.applyGaussianToHeightMap(heightMap: height, k: 3, sigma: 5))
                
                print("gradient height map")
                let temp = gradient.convertHeightMapToGradient(heightMap: height)
                print(temp)
                
                print("second derivative")
                print(gradient.convertHeightMapToGradient(heightMap: temp.0))
                
                print("sobel")
                print(gradient.applySobelOperator(to: height))
                
                print("done")
          //      print(clouds.transient)*/
                print("CHECK HERE")
               // let geom = gradient.createGeom()
               // let node = SCNNode(geometry: geom)
                let geom = self.scene?.rootNode.childNode(withName: self.modelName ?? "Mesh", recursively: true)?.geometry
                
                let geom1 = gradient.createCustomCone(top: SCNVector3(0, 0.5, 0), radius: 0.5, slices: 20)
                let coneNode = SCNNode(geometry: geom1)
               // self.scene?.rootNode.addChildNode(node)
                let node = self.scene?.rootNode.childNode(withName: self.modelName ?? "Mesh", recursively: true)
                let transformedVertices = gradient.getTransformedVertices(node: node ?? coneNode)
                var heightMap = gradient.createHeightMap4(from: transformedVertices, resolutionX: 80, resolutionZ: 80)

                print("start")
                print(heightMap)
          //      print("fill nan values")
         //       gradient.fillNaNWithClosest(heightMap: &heightMap)
           //     print(heightMap)
               // print(gradient.createHeightMap(from: geom ?? geom1, resolutionX: 128, resolutionZ: 128))
                print("done")
            }
        }
       //print(gaussMethod.smoothPointCloud(from: (scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.geometry)!))
      //  print(gaussMethod.smoothPointCloud(from: testShape))
       // let clouds = gaussMethod.smoothPointCloud(from: (scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.geometry)!)
        //let smoothedCloud = clouds//.smoothed
       // let transientCloud = clouds.transient
      //  print(smoothedCloud)
        print("gaussian")
      //  print(transientCloud)
        //might need to buffer the edges** like with image processing to ensure that those on the ends arent affected by not having nearby pointslet xAxis = SCNCylinder(radius: 0.001, height: 1)
       // print(gaussMethod.averageValues(closestPoints: points, inputPoint: point1))
       // print(gaussMethod.addNewAverage(inputPoint: point1, originalPointCloud: points, currentSmoothed: [], k: 3))
        //edge case: k > length of pointcloud
       // vertices = extractVertices(from: (scene?.rootNode.childNode(withName: modelName ?? "Mesh", recursively: true)?.geometry)!)
        
        


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
      //  print("check", vertices)
    
       // kernel = smoothedModel.generateKernel(kernelSize: 3, sigma: 0.5)
        
        setFilters()
        originalHeightMap = [[nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.04802431, 0.053461123, 0.053011194, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.049379926, 0.043913674, nan, 0.04274778, 0.03990271, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.048613973, 0.0456087, 0.046487067, 0.04357325, 0.04236363, 0.04361993, 0.0362085, 0.032990046, nan, 0.025829725, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.04735134, 0.045613475, 0.045897882, 0.043105256, 0.038871657, nan, 0.03717555, nan, 0.028285366, nan, 0.023127545, nan, 0.014230803, 0.01105066, 0.009841621, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.046096787, 0.046019126, 0.04572118, 0.03560672, 0.037184, 0.035729, 0.030736327, nan, 0.027186558, nan, nan, 0.017688107, 0.017907098, 0.012345672, 0.010788571, 0.008524563, 0.008326579, 0.009127479, 0.009165216, 0.009595867, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.044239923, 0.04185079, 0.043861892, 0.040244646, 0.03669828, nan, nan, 0.028530337, nan, 0.019682981, 0.014115978, 0.017871946, 0.0120520145, 0.013180174, 0.010213323, 0.00830926, 0.008734975, 0.008255828, 0.008437797, 0.009067275, 0.008849677, 0.009270377, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.043519948, 0.044476643, 0.044593517, 0.04298456, 0.036770444, nan, 0.030615706, nan, 0.021376401, 0.016202718, 0.011921141, nan, 0.009181995, 0.012670398, 0.010570221, 0.008050725, 0.00786674, 0.007700883, 0.008161511, 0.008639246, 0.008661959, 0.009144444, 0.009125881, 0.009190865, 0.009580795, 0.009637501, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.04231441, 0.043666977, 0.039523922, 0.034751788, 0.032081574, 0.024949558, nan, 0.018087909, nan, 0.013803132, 0.009677205, nan, 0.007992536, 0.0067648366, 0.0075607076, 0.0070923604, 0.0071804, 0.0074926205, 0.0073463395, 0.007481411, 0.008772414, 0.009206358, 0.008974083, 0.00864204, 0.0085840225, 0.009189438, 0.009707686, 0.009822525, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.03906653, 0.040425126, 0.038649358, nan, 0.023556251, 0.016589519, 0.014766261, nan, 0.01089165, 0.0110560395, 0.007980414, 0.0067872703, 0.007023588, 0.0063353814, 0.006789416, 0.0067169964, 0.006918609, 0.0067925565, 0.0072068125, 0.006964244, 0.0073406845, 0.008045901, 0.007859126, 0.007684715, 0.008454431, 0.0087150745, 0.00864663, 0.008965615, 0.009920284, 0.009952921, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.038682662, 0.037421044, nan, 0.02712202, nan, nan, 0.012724936, 0.012540229, 0.009794313, 0.006587222, 0.0070879906, 0.005470142, 0.00624647, 0.005991578, 0.0064703003, 0.006300036, 0.006658882, 0.0065004565, 0.006745737, 0.006696023, 0.0071275607, 0.0073691905, 0.007472925, 0.007850211, 0.0077692494, 0.007907253, 0.0086441785, 0.008995902, 0.009430852, 0.0095679425, 0.009827152, 0.009977613, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.03776358, 0.037060637, 0.035568647, 0.028681003, 0.01595654, nan, 0.013853498, 0.008003049, 0.0071389563, 0.009078056, 0.006256249, 0.0048782006, 0.005332317, 0.0057618134, 0.00597959, 0.006257754, 0.0058911443, 0.0060298555, 0.0074150935, 0.007101886, 0.0067329593, 0.0070547983, 0.0071531944, 0.0075879395, 0.0073019788, 0.007409293, 0.007957604, 0.008221272, 0.008654449, 0.008581694, 0.008936964, 0.009396397, 0.010203715, 0.010112848, 0.010118663, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.035547845, 0.034758106, 0.032390192, 0.026472338, 0.016754601, nan, 0.009173427, 0.006203864, 0.0049202517, 0.005112443, 0.004033923, 0.0044154823, 0.0052219518, 0.00563512, 0.0056105703, 0.0057660677, 0.005895816, 0.006672442, 0.0070915297, 0.006916832, 0.0075738803, 0.006924089, 0.0067864805, 0.007222932, 0.007301748, 0.0074053556, 0.007404268, 0.0078785755, 0.008523464, 0.0086105615, 0.008624658, 0.008824203, 0.009692594, 0.01008185, 0.010432851, 0.010109901, 0.009351902, 0.009174366, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.038733907, 0.038006056, 0.029806081, 0.026124876, 0.020313207, 0.015816074, 0.011954971, 0.009534497, 0.0056639947, 0.0042349733, 0.004091166, 0.004348729, 0.0042143725, 0.0044008344, 0.005157035, 0.0053712465, nan, 0.00589462, 0.0059965923, 0.0064699873, 0.006885696, 0.0065993927, 0.006611608, 0.0066737123, 0.0065824687, 0.0069864206, 0.0076802224, 0.0072924756, 0.007917758, 0.0079653375, 0.008202344, 0.008047469, 0.008407142, 0.008679941, 0.008998759, 0.009770524, 0.010223322, 0.009408053, 0.010344107, 0.010145921, 0.009677079, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.039751984, 0.038506452, 0.029067095, 0.020853959, nan, 0.014499031, nan, 0.011107713, 0.0060777254, 0.0046969056, 0.0041500926, 0.004444897, 0.004188679, nan, 0.004943799, 0.004666485, 0.005634755, 0.005932022, 0.0062452145, 0.0055913143, 0.0055773444, 0.005966764, 0.0060843267, 0.006657969, 0.0068856366, 0.0069124624, 0.0076047815, 0.008810621, 0.009058725, 0.009191148, 0.008719318, 0.008715831, 0.008229349, 0.007936832, 0.008478306, 0.008660872, 0.008693058, 0.008821759, 0.009873293, 0.010584388, 0.011145823, 0.011201892, 0.010835171, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.037977286, 0.03514699, 0.02400956, 0.015980303, nan, 0.012165949, 0.010426201, 0.009588152, 0.0076988786, 0.0059134737, 0.004230205, 0.004447419, 0.004376564, 0.0043621995, 0.004874911, 0.0048297755, 0.004602857, 0.005415786, 0.005840592, 0.0051925443, 0.0052430667, 0.0057271607, 0.0061187036, 0.00642813, 0.0067091323, 0.0066637024, 0.006939765, 0.0072273277, 0.009291984, 0.009564057, 0.010624673, 0.010744173, 0.009926822, 0.008678965, 0.008728731, 0.0088194795, 0.009358499, 0.009333074, 0.009053998, 0.009236135, 0.01019245, 0.010735817, 0.01112359, 0.010789905, 0.010824442, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.039708447, 0.038299873, 0.019935507, 0.017797168, 0.011329304, 0.008959081, nan, 0.00682541, 0.0051611066, 0.0043624863, 0.004178595, 0.004266806, 0.0042384975, 0.0042833015, 0.004363943, 0.0048736967, 0.0048605837, 0.00505019, 0.0053518005, 0.0057360716, 0.005580917, 0.0054220706, 0.0055289976, 0.0061194636, 0.00682744, 0.0069994256, 0.0072919466, 0.0070337504, 0.008221701, 0.009976048, 0.011177432, 0.012205996, 0.011994813, 0.010857556, 0.010872673, 0.009562019, 0.008751884, 0.0084301755, 0.009101432, 0.008853953, 0.008808773, 0.008985344, 0.009752993, 0.010096088, 0.01057104, 0.01090423, 0.011053581, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.037050035, 0.036279116, 0.022892576, 0.015664645, 0.011704054, 0.0068658404, 0.0037626736, 0.0033854805, 0.0027927868, 0.003489226, 0.0037670992, 0.0039888658, 0.003973745, 0.0041802786, 0.0045636445, 0.0051636286, 0.005402833, 0.0060290247, 0.006373115, 0.0070075914, 0.0076491497, 0.007589437, 0.006483998, 0.0063663535, 0.006769456, 0.007118322, 0.008042019, 0.008747857, 0.00917365, 0.009835154, 0.011748064, 0.012520626, 0.012662452, 0.013343159, 0.013854582, 0.012986988, 0.012066036, 0.0099301, 0.00941544, 0.008717656, 0.009200916, 0.008990828, 0.008994445, 0.009433728, 0.009590194, 0.009935293, 0.01042445, 0.011129841, 0.011388615, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.038216442, 0.026835244, 0.018127613, 0.011300217, 0.009145662, 0.0058602355, 0.0050335824, 0.0028691404, 0.002638232, 0.0028998181, 0.0038334094, 0.003935732, 0.0036067627, 0.0035585202, 0.0043268315, 0.0049800724, 0.0062662363, 0.0067615695, 0.006916359, 0.006957013, 0.0068617724, 0.007973239, 0.008469146, 0.008662086, 0.0073123053, 0.008749984, 0.009310711, 0.009398494, 0.010274574, nan, 0.011823967, 0.012696587, 0.012757834, 0.013213545, 0.0136746615, 0.014091991, 0.014000855, 0.013233203, 0.012014762, 0.010367893, 0.009120051, 0.008770838, 0.008910928, 0.008889351, 0.009392329, 0.00981224, 0.0100959465, 0.01003778, 0.010177627, 0.011576399, 0.011838235, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, 0.035588786, 0.036405295, 0.03543052, 0.016043037, 0.013070479, 0.0063373074, 0.0068555996, 0.0052038506, 0.0038359798, 0.0025366917, 0.0027249902, 0.0028603487, 0.002899088, 0.0032052658, 0.0042353235, 0.004192423, 0.0051245503, 0.0063270926, 0.0075157136, 0.007814452, 0.009182278, 0.00863469, 0.009381101, nan, 0.00875511, 0.009452004, 0.009821132, 0.010319747, 0.010371175, 0.011009119, 0.011421379, 0.011721011, 0.012212135, 0.012686685, 0.013388731, 0.013269249, 0.013954442, 0.013976019, 0.014008746, 0.013933804, 0.013387177, 0.012017988, 0.010712162, 0.009214658, 0.008698069, 0.008831758, 0.009308182, 0.009421188, 0.009115789, 0.009606432, 0.01032982, 0.010503732, 0.011900496, 0.012040298, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, 0.03262376, 0.033475272, 0.02290909, 0.013839051, 0.0102310255, 0.0047535487, 0.003117714, 0.002969049, 0.0021712221, 0.0023251995, 0.00253129, 0.002405826, 0.0027645715, 0.0031596534, 0.00391113, 0.0042601414, 0.0050458983, 0.0073627867, 0.008182708, nan, 0.00867299, 0.009497702, 0.010264315, 0.010026768, 0.0099397935, 0.009470724, 0.010133542, 0.009642888, 0.00982083, 0.010455959, 0.011586685, 0.012198769, 0.012260351, 0.011977695, 0.012152977, 0.013184063, 0.014155097, 0.015118983, 0.015154928, 0.014320888, nan, 0.014168255, 0.012990084, 0.011969566, 0.011695538, 0.01147709, 0.010363575, 0.010807194, 0.009551823, 0.00956133, 0.009579867, 0.010379761, 0.010701157, 0.011196811, 0.0120943785, 0.012164276, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, 0.033106856, 0.026996434, 0.017131448, 0.008522831, 0.007422745, nan, 0.0031375773, 0.0025755465, nan, 0.0025826395, 0.0031890012, 0.002770923, 0.0031732358, 0.0037171133, 0.004699249, 0.0051025786, nan, 0.007458739, 0.009176377, 0.008891575, 0.010349389, 0.011776693, 0.010783881, 0.011078961, 0.010797307, 0.010125488, 0.009824637, 0.009548634, 0.009933509, 0.011587851, 0.013469171, 0.015168268, 0.01333065, 0.013236191, 0.014003359, 0.013052676, 0.013823688, 0.014907248, 0.015704669, 0.015372857, 0.014197499, 0.014036309, 0.013100229, 0.012083083, 0.012513008, 0.013215687, 0.011858083, 0.012311127, 0.011504643, 0.0109370835, 0.010323495, 0.010257825, 0.010421727, 0.010738995, 0.011012219, 0.012173161, 0.012181941, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, 0.03293442, 0.031195402, 0.01784885, 0.01556997, 0.009134106, 0.0060854107, 0.0039914995, nan, 0.0031281225, 0.0027029142, 0.0027977526, 0.0033063479, 0.0033914223, 0.002628971, 0.004492022, 0.00500736, 0.0056216307, 0.008580461, 0.008733958, 0.00917685, 0.011198606, 0.011334792, 0.012008119, 0.012126721, 0.011933856, 0.011830278, 0.011566136, 0.011443935, 0.0118637085, 0.0117674135, 0.012109898, 0.013599504, 0.0149287395, 0.014810156, 0.014522113, 0.014043234, 0.013284229, 0.012835346, 0.013986286, 0.014489472, 0.014643326, 0.014217913, 0.01472472, 0.014068436, 0.013383981, 0.013245173, 0.01469966, 0.014801636, 0.01453796, 0.013013672, 0.012764815, 0.01141635, 0.011776172, 0.01165387, 0.011121627, 0.01091354, 0.011548866, 0.0124243945, 0.012443915, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, 0.03194882, 0.027859598, 0.019340232, nan, 0.011930682, nan, 0.0065961555, nan, 0.0035271272, nan, 0.0033757277, 0.0025945455, 0.0025612637, 0.0031661913, 0.0036575086, 0.004194569, 0.0050424, 0.00666349, 0.008628525, 0.009697981, 0.009626452, 0.010465559, 0.010621391, 0.010852423, 0.012531593, 0.012800515, 0.012382012, 0.00948168, 0.011352718, 0.011519149, 0.012277763, 0.012591142, 0.013179436, 0.014576606, 0.013872337, 0.012568384, 0.013343662, 0.013128545, 0.013909046, 0.013343815, 0.01273144, 0.01179973, 0.013490286, 0.014297359, 0.014277026, 0.014953196, 0.015244115, 0.015325289, 0.015587546, 0.015118692, 0.014150444, 0.013146613, 0.012190342, 0.01368406, 0.014122214, 0.013717484, 0.013639402, 0.014051922, 0.012833215, 0.013239, 0.013707668, 0.01388244, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, 0.031375803, 0.03156563, nan, 0.015055336, 0.010662131, 0.008265883, 0.005480066, 0.00486527, 0.004171971, 0.003979925, 0.0040673837, 0.0035412721, 0.0022305213, 0.0021360405, 0.0026504397, 0.0035583563, 0.0044030547, 0.005232226, 0.007945351, nan, 0.010455839, 0.012419026, 0.013747379, 0.011731174, 0.012232967, 0.012580402, 0.01254927, 0.012052339, 0.010354586, 0.008840494, 0.009895861, 0.012851905, 0.014062762, 0.013895359, 0.01476565, 0.0142795965, 0.013411976, 0.013690688, 0.012953948, 0.012920249, 0.01283624, 0.010902721, 0.0114830285, 0.0137411915, 0.013861597, 0.014865711, 0.014861502, 0.01503402, 0.015240025, 0.015097175, 0.014062464, 0.013829283, 0.011717573, 0.012404591, 0.013958547, 0.015855018, 0.015470736, 0.015853569, 0.015630841, 0.01607395, 0.0145181045, 0.015412498, 0.01406879, 0.012946568, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, 0.030796193, 0.018636964, 0.010715723, 0.0070310384, 0.00449086, 0.0036968738, 0.0025679022, nan, 0.0034427345, 0.0028856434, 0.0024217628, 0.0018975586, nan, 0.002300728, 0.002361223, 0.002947688, nan, 0.0066649243, 0.009221308, 0.010327011, 0.011204898, 0.012433544, 0.013489332, 0.012615208, 0.012477014, 0.012517527, 0.012922209, 0.011404082, 0.009474687, 0.008638255, 0.010195728, 0.012375303, 0.013251137, 0.013851251, 0.013176985, 0.013513036, 0.012667939, 0.0125400685, 0.011406168, 0.01190025, 0.012147721, 0.011587262, 0.012371898, 0.013417847, 0.014668405, 0.015006449, 0.015745059, 0.015011795, 0.014683716, 0.014691729, 0.013686519, 0.011990737, 0.01153506, 0.013368115, 0.014558926, 0.016274504, 0.016331028, 0.016415387, 0.017148707, 0.017423153, 0.016828425, 0.016323108, 0.015266102, 0.013205379, 0.012882106, 0.013303023, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, 0.030617602, 0.012415282, 0.008699402, 0.00456091, 0.003003709, 0.0015470907, 0.0013872758, 0.0013318881, 0.0011034235, 0.001410868, 0.0012689792, 0.0019286908, 0.0018323958, 0.002662018, 0.0027263612, 0.004024796, 0.0044959113, 0.0049762838, 0.007257849, 0.011484649, 0.012104932, 0.011113107, 0.01211445, 0.012063354, 0.011309799, 0.011244178, 0.012587186, 0.012628727, 0.010792825, 0.008597415, 0.010728385, 0.011320204, 0.0129995495, 0.01338153, 0.01258526, 0.012985434, 0.012357093, 0.012948167, 0.012307361, 0.011650167, 0.012645986, 0.012282539, 0.011868726, 0.011967268, 0.012046006, 0.015221439, 0.015509319, 0.016231611, 0.016339067, 0.016257383, 0.015825372, 0.014280643, 0.012463745, 0.012045894, 0.013015311, 0.0161317, 0.016778536, 0.016948827, 0.016804975, 0.016776834, 0.01592857, 0.016499866, 0.016430527, 0.014976084, 0.012976989, 0.012355857, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, 0.030438878, 0.023028344, 0.01297681, 0.006399438, 0.0031334236, 0.0009139031, nan, 0.0010895953, 0.0009292364, 0.0013399906, 0.0021949634, 0.002637025, 0.0019953288, 0.0034920238, 0.0033592544, 0.006184906, 0.0064052865, 0.0052680895, 0.0054051504, 0.005750153, 0.010501035, 0.011815887, 0.0111193955, 0.009689778, 0.010007024, 0.009275064, 0.009765804, 0.009260055, 0.009135023, 0.009458136, 0.008891068, 0.010320429, 0.011922538, 0.010800466, 0.012703627, 0.012670353, 0.012512416, 0.01237385, 0.013565525, 0.012949716, 0.012638543, 0.011008937, 0.010837104, 0.010438375, 0.010376599, 0.011928637, 0.014452141, 0.015691064, 0.016182862, 0.016269907, 0.016589377, 0.015572377, 0.0136685185, 0.013811469, 0.012652423, 0.014034659, 0.015774459, 0.01733987, 0.017791167, 0.017537512, 0.01696669, 0.01626753, 0.014858644, 0.013606057, 0.01351507, 0.013135627, 0.012622073, 0.012686031, 0.01351556, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [0.029266141, 0.025527641, 0.01383096, 0.0056826845, 0.0022286698, 0.0012145266, 0.0015609488, 0.0018323511, 0.003693357, 0.0027774647, 0.0043875873, 0.0036085732, nan, 0.0038938224, 0.005183134, 0.007475883, 0.0078082234, 0.008667409, 0.008221608, 0.008727737, 0.008153111, 0.0082268715, 0.00963036, 0.01166667, 0.011896744, 0.011276718, 0.011253748, 0.009172581, 0.008281693, 0.008011803, 0.0075213835, 0.0074879006, 0.00828965, 0.011422683, 0.011789702, 0.013508659, 0.013810921, 0.011865474, 0.012142219, 0.011817381, 0.011865102, 0.012188122, 0.010720689, 0.010524895, 0.009787206, 0.009450227, 0.010803703, 0.01520583, 0.015969682, 0.0160847, 0.015776709, 0.01566602, 0.015837487, 0.013363089, 0.012991652, 0.0132793635, 0.014573321, 0.017015018, 0.017069228, 0.017088044, 0.01734544, 0.01690448, 0.015547477, 0.013624147, 0.012819782, 0.015188538, 0.014853239, 0.014984004, 0.014332255, 0.014278632, 0.01446422, nan, nan, nan, nan, nan, nan, nan, nan, nan], [0.029461108, 0.010922708, nan, 0.006101683, 0.0029769912, 0.0011198595, 0.0030930713, 0.003500715, 0.004528776, 0.006333217, 0.0060811043, 0.0062231906, 0.006542053, 0.008940455, 0.009752646, 0.009748243, 0.010090448, 0.010190636, 0.009674963, 0.009974338, 0.009639863, 0.0079954825, 0.009880085, 0.011546183, 0.0117711425, 0.012328126, 0.012381252, 0.010594744, 0.01176054, 0.011533711, 0.009908013, 0.009448912, 0.010465208, 0.011709157, 0.011940304, 0.013953056, 0.014556851, 0.011327613, 0.010120101, 0.011920679, 0.013062108, 0.013665356, 0.0113810375, 0.010713078, 0.010779072, 0.010212727, 0.010990974, 0.0145100355, 0.016139098, 0.016324718, 0.015729409, 0.014601402, 0.014402758, 0.013554264, 0.013355732, 0.014447801, nan, 0.01641925, 0.016446516, 0.016532369, 0.016765792, 0.016736291, 0.016272712, 0.015799806, 0.01577067, 0.016862366, 0.016728014, 0.0162513, 0.016983395, 0.016506787, 0.016379422, 0.014812695, nan, nan, nan, nan, nan, nan, nan, nan], [0.02952052, 0.0091623515, 0.004520215, 0.0029673055, 0.002177097, 0.0018894449, 0.003952205, 0.0052591935, 0.006378174, 0.0067998916, 0.007754281, 0.007245466, 0.009825274, 0.010004275, 0.009737711, 0.009493411, 0.01001887, 0.010787811, 0.0108776875, 0.010030635, 0.010034189, 0.008493252, 0.009782463, 0.010201748, 0.010911543, 0.012097493, 0.012284741, 0.011844862, 0.011750337, 0.012000486, 0.011342015, 0.010077603, 0.010116827, 0.011028122, 0.012172867, 0.012990288, 0.013021793, 0.012544375, 0.011844873, 0.011784427, 0.013360366, 0.01365982, 0.012243468, 0.011376131, 0.0133485235, 0.012674879, 0.012321975, 0.012839802, 0.013879057, 0.014777739, 0.014817938, 0.014758959, 0.015135147, 0.014817294, 0.0140175, 0.014901735, 0.01587934, 0.016005684, 0.016731158, 0.01681858, 0.016789079, 0.016570203, 0.016430903, 0.01610924, 0.015542593, 0.016854655, 0.017221965, 0.017100181, 0.017210133, 0.018262783, 0.018117208, 0.01754292, 0.0146464, nan, nan, nan, nan, nan, nan, nan], [0.033570223, 0.0058583245, 0.001823239, 0.0023696348, 0.002243258, 0.0025863126, nan, 0.00554692, 0.0063169748, 0.008447267, 0.00873087, 0.008829117, 0.010521211, 0.009816464, 0.010282949, 0.010154214, 0.0112400055, 0.011862062, 0.010673322, 0.010724351, 0.010729879, 0.0098208375, 0.009225503, 0.010939058, 0.011836059, 0.012085091, 0.012588218, 0.014590815, 0.014781866, 0.01359532, 0.013519958, 0.013177026, 0.011234768, 0.010329753, 0.010147862, 0.010055259, 0.011788465, 0.0135306455, 0.012195326, 0.012770705, 0.012911465, 0.0125895925, 0.012233019, 0.013061333, 0.014235672, 0.013309374, 0.013662785, 0.013668027, 0.013057925, 0.013685472, 0.015542608, 0.015837021, 0.01599859, 0.016319308, 0.015836522, 0.016086098, 0.016237304, 0.015797887, 0.01607987, 0.01655412, 0.016629752, 0.016229976, 0.016116261, 0.015311938, 0.014701698, 0.016715996, 0.017112032, 0.017442245, 0.016929613, 0.017497163, 0.017422087, 0.017027767, 0.015289778, 0.013339341, nan, nan, nan, nan, nan, nan], [0.035231486, 0.0030760542, 0.0014117286, 0.0006327182, 3.4056604e-05, 0.002200909, 0.004475087, nan, 0.006431639, 0.007125955, 0.0075583346, 0.009013325, 0.010200396, 0.010861527, 0.01065791, 0.009998165, 0.010358423, 0.011007335, 0.010807499, 0.010227717, 0.011083696, 0.010244269, 0.009899341, 0.01131916, 0.011869889, 0.012420461, 0.012547161, 0.015181754, 0.014568072, 0.014064264, 0.01302043, 0.014009383, 0.013120372, 0.013022695, 0.011423029, 0.010056242, 0.009964254, 0.010626279, 0.012328904, 0.012434404, 0.013616074, 0.0136807, 0.012953032, 0.013061486, 0.013756946, 0.01202257, 0.014351267, 0.0150625, 0.014746051, 0.012957636, 0.014662471, 0.015296239, 0.015542418, 0.016163424, 0.015231028, 0.015054025, 0.014775336, 0.01514522, 0.015027113, 0.014978074, 0.015304726, 0.015217587, 0.015003562, 0.015139371, 0.016010724, 0.017559681, 0.018360239, 0.017567813, 0.015897833, 0.015162922, 0.015124483, 0.0141605735, 0.013952678, 0.012780078, nan, nan, nan, nan, nan, nan], [0.037225097, 0.004017286, 0.0019636154, 0.00020062923, -0.00030571967, 0.00077376515, 0.0023942888, 0.0046223924, 0.008220926, 0.008424301, 0.009011336, 0.008886345, 0.0090074465, 0.009958148, 0.0103548765, 0.010564156, 0.0097645, 0.01017027, 0.009872753, 0.010926455, 0.011369221, nan, 0.010795802, 0.010490738, 0.010755014, 0.011258431, 0.0120556615, 0.015232753, 0.015479334, 0.014951795, 0.014120191, 0.014856074, 0.014745086, 0.013789564, 0.013371997, 0.011548363, 0.011560086, 0.01379538, 0.015315574, 0.015638463, 0.015971433, 0.013619103, 0.0147086345, 0.015036449, 0.015438147, 0.013319414, 0.013917666, 0.014095586, 0.014297906, 0.013562918, 0.014675457, 0.014835145, 0.015722178, 0.0149209425, 0.015116446, 0.014957812, 0.013594881, 0.01426512, 0.013970558, 0.014655188, 0.014226388, 0.015547257, 0.015960991, 0.015183359, 0.016047776, 0.017601456, 0.018555481, 0.018381856, 0.015982196, 0.014136994, 0.014053773, 0.014402954, 0.013895748, 0.012707859, 0.011708535, 0.010537934, nan, nan, nan, nan], [0.04026614, 0.0052688494, nan, 0.0015132874, -0.00051050633, 0.00024630874, 0.0025494993, nan, 0.0062245205, 0.007022906, 0.007876318, 0.008843217, 0.008524116, 0.009112269, 0.010573685, 0.010508269, 0.008710049, 0.008724287, 0.0091995895, 0.011543829, 0.01175385, 0.010747485, 0.011004906, 0.009934362, 0.010060448, 0.011032082, 0.012359157, 0.012625918, 0.013908066, 0.013875227, 0.0126632005, 0.012241181, 0.014083892, 0.013748247, 0.012934707, 0.012597229, 0.011789583, 0.013765749, 0.016283989, 0.016738757, 0.015348036, 0.014768608, 0.015279673, 0.015248504, 0.015405979, 0.01509545, 0.0147767775, 0.015481707, 0.016248677, 0.015856702, 0.015426446, 0.015881851, 0.015554402, 0.015141249, 0.015611023, 0.014961135, 0.013950951, 0.0133422315, 0.0129328035, 0.013230637, 0.015717454, 0.017585844, 0.01702882, 0.01689633, 0.017257653, 0.018508643, 0.018813655, 0.017949782, 0.016849633, 0.016114634, 0.0145755075, 0.016412828, 0.0151608065, 0.01432666, nan, 0.011187635, nan, nan, nan, nan], [0.043146513, 0.009404048, 0.0036667585, 0.0029222965, 0.0008659288, -0.00012027472, 0.00082570314, 0.0047997013, 0.0057915524, 0.006476935, 0.0068504177, 0.00834452, 0.008971788, 0.008411124, 0.009729683, 0.009665921, 0.009747855, 0.009889692, 0.009867761, 0.0103357285, 0.00973323, 0.009927586, 0.010820426, 0.010718137, 0.009219784, 0.010438617, 0.010311935, 0.010953233, 0.010545142, 0.0112809725, 0.012036182, 0.012117647, 0.01276977, 0.013238236, 0.013568524, 0.013718978, 0.015194632, 0.0131391585, 0.013532352, 0.014061224, 0.014645837, 0.016119305, 0.01667367, 0.015433844, 0.014623407, 0.014746092, 0.01430928, 0.014845904, 0.01668686, 0.017016765, 0.017841123, 0.017502613, 0.016963236, 0.015152015, 0.015648067, 0.015749961, 0.0148477, 0.015236996, 0.014786422, 0.014633667, 0.016128, 0.016955018, 0.01699723, 0.016896524, 0.018078662, 0.01791218, 0.018389031, 0.017138664, 0.017450597, 0.01707541, 0.018600402, 0.018570634, 0.017058048, 0.015295973, 0.014022777, 0.013912026, 0.012124794, nan, nan, nan], [0.047487997, 0.013231695, 0.0075192302, nan, 0.0014487728, -0.00018407404, -0.00019673258, 0.0011936054, 0.0031885207, 0.004678428, 0.00620088, 0.0071840696, 0.008294284, 0.008131381, 0.009055596, 0.009637363, 0.00996929, 0.00924775, 0.009740535, 0.010017242, 0.010434516, 0.00934666, 0.010373928, 0.009616114, 0.009445511, 0.009965859, 0.009938538, 0.009552196, 0.010738917, 0.010711905, 0.011479545, 0.010613345, 0.010271233, 0.010935441, 0.014163066, 0.015127331, 0.016858306, 0.016220372, 0.013577186, 0.013599362, 0.014327597, 0.015318919, 0.01585389, 0.01467251, 0.013963196, 0.015050288, 0.015934296, 0.014746133, 0.01559826, 0.01612496, 0.017822418, 0.017899044, 0.017353013, 0.016530354, 0.016814988, 0.016530842, 0.015592031, 0.015777692, 0.016002387, 0.01642713, 0.017002635, 0.017498907, 0.017875098, 0.018235844, 0.017984048, 0.017225187, 0.016265474, 0.01697566, 0.01808227, 0.017931346, 0.018910049, 0.018659085, 0.01799316, 0.015758427, nan, 0.014748329, 0.014145181, nan, nan, nan], [0.04977069, 0.011420935, 0.007473044, nan, 0.0009572357, -1.5057623e-05, -0.00020923465, 0.0001982227, 0.0012112334, 0.0029566437, 0.0043844096, 0.0058883913, 0.0076591223, 0.008273341, 0.009085052, 0.009174585, 0.008958623, 0.007727083, 0.008194882, 0.008736845, 0.008963946, 0.008831654, 0.008046281, 0.0080398545, 0.00980255, 0.010231879, 0.010151304, 0.009602029, 0.009457894, 0.010924038, 0.011712663, 0.0112554245, 0.012042247, 0.0123598315, 0.012209032, 0.014600828, 0.016315248, 0.0152485445, 0.012472935, 0.0133267045, 0.012664296, 0.013808966, 0.012338586, 0.014124475, 0.013241798, 0.01600689, 0.01699967, 0.01563494, 0.015425049, 0.015960436, 0.018374786, 0.018638968, 0.017251536, 0.016589385, 0.01610823, 0.015393652, 0.015324175, 0.01564145, 0.016661182, 0.017054953, 0.017433528, 0.017963499, 0.01732596, 0.017601341, 0.017034601, 0.016595855, 0.015290163, 0.016800966, 0.016869742, 0.018163722, 0.017981289, 0.018023256, 0.016512843, 0.016321443, 0.015763506, 0.015489958, 0.012923086, nan, nan, nan], [0.051277988, 0.01166337, 0.0056622103, 0.0026844442, 0.0006363541, -2.2880733e-05, -0.00040560216, 0.00022158027, 0.0008361861, 0.0023992807, 0.0045045763, 0.004816491, 0.0068058744, 0.007757634, 0.009530127, 0.0071506537, 0.0076391734, 0.007630799, 0.008837678, 0.0090299025, 0.009760693, 0.0092778355, 0.008862, 0.008654021, 0.0077405833, 0.008454263, 0.008121137, 0.008871283, 0.00912388, 0.009879593, 0.0110030025, 0.011559758, 0.012699299, 0.012707435, 0.012920339, 0.013303809, 0.014009271, 0.014658015, 0.013280209, 0.012241129, 0.012873445, 0.01080595, 0.011917688, 0.013485413, 0.014887817, 0.014739923, 0.014192618, 0.01558847, 0.016596727, 0.016313434, 0.018385448, 0.018700592, 0.01608571, 0.01536449, 0.01333734, 0.0149455145, 0.01499062, 0.015122566, 0.015510291, 0.016655013, 0.01745538, 0.017906412, 0.017332625, 0.017109837, 0.017235838, 0.016603589, 0.015860759, 0.015901893, 0.016050676, 0.015551239, 0.015816662, 0.015429366, 0.015637033, 0.015677951, 0.015674623, 0.014707642, 0.013077682, nan, nan, nan], [0.05447752, 0.008776858, 0.00345622, 0.0010800734, nan, -8.08388e-06, -0.00010617077, 0.0007144436, 0.0018819869, 0.004621662, 0.0059068277, 0.0059208646, 0.005408276, 0.0067772754, 0.007521365, 0.007721603, 0.0067652725, 0.007564567, 0.007932421, 0.008265357, 0.008080225, 0.009451095, 0.009740844, 0.008416392, 0.007703811, 0.008561034, 0.008388221, 0.0074264333, 0.008124113, 0.009434849, 0.009174705, 0.011800818, 0.012454014, 0.013006471, 0.013650671, 0.014556345, 0.014254019, 0.015715946, 0.01588751, 0.01452079, 0.015238892, 0.013028499, 0.013862602, 0.0135345645, 0.0144151375, 0.014085025, 0.0137987025, 0.01537675, 0.01602823, 0.0184105, 0.017914899, 0.016091228, 0.015191797, 0.0145638175, 0.014042299, 0.013407394, 0.014016684, 0.013685379, 0.014553845, 0.015511919, 0.017382752, 0.017584972, 0.016738158, 0.01682524, 0.016832624, 0.016738117, 0.016425554, 0.0165417, 0.01645597, nan, 0.015049849, 0.014098486, 0.0144716, 0.015081717, 0.015221041, 0.015028309, 0.0129444245, nan, nan, nan], [0.06147355, 0.006253667, 0.003170155, 0.00097148865, nan, 0.00037184358, 0.00019189715, 0.0013855919, 0.0033667013, nan, 0.0064829066, 0.006633103, 0.0075533986, 0.007653903, 0.008376837, 0.007985365, 0.007783603, 0.008215938, 0.008285433, 0.008536398, 0.009718325, 0.009955745, 0.009783246, 0.008590829, 0.0065862425, 0.0075635538, 0.00724151, 0.007495858, 0.008444682, 0.010379255, 0.009680912, 0.011265684, 0.012877263, 0.013543721, 0.013377838, 0.013394315, 0.012909509, 0.016020764, 0.01581645, 0.015403934, 0.015416738, 0.014438216, 0.014546096, 0.014161546, 0.014724925, 0.014568817, 0.014379039, 0.015221924, 0.01651857, 0.017793752, 0.01623673, 0.014997415, 0.015137143, 0.0153904, 0.014558803, 0.013653874, 0.013473421, 0.014161721, 0.015887737, 0.016097367, 0.015789878, 0.016515724, 0.018320382, 0.017343462, 0.016685836, 0.017089434, 0.016909018, 0.017332241, 0.017100308, 0.016269127, 0.014483508, 0.014271747, 0.014499042, 0.014968708, 0.014959792, 0.014616627, 0.01374392, nan, nan, nan], [0.057629846, 0.014256485, 0.0048784167, nan, 0.00065760314, -3.9227307e-05, -0.0004825443, 0.0008934662, 0.002969578, 0.0052473843, 0.006572392, 0.0065529384, 0.0076276585, 0.008169226, 0.007616546, 0.009449452, 0.010413997, 0.008560389, 0.009308726, 0.009504013, 0.010156151, 0.010232627, 0.009704679, nan, 0.00724753, 0.0060715266, 0.0060065016, 0.008816801, 0.009518344, 0.011007965, 0.009396512, 0.010362286, 0.012495808, 0.011598382, 0.011007916, 0.013727985, 0.014370777, 0.012331124, 0.0142148025, 0.014738727, 0.014722947, 0.014754668, 0.013735145, 0.013992947, 0.015048716, 0.016282193, 0.016258176, 0.01712602, 0.018116385, 0.01783707, 0.016297657, 0.014791176, 0.015386093, 0.014610864, 0.013643343, 0.013456069, 0.012614824, 0.011792619, 0.013028566, 0.013881244, 0.014514953, 0.016589362, 0.017639615, 0.017848145, 0.01849065, 0.01741365, 0.016684, 0.017460797, 0.015943479, 0.015353559, 0.014798582, 0.01438022, 0.014285237, 0.014841128, 0.014910968, 0.014979929, 0.014791818, 0.014877845, nan, nan], [nan, 0.06981845, 0.020472169, 0.004112065, 0.0024357662, 0.0002406612, -0.000105559826, 0.0015766695, 0.0039671585, 0.005152058, 0.006251335, 0.006027445, 0.0070415065, 0.0076543987, 0.00847635, 0.008516993, 0.010390587, 0.00931751, 0.008896943, 0.009095065, 0.010077469, 0.011048429, 0.010937143, 0.00982248, 0.0063068494, 0.0048454963, 0.006514054, 0.00875292, 0.00930357, 0.010178369, 0.009096213, 0.010906834, 0.011576369, 0.012574766, 0.012715902, 0.014644455, 0.014027823, 0.012475435, 0.012866419, 0.01372423, 0.015422385, 0.015350752, 0.014594093, 0.012933344, 0.014121432, 0.015817069, 0.01557802, 0.015861306, 0.017457291, 0.016989585, 0.016495392, 0.015255835, 0.015237402, 0.014595397, 0.013206691, 0.0124578215, 0.014014538, 0.013826933, 0.013672855, 0.0128831975, 0.012732055, 0.01588944, 0.016364984, 0.017652001, 0.01807684, 0.017394852, 0.01638908, 0.016300343, 0.015656456, 0.015267946, 0.015336579, 0.014374968, 0.013764592, 0.013904575, 0.0150756445, 0.015334543, 0.014787968, 0.015398743, nan, nan], [nan, 0.057461478, 0.029060185, 0.010601133, 0.0053613707, 0.0024432242, 0.0010397732, 0.0006888658, 0.002406545, 0.0036457926, 0.0054593906, 0.0058293305, 0.005500134, 0.006600566, 0.008113146, 0.008486424, 0.009778909, 0.009285122, 0.010013483, 0.009606943, 0.009673163, 0.010413278, 0.011031453, 0.010266099, 0.008881476, 0.0062640347, 0.0070502274, 0.008998331, 0.009737365, 0.01032313, 0.009228446, 0.010119591, 0.010582395, 0.011988178, 0.012842704, 0.01193393, 0.010991298, 0.012671221, 0.013832986, 0.01255554, 0.013419405, 0.013824105, 0.0136514455, 0.012544643, 0.013191398, 0.014015026, 0.013574678, 0.013166182, 0.014570996, 0.013923969, 0.014252681, 0.014441337, nan, 0.014742617, 0.014108725, 0.013734434, 0.015165567, 0.015694901, 0.015352409, 0.016808927, 0.01740285, 0.017025545, 0.01685432, 0.015652508, 0.015598305, 0.015146505, 0.015016321, 0.01477861, 0.015797377, 0.015768953, 0.0144916475, 0.01386017, 0.0145682655, 0.0143366605, 0.014834622, nan, 0.0141511485, 0.012415126, nan, nan], [nan, 0.0664341, 0.06664856, 0.020967811, 0.01614862, 0.0053339675, nan, 0.001009807, 0.001843147, 0.0020600185, 0.0011862256, 0.003728073, 0.0043795444, 0.0062526427, 0.006894529, 0.0077968277, 0.0077825226, 0.00904477, 0.008744203, 0.008978374, 0.009109728, 0.009246692, 0.010559145, 0.011088982, 0.010702848, 0.009868804, 0.009079006, 0.00966667, 0.0101514235, 0.01131333, 0.012099892, 0.012081344, 0.012246236, 0.010831494, 0.011491351, 0.011984747, 0.011987522, 0.012692682, 0.014122684, 0.011276182, 0.010118067, 0.012086961, 0.010335308, 0.0098978765, 0.009325225, 0.009917323, 0.011233721, 0.012255546, 0.013556588, 0.013855431, 0.014485415, 0.0149445385, 0.014596533, 0.015230261, 0.014537539, 0.016552262, 0.015864518, 0.014912777, 0.01585875, 0.018518493, 0.018210575, 0.016983677, 0.015822373, 0.015154753, 0.01423692, 0.015049774, 0.01383286, 0.013320837, 0.013804082, 0.014029168, 0.014366329, 0.01436683, 0.0144736525, 0.013991581, 0.013243012, 0.013636773, 0.011722803, 0.01459231, nan, nan], [nan, nan, nan, 0.06524675, 0.021208785, 0.0134730935, 0.0023202375, nan, 0.00068784505, 0.0007548146, 0.0009412691, 0.000933215, 0.001898326, 0.0045840032, 0.006662935, 0.0090455115, 0.008838601, 0.007930063, 0.008587085, 0.009317096, 0.00900998, 0.009229459, 0.010178462, 0.011674553, 0.011621956, 0.012408428, 0.011893045, 0.011124402, 0.010150913, 0.0122464895, 0.013244946, 0.012912892, 0.012537517, 0.012360245, 0.01068515, 0.011873111, 0.012085214, 0.010610372, 0.011136398, 0.0111245215, 0.010761321, 0.009191953, 0.009431876, 0.008338463, 0.00809294, 0.009280898, 0.011283759, nan, 0.0129995495, 0.013734464, 0.0142143145, 0.01403369, 0.014748987, 0.015853435, 0.0157024, 0.01744834, 0.017284364, 0.016906377, 0.016019542, 0.016587745, 0.01771428, 0.016337499, 0.014008347, 0.013044167, 0.01346527, nan, nan, 0.0125210695, 0.012915686, 0.013656149, 0.014136674, 0.014123784, 0.014007719, 0.013974322, 0.0134927705, 0.012441903, 0.011642259, 0.011180956, 0.013275161, nan], [nan, nan, nan, 0.07133467, 0.06583562, 0.016645603, 0.0107138455, nan, 0.0052056536, 0.0017911643, 0.0015363134, 0.0023836866, 0.002060555, 0.0036206841, 0.006531175, 0.008944083, 0.008955065, 0.008625962, 0.008624069, 0.008028418, 0.008592304, 0.008133613, 0.009738687, 0.010811843, 0.01202118, 0.012251291, 0.012005959, 0.011947978, 0.010497998, 0.011099979, 0.013291437, 0.012410622, 0.012243621, 0.012057051, 0.011917774, 0.01196884, 0.011523787, 0.011650216, 0.011155415, 0.011540446, 0.0117183775, 0.011807766, 0.0106121, 0.00965298, 0.008923918, 0.0104971975, 0.011477172, 0.013227906, 0.013683032, 0.013409998, 0.014034152, 0.014549769, 0.017016359, 0.016922425, 0.016063638, 0.017577294, 0.017536517, 0.017331008, 0.016088072, 0.015701625, 0.01404709, 0.013905607, 0.013712686, 0.01321971, 0.012699269, nan, 0.0123192705, 0.01277357, 0.0126308575, 0.013234399, 0.013583882, 0.013787307, 0.013766358, 0.013428975, nan, 0.01295653, 0.0127768535, 0.012092529, 0.012589779, 0.013209391], [nan, nan, nan, nan, 0.06546681, 0.05380936, nan, 0.01761517, nan, 0.002783291, 0.0027574375, nan, 0.004386287, 0.005495604, 0.0077195577, 0.009389166, 0.010714576, 0.010173049, 0.009428963, 0.009955093, 0.009581666, 0.009881955, 0.009811476, 0.010111447, 0.011834677, 0.011579156, 0.012179673, 0.011884075, 0.010730565, 0.011776127, 0.013091039, 0.012777787, 0.012816314, 0.011714391, 0.012042873, 0.010675292, 0.010676891, 0.011889368, 0.012094203, 0.013457347, 0.012350645, 0.012187459, 0.011434726, 0.010569371, 0.011371221, 0.012819104, 0.013197884, 0.013291165, 0.014588751, 0.014668863, 0.014582504, 0.015675198, 0.016498514, 0.016782008, 0.016089145, 0.016795542, 0.016960457, 0.017152712, 0.015928071, 0.0147555135, 0.013907876, 0.013828456, 0.013674822, 0.013123732, 0.012322001, 0.012337096, 0.012270838, 0.012796912, 0.012820639, 0.013394551, 0.013305567, 0.013508143, 0.013709815, 0.013832739, 0.013729528, nan, nan, nan, 0.0132907, nan], [nan, nan, nan, nan, nan, 0.057769485, 0.024957955, 0.016419388, 0.010938406, 0.0059500113, 0.00453192, 0.004208423, 0.004861649, 0.006647438, 0.0077342987, 0.008395277, 0.009910539, 0.010225046, 0.010581888, 0.010348149, 0.010029376, 0.0099247135, 0.009566098, 0.009668071, 0.010406967, 0.010992974, 0.012127802, 0.011768959, 0.011075955, 0.010716204, 0.012109004, 0.011450771, 0.012106944, 0.011855178, 0.011993963, 0.011222761, 0.011201203, 0.011686988, 0.012484096, 0.012947459, 0.012780905, 0.011533566, 0.011713166, 0.011311669, 0.012663044, 0.013230175, 0.013670638, 0.014354926, 0.014497809, 0.015883945, 0.015349995, 0.015860755, 0.0154849775, 0.01607687, 0.017907843, 0.01706091, 0.01582421, 0.013687603, 0.01279597, 0.012360118, 0.013070151, 0.013520956, 0.012980022, 0.012533095, 0.011657916, 0.011592694, nan, 0.012696754, 0.012522863, 0.012612214, 0.012901317, 0.013290312, nan, 0.013582088, nan, 0.0133440625, 0.013713729, 0.013619348, nan, nan], [nan, nan, nan, nan, nan, nan, 0.050262928, 0.046089128, 0.021423541, 0.011754215, 0.0042945705, 0.0029428042, 0.003998399, 0.005249977, 0.0065174997, 0.007757228, 0.008145846, 0.009616468, 0.010295205, 0.010523997, 0.009974971, 0.009030189, 0.008655231, 0.008923687, 0.0101731755, 0.010313384, 0.010305285, 0.009893235, 0.011435501, 0.010131478, 0.0098397955, 0.011126969, 0.011938054, 0.01175005, 0.010597628, 0.010619078, 0.010888178, 0.011493206, 0.012432814, 0.011610597, 0.011222087, 0.011693068, 0.011356335, 0.011169147, 0.012586642, 0.012672789, 0.013253268, 0.014493503, 0.015921429, 0.015750486, 0.015224237, 0.015303653, 0.014962342, 0.015794571, 0.01669421, 0.017126694, 0.014971115, 0.013833433, 0.014169551, 0.013174605, 0.012343153, 0.012461763, 0.012260724, 0.01211977, 0.011978295, 0.012289867, nan, 0.012343712, 0.012622844, nan, 0.012496689, 0.012846833, 0.0129344985, nan, 0.013916381, 0.013818843, 0.0137863215, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, 0.040400542, 0.015847597, 0.0072613135, 0.004035685, 0.0024323612, 0.0034761429, 0.004720524, 0.0052399784, 0.0058363825, 0.007798869, 0.01070074, 0.010583539, 0.011003394, 0.010061309, 0.009752691, 0.0097851865, 0.008597471, 0.008924987, 0.008819718, 0.0077257603, 0.008710895, 0.008551311, 0.009670805, 0.010643072, 0.010665901, 0.010654952, 0.010950815, 0.011397626, 0.0110711865, 0.010937113, 0.011300698, 0.011684157, 0.01047419, 0.010623127, 0.011412274, 0.010574512, 0.01144021, 0.013562437, 0.013539694, 0.0153583065, 0.015376888, 0.015053924, 0.014973577, 0.014383867, 0.01490657, 0.015052222, 0.01515688, 0.014274105, 0.013697103, 0.014584482, 0.014385596, 0.013350856, 0.012355063, 0.011466946, 0.011372544, 0.012068752, 0.0124486685, 0.012005981, 0.012172077, 0.012480084, 0.012447022, 0.012647076, 0.012835283, 0.012872202, nan, 0.013872689, 0.013945457, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.034896657, 0.010240719, 0.0054868236, 0.0034191944, 0.0027371272, 0.004854191, 0.0067037493, 0.008268621, 0.0096994005, 0.008463059, 0.0095657855, 0.011733267, 0.0106842145, 0.009955399, 0.009819254, 0.009677462, 0.00960369, 0.00870581, 0.009695545, 0.008531135, 0.0080081485, 0.009345196, 0.010377701, nan, 0.010493398, 0.0116957165, nan, 0.011381716, 0.011418693, 0.011423193, 0.009989958, 0.009580385, 0.009972367, 0.01136677, 0.011066992, 0.011614561, 0.013761498, 0.013365485, 0.014358204, 0.013725106, 0.015297085, 0.015352011, 0.0147656575, 0.014186677, 0.014591813, 0.0141605735, 0.0139046535, 0.013559412, 0.014521722, nan, 0.013708558, nan, 0.011348333, nan, 0.011289414, 0.012336396, 0.012748089, 0.012158029, 0.012870241, 0.012422048, 0.012791846, 0.013159204, 0.0136584435, 0.013986893, nan, 0.013983067, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.032101315, 0.010750636, 0.006590631, 0.0051104985, 0.0070486106, 0.0070906505, 0.009659871, 0.009779807, nan, 0.009294122, 0.010148019, 0.010675881, 0.010260355, 0.0097211115, 0.00959703, 0.009907562, 0.0101826005, 0.009600874, 0.008727569, 0.0086079165, 0.009363871, 0.010356128, 0.0112095475, 0.011484023, 0.011298165, 0.011160497, 0.01171631, 0.011591673, 0.012336001, 0.012044121, 0.011174314, 0.012109119, 0.012889106, nan, 0.013196569, 0.013641827, 0.01382545, 0.013652604, 0.012721632, 0.0127884075, 0.013458785, 0.013222229, 0.013347656, 0.0141562, 0.014054008, 0.013339777, 0.013213273, 0.014054697, 0.013944946, nan, 0.013057604, nan, 0.011645775, 0.011788737, 0.012039363, 0.012742467, 0.012906201, nan, 0.012641732, 0.013216123, 0.01327852, nan, nan, 0.013854204, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.02535946, 0.022565998, 0.008826375, 0.006333567, nan, 0.009224262, 0.008969665, 0.009651326, 0.009547554, 0.008422919, 0.009074993, 0.010386553, 0.009683862, 0.00912055, 0.008966263, 0.009306397, 0.00914197, 0.009096637, 0.008869544, 0.008862387, 0.010335848, 0.0113649, 0.01136354, 0.010774821, 0.01093033, 0.011432208, 0.011579007, 0.012333032, 0.012134161, 0.011490695, 0.013049815, 0.012387168, 0.013260242, 0.013272643, 0.01360273, nan, 0.013482563, 0.012703098, 0.012089897, 0.012334567, 0.013372824, 0.014500838, 0.014189146, 0.012756221, 0.012586419, 0.012473062, 0.0134918615, 0.013791453, 0.012707468, 0.012489598, 0.011685565, 0.011595663, 0.012213238, 0.012511205, 0.01276505, 0.012851737, 0.012739886, 0.012964515, nan, 0.01325088, nan, 0.013567086, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.019523464, 0.016476713, 0.0070107393, 0.007936116, 0.008869875, 0.009685885, 0.009461686, 0.0081680305, 0.008052293, 0.008558873, 0.010377251, 0.0096545, 0.0082329735, 0.008192945, 0.008801125, 0.009398118, 0.0092518665, 0.008326378, 0.008561268, 0.009975541, 0.010917962, 0.011038836, 0.011047646, 0.011019278, 0.011542838, 0.01117938, 0.011044208, 0.011643782, 0.012196034, 0.013276447, 0.013669558, 0.013556216, 0.0137155615, 0.0144139305, nan, 0.014414333, nan, 0.013455715, 0.013419192, 0.013629302, 0.014269214, 0.0128116645, 0.012247968, nan, 0.011491604, 0.011760406, 0.012111586, 0.011065923, 0.011619031, 0.011411227, 0.011385299, 0.011418298, 0.012031522, 0.012569994, 0.012694161, 0.012869421, 0.012881976, 0.013082987, nan, 0.013773022, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.0115554035, 0.008441713, 0.008244693, 0.0088842735, 0.0088725835, 0.008896105, 0.009336807, 0.007311836, 0.008560661, 0.007883295, 0.008159135, 0.008659981, 0.008944266, 0.009337563, 0.009137191, 0.009077489, 0.009928618, 0.009586737, 0.009826951, 0.010149866, 0.009764995, 0.0090114325, 0.00996149, 0.009261098, 0.009981655, 0.010748237, 0.013133392, 0.013840068, 0.0136861205, nan, 0.013673294, 0.014286205, 0.01490901, 0.014824454, nan, 0.0143304765, 0.014179554, 0.01341344, 0.013186306, 0.011619654, 0.012166563, 0.0109233335, 0.011058982, 0.010994203, 0.010503959, nan, 0.01134203, 0.01145399, 0.011947133, 0.011553358, 0.011716761, 0.012059286, 0.012722831, 0.01275409, 0.013101436, nan, 0.0137582775, 0.013763282, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.007294353, 0.007319346, 0.007807173, 0.008866042, 0.00895014, 0.0073582046, 0.0065452605, 0.006698549, 0.0068579353, 0.0077684745, 0.008977521, 0.009773824, 0.010359909, 0.010899313, 0.010048542, 0.009203687, 0.009297967, 0.0097986795, 0.0101694055, 0.008879628, 0.009300709, 0.009866055, 0.009425737, 0.009244949, 0.009917986, 0.0124167055, 0.012939341, 0.013785478, nan, 0.013651397, 0.014328703, 0.015163869, 0.01552197, nan, 0.014895882, 0.013776254, 0.012868091, 0.01228236, 0.010303974, 0.010733616, 0.009822801, 0.010134812, 0.01054832, 0.010641329, 0.011017203, nan, 0.011209864, 0.01226395, 0.011595305, 0.011934135, 0.012079559, nan, 0.012758985, nan, 0.013590451, 0.013641691, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.006673686, 0.0067289695, 0.006144777, 0.0046211593, 0.004764475, 0.00414801, 0.0052124523, 0.005011026, nan, 0.008634239, 0.009479608, 0.009609491, 0.010213248, 0.011204392, 0.010737695, 0.0102392435, 0.010986056, 0.011937503, 0.011466894, 0.011147156, 0.010990862, nan, 0.009539913, 0.009347517, 0.010903083, 0.012322344, 0.013256837, 0.01339202, nan, 0.014058121, 0.015947267, 0.016079824, nan, 0.0145428255, 0.013622809, 0.012492254, nan, 0.010476388, 0.010443453, 0.010099437, nan, 0.010379139, 0.010803733, 0.010693606, 0.010544121, 0.010732003, 0.011542432, 0.011505067, 0.012177501, 0.012223203, 0.012416825, 0.012556713, 0.013159094, 0.013186738, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.0065179914, 0.005584866, 0.0037966892, 0.002773296, 0.003874503, 0.0054672323, 0.004942242, 0.0069180243, 0.007266246, 0.0069186054, 0.0076880082, 0.009159982, 0.009494651, 0.009928703, 0.011626314, 0.011305094, 0.010895539, 0.012460988, 0.012776911, 0.011772003, 0.011674698, 0.011379752, 0.010261573, 0.008726191, 0.009220324, 0.009790681, 0.010900911, 0.013108842, 0.01397625, 0.014074001, 0.0145942345, 0.015246637, 0.014838286, 0.014537316, 0.014466248, 0.013082251, 0.010830108, 0.010052152, 0.010473363, 0.010377847, 0.0106395, 0.010436308, 0.011183914, 0.01090144, 0.010360535, 0.010357376, 0.01119874, 0.012027945, 0.011851229, 0.011873234, nan, nan, 0.012452774, 0.012800669, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.005831059, 0.005613435, 0.0043439046, 0.0050042234, 0.0057110675, 0.0067679025, 0.00755525, 0.0076298304, 0.0076489486, 0.008052785, 0.007391326, 0.008545663, 0.009750448, 0.010091383, 0.010926466, 0.011382267, 0.011814415, 0.012147259, 0.011884071, 0.011694025, 0.010875531, 0.010542113, 0.008448694, 0.0073569715, nan, 0.009598382, 0.011880688, 0.012786809, 0.014093507, 0.014795471, 0.015203536, 0.014741663, 0.0134129785, 0.013759736, 0.010960512, 0.009701174, 0.009274151, 0.009653743, 0.010236438, 0.011030789, 0.011390209, 0.011063926, 0.01042236, nan, 0.010405742, 0.011585735, 0.012012869, nan, 0.011830557, 0.011892151, 0.0117641315, 0.011952447, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.0059942678, 0.0056188814, 0.006388709, 0.007982925, 0.008363318, 0.008438632, 0.00815694, 0.009025089, 0.008570235, 0.007697545, 0.008835055, 0.009341162, 0.010887511, 0.011472963, 0.012463577, 0.0123298615, 0.011678223, 0.011974573, 0.011160813, 0.010688093, 0.009996641, 0.007946465, 0.0071199685, 0.0068766735, 0.0075978935, 0.009347104, nan, 0.012000844, 0.012480643, 0.014391564, 0.01119303, 0.011108924, 0.010351073, 0.01025014, 0.00960952, 0.0096767135, 0.009418447, 0.009426475, 0.010569107, 0.010835275, 0.010316137, nan, 0.010591384, 0.010803174, nan, 0.010806359, 0.011798538, nan, 0.011905104, 0.011521172, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.0065607615, 0.0070909336, 0.008281834, 0.008800924, 0.009370405, nan, nan, 0.0075443797, 0.008265059, 0.00865569, 0.0093574, 0.010197803, nan, 0.011327609, 0.010823391, 0.011250585, 0.010911506, 0.009472035, 0.009375099, 0.009763215, 0.0069703944, 0.0069073997, nan, 0.0073297285, 0.006967243, 0.007760808, 0.008993685, 0.008890189, 0.008764531, 0.009231608, 0.009643018, 0.010268591, 0.009654667, 0.01044431, 0.00950297, nan, nan, 0.009923611, 0.009554561, 0.010031711, 0.010180693, 0.010346148, 0.010659955, nan, 0.011183687, 0.011747293, 0.011920206, 0.011604119, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.0065616407, 0.0073652193, 0.0076749846, 0.0075807124, nan, 0.008050501, nan, 0.0072029755, 0.0073030964, 0.007684171, nan, 0.010128308, 0.009910118, 0.009492349, 0.009404991, 0.008885235, 0.008063935, 0.008195121, 0.007381428, 0.0066559166, 0.0067279525, 0.006656207, nan, nan, 0.0072974786, 0.00805125, 0.00880317, 0.0085512325, 0.008221503, 0.00810938, 0.0084178485, nan, 0.008736674, nan, 0.009003371, nan, 0.00926261, 0.009373765, 0.009799086, 0.010033835, 0.010265965, 0.010308433, 0.010482311, 0.011076, 0.011538412, 0.010771859, 0.010595139, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.0060929693, 0.004942201, 0.0063165613, 0.005638417, 0.006604202, 0.007293191, 0.007176604, 0.0069753006, 0.0065094084, 0.0066594183, 0.006717447, 0.008532636, 0.007339202, 0.006648645, 0.006960191, 0.0063575953, nan, 0.0062920228, 0.0066757537, 0.0066580996, 0.0068445653, 0.0068249553, 0.007191371, nan, 0.007917866, 0.008345358, 0.008666776, nan, 0.008434065, 0.007976156, nan, 0.008751672, 0.008934047, 0.008890551, 0.009265002, nan, 0.009948701, nan, 0.009996358, 0.0099449605, 0.010312792, 0.010961503, nan, nan, 0.01084299, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.004882198, 0.0058976114, 0.0038478486, nan, 0.0049609654, nan, nan, 0.00747649, 0.0075701885, 0.0072286166, 0.006117519, 0.0059252195, 0.006460931, nan, 0.0059967376, 0.005673595, 0.005711779, nan, 0.0062276013, 0.006669879, 0.006290786, nan, nan, 0.0076301917, nan, 0.007823773, 0.008715823, 0.008944757, nan, nan, 0.008662291, nan, 0.008941837, nan, 0.009462036, nan, nan, nan, nan, 0.010471467, 0.010585327, nan, 0.010937709, 0.010686573, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.004450768, 0.0056947544, nan, nan, nan, 0.006036736, nan, 0.0068237334, nan, 0.0062054023, 0.005928725, nan, 0.006160043, nan, 0.0055676736, nan, nan, nan, 0.0063758865, nan, 0.0066552684, 0.0070948713, 0.0075960755, nan, 0.007934526, 0.008929852, 0.009797677, nan, 0.009448726, nan, nan, 0.0094129145, nan, 0.009728905, 0.010026753, nan, 0.010851067, nan, nan, 0.010940235, nan, 0.01059103, 0.010304686, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.005408883, 0.005123239, 0.004407108, 0.0051441602, nan, nan, nan, 0.005716469, nan, nan, nan, 0.0052567273, nan, nan, 0.005789511, 0.0058607794, 0.0059444197, nan, 0.0064983554, nan, 0.0071505755, 0.0071533844, 0.007497728, nan, 0.008462321, 0.009653587, 0.010325331, 0.010305949, nan, 0.009099372, 0.00931374, 0.010221649, 0.010555159, 0.010499541, nan, 0.010602906, 0.01065002, 0.010743387, 0.010933954, 0.010761771, 0.010269374, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.0048308484, 0.00454608, nan, nan, 0.0055190846, nan, 0.0051097944, nan, 0.00480929, nan, nan, 0.0050936937, nan, 0.0056031793, nan, nan, 0.0063507073, nan, 0.006903343, nan, 0.006898295, 0.0073038787, 0.00823734, nan, 0.009814728, 0.010470886, 0.010828633, 0.010761727, 0.009342235, 0.010192014, 0.010390203, 0.010833688, 0.010589618, 0.010544166, 0.010889705, 0.011196379, 0.011042152, 0.011246197, 0.009968657, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.004641123, 0.00449948, nan, nan, 0.005428031, nan, 0.0055955984, 0.0044747368, 0.0046627037, nan, nan, 0.0050816983, 0.0058354028, 0.006185785, nan, 0.0070198067, nan, 0.0071755983, nan, 0.0076812804, 0.0083204135, 0.009157468, 0.00967484, 0.010249939, 0.010646272, 0.010358721, nan, 0.0100630075, 0.010522384, 0.010104962, 0.009694289, 0.010416724, 0.010707945, 0.011199787, 0.011265703, 0.011196062, 0.009929433, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.004743941, 0.0044778846, 0.0042710006, nan, 0.0043701977, 0.0045118853, nan, 0.0044613965, nan, nan, 0.0057123527, nan, nan, 0.007106997, nan, 0.007592533, nan, 0.007601589, nan, 0.007836491, nan, 0.008788001, 0.009825893, 0.010129038, 0.009994183, 0.009604938, nan, 0.009207983, 0.0096993, 0.010214575, 0.010597669, 0.010947391, 0.011108305, 0.0115550235, 0.011353191, 0.009865604, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.0048828237, 0.004863862, nan, nan, nan, nan, 0.004390657, 0.0045573562, 0.0044306964, 0.0052211173, 0.006158311, 0.0068494044, nan, nan, nan, 0.0077004135, nan, 0.007421747, nan, 0.007850006, 0.0084577985, 0.008722495, nan, 0.009311661, 0.009618111, 0.009766843, 0.009642202, 0.009290237, 0.0095871575, 0.00996365, 0.0103438385, 0.011466809, 0.011830695, 0.011557311, 0.011213765, 0.0075694174, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.005031813, 0.005256865, 0.0044927336, nan, 0.0043956675, 0.0050470717, 0.0056778677, 0.0056451634, 0.0055941157, 0.0061692446, 0.0073426217, nan, 0.0075064264, 0.00760293, nan, 0.0077738836, nan, 0.008260485, nan, nan, 0.008171357, nan, 0.009308271, 0.009766299, nan, 0.010074254, nan, 0.009756565, 0.009500399, 0.010046579, 0.011022389, 0.012118619, 0.01156114, 0.010291595, 0.006180521, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.005405985, 0.005547695, nan, 0.0044004656, 0.0055376813, 0.0065938495, 0.006756168, 0.0056899115, 0.006685037, 0.0067063905, 0.007420771, 0.0073390715, 0.007323548, 0.008193985, 0.008777868, 0.009669624, 0.008899145, 0.009182386, nan, 0.008315165, nan, 0.009405669, nan, 0.010452755, 0.010462247, 0.010339726, 0.010055054, 0.009602465, 0.01063161, 0.011198822, 0.010630872, 0.011284292, 0.008853465, 0.0010517165, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.005841173, 0.004972089, nan, 0.0056023262, 0.006775461, 0.0076706707, 0.0068525933, 0.0070164055, 0.007668674, 0.007989116, 0.007875562, 0.007796269, 0.007987641, 0.00834709, 0.00945957, 0.0094514415, 0.009381991, 0.008404337, 0.00819166, nan, 0.009285729, nan, 0.010350689, nan, 0.009673357, nan, 0.00986062, 0.009882253, 0.010243177, 0.010176055, 0.00840608, 0.0017130449, -0.011987962, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.0062082335, 0.0056349486, 0.005762838, 0.005254533, 0.006942544, 0.00625512, 0.006670255, 0.006834097, 0.0073191673, 0.007554956, 0.0071947947, 0.0078175105, 0.0077953897, 0.008779921, 0.008404717, nan, 0.007621713, 0.008020952, nan, 0.008749515, 0.009581801, 0.009063844, nan, 0.008497525, 0.009273928, 0.009477977, 0.009163484, 0.008936487, 0.008652192, 0.004755646, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.00789243, 0.008062992, 0.006167561, 0.0054684803, 0.0068167783, 0.006941732, 0.0070547685, 0.0073114038, 0.007314574, 0.007169828, 0.0074356273, 0.007955924, nan, nan, nan, nan, 0.0072053, 0.007734794, 0.0073638707, nan, 0.0074493177, 0.008076385, nan, 0.007835865, 0.0074872896, 0.0025876276, nan, nan, -0.011048868, nan, -0.026849613, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.0083380155, 0.006407194, 0.0056089796, 0.006490797, 0.0055596344, 0.00549211, 0.0066206753, 0.0071688965, 0.006991066, 0.0075913183, 0.008310784, 0.008493431, 0.007849805, nan, 0.007133186, 0.0066693425, nan, 0.005602058, nan, 0.0049175173, 0.0047832467, 0.005814746, 0.00491371, 0.0031650588, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.006674573, 0.0053208955, 0.004858367, 0.004718408, 0.0049006864, 0.005713962, 0.005902007, 0.0060364716, 0.0071019717, 0.0073141865, 0.007336214, nan, 0.006834671, nan, 0.0056635216, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.006124966, 0.0048991106, 0.004936438, 0.0054078773, 0.0054468513, 0.0057907626, 0.0053555667, 0.00554689, 0.006423045, 0.007036131, 0.0064271465, nan, 0.0060644895, 0.0054700933, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.005171042, 0.005623676, 0.005713951, 0.0057869405, 0.0061135925, 0.0062897913, 0.0063346103, 0.0065367036, 0.006076038, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan], [nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, 0.0059132352, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan]]
        
        enhancedMap = originalHeightMap ?? [[]]
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
        
        //edge case - no conditions created - resolve this
       
        filterSetting.menu = UIMenu(children : [
            //bug - without pressing anything - should go to the currently selected item
            UIAction(title : "None", handler : optionClosure),
            UIAction(title : "Gaussian", handler : optionClosure),
            UIAction(title : "Weighted Average", handler : optionClosure),
            UIAction(title : "Ricker Wavelet", handler : optionClosure),
            UIAction(title : "Height Map", handler : optionClosure),
            
        ])
        
        filterSetting.showsMenuAsPrimaryAction = true
        filterSetting.changesSelectionAsPrimaryAction = true
    }
    
    // Assuming text contains lines of space-separated coordinates, e.g., "x y z\n"
    // Function to convert a line of text to SCNVector3
    func convertTextToSCNVector3(text: String) -> [SCNVector3] {
        var vectorList: [SCNVector3] = []
        
        // Split text into lines
        let lines = text.components(separatedBy: .newlines)
        
        // Iterate over each line and convert it to SCNVector3
        for line in lines {
            // Example line format: SCNVector3(x: 0.102449834, y: 8.901209e-05, z: 0.15636508)
            
            // Remove "SCNVector3" and parentheses
            var cleanLine = line.replacingOccurrences(of: "SCNVector3", with: "")
            cleanLine = cleanLine.replacingOccurrences(of: "(", with: "")
            cleanLine = cleanLine.replacingOccurrences(of: ")", with: "")
            
            // Split line by commas to get individual components
            let components = cleanLine.components(separatedBy: ",")
            
            // Extract x, y, and z values
            guard components.count == 3,
                  let xString = components[0].split(separator: ":").last?.trimmingCharacters(in: .whitespaces),
                  let yString = components[1].split(separator: ":").last?.trimmingCharacters(in: .whitespaces),
                  let zString = components[2].split(separator: ":").last?.trimmingCharacters(in: .whitespaces),
                  let x = Float(xString),
                  let y = Float(yString),
                  let z = Float(zString) else {
                // Skip this line if it doesn't match the expected format
                continue
            }
            
            // Create SCNVector3 object and add it to the list
            vectorList.append(SCNVector3(x, y, z))
        }
        
        return vectorList
    }
    
/*    @IBAction func applyGaussian(_ sender: Any) {
        if !gradientToggle{
            gradientToggle = true
       //     smoothButton.tintColor = .green
        }
        else{
            gradientToggle = false
          //  smoothButton.tintColor = .blue
        }
    }*/
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
                        print("surface normal", result.localNormal)
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
                       // if !(hapticTransient ?? true) && hapticsToggle && !palpationToggle{
                        if hapticsToggle && !palpationToggle{
                      /*      //continuous mode
                            let tempGradient = gradientMethod()
                            let approxPoint = tempGradient.closestDistance(points: smoothedCloud ?? [], inputPoint: position, k: 1)[0]
                            //gets scaled height value between 1 and 0
                            let scaledValue = HeightMap().scaleValue(value: approxPoint.y, maxValue: maxContinuous ?? 1, minValue: minContinuous ?? 0)
                            tempHaptics?.createContinuousHapticPlayer(initialIntensity: scaledValue, initialSharpness: 0.73)
                            currentIntensity = 0.1
                            currentSharpness = scaledValue
                         //   tempHaptics?.continuousPlayer.start(atTime: 0)
                            // Warm engine.
                            do {
                                // Begin playing continuous pattern.
                        //    try tempHaptics?.continuousPlayer?.start(atTime: CHHapticTimeImmediate)
                                print("STARTED CONTINUOUS PLAYER")
                            } catch let error {
                                print("Error starting the continuous haptic player: \(error)")
                            }*/

                           // let rotation = SCNQuaternion(x: 0.0, y: (position.y * Float.pi)/180, z: 0.0, w: (position.y * Float.pi)/180)

                            
                        }
                        if hapticsToggle && palpationToggle{
                            let surfaceNormalVector = result.worldNormal
                            var test = sceneView.defaultCameraController.pointOfView?.worldFront ?? SCNVector3(x: 0, y: -1, z: 0)
                            test.y = -(test.y)
                            print(test)
                            guard let currentTransform = sceneView.defaultCameraController.pointOfView?.transform else { return }

                            let rotationQuaternion = SCNQuaternion.fromTwoVectors(surfaceNormalVector, test)
                            let newTransform = SCNMatrix4Mult(currentTransform, rotationQuaternion)

                            //print("New camera orientation:", cameraNode.rotation)
                            sceneView.defaultCameraController.pointOfView?.transform = newTransform
                        //    rotatePalpation(result: result)
                        //    let angleInRadians: Float = 1 * (Float.pi / 180) // Convert 1 degree to radians

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
            if result.node.name == modelName {
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
                    print("points")
                    print(position.y)
                    print(approxPoint.y)
                    print(nextPoint.y)
                    print(previousPosition?.yPos)
                    print(changeInGradient)
                    print("end")
                    
                    //height = (approxPoint.y * 1000) + 1
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
                        
                       /* switch self.filter {
                        case .none:
                            scaledValue = HeightMap().scaleValue(value: position.y, maxValue: maxPoint?.y ?? 1, minValue: minPoint?.y ?? 0)
                            height = scaledValue
                            print("height", height)
                        case .gaussian:
                            if let allVertices = modelVertices {
                                print("start gauss")

                                print(position)
                                let gaussianMax = self.filterMax?.y ?? 1
                                let gaussianMin = self.filterMin?.y ?? 0
                                let gaussian = tempGradient.applyGaussianFilter(to: position, sigma: sigmaVal, vertices: allVertices, kernelSize: kVal)
                                scaledValue = HeightMap().scaleValue(value: gaussian.y, maxValue: gaussianMax, minValue: gaussianMin)
                                print(gaussian)
                          //      print("gaussian bump")
                           //     print(kVal)
                           //     print(sigmaVal)
                              //  print(allVertices)
                                //bumpy
                                let bumpyHeight = position.y - gaussian.y
                                print("bumpyheight", bumpyHeight)
                                print(gaussianMax)
                                print(gaussianMin)
                                print((minPoint?.y ?? 0) - gaussianMin)
                                height = HeightMap().scaleValue(value: bumpyHeight, maxValue: (maxPoint?.y ?? 1) - (gaussianMax), minValue: (minPoint?.y ?? 0) - (gaussianMin))
                            //    print(gaussianMax)
                            //    print(gaussianMin)
                                print("height", height)
                            
                                
                            }
                        
                            else{
                                //
                            }
                        case .heightMap:
                            let gridPoint = mapPointToHeightMap(hitResult: result, gridSize: 50)//113)
                            if let rickerMap = self.enhancedMap {
                                let (gridX, gridY) = gridPoint
                                if gridY >= 0 && gridY < rickerMap.count && gridX >= 0 && gridX < rickerMap[gridY].count {
                                    let value = rickerMap[gridY][gridX]
                                    height = value
                                    print("Height Map Height")
                                    print(height)
                                    } else {
                                        // Handle the case where the point is outside the bounds of the height map
                                        print("invalid access")// Returning NaN or another sentinel value to indicate an invalid access
                                    }
                                
                            }
                        case .average:
                            if let allVertices = modelVertices {
                                let average = tempGradient.addNewAverage(inputPoint: position, originalPointCloud: allVertices, k: kVal)
                                
                            //    print("average bump")
                                let bumpyHeight = position.y - average.y
                                let averageMax = self.filterMax?.y ?? 1
                                let averageMin = self.filterMin?.y ?? 0
                                scaledValue = HeightMap().scaleValue(value: average.y, maxValue: averageMax, minValue: averageMin)
                                height = HeightMap().scaleValue(value: bumpyHeight, maxValue: (maxPoint?.y ?? 1) - (averageMax), minValue: (minPoint?.y ?? 0) - (averageMin))
                                print("height", height)
                           //     print(averageMax)
                           //     print(averageMin)
                           //     print(self.filterMax?.y)
                            }
                            else{
                                //
                            }
                        case .edge:
                            if let allVertices = modelVertices {
                                let accentuated = tempGradient.applyMexicanHatFilter(to: position, sigma: sigmaVal, vertices: allVertices, kernelSize: kVal)
                                
                                let accentuatedMax = self.filterMax?.y ?? 1
                                let accentuatedMin = self.filterMin?.y ?? 0
                                scaledValue = HeightMap().scaleValue(value: (position.y - accentuated.y), maxValue: (maxPoint?.y ?? 1) - (accentuatedMax), minValue: (minPoint?.y ?? 0) - (accentuatedMin))
                                height = HeightMap().scaleValue(value: accentuated.y, maxValue: accentuatedMax , minValue: accentuatedMin)
                                print("height", height)
                                
                            }
                        
                    }*/
                        let gridSize = enhancedMap?.endIndex
                        print("grid size", gridSize)
                        let gridPoint = mapPointToHeightMap(hitResult: result, gridSize: 80)//
                        if let map = self.enhancedMap {
                            let (gridX, gridY) = gridPoint
                            if gridY >= 0 && gridY < map.count && gridX >= 0 && gridX < map[gridY].count {
                                let value = map[gridY][gridX]
                                if value.isNaN{
                                    height = 0
                                }
                                else{
                                    let scaledValue = HeightMap().scaleValue(value: value, maxValue: self.maxHeight ?? 1, minValue: self.minHeight ?? 0)
                                    height = scaledValue
                                }
                                
                                print("Height Map Height")
                                print(height)
                                } else {
                                    // Handle the case where the point is outside the bounds of the height map
                                    print("invalid access")// Returning NaN or another sentinel value to indicate an invalid access
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
                        
                        
                            try tempHaptics?.playHeightHaptic(height:height)
                        
                        
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
                        
                        let rotationQuaternion = SCNQuaternion.fromTwoVectors(surfaceNormalVector,test)
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
   //     smoothButton.isHidden = true
        palpationOption.isHidden = true
        hapticMethod.isHidden = true
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
        settingsButton.isHidden = false
  //      smoothButton.isHidden = false
        palpationOption.isHidden = false
        hapticMethod.isHidden = false
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
    
    ///Rotates model so that surface normal being touched corresponds with camera view?
    func rotatePalpation1(result: SCNHitTestResult){
        let surfaceNormalVector = result.worldNormal
        var test = sceneView.defaultCameraController.pointOfView?.worldFront ?? SCNVector3(x: 0, y: -1, z: 0)
        test.y = -(test.y)
        print(test)
        guard let currentTransform = sceneView.defaultCameraController.pointOfView?.transform else { return }

        let rotationQuaternion = SCNQuaternion.fromTwoVectors(surfaceNormalVector, test)
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
        
        let rotationQuaternion = SCNQuaternion.fromTwoVectors(cameraFront, surfaceNormalVector)
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

        // Create a target orientation: this assumes the normal is in world coordinates
        // You may need to convert it from local to world coordinates depending on your setup
        let targetOrientation = SCNQuaternion(x: -normal.x, y: -normal.y, z: -normal.z, w: 1)

        // Interpolate between the current orientation and the target orientation
        let slerpQuat = slerp(from: currentOrientation, to: targetOrientation, fraction: 0.1) // Adjust fraction for smoother or faster rotation

        // Set the new orientation to the camera
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
        // Simple lerp formula for demonstration; consider using simd.slerp for better results
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
        if gradientHeightMap.selectedSegmentIndex == 0{
            self.gradientEffect = true
        }else{
            self.gradientEffect = false
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
            //self.filter = .average
            //self.kVal = Int(kSetting.value)

          /*  guard let maxPoint = self.maxPoint, let allVertices = self.modelVertices, let minPoint = self.minPoint else {
                return
            }
            let tempGradient = gradientMethod()
            self.filterMax = tempGradient.addNewAverage(inputPoint: maxPoint, originalPointCloud: allVertices, k: kVal)

            self.filterMin = tempGradient.addNewAverage(inputPoint: minPoint, originalPointCloud: allVertices, k: kVal)*/
            let tempGradient = gradientMethod()
            let tempHeightMap = tempGradient.convertHeightMapToGradient(heightMap: originalHeightMap ?? [[]])
            let secondTemp = tempGradient.convertHeightMapToGradient(heightMap: tempHeightMap.0)
            enhancedMap = secondTemp.0
            
            
        case "Ricker Wavelet":
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
        case "Default":
            self.filter = .heightMap
            enhancedMap = self.originalHeightMap
            
        default:
            break
        }
        self.maxHeight = findMaxElement(in: enhancedMap ?? [[]])
        self.minHeight = findMinElement(in: enhancedMap ?? [[]])
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

        // Clamp the values to ensure they are within the grid bounds
        let clampedGridX = max(0, min(gridX, gridSize - 1))
        let clampedGridY = max(0, min(gridY, gridSize - 1))

        return (clampedGridX, clampedGridY)
    }

    
    
}

extension SCNQuaternion {
    static func fromTwoVectors(_ vectorA: SCNVector3, _ vectorB: SCNVector3) -> SCNMatrix4  {
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
        angle = angle/4
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



func findMaxElement(in array: [[Float]]) -> Float? {
    // Flatten the 2D array to a 1D array and find the max element
    return array.flatMap { $0 }.max()
}

func findMinElement(in array: [[Float]]) -> Float? {
    // Flatten the 2D array to a 1D array and find the max element
    return array.flatMap { $0 }.min()
}
