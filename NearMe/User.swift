//
//  user.swift
//  NearMe
//
//  Created by Nathan Nguyen on 5/25/17.
//  Copyright © 2017 Nathan Nguyen. All rights reserved.
//

import Foundation
import AWSDynamoDB
import CoreLocation

// TODO: Pick between person or user
class User : AWSDynamoDBObjectModel,AWSDynamoDBModeling {
    
    var username : String?
    var userID : NSNumber?
    var firstName : String?
    var lastName : String?
    var profilePicture : UIImage?
    var online : NSNumber = true
    var sex : String?
    var friends : NSMutableSet?
    var friendRequests: [String]?
    var headshot: UIImage?
    
    var address : String?
    var facebookId : NSNumber?
//  var occupation : String?
//  var relationshipStatus : String?
    var password : String?
//  var interests = [String]()
    var facebookUserID : String?
//  var emailAddress : String?
//  var weekendPlans = [String: String]()
    
//  location purposes
    var location : CLLocation?
    var postalCode: String?
    var administrativeArea: String?
    var country: String?
    var locality: String?
    var latitude: NSNumber?
    var longitude: NSNumber?
    var buildingOccupied: String?
    
    class func dynamoDBTableName() -> String {
        return "accounts"
    }
    
    class func hashKeyAttribute() -> String {
        return "username"
    }
    
}
