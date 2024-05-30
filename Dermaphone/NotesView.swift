//
//  NotesView.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 30/04/2024.
//

import Foundation
import UIKit

class NotesView : UIViewController {
    
    @IBOutlet weak var NotesTitle: UILabel!
    var editMode = false
    var labelTitle : String?
    var notesType : String?
    var textContent : String?
    @IBOutlet weak var text: UITextView!
    @IBOutlet weak var editButton: UIButton!
    var condition : SkinCondition?
    override func viewDidLoad() {
        super.viewDidLoad()
        editMode = false
        text.isEditable = false
        text.isUserInteractionEnabled = false
        NotesTitle.text = labelTitle ?? ""
        text.text = textContent ?? ""
    //    editButton.setTitle("Done", for: .highlighted)
   //     editButton.setTitle("Edit", for: .normal)
        
    }
    //edge case - sort out clicking similar conditions
    func set(condition : SkinCondition, type : String){
        self.condition = condition
        self.notesType = type
        switch type {
        case "Notes":
            labelTitle = "Clinical Notes"
            textContent = self.condition?.notes ?? ""
        case "Treatment":
            labelTitle = "Treatment"
            textContent = self.condition?.treatment ?? ""
        case "Symptoms":
            labelTitle = "Symptoms"
            textContent = self.condition?.symptoms ?? ""
        default://should never enter this
            labelTitle = "Error"
            textContent = ""
        }
        
    }
    @IBAction func editTouched(_ sender: Any) {
        if editMode{
            editMode = false
            text.isEditable = false
            text.isUserInteractionEnabled = false
         //   editButton.isHighlighted = false
            editButton.backgroundColor = .blue
            editButton.tintColor = .blue
            switch notesType {
            case "Notes":
                break
            case "Treatment":
                break
            case "Symptoms":
                break
            default://should never enter this
                break//how to change model's value
            }
            
        }
        else{
            editMode = true
            text.isEditable = true
            text.isUserInteractionEnabled = true
         //   editButton.isHighlighted = true

            editButton.backgroundColor = .green
            editButton.tintColor = .green
        }
    }
}
