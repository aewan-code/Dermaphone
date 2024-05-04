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
    @IBOutlet weak var text: UITextView!
    @IBOutlet weak var editButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        NotesTitle.text = "Symptoms"
        editMode = false
        text.isEditable = false
    //    editButton.setTitle("Done", for: .highlighted)
   //     editButton.setTitle("Edit", for: .normal)
        
    }
    
    @IBAction func editTouched(_ sender: Any) {
        if editMode{
            editMode = false
         //   editButton.isHighlighted = false
            editButton.backgroundColor = .blue
            editButton.tintColor = .blue
        }
        else{
            editMode = true
            text.isEditable = true
         //   editButton.isHighlighted = true

            editButton.backgroundColor = .green
            editButton.tintColor = .green
        }
    }
}
