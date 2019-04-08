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

class UserProfileViewController: ProfileViewController {
    
    @IBOutlet weak var UserProfilePicture: UIImageView!
    @IBOutlet weak var UserDetails: UILabel!
    var userDetailsText : String!
    
    override func viewDidLoad() {
        let tbc = self.tabBarController as! MainTabBarController
        self.userSelected = tbc.userloggedIn        
        if (self.userSelected != nil) {
            downloadProfilePic()
        }
        
        pullFacebookInfo()
        
    }
    
    private func pullFacebookInfo () {
        if((AccessToken.current) != nil) {
            let graphRequest = GraphRequest(graphPath: self.userSelected.facebookId!, parameters: ["fields" : "id, name, email"], accessToken: AccessToken.current, httpMethod: GraphRequestHTTPMethod.GET, apiVersion: "")
            let connection = GraphRequestConnection()
            
            connection.add(graphRequest) { httpResponse, result in
                let data = result as! [String : AnyObject]
                let name = data["name"] as! String
                //                let email = data["email"] as! String
                var splitName = name.components(separatedBy: " ")
                splitName.removeFirst()
                print("logged in user name is \(String(describing: name))")
                
                let FBid = data["id"] as? String
                print("Facebook id is \(String(describing: FBid))")
                
//                self.UserDetails.text?.append(name + "\n" + self.userSelected.buildingOccupied!)
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
        let loginVC:LoginViewController = UIStoryboard(name: "Access", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        
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
