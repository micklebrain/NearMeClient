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

enum sex : String {
    case male = "male"
    case female = "female"
}

enum relationshipStatus {
    case single
    case married
    case taken
}

func == (lhs: User, rhs: User) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

class User : Hashable {
    
    //Account
    var userId : NSNumber?
    var username : String?
    var password : String?
    
    //Individual
    var firstName : String?
    var middleName : String?
    var lastName : String?
    var sex : sex?
    
    var friends : [String]?
    var school : String?
//    var headshotImage: UIImage?
    var headshot = #imageLiteral(resourceName: "empty-headshot.jpg")
    var facebookId : String?
    var online : Bool?
    var profilePicture : UIImage?
    var friendRequests: [String]?
    var address : String?
    //  var occupation : String?
    //  var relationshipStatus : String?
    //  var interests = [String]()
    //  var emailAddress : String?
    //  var weekendPlans = [String: String]()
    
    //  Location
    var lastLocation: CLLocation?
    var lastPlacemark: CLPlacemark?
    var currentLocation : location?
    var location : CLLocation?
    var postalCode: String?
    var administrativeArea: String?
    var country: String?
    var locality: String?
    var latitude: NSNumber?
    var longitude: NSNumber?
    var buildingOccupied: String?
    var floor: Int!
    
    var hashValue: Int {
        get {
            return (username?.hashValue)!
        }
    }
    
}
