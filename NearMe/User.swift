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

func == (lhs: User, rhs: User) -> Bool {
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

class User : Hashable /* AWSDynamoDBObjectModel,AWSDynamoDBModeling */ {
    
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
    var headshotImage: UIImage?
    var facebookId : String?
    var online : Bool = true
    var profilePicture : UIImage?
    var friendRequests: [String]?
    var headshot: UIImage?
    var address : String?
    //  var occupation : String?
    //  var relationshipStatus : String?
    //  var interests = [String]()
    //  var emailAddress : String?
    //  var weekendPlans = [String: String]()
    
    //  Location
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
    
    //    Has to change first name will not be unique
    var hashValue: Int {
        get {
            return (firstName?.hashValue)!
        }
    }
    
    //    class func dynamoDBTableName() -> String {
    //        return "accounts"
    //    }
    //
    //    class func hashKeyAttribute() -> String {
    //        return "username"
    //    }
    
}
