//
//  LesionLibrary.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 23/05/2024.
//
import RealityKit
import UIKit

class LesionLibrary: UIViewController, UITableViewDataSource{

    
    
    @IBOutlet weak var table: UITableView!
    var data : [SkinCondition] = []
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let linkedModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: LesionLibraryTableViewCell.identifier, for: indexPath) as! LesionLibraryTableViewCell
        cell.configure(with: data[indexPath.row])
        cell.delegate = self
        return cell
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        createModels()
        table.register(LesionLibraryTableViewCell.nib(), forCellReuseIdentifier: LesionLibraryTableViewCell.identifier)
        table.dataSource = self
        // Do any additional setup after loading the view.
    }

    func createModels(){
      //  let testModel = SkinCondition(name: "Test Model", description: "", texture: "", symptoms: "", treatment: "", modelName: "triangle", images: [], modelFile: "tri.scn", similarConditions: [], notes: "", urgency: "Test")
        let skin3Model = SkinCondition(name: "Actinic Keratosis", description: "(Precancerous) Most common precancer. Can evolve into squamous cell carcinoma", texture: "crusty rough spots", symptoms: "pink coloration", treatment: "", modelName: "Mesh", images: [], modelFile: "testTransform.scn", similarConditions: [], notes: "(Precancerous) Most common precancer. Can evolve into squamous cell carcinoma. Crusty rough spots", urgency: "Precancerous")
        let skin2Model = SkinCondition(name: "Basal Cell Carcinoma", description: "(Cancerous) Most common form of skin cancer. Normally found on body pars exposed to the sun", texture: "", symptoms: "recurring sore that bleeds and heals", treatment: "", modelName: "Mesh", images: [], modelFile: "test2scene.scn", similarConditions: [(skin3Model, "link to cancer")], notes: "(Cancerous) Most common form of skin cancer. Normally found on body pars exposed to the sun.", urgency: "Cancerous")
        if let image1 = UIImage(named: "IMG_3929") {
            skin3Model.image?.append(image1)
        }
        if let image2 = UIImage(named: "BasalImage") {
            skin2Model.image?.append(image2)
        }
     //   data.append(testModel)
        data.append(skin3Model)
        data.append(skin2Model)
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension LesionLibrary : LesionLibraryTableViewCellDelegate {
    func buttonPressed(forModel model: SkinCondition) {
        print("view button pressed")
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "skinmodel") as? skinmodel else {
            return
        }
        vc.set(model: model)
        print("check")
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
}
