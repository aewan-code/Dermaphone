//
//  LinkConditions.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 09/05/2024.
//

import UIKit

class LinkConditions: UIViewController, UITableViewDataSource, UITableViewDelegate, LinkConditionCellDelegate {
    //FIX THIS
    func buttonPressed(forModel model: SkinCondition) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "skinmodel") as? skinmodel else {
            return
        }
        vc.set(model: model)
        print("check")
        dismiss(animated: true) {
            // Presentation of new view controller should be done after the current view controller is dismissed
           // present(vc, animated: true, completion: nil)
            self.navigationController?.popToRootViewController(animated: true)
           // self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    var linkedConditions : [(SkinCondition, String)]?
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return linkedConditions?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let linkedModel = linkedConditions?[indexPath.row]
        print("link")
        print(linkedModel?.1)
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! LinkConditionCell
        cell.modelImage.image = linkedModel?.0.image?.first ?? nil
        cell.modelLink.text = linkedModel?.1 ?? ""
        cell.currentModel = linkedModel?.0
        print(cell.currentModel?.name)
        cell.modelName.text = linkedModel?.0.name ?? ""
        cell.delegate = self
        return cell
    }
    

    @IBOutlet weak var table: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        table.dataSource = self
        table.delegate = self
        // Do any additional setup after loading the view.
    }
    
    func set(linkedModels : [(SkinCondition, String)]){
        self.linkedConditions = linkedModels
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }

}
