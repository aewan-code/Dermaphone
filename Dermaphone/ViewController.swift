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
 
    var currentModel : SkinCondition = SkinCondition(name: "Actinic Keratosis", description: "(Precancerous) Most common precancer. Can evolve into squamous cell carcinoma", texture: "crusty rough spots", symptoms: "pink coloration", treatment: "", modelName: "Mesh", images: [], modelFile: "testTransform.scn", similarConditions: [], notes: "", urgency: "")
    //Change currentModel so that if no models have been created either portrays a test one or presents a popup
    var skinConditions : [SkinCondition] = []
    @IBOutlet weak var ViewModel: UIButton!
    @IBAction func touchViewModel(_ sender: Any) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "skinmodel") as? skinmodel else {
            return
        }
        vc.set(model: currentModel)
        print("check")
        navigationController?.pushViewController(vc, animated: true)
    }
    override func viewDidLoad() {
        createModels()
        super.viewDidLoad()
        setModel()

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
                        self.currentModel = condition
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
        let skin3Model = SkinCondition(name: "Actinic Keratosis", description: "(Precancerous) Most common precancer. Can evolve into squamous cell carcinoma", texture: "crusty rough spots", symptoms: "pink coloration", treatment: "", modelName: "Mesh", images: [], modelFile: "testTransform.scn", similarConditions: [], notes: "(Precancerous) Most common precancer. Can evolve into squamous cell carcinoma. Crusty rough spots", urgency: "Precancerous")
        let skin2Model = SkinCondition(name: "Basal Cell Carcinoma", description: "(Cancerous) Most common form of skin cancer. Normally found on body pars exposed to the sun", texture: "", symptoms: "recurring sore that bleeds and heals", treatment: "", modelName: "Mesh", images: [], modelFile: "test2scene.scn", similarConditions: [], notes: "(Cancerous) Most common form of skin cancer. Normally found on body pars exposed to the sun.", urgency: "Cancerous")
        skinConditions.append(skin3Model)
        skinConditions.append(skin2Model)
    }
    
            
            


}

