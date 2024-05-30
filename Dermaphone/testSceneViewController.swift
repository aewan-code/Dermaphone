//
//  testSceneViewController.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 25/05/2024.
//

import UIKit
import SceneKit
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth


class testSceneViewController: UIViewController {

    @IBOutlet weak var sceneView: SCNView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let database = DatabaseManagement()
        let sceneURL = database.localFileURL(for: "scene.usdz", directory: .documentDirectory)
        let textureURL = database.localFileURL(for: "texture.png", directory: .cachesDirectory)
        let normalURL = database.localFileURL(for: "normal.png", directory: .cachesDirectory)
        let diffuseURL = database.localFileURL(for: "diffuse.png", directory: .cachesDirectory)
        DispatchQueue.global(qos: .background).async{
            database.downloadFile(from: "models/Test Model/baked_mesh.usdz", to: sceneURL) { success in
                DispatchQueue.main.async {
                    if success {
                        print("File was successfully downloaded to \(sceneURL)")
                   
                                                            if let scene1 = self.loadScene(from: sceneURL) {
                                                              //  self.applyMaterials(to: scene.rootNode.childNodes.first!, textureURL: textureURL, normalURL: normalURL, diffuseURL: diffuseURL)
                                                                let mainScene = SCNScene()

                                                                let root = scene1.rootNode
                                                                self.sceneView.scene = mainScene
                                                                mainScene.rootNode.addChildNode(root)
                                                                let ambientLight = SCNLight()
                                                                ambientLight.type = .ambient
                                                                ambientLight.color = UIColor.white // Adjust the light color as needed
                                                                let ambientLightNode = SCNNode()
                                                                ambientLightNode.light = ambientLight
                                                                mainScene.rootNode.addChildNode(ambientLightNode)
                                                                self.sceneView.allowsCameraControl = true
                                                              //  self.sceneView.backgroundColor = UIColor.black
                                                              
                                                                
                                                            }
                    } else {
                        print("Failed to download the file.")
                    }
                }
            }
        }
       

        

      



    }
    
    func completeDownload(completion: Bool){
        print("Download complete!")
    }
    

    func loadScene(from localURL: URL) -> SCNScene? {
        do {
            let scene = try SCNScene(url: localURL, options: nil)
            return scene
        } catch {
            print("Failed to load SceneKit scene: \(error)")
            return nil
        }
    }

    func applyMaterials(to node: SCNNode, textureURL: URL, normalURL: URL, diffuseURL: URL) {
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(contentsOfFile: diffuseURL.path)
        material.normal.contents = UIImage(contentsOfFile: normalURL.path)
        material.ambient.contents = UIImage(contentsOfFile: textureURL.path)

        node.geometry?.materials = [material]
    }

    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
