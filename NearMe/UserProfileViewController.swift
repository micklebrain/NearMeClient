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


class UserProfileViewController: ProfileViewController {

    @IBOutlet weak var UserProfilePicture: UIImageView!
    var userLoggedIn: User?
    
    @IBOutlet weak var NameLabel: UILabel!
    @IBOutlet weak var EmailLabel: UILabel!
    @IBOutlet weak var isOnlineLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tbc = self.tabBarController as! MainTabBarController
        self.userLoggedIn = tbc.userloggedIn
        
        if (self.userLoggedIn != nil) {
            if (userLoggedIn?.online)! {
                isOnlineLabel.text = "online"
            } else {
                isOnlineLabel.text = "offline"
            }
            
            downloadProfilePic()
        }
        
        pullFacebookInfo()

    }
    
    private func pullFacebookInfo () {
        if(FBSDKAccessToken.current() != nil)
        {
            //This request dosnt happen fast enough
            let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields" : "id, name, email"])
            let connection = FBSDKGraphRequestConnection()
            
            connection.add(graphRequest, completionHandler: { (connection, result, error) -> Void in
                let data = result as! [String : AnyObject]
                var name = data["name"] as! String
                var email = data["email"] as! String
                var splitName = name.components(separatedBy: " ")
                let firstName = splitName.removeFirst()
                print("logged in user name is \(String(describing: name))")
                
                let FBid = data["id"] as? String
                print("Facebook id is \(String(describing: FBid))")
                
                self.NameLabel.text = name
                self.EmailLabel.text = email
                
            })
            connection.start()
            
        }
    }
    
    private func downloadProfilePic () {
        
        var headshot = #imageLiteral(resourceName: "empty-headshot")
        var pictureUrl = "http://graph.facebook.com/"
        pictureUrl += (userLoggedIn?.facebookId)!
        pictureUrl += "/picture?type=large"
        
        let url = URL(string: pictureUrl)
        
        if let url = url {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    print(error)
                } else {
                    if let usableData = data {
                        headshot  = UIImage(data: usableData)!
                        self.userLoggedIn?.headshot = headshot
                        DispatchQueue.main.async {
                          self.UserProfilePicture.image = headshot
                        }
                    }
                }
            }
            task.resume()
        }
        
    }
    
    func pullFriendRequests (user : String) -> String {
        
        var friendRequests = ""
        
        let utilities = Util()
        let wifiAddress = utilities.getWiFiAddress() as! String
//        let url = URL(string: "http://" + wifiAddress + ":8080/updateLocation")
        
        //this is roomwifi
        let url = URL(string: "http://192.168.1.18:8080/pullAccountsLocal")
        
        let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            
            let json = try? JSONSerialization.jsonObject(with: data!, options: [])
            print(json)
            
            let users = json as! [String]
            
           friendRequests = users.joined(separator: ", ")
        
        }
        task.resume()
        return friendRequests
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logout(_ sender: Any) {
            let loginVC:LoginViewController = UIStoryboard(name: "Access", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        
            AccessToken.current = nil

            self.present(loginVC, animated: false, completion: nil)
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
