//
//  LoginViewController.swift
//  NearMe
//
//  Created by Nathan Nguyen on 5/24/17.
//  Copyright © 2017 Nathan Nguyen. All rights reserved.
//

import Alamofire
import FacebookLogin
import FacebookCore
import SwiftyJSON
import UIKit

class LoginViewController: UIViewController {
    
    var userloggedIn : User!
    var loginButton:LoginButton!
   
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Cache the token in case offline
        if (AccessToken.current != nil) {
            // Crashes without Internet
            // This request dosnt happen fast enough
            
           let connection = GraphRequestConnection()
           
            connection.add(GraphRequest(graphPath: "/me")) { httpResponse, result in
                
                switch result {
                case .success(let _):
                    
                    let data = result as! [String : AnyObject]
                    let name = data["name"] as! String
                    var splitName = name.components(separatedBy: " ")
                    let firstName = splitName.removeFirst()
                    let FBid = data["id"] as? String
                    
                    self.userloggedIn = User()
                    self.userloggedIn?.firstName = firstName
                    self.userloggedIn?.facebookId = FBid
                    
                    //Hardcoded
                    self.userloggedIn?.username = "SFNathan"
                    
                    let maintabbarVC:MainTabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainTabBarController") as! MainTabBarController
                    
                    maintabbarVC.userloggedIn = self.userloggedIn
                    
                    self.present(maintabbarVC, animated: false, completion: nil)
                    
                case .failed(let error):
                    print("Graph Request Failed: \(error)")
                }
                
            }
            connection.start()    

        }
        
        password.resignFirstResponder()
        
        //Facebook login button
        self.loginButton = LoginButton(readPermissions: [ .publicProfile, .email, .userFriends ])
        loginButton.center = view.center
    
    }
    
    @IBAction func loginFacebook(_ sender: Any) {
        
        // TODO: Add loading activity indicator for slow request response
        let loginManager = LoginManager()
        loginManager.logIn(readPermissions: [ .publicProfile, .email, .userFriends ], viewController: self) { (loginResult) in
            switch loginResult {
            case.cancelled:
                print("Login to Facebook has been canceled")
            case.failed(let error):
                print("Ooops")
            case.success(grantedPermissions: _, declinedPermissions: _, token: let token):
                //Pull user's information from granted permissions
                
                let maintabbarVC:MainTabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainTabBarController") as! MainTabBarController
                
                self.userloggedIn = User()
                self.userloggedIn.facebookId = token.userId
                
                let wifiipAddress = Util.getIFAddresses()[1]
                var localUrlString = "http://\(wifiipAddress):8080/account?facebookId="
                localUrlString.append(self.userloggedIn.facebookId ?? "")
                let localUrl = URL(string: localUrlString)
                
                Alamofire.request(localUrl!).response(completionHandler: { (response) in
                    let json = try? JSONSerialization.jsonObject(with: response.data!, options: [])

                    if let userFields = json as? [Any] {
                        let userFieldsDictionary = userFields[0] as! [String: Any]
                        self.userloggedIn.username = userFieldsDictionary["username"] as? String
                        self.userloggedIn.firstName = userFieldsDictionary["firstname"] as? String
                        self.userloggedIn.lastName = userFieldsDictionary["lastname"] as? String
                        self.userloggedIn.school = userFieldsDictionary["school"] as? String
                    }

                    maintabbarVC.userloggedIn = self.userloggedIn

                    self.present(maintabbarVC, animated: false, completion: nil)

                })
                
            }
        }
        
    }
    
    @IBAction func logout(_ sender: Any) {
        let deletepermission = GraphRequest(graphPath: "me/permissions/", parameters: [:], httpMethod: GraphRequestHTTPMethod.DELETE)
//        deletepermission.start({(connection,result,error)-> Void in
//            print(String(describing:"the delete permission is \(describing: result))"))
//        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        password.resignFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
