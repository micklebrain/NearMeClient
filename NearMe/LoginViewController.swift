//
//  LoginViewController.swift
//  NearMe
//
//  Created by Nathan Nguyen on 5/24/17.
//  Copyright © 2017 Nathan Nguyen. All rights reserved.
//

import UIKit
import AWSDynamoDB
import FacebookLogin
import FacebookCore
import FBSDKLoginKit

class LoginViewController: UIViewController {
    
    var results: [AWSDynamoDBObjectModel]?
    var userloggedIn : User!
    
    var loginButton:LoginButton!
   
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        if(FBSDKAccessToken.current() != nil)
//        {
//            //This request dosnt happen fast enough
//            let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields" : "id, name, email"])
//            let connection = FBSDKGraphRequestConnection()
//
//            connection.add(graphRequest, completionHandler: { (connection, result, error) -> Void in
//                let data = result as! [String : AnyObject]
//                var name = data["name"] as! String
//                var splitName = name.components(separatedBy: " ")
//                let firstName = splitName.removeFirst()
//                print("logged in user name is \(String(describing: name))")
//
//                let FBid = data["id"] as? String
//                print("Facebook id is \(String(describing: FBid))")
//
//                self.userloggedIn = User()
//                self.userloggedIn?.firstName = firstName
//                self.userloggedIn?.username = "Tester"
//                self.userloggedIn?.facebookId = FBid
//
//            })
//            connection.start()
//            
//            let maintabbarVC:MainTabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainTabBarController") as! MainTabBarController
//
//            maintabbarVC.userloggedIn = self.userloggedIn
//
//            let initialViewController = UIStoryboard(name: "Main", bundle:nil).instantiateInitialViewController() as! UIViewController
//            let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
//            appDelegate.window?.rootViewController = initialViewController
//
//            self.present(maintabbarVC, animated: false, completion: nil)
//        }
        
        password.resignFirstResponder()
        
        //Facebook login button
        self.loginButton = LoginButton(readPermissions: [ .publicProfile, .email, .userFriends ])
        loginButton.center = view.center
        
//      self.FbLoginButton.readPermissions = ["id, name, email"]
        
//        view.addSubview(loginButton)
    
    }
    
    @IBAction func loginFacebook(_ sender: Any) {
        
        let loginManager = LoginManager()
        loginManager.logIn(readPermissions: [ .publicProfile, .email, .userFriends ], viewController: self) { (loginResult) in
            switch loginResult {
            case.cancelled:
                print("We failed")
            case.failed(let error):
                print(error)
            case.success(grantedPermissions: let grantedPermissions, declinedPermissions: let declinedPermissions, token: let accessToken):
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
    
    
    @IBAction func loginButtonClicked(_ sender: Any) {
        let loginManager = LoginManager()
        loginManager.logIn(readPermissions: [.email, .userFriends, .publicProfile], viewController: self, completion: ({ (loginResult) in
            switch loginResult {
            case LoginResult.cancelled:
                print("Things were canceled")
            case LoginResult.failed:
                print("Things failed")
            case LoginResult.success(grantedPermissions: nil, declinedPermissions: nil, token: nil):
                
                let maintabbarVC:MainTabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainTabBarController") as! MainTabBarController
                
                maintabbarVC.userloggedIn = self.userloggedIn
                
                let initialViewController = UIStoryboard(name: "Main", bundle:nil).instantiateInitialViewController() as! UIViewController
                let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
                appDelegate.window?.rootViewController = initialViewController
                
                self.present(maintabbarVC, animated: false, completion: nil)
            default:
                print("Not an option")
            }
        }))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        password.resignFirstResponder()
    }
    
    func scanUsers (_ completeionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void) {
        
//        let objectMapper = AWSDynamoDBObjectMapper.default()
//        let scanExpression = AWSDynamoDBScanExpression()
//        scanExpression.filterExpression = "firstName = :val"
//        scanExpression.expressionAttributeValues = [":val": username.text]
//
//        objectMapper.scan(User.self, expression: scanExpression) { (response: AWSDynamoDBPaginatedOutput?, error: Error?) in
//            DispatchQueue.main.async(execute: {
//                completeionHandler(response, error as NSError?)
//            })
//        }
    }
    
    //Security
    func authenticateUser () {
        
        let completionHandler = {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
        if let error = error {
        var errorMessage = "Failed to retrieve items. \(error.localizedDescription)"
            if (error.domain == AWSServiceErrorDomain && error.code == AWSServiceErrorType.accessDeniedException.rawValue) {
                errorMessage = "Access denied. You are not allowed to perform this operation."
                print(errorMessage)
            }
        }
        else if response!.items.count == 0 {
            print("No items match your criteria. Insert more sample data and try again.")
        }
        else {
            let nearbyPeopleVC:NearbyLocationsViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ProfileViewController") as! NearbyLocationsViewController
            let currentUser = User()
            currentUser.username = self.username.text
            currentUser.firstName = self.username.text
            self.present(nearbyPeopleVC, animated: false, completion: nil)
        }
        }
        
        scanUsers(completionHandler)
    }

    @IBAction func logout(_ sender: Any) {
        let deletepermission = FBSDKGraphRequest(graphPath: "me/permissions/", parameters: nil, httpMethod: "DELETE")
        deletepermission?.start(completionHandler: {(connection,result,error)-> Void in
            print("the delete permission is \(result)")
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
