//
//  GeorgiaTable.swift
//  NearMe                  
//
//  Created by Nathan Nguyen on 5/31/17.
//  Copyright © 2017 Nathan Nguyen. All rights reserved.
//

import Foundation
import AWSDynamoDB
//import AWSMobileHubHelper

class GeorgiaTable: NSObject, Table {
    
    var tableName: String
    var partitionKeyName: String
    var partitionKeyType: String
    var sortKeyName: String?
    var sortKeyType: String?
    var model: AWSDynamoDBObjectModel
    var indexes: [Index]
    var orderedAttributeKeys: [String] {
        return produceOrderedAttributeKeys(model)
    }
    var tableDisplayName: String {
        return "Georgia"
    }
    
    override init() {
        
        model = Locations()
        
        tableName = model.classForCoder.dynamoDBTableName()
        partitionKeyName = model.classForCoder.hashKeyAttribute()
        partitionKeyType = "String"
        indexes = [
            
            LocationsPrimaryIndex(),
            
            LocationsCategories()
        ]
        if let sortKeyNamePossible = model.classForCoder.rangeKeyAttribute?() {
            sortKeyName = sortKeyNamePossible
            sortKeyType = "String"
        }
        super.init()
    }
    
}
