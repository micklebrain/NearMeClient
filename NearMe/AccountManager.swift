//
//  AccountManager.swift
//  NearMe
//
//  Created by Nathan Nguyen on 4/22/19.
//  Copyright © 2019 Nathan Nguyen. All rights reserved.
//

import Alamofire
import Foundation

class AccountManager {
    
    func pullUser(_ facebookId: String) {
        
    }
    
    func pullAllUsers() {
        
        let allUsersUrl = URL(string: "https://crystal-smalltalk.herokuapp.com/pullAllUsers")
        
        //        Alamofire.request(pullNearbyUsersUrl!, method: .post, parameters: userDetails, encoding: JSONEncoding.default)
        Alamofire.request(allUsersUrl!, method: .get)
            .responseJSON{ response in
                if response.response?.statusCode == 200 {
                    if let json = response.result.value {
                        let users = json as! [Any]
                        
                        var usersFacebookIds = [String]()
                        
                        for someUser in users {
                            let userDetails = someUser as! [String: Any]
                            let newPerson = User()
                            let facebookId = userDetails["facebookId"] as! String
                            usersFacebookIds.append(facebookId)
                            
                            
                                newPerson.username = userDetails["username"] as? String
                                newPerson.firstName = userDetails["firstname"] as? String
                                newPerson.lastName = userDetails["lastname"] as? String
                                newPerson.facebookId = userDetails["facebookId"] as? String
                                newPerson.school = userDetails["school"] as? String
                                newPerson.employer = userDetails["employer"] as? String
                                                                
//                            if (self.userCacheURL != nil) {
//                                self.userCacheQueue.addOperation {
//                                    if let stream = OutputStream(url: self.userCacheURL!, append: false) {
//                                        stream.open()
//                                        JSONSerialization.writeJSONObject(json, to: stream, options: [.prettyPrinted], error: nil)
//                                        stream.close()
//                                    }
//                                }
//                            }
                        }
                        
                    }
                    //If happens show cached data
                } 
        }
        
    }
    
    func createAccount() {
//        let _ = URL(string: "https://crystal-smalltalk.herokuapp.com/createAccount")
//        
//        let localUrl = URL(string: "http://localhost:8080/createAccount")
//        
//        let userDetails : Parameters = [
//            "firstName": firstNameTextField.text!,
//            "lastName": lastNameTextField.text!,
//            "userName": usernameTextField.text!
//            //"password": passwordTextField.text!,
//        ]
//        
//        Alamofire.request(localUrl!, method: .post, parameters: userDetails, encoding: JSONEncoding.default)
//        .response { response in
//        print(response.response?.statusCode ?? 500)
//        }
    }
    
}
