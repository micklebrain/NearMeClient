//
//  AccountsTable.swift
//  NearMe
//
//  Created by Nathan Nguyen on 5/31/17.
//  Copyright © 2017 Nathan Nguyen. All rights reserved.
//

import Foundation
import AWSDynamoDB
//import AWSMobileHubHelper

//class AccountsTable : NSObject, Table {
//    
//    var tableName: String
//    var partitionKeyName: String
//    var partitionKeyType: String
//    var sortKeyName: String?
//    var sortKeyType: String?
//    var model: AWSDynamoDBObjectModel
//    var indexes: [Index]
//    var orderedAttributeKeys: [String] {
//        return produceOrderedAttributeKeys(model)
//    }
//    var tableDisplayName: String {
//        return "Accounts"
//    }
//    
//    override init() {
//        model = User()
//        tableName = model.classForCoder.dynamoDBTableName()
//        partitionKeyName = model.classForCoder.hashKeyAttribute()
//        partitionKeyType = "String"
//        
//        
//        super.init()
//    }
//    
//    func tableAttributeName(_ dataObjectAttributeName: String) -> String {
//        return Locations.jsonKeyPathsByPropertyKey()[dataObjectAttributeName] as! String
//    }
//    
//    func scanForNearbyUsers (locality : String, _ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void) {
//        let objectMapper = AWSDynamoDBObjectMapper.default()
//        let scanExpression = AWSDynamoDBScanExpression()
//        
//        scanExpression.filterExpression = "#locality = :locality"
//        scanExpression.expressionAttributeNames = ["#locality": "locality" ,]
//        scanExpression.expressionAttributeValues = [":userId": locality]
//        
//        objectMapper.scan(User.self, expression: scanExpression) { (reponse:
//            AWSDynamoDBPaginatedOutput?, error: Error?) in
//            DispatchQueue.main.async( execute: {
//                completionHandler(reponse, error as NSError?)
//            })
//        }
//    }
//    
//    
//}
