//
//  SignupViewController.swift
//  NearMe
//
//  Created by Nathan Nguyen on 5/25/17.
//  Copyright © 2017 Nathan Nguyen. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireSwiftyJSON

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
    
    func createAccount () {
        
        let _ = URL(string: "https://crystal-smalltalk.herokuapp.com/createAccount")
        
        let localUrl = URL(string: "http://localhost:8080/createAccount")
        
        let userDetails : Parameters = [
            "firstName": firstNameTextField.text!,
            "lastName": lastNameTextField.text!,
            "userName": usernameTextField.text!,
            "password": passwordTextField.text!,
        ]
        
        Alamofire.request(localUrl!, method: .post, parameters: userDetails, encoding: JSONEncoding.default)
            .response { response in
                print(response.response?.statusCode)
        }
        
    }

    @IBAction func signUp(_ sender: Any) {
        createAccount()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        passwordTextField.resignFirstResponder()
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
