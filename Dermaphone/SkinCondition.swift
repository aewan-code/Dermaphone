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
    let image : [UIImage]?
    let texture : String?//features e.g. colour
    let symptoms : String?
    let treatment: String?
    let modelName : String
    let modelFile : String
    let similarConditions : [SkinCondition]?
    let notes : String?
 //   let model : [skinmodel]//Should this be a view controller? List of all models that are this skin condition
    init(name : String, description : String, texture : String, symptoms : String, treatment : String, modelName : String, images : [UIImage], modelFile : String, similarConditions : [SkinCondition], notes : String ){
        self.name = name
        self.description = description
        self.texture = texture
        self.symptoms = symptoms
        self.treatment = treatment
        self.image = images
        self.modelFile = modelFile
        self.modelName = modelName
        self.similarConditions = similarConditions
        self.notes = notes
    }
    
    //set image - either from gallery or from camera or from model (screenshot) (ideally needs to be top down view). Can it get dermnet image maybe?
    func setImage(){
        
    }
    
    func changeTreatment(){
        
    }
    
    
    //link to (all or most compatible?)other skin conditions, related by texture, colour, diagnosis method, treatment etc
    //do i need information about how they are connected?
    func addLink(){
        
    }
    
    func removeConditionLink(){
        
    }
}
