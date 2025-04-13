//
//  Patient+Extensions.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 28/02/25.
//

import Foundation
import CoreData

extension Patient {
    var fullName: String {
        let first = firstName ?? ""
        let last = lastName ?? ""
        return "\(first) \(last)".trimmingCharacters(in: .whitespaces)
    }
}
