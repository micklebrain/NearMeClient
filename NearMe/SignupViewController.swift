//
//  SignupViewController.swift
//  NearMe
//
//  Created by Nathan Nguyen on 5/25/17.
//  Copyright © 2017 Nathan Nguyen. All rights reserved.
//

import UIKit
import AWSDynamoDB

class SignupViewController: UIViewController {
   
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    let urlProtocol = "http://"
    let localDomain = "localhost:8080/"

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func signUp(_ sender: Any) {
        
        createAccount()
//        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
//        
//        let newUser = User()
//        
//        newUser?.firstName = firstNameTextField.text
//        newUser?.lastName = lastNameTextField.text
//        newUser?.username = usernameTextField.text
//        newUser?.password = passwordTextField.text
//        
//        var newAccount = Account()
//        newAccount.firstName = firstNameTextField.text
//        newAccount.lastName = lastNameTextField.text
//        newAccount.userName = usernameTextField.text
//        newAccount.password = passwordTextField.text
//        
//        createAccount(newAccount: newAccount)
//        
//        dynamoDBObjectMapper.save(newUser!).continueWith(block: { (task:AWSTask<AnyObject>!) -> Void in
//            if (task.error as NSError?) != nil {
//                print("The request failed. Error: !(error)")
//            }
//        })
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func createAccount () {
            let apiMethod = "createAccount/"
            var urlString = urlProtocol + localDomain + apiMethod
            let firstNameParamString = "firstname/" +
                    firstNameTextField.text! + "/"
            let lastNameParamString =
                    "lastname/" + lastNameTextField.text! + "/"
            let passwordParamString =
                    "password/" + passwordTextField.text!
        
            urlString += firstNameParamString + lastNameParamString + passwordParamString
        
            let url = URL(string: urlString)
            let session = URLSession.shared
        
            let request = NSMutableURLRequest(url: url!)
            request.httpMethod = "GET"
//          request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        
            let task = session.dataTask(with: request as URLRequest) {
                (data, response, error) in
                
                // Check for error
                if error != nil
                {
                    print("error=\(error)")
                    return
                }

                let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                print("responseString = \(responseString)")
            }
                
            task.resume()
        
    }
    
    
//    func createAccount(newAccount: Account) {
//        let url = URL(string: "localhost:8080/createAccount")
//        let session = URLSession.shared
//        
//        let request = NSMutableURLRequest(url: url!)
//        request.httpMethod = "POST"
//        
//        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
//        let paramString = "{" +
//        "\"firstName\": \"Nathan\"," +
//        "\"lastName\": \"Nguyen\"" +
//        "}"
////        let paramString = newAccount
//        request.httpBody = paramString.data(using: String.Encoding.utf8)
//        
//        let task = session.dataTask(with: request as URLRequest) {
//            (data, response, error) in
//            guard let _: Data = data, let _: URLResponse = response, error == nil else {
//                print("*****error")
//                return
//            }
//            let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
//            print("*****This is the data 4: \(dataString)") //JSONSerialization
//        }
//        
//        task.resume()
//
//    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
