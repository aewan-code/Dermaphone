//
//  APIRequest.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 13/05/2024.
//

import Foundation
import UIKit

enum APIError:Error {
    case responseProblem
    case decodingProblem
    case encodingProblem
}

struct APIRequest {
    let resourceURL: URL
    let boundary: String = "Boundary-\(UUID().uuidString)"
    let imageArray:[UIImage] = [
        UIImage(named: "IMG_3904")!,
        UIImage(named: "IMG_3905")!,
        UIImage(named: "IMG_3906")!,
        UIImage(named: "IMG_3907")!,
        UIImage(named: "IMG_3908")!,
        UIImage(named: "IMG_3909")!,
        UIImage(named: "IMG_3910")!,
        UIImage(named: "IMG_3911")!,
        UIImage(named: "IMG_3912")!,
        UIImage(named: "IMG_3913")!,
        UIImage(named: "IMG_3914")!,
        UIImage(named: "IMG_3915")!,
        UIImage(named: "IMG_3916")!,
        UIImage(named: "IMG_3917")!,
        UIImage(named: "IMG_3918")!
    ]
    init(endpoint: String){
        let resourceString = "http://192.168.0.38:8000/\(endpoint)"
        guard let resourceURL = URL(string: resourceString) else {fatalError()}
        
        self.resourceURL = resourceURL
        print(resourceURL)
        
    }
    
    func send (_ messageToSend:Message, completion: @escaping(Result<Message, APIError>) -> Void){
        do {
            var urlRequest = URLRequest(url: resourceURL)
            urlRequest.httpMethod = "POST"
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONEncoder().encode(messageToSend)
            
            let dataTask = URLSession.shared.dataTask(with: urlRequest) { data, response, _ in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let jsonData = data else {
                    print(response)
                    print(data)
                    completion(.failure(.responseProblem))
                    return
                }
                
                do {
                    let messageData = try JSONDecoder().decode(Message.self, from: jsonData)
                    completion(.success(messageData))
                }catch{
                    completion(.failure(.decodingProblem))
                }
            }
            dataTask.resume()
        }catch{
            completion(.failure(.encodingProblem))
        }
    }
    
    func sendImage(){
        do{
            var urlRequest = URLRequest(url: resourceURL)
            urlRequest.httpMethod = "POST"
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("multipart/form-data; boundary=" + self.boundary, forHTTPHeaderField: "Content-Type")
            let requestBody = self.multipartFormDataBody(self.boundary, "Aleera", imageArray)
            urlRequest.httpBody = requestBody
            
            URLSession.shared.dataTask(with: urlRequest){
                data, resp, error in
                if let error = error {
                    print(error)
                    return
                }
                print("success")
            }.resume()
        }catch{
            
        }
    }
    
    private func multipartFormDataBody(_ boundary:String, _ fromName: String, _ images: [UIImage]) -> Data {
        
        let lineBreak = "\r\n"
        var body = Data()
        body.append("--\(boundary + lineBreak)")//cut off excess space and make a new line
        body.append("Content-Disposition: form-data; name=\"senderName\"\(lineBreak + lineBreak)")
        body.append("\(fromName + lineBreak)")
        
        for image in images {
            if let uuid = UUID().uuidString.components(separatedBy: "-").first {
                body.append("--\(boundary + lineBreak)")
                body.append("Content-Disposition: form-data; name=\"imageUploads\"; filename=\"\(uuid).jpg\"\(lineBreak) ")
                body.append("Content-Type: image/jpeg\(lineBreak + lineBreak)")
                body.append(image.jpegData(compressionQuality: 0.99)!)
                body.append(lineBreak)
            }
        }
        body.append("--\(boundary)--\(lineBreak)")//End multipart form and return
        return body
    }
}
