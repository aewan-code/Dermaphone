//
//  DatabaseManagement.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 25/05/2024.
//

import UIKit
import Firebase
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class DatabaseManagement{
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    
    func getModelFromStorage(){
        // Create a reference with an initial file path and name
        let storage = Storage.storage()
        let pathReference = storage.reference(withPath: "models/ActinicKeratosis/testTransform.usda")
        let localURL = getDocumentsDirectory().appendingPathComponent("testModel.usda")
        // Create local filesystem URL
     //   let localURL = URL(string: "path/to/image")!

        // Download to the local filesystem
        let downloadTask = pathReference.write(toFile: localURL) { url, error in
            if let error = error {
              // Handle the error
              print("An error occurred: \(error)")
            } else if let url = url {
              // Use the local file URL for further operations
              print("Downloaded file available at: \(url)")
            }
        }
            
    }
    
    func downloadFile(from path: String, to localPath: URL, completion: @escaping (Bool) -> Void) {
        let storage = Storage.storage()
        let pathReference = storage.reference(withPath: path)
        let islandRef = storage.reference().child(path)

        // Start the file download
        let downloadTask = islandRef.write(toFile: localPath) { url, error in
            if let error = error {
                print("An error occurred: \(error)")
                completion(false)
            } else {
                print("Downloaded file available at: \(url)")
                completion(true)
            }
        }
    }
    
    func localFileURL(for fileName: String, directory: FileManager.SearchPathDirectory) -> URL {
        let path = FileManager.default.urls(for: directory, in: .userDomainMask)[0]
        return path.appendingPathComponent(fileName)
    }
}
