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
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

class ViewController: UIViewController {
    @IBOutlet weak var readUsers: UIButton!
    var db: Firestore!
    @IBOutlet weak var addUsers: UIButton!
    @IBOutlet weak var addModel: UIButton!
   // var currentModel : SkinCondition = SkinCondition(name: "Actinic Keratosis", description: "(Precancerous) Most common precancer. Can evolve into squamous cell carcinoma", texture: "crusty rough spots", symptoms: "pink coloration", treatment: "", modelName: "Mesh", images: [], modelFile: "testTransform.scn", similarConditions: [], notes: "", urgency: "")
    //Change currentModel so that if no models have been created either portrays a test one or presents a popup
    var skinConditions : [SkinCondition] = []
    @IBOutlet weak var ViewModel: UIButton!
    @IBAction func touchViewModel(_ sender: Any) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "skinmodel") as? skinmodel else {
            return
        }
    //    vc.set(model: currentModel)
        print("check")
        navigationController?.pushViewController(vc, animated: true)
    }
    override func viewDidLoad() {
      //  let settings = FirestoreSettings()
        
     //   Firestore.firestore().settings = settings
        // [END setup]
     //   db = Firestore.firestore()
        
        createModels()
        super.viewDidLoad()
        setModel()
        
        
        

    }
    
    @IBAction func createUserTouched(_ sender: Any) {
       /* Task { @MainActor in
            await addAdaLovelace()
            await addAlanTuring()
        }*/
    }
    private func addAdaLovelace() async {
      // [START add_ada_lovelace]
      // Add a new document with a generated ID
   /*   do {
        let ref = try await db.collection("users").addDocument(data: [
          "first": "Ada",
          "last": "Lovelace",
          "born": 1815
        ])
        print("Document added with ID: \(ref.documentID)")
      } catch {
        print("Error adding document: \(error)")
      }*/
      // [END add_ada_lovelace]
    }
    
    private func addAlanTuring() async {

    }
    
    @IBAction func readUsersTouched(_ sender: Any) {
     /*   Task { @MainActor in
            await readDatabase()
        }*/
    }
    private func readDatabase() async {
    /*    do {
          let snapshot = try await db.collection("users").getDocuments()
          for document in snapshot.documents {
            print("\(document.documentID) => \(document.data())")
          }
        } catch {
          print("Error getting documents: \(error)")
        }*/
    }
    
    func setModel(){
        
        let optionClosure = {(action : UIAction) in
            print(action.title)
            //edge case - don't allow multiple conditions with the same name
            if self.skinConditions.isEmpty{
                //have a test model that users can look at
                
            }
            var foundCondition = false
            while !foundCondition{
                for condition in self.skinConditions{
                    if action.title == condition.name{
                        foundCondition = true
                  //      self.currentModel = condition
                    }
                    
                }
            }
            
        }
        
        //edge case - no conditions created - resolve this
       
        ViewModel.menu = UIMenu(children : [
            //bug - without pressing anything - should go to the currently selected item
            UIAction(title : skinConditions[0].name, handler : optionClosure),
            UIAction(title : skinConditions[1].name, handler : optionClosure),
            
        ])
        
        ViewModel.showsMenuAsPrimaryAction = true
        ViewModel.changesSelectionAsPrimaryAction = true
                                
    }
    //this will later be 'loadModels' - to be loaded from the database
    func createModels(){
        
            //let skin3Model = SkinCondition(name: "Actinic Keratosis", description: "(Precancerous) Most common precancer. Can evolve into squamous cell carcinoma", texture: "crusty rough spots", symptoms: "pink coloration", treatment: "", modelName: "Mesh", images: [], modelFile: "testTransform.scn", similarConditions: [], notes: "(Precancerous) Most common precancer. Can evolve into squamous cell carcinoma. Crusty rough spots", urgency: "Precancerous")
   //     let skin2Model = SkinCondition(name: "Basal Cell Carcinoma", description: "(Cancerous) Most common form of skin cancer. Normally found on body pars exposed to the sun", texture: "", symptoms: "recurring sore that bleeds and heals", treatment: "", modelName: "Mesh", images: [], modelFile: "test2scene.scn", similarConditions: [(skin3Model, "link to cancer")], notes: "(Cancerous) Most common form of skin cancer. Normally found on body pars exposed to the sun.", urgency: "Cancerous")
    /*    if let image1 = UIImage(named: "IMG_3929") {
            skin3Model.image?.append(image1)
            print("yes")
        }
        
        skinConditions.append(skin3Model)
        skinConditions.append(skin2Model)*/
    }
    
    @IBAction func addedModel(_ sender: Any) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        //let modelsRef = storageRef.child("models")
        // File located on disk
       // let localFile = URL(string: "/Users/ace20/Documents/testTransform.scn")!
        guard let fileURL = Bundle.main.url(forResource: "testTransform", withExtension: "scn")  else {
          return
        }
        let localFile = fileURL
        // Create a reference to the file you want to upload
        var modelsRef = storageRef.child("models/ActinicKeratosis.scn")
        guard let fileURLTexture = Bundle.main.url(forResource: "skin3_tex0", withExtension: "png")  else {
          return
        }
        guard let fileURLNorm = Bundle.main.url(forResource: "baked_mesh_norm0", withExtension: "png")  else {
          return
        }
        guard let fileURLA = Bundle.main.url(forResource: "baked_mesh_ao0", withExtension: "png")  else {
          return
        }
        // Upload the file to the path "images/rivers.jpg"
        let uploadTask = modelsRef.putFile(from: localFile, metadata: nil) { metadata, error in
          guard let metadata = metadata else {
            // Uh-oh, an error occurred!
              print("error 1", error)
            return
          }
          // Metadata contains file metadata such as size, content-type.
          let size = metadata.size
            print("metadata", metadata)
            modelsRef = storageRef.child("models/skin3_tex0.png")
            let uploadTaskTexture = modelsRef.putFile(from: fileURLTexture, metadata: nil) { metadata, error in
                guard let metadataT = metadata else {
                    // Uh-oh, an error occurred!
                    print("error 1", error)
                    return
                }
                // Metadata contains file metadata such as size, content-type.
                print("metadata", metadataT)
            }
                modelsRef = storageRef.child("models/baked_mesh_norm0.png")
                let uploadTaskNorm = modelsRef.putFile(from: fileURLNorm, metadata: nil) { metadata, error in
                    guard let metadataNorm = metadata else {
                        // Uh-oh, an error occurred!
                        print("error 1", error)
                        return
                    }
                    print("metadata", metadataNorm)
                }
                    
                  // Metadata contains file metadata such as size, content-type.
                    
                    
                    modelsRef = storageRef.child("models/baked_mesh_ao0.png")
                    let uploadTaskA = modelsRef.putFile(from: fileURLA, metadata: nil) { metadata, error in
                        guard let metadataA = metadata else {
                            // Uh-oh, an error occurred!
                            print("error 1", error)
                            return
                        }
                        print("metadata", metadataA)
                    }
          // You can also access to download URL after upload.
            modelsRef = storageRef.child("models")
          modelsRef.downloadURL { (url, error) in
            guard let downloadURL = url else {
                
              // Uh-oh, an error occurred!
              return
            }
          }
        }
            
    }
    
    
            
            


}

