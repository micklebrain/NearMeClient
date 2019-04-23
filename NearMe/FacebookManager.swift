//
//  FacebookManager.swift
//  NearMe
//
//  Created by Nathan Nguyen on 4/22/19.
//  Copyright © 2019 Nathan Nguyen. All rights reserved.
//

import Foundation
import FacebookCore
import FacebookLogin

class FacebookManager {
    
    func downloadFacebookPicture(facebookId : String) {
        let graphRequest = GraphRequest(graphPath: "46", parameters: ["fields" : "id, name, email"], accessToken: AccessToken.current, httpMethod: GraphRequestHTTPMethod.GET, apiVersion: .defaultVersion)
        // Get current facebook profile
        //                        let graphRequest = GraphRequest(graphPath: "/me", parameters: ["fields" : "id, name, email"], accessToken: AccessToken.current, httpMethod: GraphRequestHTTPMethod.GET, apiVersion: "")
        
        let connection = GraphRequestConnection()
        connection.add(graphRequest) { response, result in
            
            switch result {
            case .success(let response):
                
                print("Custom Graph Request Succeeded: \(response)")
                print("My facebook id is \(String(describing: response.dictionaryValue?["id"]))")
                print("My name is \(String(describing: response.dictionaryValue?["name"]))")
                //                    let data = result as! [String : AnyObject]
                let facebookName = (response.dictionaryValue?["name"]) as! String
                var splitName = facebookName.components(separatedBy: " ")
                splitName.removeFirst()
                print("logged in user name is \(String(describing: facebookName))")
                
                let FBid = (response.dictionaryValue?["id"]) as! String
                print("Facebook id is \(String(describing: FBid))")
                
            case .failed(let error):
                print(error)
                print("Failed to get facebook credential")
            }
            
        }
        connection.start()
    }
    
}