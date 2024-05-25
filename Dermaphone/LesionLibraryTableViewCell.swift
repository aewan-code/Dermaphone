//
//  LesionLibraryTableViewCell.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 23/05/2024.
//

import UIKit

protocol LesionLibraryTableViewCellDelegate: AnyObject {
    func buttonPressed(forModel model: SkinCondition)
}
class LesionLibraryTableViewCell: UITableViewCell {

    @IBOutlet weak var viewButton: UIButton!
    @IBOutlet weak var modelImage: UIImageView!
    @IBOutlet weak var modelName: UILabel!
    
    static let identifier = "LesionLibraryTableViewCell"
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    static func nib() -> UINib {
        return UINib(nibName: "LesionLibraryTableViewCell", bundle: nil)
    }
    
    weak var delegate: LesionLibraryTableViewCellDelegate?
    var currentModel : SkinCondition?
    func configure(with model: SkinCondition){
        self.currentModel = model
        self.modelImage.image = model.image?.first
        self.modelName.text = model.name
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func buttonPressed(_ sender: UIButton) {
            try delegate?.buttonPressed(forModel: currentModel!)

    }

}
