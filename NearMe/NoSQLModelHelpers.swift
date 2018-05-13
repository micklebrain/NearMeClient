////
////  NoSQLModelHelpers.swift
////  NearMe
////
////  Created by Nathan Nguyen on 4/24/17.
////  Copyright © 2017 Nathan Nguyen. All rights reserved.
////
//
//import Foundation
//
//let GetItem = "GetItem"
//let QueryWithPartitionKey = "QueryWithPartitionKey"
//let QueryWithPartitionKeyAndFilter = "QueryWithPartitionKeyAndFilter"
//let QueryWithPartitionKeyAndSortKey = "QueryWithPartitionKeyAndSortKey"
//let QueryWithPartitionKeyAndSortKeyAndFilter = "QueryWithPartitionKeyAndSortKeyAndFilter"
//let Scan = "Scan"
//let ScanWithFilter = "ScanWithFilter"
//
//@objc protocol Index {
//    var indexName: String? {get}
//    
//    func supportedOperations() -> [String]
//    
//    @objc optional func queryWithPartitionKeyDescription() -> String
//    
//    @objc optional func queryWithPartitionKeyWithCompletionHandler(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void)
//    
//    @objc optional func queryWithPartitionKeyAndFilterDescription() -> String
//    
//    @objc optional func queryWithPartitionKeyAndFilterWithCompletionHandler(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void)
//    
//    @objc optional func queryWithPartitionKeyAndSortKeyDescription() -> String
//    
//    @objc optional func queryWithPartitionKeyAndSortKeyWithCompletionHandler(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void)
//    
//    @objc optional func queryWithPartitionKeyAndSortKeyAndFilterDescription() -> String
//    
//    @objc optional func queryWithPartitionKeyAndSortKeyAndFilterWithCompletionHandler(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void)
//}
//
//@objc protocol Table {
//    
//    var tableName: String {get set}
//    var tableDisplayName: String {get}
//    var partitionKeyName: String {get set}
//    var partitionKeyType: String {get set}
//    var sortKeyName: String? {get set}
//    var sortKeyType: String? {get set}
//    var model: AWSDynamoDBObjectModel {get set}
//    var indexes: [Index] {get set}
//    var orderedAttributeKeys: [String] {get}
//    
//    /**
//     * Converts the attribute name from data object format to table format.
//     * This should be overriden by each table class.
//     *
//     * - parameter dataObjectAttributeName: data object attribute name
//     * - returns: table attribute name
//     */
//    @objc optional func tableAttributeName(_ dataObjectAttributeName: String) -> String
//    
//    @objc optional func getItemDescription() -> String
//    
//    @objc optional func getItemWithCompletionHandler(_ completionHandler: @escaping (_ response: AWSDynamoDBObjectModel?, _ error: NSError?) -> Void)
//    
//    @objc optional func scanDescription() -> String
//    
//    @objc optional func scanWithCompletionHandler(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void)
//    
//    @objc optional func scanWithFilterDescription() -> String
//    
//    @objc optional func scanWithFilterWithCompletionHandler(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void)
//    
//    @objc optional func insertSampleDataWithCompletionHandler(_ completionHandler: @escaping (_ errors: [NSError]?) -> Void)
//    
//    @objc optional func removeSampleDataWithCompletionHandler(_ completionHandler: @escaping (_ errors: [NSError]?) -> Void)
//    
//    @objc optional func updateItem(_ item: AWSDynamoDBObjectModel, completionHandler: @escaping (_ error: NSError?) -> Void)
//    
//    @objc optional func removeItem(_ item: AWSDynamoDBObjectModel, completionHandler: @escaping (_ error: NSError?) -> Void)
//    
//    @objc optional func produceOrderedAttributeKeys(_ model: AWSDynamoDBObjectModel)
//}
//
//extension Table {
//    
//    func produceOrderedAttributeKeys(_ model: AWSDynamoDBObjectModel) -> [String] {
//        let keysArray = Array(model.dictionaryValue.keys)
//        var keys = keysArray as! [String]
//        keys = keys.sorted()
//        
//        if let rangeKeyAttribute = model.classForCoder.rangeKeyAttribute?() {
//            let index = keys.index(of: rangeKeyAttribute)
//            if let index = index {
//                keys.remove(at: index)
//                keys.insert(rangeKeyAttribute, at: 0)
//            }
//        }
//        let hashKeyAttribute = model.classForCoder.hashKeyAttribute()
//        let index = keys.index(of: hashKeyAttribute)
//        if let index = index {
//            keys.remove(at: index)
//            keys.insert(hashKeyAttribute, at: 0)
//        }
//        return keys
//    }
//}
//
