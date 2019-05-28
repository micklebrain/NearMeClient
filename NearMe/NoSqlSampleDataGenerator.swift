//
//  NoSqlSampleDataGenerator.swift
//  NearMe
//
//  Created by Nathan Nguyen on 4/24/17.
//  Copyright © 2017 Nathan Nguyen. All rights reserved.
//

import Foundation

let NoSQLSampleDataGeneratorSampleDataStringPrefix: String = "demo"
let NoSQLSampleDataGeneratorSampleDataNumberMinimum: UInt32 = 1111000000
let NoSQLSampleDataGeneratorSampleDataNumberMaximum: UInt32 = 1111999999
let NoSQLSampleDataGeneratorRandomNumberMaximum: UInt32 = NoSQLSampleDataGeneratorSampleDataNumberMaximum - NoSQLSampleDataGeneratorSampleDataNumberMinimum
let NoSQLSampleDataGeneratorSampleDataPartition: UInt8 = 4
var NoSQLSampleDataGeneratorSampleStringValues: [String] = ["apple", "banana", "orange", "pear", "pineapple", "lemon",
                                                            "cherry", "avocado", "blueberry", "raspberry", "grape", "watermelon", "papaya"]

class NoSQLSampleDataGenerator {
    
    // MARK: - Internal Methods
    
    class func randomNumber() -> UInt32 {
        return arc4random_uniform(NoSQLSampleDataGeneratorRandomNumberMaximum)
    }
    
    // MARK: - Partition Methods
    
    class func randomPartitionSampleNumber() -> NSNumber {
        return NSNumber(value: NoSQLSampleDataGeneratorSampleDataNumberMinimum + arc4random_uniform(UInt32(NoSQLSampleDataGeneratorSampleDataPartition)) + 1 as UInt32)
    }
    
    class func randomPartitionSampleStringWithAttributeName(_ attributeName: String) -> String {
        return "\(NoSQLSampleDataGeneratorSampleDataStringPrefix)-\(attributeName)-\(arc4random_uniform(UInt32(NoSQLSampleDataGeneratorSampleDataPartition)) + 1)"
    }
    
    class func randomPartitionSampleBinary() -> Data {
        return "\(NoSQLSampleDataGeneratorSampleDataStringPrefix)-\(randomPartitionSampleNumber())".data(using: String.Encoding.utf8)!
    }
    
    // MARK: - General Methods
    
    class func randomSampleNumber() -> NSNumber {
        return NSNumber(value: NoSQLSampleDataGeneratorSampleDataNumberMinimum + randomNumber() as UInt32)
    }
    
    class func randomSampleStringWithAttributeName(_ attributeName: String) -> String {
        return "\(NoSQLSampleDataGeneratorSampleDataStringPrefix)-\(attributeName)-\(randomNumber().formattedIntegerString())"
    }
    
    class func randomSampleBOOL() -> NSNumber {
        // If random number is even number then return true, false for odd numbers
        return NSNumber(value: self.randomNumber() % 2 == 0)
    }
    
    class func randomSampleBinary() -> Data {
        return "\(NoSQLSampleDataGeneratorSampleDataStringPrefix)-\(randomSampleNumber())".data(using: String.Encoding.utf8)!
    }
    
    class func randomSampleStringSet() -> Set<String> {
        var set: Set<String> = Set()
        for value in randomSampleStringArray() {
            set.insert(value)
        }
        return set
    }
    
    class func randomSampleNumberSet() -> Set<NSNumber> {
        var numberSet: Set<NSNumber> = Set()
        let arrayCount: UInt32 = arc4random_uniform(UInt32(NoSQLSampleDataGeneratorSampleStringValues.count)) + 1
        for _ in 0..<arrayCount {
            numberSet.insert(self.randomSampleNumber())
        }
        return numberSet
    }
    
    class func randomSampleBinarySet() -> Set<Data> {
        var set: Set<Data> = Set()
        for randomString in randomSampleStringArray() {
            set.insert(randomString.data(using: String.Encoding.utf8)!)
        }
        return set
    }
    
    class func randomSampleStringArray() -> [String] {
        var stringArray: [String] = []
        // Get a random number of insertion items
        let items: Int = Int(arc4random_uniform(UInt32(NoSQLSampleDataGeneratorSampleStringValues.count / 2)) + 1)
        // Insert items for corresponding count
        for _ in 0..<items {            stringArray.append(NoSQLSampleDataGeneratorSampleStringValues[Int(arc4random_uniform(UInt32(NoSQLSampleDataGeneratorSampleStringValues.count)))])
        }
        return stringArray
        
    }
    
    class func randomSampleMap() -> [String: String] {
        var dictionary: [String: String] = [:]
        let dictionaryCount: UInt32 = arc4random_uniform(UInt32(NoSQLSampleDataGeneratorSampleStringValues.count)) + 1
        for index in 0..<dictionaryCount {
            let key: String = NoSQLSampleDataGeneratorSampleStringValues[Int(index)]
            dictionary[key] = randomSampleStringWithAttributeName(key)
        }
        return dictionary
    }
}

extension UInt32 {
    fileprivate func formattedIntegerString() -> String {
        return String(format: "%06d", self)
    }
    
    fileprivate func formattedLongString() -> String {
        return String(format: "%06llu", self)
    }
}
