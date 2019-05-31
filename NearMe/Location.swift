//
//  Location.swift
//  NearMe
//
//  Created by Nathan Nguyen on 6/29/17.
//  Copyright © 2017 Nathan Nguyen. All rights reserved.
//

import Foundation
import CoreLocation

class Location {
    
    var location: CLLocation?
    var lastLocation: String?
    var postalCode: String?
    var administrativeArea: String?
    var country: String?
    var locality: String?
    var latitude: NSNumber?
    var longitude: NSNumber?
    var floor: Int?
    
}
