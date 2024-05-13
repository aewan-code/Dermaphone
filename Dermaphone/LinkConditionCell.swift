//
//  LinkConditionCell.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 09/05/2024.
//

import UIKit

protocol LinkConditionCellDelegate: AnyObject {
    func buttonPressed(forModel model: SkinCondition)
}

class LinkConditionCell: UITableViewCell {

    @IBOutlet weak var modelImage: UIImageView!
    
    @IBOutlet weak var modelLink: UILabel!
    @IBOutlet weak var modelName: UILabel!

    @IBOutlet weak var viewModel: UIButton!
    
    weak var delegate: LinkConditionCellDelegate?
    var currentModel : SkinCondition?

    @IBAction func buttonPressed(_ sender: UIButton) {
        if let model = currentModel {
            delegate?.buttonPressed(forModel: model)
        }
    }

}
