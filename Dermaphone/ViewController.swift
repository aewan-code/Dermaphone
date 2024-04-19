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
            
            if action.title == "baked_mesh"{
                self.modelFile = "baked_mesh.scn"
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
            UIAction(title : "baked_mesh", state: .on, handler : optionClosure),
            UIAction(title : "Mesh", handler : optionClosure),
          //  UIAction(title : "skin3", handler : optionClosure),
         //   UIAction(title : "skin4", handler : optionClosure),
        //UIAction(title : "skin5", handler : optionClosure)
            
        ])
        
        ViewModel.showsMenuAsPrimaryAction = true
        ViewModel.changesSelectionAsPrimaryAction = true
                                
    }

            
            


}

