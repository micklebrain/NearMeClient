//
//  Person.swift
//  NearMe
//
//  Created by Nathan Nguyen on 4/18/17.
//  Copyright © 2017 Nathan Nguyen. All rights reserved.
//

import Foundation

func ==(lhs: Person, rhs: Person) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

class Person : Hashable {
    
    var firstName : String?
    var middleName : String?
    var lastName : String?
    var userId : String?
    
    var online : Bool = true
    
    var hashValue: Int {
        get {
            return (firstName?.hashValue)!
        }
    }
    
//    init(firstName: String) {
//        self.firstName = firstName
//    }
    
}
