//
//  LocationAPIHandler.swift
//  NearMe
//
//  Created by Nathan Nguyen on 5/25/19.
//  Copyright © 2019 Nathan Nguyen. All rights reserved.
//

import Foundation
import GoogleMaps
import Alamofire

class LocationAPIHandler {
    
    static func updateLocation(user: User, locality: String, longitude: Double, latitude: Double, building: String, zipCode: Int) {
        
        _ = locality.replacingOccurrences(of: " ", with: "")
        let buildingCleanse = building.replacingOccurrences(of: " ", with: "")
        
        let url = URL(string: "https://crystal-smalltalk.herokuapp.com/updateLocation?longitude=\(longitude)&latitude=\(latitude)&zipCode=\(zipCode)&building=\(buildingCleanse)")
        
        let userDetails: Parameters = [
            "firstname": user.firstName!,
            "username": user.username!,
            "facebookId": user.facebookId!,
            "locality": locality
        ]
        
        Alamofire.request(url!, method: .post, parameters: userDetails, encoding: JSONEncoding.default)
            .response { response in
                print(response.response?.statusCode ?? "Status code not found")
        }
        
    }
    
}
