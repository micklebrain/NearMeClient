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
   
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!

    
    // TODO: Logout facebook
    override func viewDidLoad() {
        super.viewDidLoad()
        
        password.resignFirstResponder()
        
        let loginButton = LoginButton(readPermissions: [ .publicProfile, .email, .userFriends ])
        loginButton.center = view.center
        view.addSubview(loginButton)
//        loginButton.addTar
        
        if let accessToken = AccessToken.current {
           print(AccessToken.current?.userId)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if(FBSDKAccessToken.current() != nil)
        {
        print(FBSDKAccessToken.current().permissions)
//      Graph Path : "me" is going to get current user logged in
        let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields" : "id, name, email"])
        let connection = FBSDKGraphRequestConnection()
        
        connection.add(graphRequest, completionHandler: { (connection, result, error) -> Void in
            let data = result as! [String : AnyObject]
            let name = data["name"] as? String
            print("logged in user name is \(String(describing: name))")
            
            let FBid = data["id"] as? String
            print("Facebook id is \(String(describing: FBid))")
        })
        connection.start()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        password.resignFirstResponder()
    }
    
    @objc func loginButtonClicked() {
        let loginManager = LoginManager()
        loginManager.logIn([ .publicProfile ], viewController: self) { loginResult in
            switch loginResult {
            case .failed(let error):
                print(error)
            case .cancelled:
                print("User cancelled login.")
            case .success(let grantedPermissions, let declinedPermissions, let accessToken):
                print("Logged in!")
            }
        }
    }
    
    func login(_ sender: Any) {
        let nearbyPeopleVC:ProfileViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        self.present(nearbyPeopleVC, animated: false, completion: nil)
    }
    
    func scanUsers (_ completeionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void) {
        
        let objectMapper = AWSDynamoDBObjectMapper.default()
        let scanExpression = AWSDynamoDBScanExpression()
        //      scanExpression.filterExpression = "online = :val"
        //      scanExpression.expressionAttributeValues = [":val": "true"]
        
        objectMapper.scan(User.self, expression: scanExpression) { (response: AWSDynamoDBPaginatedOutput?, error: Error?) in
            DispatchQueue.main.async(execute: {
                completeionHandler(response, error as NSError?)
            })
        }
    }
    
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
            self.results = response?.items
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
