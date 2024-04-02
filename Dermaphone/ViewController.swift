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
class currentModel: ObservableObject {
    @Published var name = "baked_mesh.scn"
    
}

class ViewController: UIViewController {
 
    @ObservedObject var currentModelname = currentModel()


    @IBOutlet weak var ViewModel: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        setModel()

    }
    
    func setModel(){
        
        let optionClosure = {(action : UIAction) in
            print(action.title)
            self.currentModelname.name = action.title + ".scn"
            print(self.currentModelname.name)
        }
        
        ViewModel.menu = UIMenu(children : [
            UIAction(title : "baked_mesh", state: .on, handler : optionClosure),
            UIAction(title : "skin2", handler : optionClosure),
            UIAction(title : "Skin3", handler : optionClosure),
            UIAction(title : "Skin4", handler : optionClosure),
            UIAction(title : "Skin5", handler : optionClosure)
            
        ])
        
        ViewModel.showsMenuAsPrimaryAction = true
        ViewModel.changesSelectionAsPrimaryAction = true
                                
    }

            
            


}

