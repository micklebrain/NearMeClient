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
import SocketIO

class UserProfileViewController: ProfileViewController {
    
    @IBOutlet weak var UserProfilePicture: UIImageView!
    @IBOutlet weak var UserDetails: UILabel!
    var userDetailsText : String!
    var socket: SocketIOClient?
    
    override func viewDidLoad() {
        
//        socket = SocketIOClient(manager: NSURL(string: "https://chat-smalltalk.herokuapp.com/"), nsp: "")
//        
//        SocketIOManager.sharedInstance.connectToServerWithNickname(nickname: "Nathan", completionHandler: () -> Void)
//        SocketIOManager.sharedInstance.sendMessage(message: "Well Hello", withNickname: "Nathan")
        
        let tbc = self.tabBarController as! MainTabBarController
        self.userSelected = tbc.userloggedIn
        self.userSelected.facebookId = FBSDKAccessToken.current()?.userID
        
        if (self.userSelected != nil) {
            downloadProfilePic()
        }
        
        pullFacebookInfo()
    }
    
    private func pullFacebookInfo () {
        if((AccessToken.current) != nil) {
            let graphRequest = GraphRequest(graphPath: self.userSelected.facebookId!, parameters: ["fields" : "id, name, email"], accessToken: AccessToken.current, httpMethod: GraphRequestHTTPMethod.GET, apiVersion: .defaultVersion)
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
                    
                    self.UserDetails.numberOfLines = 0
                    
                    let userName = self.userSelected.username ?? ""
                    let firstName = self.userSelected.firstName ?? ""
                    let lastName = self.userSelected.lastName ?? ""
                    let school = self.userSelected.school ?? ""
                    
                    self.UserDetails.text?.append(
                        "Username: " + userName + "\n")
                    self.UserDetails.text?.append(
                        "Name: " + firstName + " " + lastName + "\n")
                    self.UserDetails.text?.append(
                        "School: " + school + "\n")
                    self.UserDetails.text?.append("Instagram Username: " + "\n")
                    self.UserDetails.text?.append("Snapchat Username: ")
                    
                case .failed(let error):
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
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    print(error!)
                } else {
                    if let usableData = data {
                        headshot  = UIImage(data: usableData)!
                        self.userSelected?.headshot = headshot
                        DispatchQueue.main.async {
                            self.UserProfilePicture.image = headshot
                        }
                    }
                }
            }
            task.resume()
        }
        
    }
    
    @IBAction func logout(_ sender: Any) {
        let loginVC:AuthViewController = UIStoryboard(name: "Access", bundle: nil).instantiateViewController(withIdentifier: "AuthViewController") as! AuthViewController
        
        AccessToken.current = nil
        
        self.present(loginVC, animated: false, completion: nil)
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
