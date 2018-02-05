//
//  UserProfileViewController.swift
//  NearMe
//
//  Created by Nathan Thai Nguyen on 11/29/17.
//  Copyright © 2017 Nathan Nguyen. All rights reserved.
//

import UIKit

class UserProfileViewController: UIViewController {

    @IBOutlet weak var UserProfilePicture: UIImageView!
    var userLoggedIn: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserProfilePicture.image = #imageLiteral(resourceName: "empty-headshot")
//        downloadProfilePic()
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
                        self.UserProfilePicture.image = headshot
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
        //NoiseBridge
        //        let url = URL(string: "http://10.20.1.137:8080/pullAccountsLocal")
        //this is brannan lobby wifi
        //        let url = URL(string: "http://10.12.228.178:8080/pullAccountsLocal")
        
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
