//
//  UserProfileViewController.swift
//  NearMe
//
//  Created by Nathan Thai Nguyen on 11/29/17.
//  Copyright © 2017 Nathan Nguyen. All rights reserved.
//

import UIKit
import FacebookLogin
import FacebookCore
import FBSDKLoginKit
//import SocketIO

class UserProfileViewController: ProfileViewController {
    
    @IBOutlet weak var userProfilePicture: UIImageView!
    @IBOutlet weak var userDetails: UILabel!
    var userDetailsText: String!
//    var socket: SocketIOClient?
    
    override func viewDidLoad() {
        
//        socket = SocketIOClient(manager: NSURL(string: "https://chat-smalltalk.herokuapp.com/"), nsp: "")
//        
//        SocketIOManager.sharedInstance.connectToServerWithNickname(nickname: "Nathan", completionHandler: () -> Void)
//        SocketIOManager.sharedInstance.sendMessage(message: "Well Hello", withNickname: "Nathan")
        
        self.userDetails.numberOfLines = 0
        
        if let tbc = self.tabBarController as? MainTabBarController {
            self.userSelected = tbc.userloggedIn
            self.userSelected.facebookId = AccessToken.current?.userID
        }
        
        if (self.userSelected != nil) {
            downloadProfilePic()
        }
        
        pullFacebookInfo()
    }
    
    private func pullFacebookInfo () {
        if((AccessToken.current) != nil) {
            let graphPath:String = self.userSelected.facebookId!
            let graphRequest = GraphRequest(graphPath: graphPath,
                                            parameters: ["fields": "id, name, email"],
                                            tokenString: AccessToken.current?.tokenString,
                                            version: nil,
                                            httpMethod: HTTPMethod.get)
// Get current facebook profile
// let graphRequest = GraphRequest(graphPath: "/me",
//            parameters: ["fields" : "id, name, email"],
//            accessToken: AccessToken.current,
//            httpMethod: GraphRequestHTTPMethod.GET,
//            apiVersion: "")
            
            let connection = GraphRequestConnection()
            connection.add(graphRequest) { result, data, error in
                if error == nil {
                    let response = data as? [String: Any]
                        print("Facebook graph request Succeeded: \(response)")
                        // let data = result as! [String : AnyObject]
                    let facebookName = (response!["name"]) as? String
                        var splitName = facebookName?.components(separatedBy: " ")
                        // let FBid = (response.dictionaryValue?["id"]) as! String
                        let userName = self.userSelected.username ?? ""
                        let firstName = self.userSelected.firstName ?? ""
                        let lastName = self.userSelected.lastName ?? ""
                        let school = self.userSelected.school ?? ""
                        self.userDetails.text?.append(
                            "Username: " + userName + "\n")
                        self.userDetails.text?.append(
                            "Name: " + firstName + " " + lastName + "\n")
                        self.userDetails.text?.append(
                            "School: " + school + "\n")
                        self.userDetails.text?.append("Instagram Username: " + "\n")
                        self.userDetails.text?.append("Snapchat Username: ")
                    
                } else {
                        print(error)
                        print("Failed to get facebook credential")
                }
                
            }
            connection.start()
        }
    }
    
    private func downloadProfilePic () {
        
        var headshot = #imageLiteral(resourceName: "empty-headshot")
        var pictureUrl = "http://graph.facebook.com/"
        pictureUrl += (self.userSelected?.facebookId)!
        pictureUrl += "/picture?type=large"
        
        let url = URL(string: pictureUrl)
        
        if let url = url {
            let task = URLSession.shared.dataTask(with: url) { (data, _, error) in
                if error != nil {
                    print(error!)
                } else {
                    if let usableData = data {
                        headshot  = UIImage(data: usableData)!
                        self.userSelected?.headshot = headshot
                        DispatchQueue.main.async {
                            self.userProfilePicture.image = headshot
                        }
                    }
                }
            }
            task.resume()
        }
        
    }
    
    @IBAction func logout(_ sender: Any) {
        if let loginVC: AuthViewController = UIStoryboard(name: "Access",
                                                          bundle: nil).instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController {
        
        AccessToken.current = nil
        
        self.present(loginVC, animated: false, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
     // MARK: - Navigation
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
    */
    
}
