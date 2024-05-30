//
//  LesionLibrary.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 23/05/2024.
//
import RealityKit
import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class LesionLibrary: UIViewController, UITableViewDataSource{

    @IBOutlet weak var createModel: UIButton!
    enum SourceType {
            case consultant, student
    }

    var sourceType: SourceType?
    

    
    
    
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
      //  createModels()

        // Do any additional setup after loading the view.
        configureBasedOnSource()
        Task {
            await loadModels()
            if sourceType == .consultant{
                await loadNewModels()
            }
        }


        
    }

    func createModels(){
      //  let testModel = SkinCondition(name: "Test Model", description: "", texture: "", symptoms: "", treatment: "", modelName: "triangle", images: [], modelFile: "tri.scn", similarConditions: [], notes: "", urgency: "Test")
        let skin3Model = SkinCondition(name: "Actinic Keratosis", description: "(Precancerous) Most common precancer. Can evolve into squamous cell carcinoma", texture: "crusty rough spots", symptoms: "pink coloration", treatment: "", modelName: "Mesh", images: [], modelFile: "testTransform.scn", similarConditions: [], notes: "(Precancerous) Most common precancer. Can evolve into squamous cell carcinoma. Crusty rough spots", urgency: "Precancerous", heightMap: [[]], isCreated: true)
        let skin2Model = SkinCondition(name: "Basal Cell Carcinoma", description: "(Cancerous) Most common form of skin cancer. Normally found on body pars exposed to the sun", texture: "", symptoms: "recurring sore that bleeds and heals", treatment: "", modelName: "Mesh", images: [], modelFile: "test2scene.scn", similarConditions: [(skin3Model, "link to cancer")], notes: "(Cancerous) Most common form of skin cancer. Normally found on body pars exposed to the sun.", urgency: "Cancerous", heightMap: [[]], isCreated: true)
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
    
    
    private func configureBasedOnSource() {
        print(sourceType)
            switch sourceType {
            case .consultant:
                // Configuration for when coming from User Login
                createModel.isHidden = false
                print("Came from User Login")
            case .student:
                // Configuration for when coming from Student Login
                createModel.isHidden = true
                print("Came from Student Login")
            case .none:
                break
            }
        }
    
    func loadModels() async{
        
        let db = Firestore.firestore()
        var skinConditions : [SkinCondition] = []
        do {
            let querySnapshot = try await db.collection("models").getDocuments()
          for document in querySnapshot.documents {
            print("\(document.documentID) => \(document.data())")
              print(type(of: document.data()["name"]))
              if let name = document.data()["name"] as? String,
                       let severity = document.data()["urgency"] as? String,
                       let symptoms = document.data()["symptoms"] as? String,
                       let treatment = document.data()["treatment"] as? String,
                       let notes = document.data()["clinicalNotes"] as? String
                {
                  print("check conditions created")
                  let condition = SkinCondition(name: name, description: "", texture: "", symptoms: symptoms, treatment: treatment, modelName: "", images: [], modelFile: "", similarConditions: [], notes: notes, urgency: severity, heightMap: [[]], isCreated: true)
                  skinConditions.append(condition)
              }
          }
            DispatchQueue.main.async {
                           // Ensure UI updates are on the main thread
                           //self.updateModelList()
                self.data = skinConditions
                print(self.data)
                self.table.register(LesionLibraryTableViewCell.nib(), forCellReuseIdentifier: LesionLibraryTableViewCell.identifier)
                self.table.dataSource = self
                       }
        } catch {
          print("Error getting documents: \(error)")
            DispatchQueue.main.async {
                           // Ensure UI updates are on the main thread
                           self.errorUI()
                       }
        }

    }
    
    func loadNewModels() async{
        let storage = Storage.storage()
        let storageReference = storage.reference().child("processingModels")
        var skinConditions : [SkinCondition] = []
        do {
          let result = try await storageReference.listAll()
          for prefix in result.prefixes {
              
            // The prefixes under storageReference.
            // You may call listAll(completion:) recursively on them.
          }
          for item in result.items {
              print(item.name)
              var name = item.name
              if let dotRange = name.range(of: ".") {
                name.removeSubrange(dotRange.lowerBound..<name.endIndex)
              }
              let condition = SkinCondition(name: name, description: "", texture: "", symptoms: "", treatment: "", modelName: "", images: [], modelFile: "", similarConditions: [], notes: "", urgency: "", heightMap: [[]], isCreated: false)
              skinConditions.append(condition)
            // The items under storageReference.
          }
            DispatchQueue.main.async {
                           // Ensure UI updates are on the main thread
                           //self.updateModelList()
                self.data.append(contentsOf: skinConditions)
                print(self.data)
                self.table.register(LesionLibraryTableViewCell.nib(), forCellReuseIdentifier: LesionLibraryTableViewCell.identifier)
                self.table.dataSource = self
                       }
        } catch {
          // ...
        }
    }
    
    func updateModelList(){
        
        
    }
    
    func errorUI(){
        
    }

}

extension LesionLibrary : LesionLibraryTableViewCellDelegate {
    func buttonPressed(forModel model: SkinCondition) {
        print("view button pressed")
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "skinmodel") as? skinmodel else {
            return
        }
        vc.set(model: model)
        vc.sourceType = self.sourceType
        print("check")
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
}
