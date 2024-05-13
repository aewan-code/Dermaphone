//
//  DataExtensions.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 13/05/2024.
//

import Foundation

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8){
            self.append(data)
        }
    }
}
