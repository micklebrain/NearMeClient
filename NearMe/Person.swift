//
//  Person.swift
//  NearMe
//
//  Created by Nathan Nguyen on 4/18/17.
//  Copyright © 2017 Nathan Nguyen. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

func == (lhs: Person, rhs: Person) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

enum sex : String {
    case male = "male"
    case female = "female"
}

enum relationshipStatus {
    case single
    case married
    case taken
}

class Person : Hashable {
    
    var firstName : String?
    var middleName : String?
    var lastName : String?
    var sex : sex?
    var userId : String?
    var username : String?
    var currentLocation : location?
    var location : CLLocation?
    var locality : String?
    var friends : [String]?
    var school : String?
    var headshotImage: UIImage?
    var facebookId : String?
    var online : Bool = true
    
    //    Has to change first name will not be unique
    var hashValue: Int {
        get {
            return (firstName?.hashValue)!
        }
    }
    
//    init(firstName: String) {
//        self.firstName = firstName
//    }
    
}
