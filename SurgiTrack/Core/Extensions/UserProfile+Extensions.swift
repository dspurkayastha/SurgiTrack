//
//  UserProfile+Extensions.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 12/03/25.
//

import SwiftUI

extension UserProfile {
    var fullName: String {
        let fName = firstName ?? ""
        let lName = lastName ?? ""
        return "\(fName) \(lName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var initials: String {
        let fInitial = (firstName ?? "").first.map { String($0) } ?? ""
        let lInitial = (lastName ?? "").first.map { String($0) } ?? ""
        return (fInitial + lInitial).uppercased()
    }
}
