//
//  LocationsTable.swift
//  NearMe
//
//  Created by Nathan Nguyen on 4/24/17.
//  Copyright © 2017 Nathan Nguyen. All rights reserved.
//

import Foundation
import UIKit
import AWSDynamoDB
import AWSMobileHubHelper

class LocationsTable: NSObject, Table {
    
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
        return "Locations"
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
    
    /**
     * Converts the attribute name from data object format to table format.
     *
     * - parameter dataObjectAttributeName: data object attribute name
     * - returns: table attribute name
     */
    
    func tableAttributeName(_ dataObjectAttributeName: String) -> String {
        return Locations.jsonKeyPathsByPropertyKey()[dataObjectAttributeName] as? String
    }
    
    func getItemDescription() -> String {
        let hashKeyValue = AWSIdentityManager.default().identityId!
        let rangeKeyValue = "demo-itemId-500000"
        return "Find Item with userId = \(hashKeyValue) and itemId = \(rangeKeyValue)."
    }
    
    func getItemWithCompletionHandler(_ completionHandler: @escaping (_ response: AWSDynamoDBObjectModel?, _ error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        objectMapper.load(Locations.self, hashKey: AWSIdentityManager.default().identityId!, rangeKey: "demo-itemId-500000") { (response: AWSDynamoDBObjectModel?, error: Error?) in
            DispatchQueue.main.async(execute: {
                completionHandler(response, error as NSError?)
            })
        }
    }
    
    func scanDescription() -> String {
        return "Show all items in the table."
    }
    
    func scanWithCompletionHandler(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        let scanExpression = AWSDynamoDBScanExpression()
//        scanExpression.limit = 5
        
        objectMapper.scan(Locations.self, expression: scanExpression) { (response: AWSDynamoDBPaginatedOutput?, error: Error?) in
            DispatchQueue.main.async(execute: {
                completionHandler(response, error as NSError?)
            })
        }
    }
    
    func scanWithFilterDescription() -> String {
        let scanFilterValue = 1111500000
        return "Find all items with latitude < \(scanFilterValue)."
    }
    
    // Scan for Taito
    func scanWithFilterWithCompletionHandler(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        let scanExpression = AWSDynamoDBScanExpression()
        
        scanExpression.filterExpression = "#userId = :userId"
        scanExpression.expressionAttributeNames = ["#userId": "userId" ]
        scanExpression.expressionAttributeValues = [":userId": "us-east-1:f010eb24-60f4-4896-b08b-6ce65e35fb39"]
        
        objectMapper.scan(Locations.self, expression: scanExpression) { (response: AWSDynamoDBPaginatedOutput?, error: Error?) in
            DispatchQueue.main.async(execute: {
                completionHandler(response, error as NSError?)
            })
        }
    }
    
    func insertSampleDataWithCompletionHandler(_ completionHandler: @escaping (_ errors: [NSError]?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        var errors: [NSError] = []
        let group: DispatchGroup = DispatchGroup()
        let numberOfObjects = 20
        
        let itemForGet: Locations! = Locations()
        
        itemForGet._userId = AWSIdentityManager.default().identityId!
        itemForGet._itemId = "demo-itemId-500000"
        itemForGet._category = NoSQLSampleDataGenerator.randomPartitionSampleStringWithAttributeName("category")
        itemForGet._latitude = NoSQLSampleDataGenerator.randomSampleNumber()
        itemForGet._longitude = NoSQLSampleDataGenerator.randomSampleNumber()
        itemForGet._name = NoSQLSampleDataGenerator.randomSampleStringWithAttributeName("name")
        group.enter()
        
        objectMapper.save(itemForGet, completionHandler: {(error: Error?) -> Void in
            if let error = error as NSError? {
                DispatchQueue.main.async(execute: {
                    errors.append(error)
                })
            }
            group.leave()
        })
        
        for _ in 1..<numberOfObjects {
            
            let item: Locations = Locations()
            item._userId = AWSIdentityManager.default().identityId!
            item._itemId = NoSQLSampleDataGenerator.randomSampleStringWithAttributeName("itemId")
            item._category = NoSQLSampleDataGenerator.randomPartitionSampleStringWithAttributeName("category")
            item._latitude = NoSQLSampleDataGenerator.randomSampleNumber()
            item._longitude = NoSQLSampleDataGenerator.randomSampleNumber()
            item._name = NoSQLSampleDataGenerator.randomSampleStringWithAttributeName("name")
            
            group.enter()
            
            objectMapper.save(item, completionHandler: {(error: Error?) -> Void in
                if error != nil {
                    DispatchQueue.main.async(execute: {
                        errors.append(error! as NSError)
                    })
                }
                group.leave()
            })
        }
        
        group.notify(queue: DispatchQueue.main, execute: {
            if errors.count > 0 {
                completionHandler(errors)
            } else {
                completionHandler(nil)
            }
        })
    }
    
    func removeSampleDataWithCompletionHandler(_ completionHandler: @escaping ([NSError]?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.keyConditionExpression = "#userId = :userId"
        queryExpression.expressionAttributeNames = ["#userId": "userId"]
        queryExpression.expressionAttributeValues = [":userId": AWSIdentityManager.default().identityId!]
        
        objectMapper.query(Locations.self, expression: queryExpression) { (response: AWSDynamoDBPaginatedOutput?, error: Error?) in
            if let error = error as NSError? {
                DispatchQueue.main.async(execute: {
                    completionHandler([error])
                })
            } else {
                var errors: [NSError] = []
                let group: DispatchGroup = DispatchGroup()
                for item in response!.items {
                    group.enter()
                    objectMapper.remove(item, completionHandler: {(error: Error?) in
                        if let error = error as NSError? {
                            DispatchQueue.main.async(execute: {
                                errors.append(error)
                            })
                        }
                        group.leave()
                    })
                }
                group.notify(queue: DispatchQueue.main, execute: {
                    if errors.count > 0 {
                        completionHandler(errors)
                    } else {
                        completionHandler(nil)
                    }
                })
            }
        }
    }
    
    func updateItem(_ item: AWSDynamoDBObjectModel, completionHandler: @escaping (_ error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        
        if let itemToUpdate: Locations = item as? Locations {
        
            itemToUpdate._category = NoSQLSampleDataGenerator.randomPartitionSampleStringWithAttributeName("category")
            itemToUpdate._latitude = NoSQLSampleDataGenerator.randomSampleNumber()
            itemToUpdate._longitude = NoSQLSampleDataGenerator.randomSampleNumber()
            itemToUpdate._name = NoSQLSampleDataGenerator.randomSampleStringWithAttributeName("name")
            
            objectMapper.save(itemToUpdate, completionHandler: {(error: Error?) in
                DispatchQueue.main.async(execute: {
                    completionHandler(error as NSError?)
                })
            })
        }
    }
    
    func removeItem(_ item: AWSDynamoDBObjectModel, completionHandler: @escaping (_ error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        
        objectMapper.remove(item, completionHandler: {(error: Error?) in
            DispatchQueue.main.async(execute: {
                completionHandler(error as NSError?)
            })
        })
    }
}

class LocationsPrimaryIndex: NSObject, Index {
    
    var indexName: String? {
        return nil
    }
    
    func supportedOperations() -> [String] {
        return [
            QueryWithPartitionKey,
            QueryWithPartitionKeyAndFilter,
            QueryWithPartitionKeyAndSortKey,
            QueryWithPartitionKeyAndSortKeyAndFilter
        ]
    }
    
    func queryWithPartitionKeyDescription() -> String {
        let partitionKeyValue = AWSIdentityManager.default().identityId!
        return "Find all items with userId = \(partitionKeyValue)."
    }
    
    func queryWithPartitionKeyWithCompletionHandler(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.keyConditionExpression = "#userId = :userId"
        queryExpression.expressionAttributeNames = ["#userId": "userId"]
        queryExpression.expressionAttributeValues = [":userId": "us-east-1:4b61e13c-d551-4242-9ccf-fc300788885f"]
        
        objectMapper.query(Locations.self, expression: queryExpression) { (response: AWSDynamoDBPaginatedOutput?, error: Error?) in
            DispatchQueue.main.async(execute: {
                completionHandler(response, error as NSError?)
            })
        }
        
    }
    
    func queryWithPartitionKeyAndFilterDescription() -> String {
        let partitionKeyValue = AWSIdentityManager.default().identityId!
        let filterAttributeValue = 1111500000
        return "Find all items with userId = \(partitionKeyValue) and latitude > \(filterAttributeValue)."
    }
    
    func queryWithPartitionKeyAndFilterWithCompletionHandler(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.keyConditionExpression = "#userId = :userId"
        //  queryExpression.filterExpression = "#username = :username"
        queryExpression.expressionAttributeNames = [
            "#userId": "userId"
        //   "#username": "username",
        ]
        queryExpression.expressionAttributeValues = [
            //":userId": AWSIdentityManager.default().identityId!,
            // Dont use userId
                ":userId": "us-east-1:b3625c1e-f62e-4e01-8dde-ee5f2603949e"
            // ":userId": "us-east-1:4b61e13c-d551-4242-9ccf-fc300788885f",
            //  ":username": "tester"
        ]
        
        objectMapper.query(Locations.self, expression: queryExpression, completionHandler: {(response: AWSDynamoDBPaginatedOutput?, error: Error?) in
            DispatchQueue.main.async(execute: {
                completionHandler(response, error as NSError?)
            })
        })
    }
    
    func queryWithPartitionKeyAndSortKeyDescription() -> String {
        let partitionKeyValue = AWSIdentityManager.default().identityId!
        let sortKeyValue = "demo-itemId-500000"
        return "Find all items with userId = \(partitionKeyValue) and itemId < \(sortKeyValue)."
    }
    
    func queryWithPartitionKeyAndSortKeyWithCompletionHandler(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.keyConditionExpression = "#userId = :userId AND #itemId < :itemId"
        queryExpression.expressionAttributeNames = [
            "#userId": "userId",
            "#itemId": "itemId"
        ]
        queryExpression.expressionAttributeValues = [
            ":userId": AWSIdentityManager.default().identityId!,
            ":itemId": "demo-itemId-500000"
        ]
        
        objectMapper.query(Locations.self, expression: queryExpression, completionHandler: {(response: AWSDynamoDBPaginatedOutput?, error: Error?) -> Void in
            DispatchQueue.main.async(execute: {
                completionHandler(response, error as NSError?)
            })
        })
    }
    
    func queryWithPartitionKeyAndSortKeyAndFilterDescription() -> String {
        let partitionKeyValue = AWSIdentityManager.default().identityId!
        let sortKeyValue = "demo-itemId-500000"
        let filterValue = 1111500000
        return "Find all items with userId = \(partitionKeyValue), itemId < \(sortKeyValue), and latitude > \(filterValue)."
    }
    
    func queryWithPartitionKeyAndSortKeyAndFilterWithCompletionHandler(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.keyConditionExpression = "#userId = :userId AND #itemId < :itemId"
        queryExpression.filterExpression = "#latitude > :latitude"
        queryExpression.expressionAttributeNames = [
            "#userId": "userId",
            "#itemId": "itemId",
            "#latitude": "latitude"
        ]
        queryExpression.expressionAttributeValues = [
            ":userId": AWSIdentityManager.default().identityId!,
            ":itemId": "demo-itemId-500000",
            ":latitude": 1111500000
        ]
        
        objectMapper.query(Locations.self, expression: queryExpression, completionHandler: {(response: AWSDynamoDBPaginatedOutput?, error: Error?) in
            DispatchQueue.main.async(execute: {
                completionHandler(response, error as NSError?)
            })
        })
    }
}

class LocationsCategories: NSObject, Index {
    
    var indexName: String? {
        
        return "Categories"
    }
    
    func supportedOperations() -> [String] {
        return [
            QueryWithPartitionKey,
            QueryWithPartitionKeyAndFilter,
            QueryWithPartitionKeyAndSortKey,
            QueryWithPartitionKeyAndSortKeyAndFilter
        ]
    }
    
    func queryWithPartitionKeyDescription() -> String {
        let partitionKeyValue = "demo-category-3"
        return "Find all items with category = \(partitionKeyValue)."
    }
    
    func queryWithPartitionKeyWithCompletionHandler(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.indexName = "Categories"
        queryExpression.keyConditionExpression = "#category = :category"
        queryExpression.expressionAttributeNames = ["#category": "category"]
        queryExpression.expressionAttributeValues = [":category": "demo-category-1"]
        
        objectMapper.query(Locations.self, expression: queryExpression) { (response: AWSDynamoDBPaginatedOutput?, error: Error?) in
            DispatchQueue.main.async(execute: {
                completionHandler(response, error as NSError?)
            })
        }
    }
    
    func queryWithPartitionKeyAndFilterDescription() -> String {
        let partitionKeyValue = "demo-category-3"
        let filterAttributeValue = "demo-itemId-500000"
        return "Find all items with category = \(partitionKeyValue) and itemId > \(filterAttributeValue)."
    }
    
    func queryWithPartitionKeyAndFilterWithCompletionHandler(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.indexName = "Categories"
        queryExpression.keyConditionExpression = "#category = :category"
        queryExpression.filterExpression = "#itemId > :itemId"
        queryExpression.expressionAttributeNames = [
            "#category": "category",
            "#itemId": "itemId"
        ]
        queryExpression.expressionAttributeValues = [
            ":category": "demo-category-3",
            ":itemId": "demo-itemId-500000"
        ]
        
        objectMapper.query(Locations.self, expression: queryExpression, completionHandler: {(response: AWSDynamoDBPaginatedOutput?, error: Error?) in
            DispatchQueue.main.async(execute: {
                completionHandler(response, error as NSError?)
            })
        })
    }
    
    func queryWithPartitionKeyAndSortKeyDescription() -> String {
        let partitionKeyValue = "demo-category-3"
        let sortKeyValue = 1111500000
        return "Find all items with category = \(partitionKeyValue) and longitude < \(sortKeyValue)."
    }
    
    func queryWithPartitionKeyAndSortKeyWithCompletionHandler(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.indexName = "Categories"
        queryExpression.keyConditionExpression = "#category = :category AND #longitude < :longitude"
        queryExpression.expressionAttributeNames = [
            "#category": "category",
            "#longitude": "longitude"
        ]
        queryExpression.expressionAttributeValues = [
            ":category": "demo-category-3",
            ":longitude": 1111500000
        ]
        
        objectMapper.query(Locations.self, expression: queryExpression, completionHandler: {(response: AWSDynamoDBPaginatedOutput?, error: Error?) -> Void in
            DispatchQueue.main.async(execute: {
                completionHandler(response, error as NSError?)
            })
        })
    }
    
    func queryWithPartitionKeyAndSortKeyAndFilterDescription() -> String {
        let partitionKeyValue = "demo-category-3"
        let sortKeyValue = 1111500000
        let filterValue = "demo-itemId-500000"
        return "Find all items with category = \(partitionKeyValue), longitude < \(sortKeyValue), and itemId > \(filterValue)."
    }
    
    func queryWithPartitionKeyAndSortKeyAndFilterWithCompletionHandler(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.indexName = "Categories"
        queryExpression.keyConditionExpression = "#category = :category AND #longitude < :longitude"
        queryExpression.filterExpression = "#itemId > :itemId"
        queryExpression.expressionAttributeNames = [
            "#category": "category",
            "#longitude": "longitude",
            "#itemId": "itemId"
        ]
        queryExpression.expressionAttributeValues = [
            ":category": "demo-category-3",
            ":longitude": 1111500000,
            ":itemId": "demo-itemId-500000"
        ]
        
        objectMapper.query(Locations.self,
                           expression: queryExpression,
                           completionHandler: {(response: AWSDynamoDBPaginatedOutput?, error: Error?) in
            DispatchQueue.main.async(execute: {
                completionHandler(response, error as NSError?)
            })
        })
    }
}
