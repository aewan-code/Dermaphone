//
//  skinConditionInfo.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 02/04/2024.
//

import UIKit

class skinConditionInfoView : UIViewController{
    var name : String? = nil
    var conditionDescription : String? = nil
    var conditionCauses : String? = nil
    var conditionPeople : String? = nil
    var conditionImage : UIImage? = nil
    var treatment : String? = nil
    var diagnosisMethod : String? = nil
    var features : [String]? = nil
    var editMode : Bool = false
    var skinCondition : SkinCondition? = nil
    @IBOutlet weak var modelImage: UIImageView!
    @IBOutlet weak var editButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        editButton.setTitle("Done", for: .highlighted)//does this go here?
        editButton.setTitle("Edit", for: .normal)
    }
    
    @IBAction func editButtonPressed(_ sender: Any) {
        if !editMode {
            editButton.isHighlighted = true
            editMode = true
        }
        else{
            editButton.isHighlighted = false
            editMode = false
        }
    }
    
    func setImage(image : UIImage){
        modelImage.image = image
    }
    
}
