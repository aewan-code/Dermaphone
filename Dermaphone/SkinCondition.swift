//
//  SkinCondition.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 02/04/2024.
//

import UIKit

class SkinCondition{
    let name : String
    let description : String?//are they required when creating the skin condition package?
    let cause : String?
    let image : UIImage?
    let texture : String?//features e.g. colour
    let diagnosis : String?
    let treatment: String?
    let model : [skinmodel]//Should this be a view controller? List of all models that are this skin condition
    init(name : String, description : String, cause : String, texture : String, diagnosis : String, treatment : String, model : skinmodel, image : UIImage){
        self.name = name
        self.description = description
        self.cause = cause
        self.texture = texture
        self.diagnosis = diagnosis
        self.treatment = treatment
        self.model = [model]
        self.image = image
    }
    
    //set image - either from gallery or from camera or from model (screenshot) (ideally needs to be top down view). Can it get dermnet image maybe?
    func setImage(){
        
    }
    
    //link to (all or most compatible?)other skin conditions, related by texture, colour, diagnosis method, treatment etc
    func addLink(){
        
    }
}
