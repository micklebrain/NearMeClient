//
//  AccountAPIHandler.swift
//  NearMe
//
//  Created by Nathan Nguyen on 5/28/19.
//  Copyright © 2019 Nathan Nguyen. All rights reserved.
//

import Foundation
import Alamofire

class AccountAPIHandler {
    
    static func getUsername(facebookId: String, completion: @escaping (String) -> Void) {
        
        let username = ""
        let url = URL(string: "https://crystal-smalltalk.herokuapp.com/sync")
        
        let userDetails: Parameters = [
            "facebookId": facebookId
        ]
        
        Alamofire.request(url!, method: .post, parameters: userDetails, encoding: JSONEncoding.default)
            .responseString { response in
                if let data = response.result.value {
                    let username = data
                    completion(username)
                }
        }
        
    }
    
}
