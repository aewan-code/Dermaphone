//
//  loginStudent.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 29/05/2024.
//

import UIKit

class loginStudent: UIViewController {

    @IBOutlet weak var login: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func loginbutton(_ sender: Any) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "LesionLibrary") as? LesionLibrary else {
            return
        }
    //    vc.set(model: currentModel)
        vc.sourceType = .student
        navigationController?.pushViewController(vc, animated: false)
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
