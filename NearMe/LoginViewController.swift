//
//  LoginViewController.swift
//  NearMe
//
//  Created by Nathan Nguyen on 5/24/17.
//  Copyright © 2017 Nathan Nguyen. All rights reserved.
//

import UIKit
import FacebookLogin
import FacebookCore
import FBSDKLoginKit

class LoginViewController: UIViewController {
    
//    var results: [AWSDynamoDBObjectModel]?
    var userloggedIn : User!
    
    var loginButton:LoginButton!
   
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Cache the token in case offline
        if(FBSDKAccessToken.current() != nil)
        {
            //Crashes without Internet
            //This request dosnt happen fast enough
            let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields" : "id, name, email"])
            let connection = FBSDKGraphRequestConnection()

            connection.add(graphRequest, completionHandler: { (connection, result, error) -> Void in
                if (connection?.urlResponse != nil && connection?.urlResponse.statusCode == 200) {
                    let data = result as! [String : AnyObject]
                    let name = data["name"] as! String
                    var splitName = name.components(separatedBy: " ")
                    let firstName = splitName.removeFirst()
                    print("logged in user name is \(String(describing: name))")

                    let FBid = data["id"] as? String
                    print("Facebook id is \(String(describing: FBid))")

                    self.userloggedIn = User()
                    self.userloggedIn?.firstName = firstName
//                    self.userloggedIn?.username = "GANathan"
                    self.userloggedIn?.facebookId = FBid
        
                    let maintabbarVC:MainTabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainTabBarController") as! MainTabBarController
                    
                    maintabbarVC.userloggedIn = self.userloggedIn
                    
//                    let initialViewController = UIStoryboard(name: "Main", bundle:nil).instantiateInitialViewController() as! UIViewController
//                    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
//                    appDelegate.window?.rootViewController = initialViewController
                    
                    self.present(maintabbarVC, animated: false, completion: nil)
                }
            })
            connection.start()

        }
        
        password.resignFirstResponder()
        
        //Facebook login button
        self.loginButton = LoginButton(readPermissions: [ .publicProfile, .email, .userFriends ])
        loginButton.center = view.center
    
    }
    
    @IBAction func loginFacebook(_ sender: Any) {
        
        let loginManager = LoginManager()
        loginManager.logIn(readPermissions: [ .publicProfile, .email, .userFriends ], viewController: self) { (loginResult) in
            switch loginResult {
            case.cancelled:
                print("We failed")
            case.failed(let error):
                print(error)
            case.success(grantedPermissions: let grantedPermissions, declinedPermissions: let declinedPermissions, token: let _):
                //Pull user's information from granted permissions
                
                let maintabbarVC:MainTabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainTabBarController") as! MainTabBarController
                
                maintabbarVC.userloggedIn = self.userloggedIn
                
                let initialViewController = UIStoryboard(name: "Main", bundle:nil).instantiateInitialViewController() as! UIViewController
                let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
                appDelegate.window?.rootViewController = initialViewController
                
                self.present(maintabbarVC, animated: false, completion: nil)
            }
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        password.resignFirstResponder()
    }

    @IBAction func logout(_ sender: Any) {
        let deletepermission = FBSDKGraphRequest(graphPath: "me/permissions/", parameters: nil, httpMethod: "DELETE")
        deletepermission?.start(completionHandler: {(connection,result,error)-> Void in
            print(String(describing:"the delete permission is \(describing: result))"))
        })
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
