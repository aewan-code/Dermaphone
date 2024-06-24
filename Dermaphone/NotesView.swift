//
//  NotesView.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 30/04/2024.
//

import Foundation
import UIKit
protocol NotesViewControllerDelegate: AnyObject {
    func notesViewController(_ controller: NotesView, didUpdateNotes notes: String, type: String)
}

class NotesView : UIViewController {
    @IBOutlet weak var studentNotes: UIView!
    weak var delegate: NotesViewControllerDelegate?
    
    @IBOutlet weak var NotesTitle: UILabel!
    var editMode = false
    var labelTitle : String?
    var notesType : String?
    var textContent : NSAttributedString?
    var usertype : LesionLibrary.SourceType?
    @IBOutlet weak var text: UITextView!
    @IBOutlet weak var editButton: UIButton!
    var condition : SkinCondition?
    override func viewDidLoad() {
        super.viewDidLoad()
        editMode = false
        text.isEditable = false
        //  text.isUserInteractionEnabled = false
        text.isScrollEnabled = true
        text.isEditable = false
        NotesTitle.text = labelTitle ?? ""
        text.attributedText = textContent ?? parseAndFormatText("")
        switch usertype{
        case .consultant:
            editButton.isHidden = false
            studentNotes.isHidden = true
        case .student:
            editButton.isHidden = true
            studentNotes.isHidden = false
        
        case .none:
            editButton.isHidden = true
        }
        
    }
    //edge case - sort out clicking similar conditions
    func set(condition : SkinCondition, type : String, user : LesionLibrary.SourceType){
        self.condition = condition
        self.notesType = type
        print("text")
        switch type {
        case "Notes":
            labelTitle = "Clinical Notes"
            print(self.condition?.notes)
            textContent = parseAndFormatText(self.condition?.notes ?? "")
        case "Treatment":
            labelTitle = "Treatment"
            print(self.condition?.treatment)
            textContent = parseAndFormatText(self.condition?.treatment ?? "")
        case "Symptoms":
            labelTitle = "Overview"
            print(self.condition?.symptoms)
            textContent = parseAndFormatText(self.condition?.symptoms ?? "")
        default://should never enter this
            labelTitle = "Error"
            textContent = parseAndFormatText("")
        }
        self.usertype = user
        

        
    }
    @IBAction func editTouched(_ sender: Any) {
        if editMode{
            editMode = false
            text.isEditable = false
          //  text.isUserInteractionEnabled = false
         //   editButton.isHighlighted = false
            editButton.backgroundColor = .blue
            editButton.tintColor = .blue
            text.isScrollEnabled = true
            text.isEditable = false
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
          //  text.isUserInteractionEnabled = true
         //   editButton.isHighlighted = true

            editButton.backgroundColor = .green
            editButton.tintColor = .green
        }
    }
    
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        // Assume notesTextView contains the edited notes
        let updatedNotes = text.text
        print(updatedNotes)

        // Notify the delegate about the update
        delegate?.notesViewController(self, didUpdateNotes: updatedNotes ?? "", type: notesType ?? "")
        print("hi")
        
        // Dismiss or pop the view controller
        navigationController?.popViewController(animated: true)
    }
    
    func parseAndFormatText(_ rawText: String) -> NSAttributedString {
        let fullAttributedString = NSMutableAttributedString()
        let lines = rawText.components(separatedBy: "\\n")
        print("start")
        print(lines)

        let titleAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)]
        let bulletPointAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
        let bodyAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
        let boldAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)]

        var previousLineWasEmpty = true

        for line in lines {
            if line.starts(with: " ##") || line.starts(with: "  ##") || line.starts(with: "##"){  // Bold
                let bold = line.replacingOccurrences(of: "## ", with: "")
                let attributedBold = NSAttributedString(string: bold + "\n", attributes: boldAttributes)
                fullAttributedString.append(attributedBold)
                previousLineWasEmpty = false
            } else if line.starts(with: " -") {  // Bullet points
                let bulletPoint = line.replacingOccurrences(of: "- ", with: "• ")
                let attributedBulletPoint = NSAttributedString(string: bulletPoint + "\n", attributes: bulletPointAttributes)
                fullAttributedString.append(attributedBulletPoint)
                previousLineWasEmpty = false
            } else if line.starts(with: " #") || line.starts(with: "  #") || line.starts(with: "#"){//Title
                let title = line.replacingOccurrences(of: "# ", with: "")
                let attributedTitle = NSAttributedString(string: title + "\n", attributes: titleAttributes)
                fullAttributedString.append(attributedTitle)
                previousLineWasEmpty = false
            } else if line.isEmpty {
                previousLineWasEmpty = true
            } else if !previousLineWasEmpty {  // Continuation of previous text
                let continuationText = NSAttributedString(string: line + "\n", attributes: bodyAttributes)
                fullAttributedString.append(continuationText)
            } else {  // Body text
                let bodyText = NSAttributedString(string: line + "\n", attributes: bodyAttributes)
                fullAttributedString.append(bodyText)
                previousLineWasEmpty = false
            }
        }

        return fullAttributedString
    }
}

extension String {
  func convertToAttributedString() -> NSAttributedString? {
      guard let data = self.data(using: .utf8) else { return nil }
      do {
          return try NSAttributedString(data: data,
                                        options: [.documentType: NSAttributedString.DocumentType.html,
                                                  .characterEncoding: String.Encoding.utf8.rawValue],
                                        documentAttributes: nil)
      } catch {
          print("Error converting string to NSAttributedString: \(error)")
          return nil
      }
  }
}
