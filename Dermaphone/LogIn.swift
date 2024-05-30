//
//  LogIn.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 23/05/2024.
//

import Foundation
import UIKit
import RealityKit

class LogIn : UIViewController{
    
    @IBOutlet weak var loginbutton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
    
    }

    @IBAction func login(_ sender: Any) {
        print("login pressed")
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "LesionLibrary") as? LesionLibrary else {
            return
        }
        
    //    vc.set(model: currentModel)
        vc.sourceType = .consultant
        navigationController?.pushViewController(vc, animated: false)
    }
    /*   @IBAction func changeUserType(_ sender: Any) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "loginStudent") as? loginStudent else {
            return
        }
    }*/
    
}
