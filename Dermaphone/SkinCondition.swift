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
    //let image : ImageLoader
    let texture : String?//features e.g. colour
    let diagnosis : String?
    let treatment: String?
    let model : skinmodel//Should this be a view controller
    init(name : String, description : String, cause : String, texture : String, diagnosis : String, treatment : String, model : skinmodel){
        self.name = name
        self.description = description
        self.cause = cause
        self.texture = texture
        self.diagnosis = diagnosis
        self.treatment = treatment
        self.model = model
    }
}
