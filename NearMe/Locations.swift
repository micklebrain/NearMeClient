////
////  Locations.swift
////  NearMe
////
////  Created by Nathan Nguyen on 4/21/17.
////  Copyright © 2017 Nathan Nguyen. All rights reserved.
////
//
//import Foundation
//
//class Locations: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
//    
//    var _userId: String?
//    var _itemId: String?
//    var _username: String? 
//    var _category: String?
//    var _latitude: NSNumber?
//    var _longitude: NSNumber?
//    var _name: String?
//    var _postalCode: String?
//    var _administrativeArea: String?
//    var _country: String?
//    var _locality: String?
//    
//    class func dynamoDBTableName() -> String {
//        return "nearme-mobilehub-1384398264-Locations"
//    }
//    
//    class func hashKeyAttribute() -> String {
//        return "_userId"
//    }
//    
//    class func rangeKeyAttribute() -> String {
//        return "_itemId"
//    }
//    
//    override class func jsonKeyPathsByPropertyKey() -> [AnyHashable: Any] {
//        return [
//            "_userId" : "userId",
//            "_username" : "username",
//            "_itemId" : "itemId",
//            "_category" : "category",
//            "_latitude" : "latitude",
//            "_longitude" : "longitude",
//            "_name" : "name",
//            "_postalCode" : "postalCode",
//            "_administrativeArea" : "administrativeArea",
//            "_country" : "country",
//            "_locality" : "locality"
//        ]
//    }
//    
//}
