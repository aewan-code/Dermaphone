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
 

    var modelName : String = "Mesh"
    var modelFile : String = "baked_mesh.scn"//"testTransform.scn"
    @IBOutlet weak var ViewModel: UIButton!
    @IBAction func touchViewModel(_ sender: Any) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "skinmodel") as? skinmodel else {
            return
        }
        vc.set(name: modelName, fileName: modelFile)
        print("check")
        navigationController?.pushViewController(vc, animated: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()        
        setModel()

    }
    
    func setModel(){
        
        let optionClosure = {(action : UIAction) in
            print(action.title)
            
            if action.title == "skin2model"{
                self.modelFile = "test2scene.scn"
                self.modelName = "Mesh"
            }
            else{
                self.modelFile = "testTransform.scn"
                self.modelName = "Mesh"
            }
        //    self.currentModelname.name = action.title + ".scn"
        //    print(self.currentModelname.name)
            
        }
        
        ViewModel.menu = UIMenu(children : [
            UIAction(title : "skin2model", state: .on, handler : optionClosure),
            UIAction(title : "skin3model", handler : optionClosure),
          //  UIAction(title : "skin3", handler : optionClosure),
         //   UIAction(title : "skin4", handler : optionClosure),
        //UIAction(title : "skin5", handler : optionClosure)
            
        ])
        
        ViewModel.showsMenuAsPrimaryAction = true
        ViewModel.changesSelectionAsPrimaryAction = true
                                
    }

            
            


}

