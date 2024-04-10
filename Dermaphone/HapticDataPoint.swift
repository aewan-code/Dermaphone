//
//  HapticDataPoint.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 10/04/2024.
//

import Foundation

struct HapticDataPoint : Identifiable {
    var id = UUID().uuidString
    var intensity : Float
    var time : Float
}
