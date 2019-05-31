//
//  FacebookManager.swift
//  NearMe
//
//  Created by Nathan Nguyen on 4/22/19.
//  Copyright © 2019 Nathan Nguyen. All rights reserved.
//

import FacebookCore
import FacebookLogin
import FBSDKCoreKit
import FBSDKLoginKit
import Foundation

class FacebookManager {
    
    func downloadFacebookPicture(facebookId: String) {
        let graphRequest = GraphRequest(graphPath: "46",
                                        parameters: ["fields": "id, name, email"],
                                        tokenString: AccessToken.current?.tokenString,
                                        version: nil,
                                        httpMethod: HTTPMethod.get)
    
        // Get current facebook profile
        // let graphRequest = GraphRequest(graphPath: "/me",
        //                                 parameters: ["fields" : "id, name, email"],
        //                                 accessToken: AccessToken.current,
        //                                 httpMethod: GraphRequestHTTPMethod.GET,
        //                                 apiVersion: "")
        
        let connection = GraphRequestConnection()
        connection.add(graphRequest, completionHandler: { result, data, graphError in
            if graphError == nil {
                let response = data as? [String:Any]
                print("Custom Graph Request Succeeded: \(response)")
//                print("My facebook id is \(String(describing: response["id"]))")
//                print("My name is \(String(describing: response.dictionaryValue?["name"]))")
                //                    let data = result as! [String : AnyObject]
                guard let facebookName = (response!["name"]) as? String else {
                    return
                }
                var splitName = facebookName.components(separatedBy: " ")
                splitName.removeFirst()
                print("logged in user name is \(String(describing: facebookName))")
                
                if let FBid = (response!["id"]) as? String {
                    print("Facebook id is \(String(describing: FBid))")
                }
            } else {
                    print(graphError)
                    print("Failed to get facebook credential")
            }
        })
        connection.start()
    }
    
}
