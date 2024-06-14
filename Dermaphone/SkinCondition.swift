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
    var image : [UIImage]?
    var texture : String?//features e.g. colour
    var symptoms : String?
    var treatment: String?
    let modelName : String
    let modelFile : String
    var similarConditions : [(SkinCondition, String)]?
    var notes : String?
    var heightMap : [[Float]]
    let urgency : String?
    var isCreated : Bool
    var rotationScale : Int
 //   let model : [skinmodel]//Should this be a view controller? List of all models that are this skin condition
    init(name : String, description : String, texture : String, symptoms : String, treatment : String, modelName : String, images : [UIImage], modelFile : String, similarConditions : [(SkinCondition, String)], notes : String, urgency : String, heightMap : [[Float]], isCreated : Bool, rotationScale : Int ){
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
        self.urgency = urgency
        self.heightMap = heightMap
        self.isCreated = isCreated
        self.rotationScale = rotationScale
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
