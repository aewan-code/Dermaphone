//
//  Message.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 13/05/2024.
//

import Foundation

final class Message: Codable {
    var id:Int?
    var message: String
    
    init(message:String){
        self.message = message
    }
}
