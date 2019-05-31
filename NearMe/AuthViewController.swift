//
//  LoginViewController.swift
//  LoginScreen
//

import FacebookCore
import FacebookLogin
import FBSDKCoreKit
import FBSDKLoginKit
import UIKit

class AuthViewController: UIViewController {
    
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    
    var userloggedIn: User!
    
    // Facebook login permissions
    // Add extra permissions you need
    // Remove permissions you don't need
    private let readPermissions: [Permission] = [ .publicProfile, .email, .userFriends, .custom("user_posts") ]
    
    @IBAction func didTapLoginButton(_ sender: FacebookLoginButton) {
        // Regular login attempt. Add the code to handle the login by email and password.
        guard let email = usernameTextField.text, let pass = passwordTextField.text else {
            // It should never get here
            return
        }
        didLogin(method: "email and password", info: "Email: \(email) \n Password: \(pass)")
    }
    
    @IBAction func didTapFacebookLoginButton(_ sender: Any) {
        // Facebook login attempt
        let loginManager = LoginManager()
        loginManager.logIn(permissions: readPermissions,
                           viewController: self,
                           completion: didReceiveFacebookLoginResult)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        usernameTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    private func didReceiveFacebookLoginResult(loginResult: LoginResult) {
        switch loginResult {
        case .success(granted: _, declined: _, token: let token):
            didLoginWithFacebook(token)
        case .failed: break
        default: break
        }
    }
    
    private func didLoginWithFacebook(_ token: AccessToken) {
        // Successful log in with Facebook
        if let accessToken = AccessToken.current {
//            let facebookAPIManager = FacebookAPIManager(accessToken: accessToken)
//            facebookAPIManager.requestFacebookUser(completion: { (facebookUser) in
//                if let _ = facebookUser.email {
//                    let info = "First name: \(facebookUser.firstName!) \n Last name: \(facebookUser.lastName!) \n Email: \(facebookUser.email!)"
//                    self.didLogin(method: "Facebook", info: info)
//                }
//            })
            self.userloggedIn = User()
            self.userloggedIn.facebookId = token.userID
            let wifiipAddress = Util.getIFAddresses()[1]
            var localUrlString = "http://\(wifiipAddress):8080/getAccount?facebookId="
            localUrlString.append(self.userloggedIn.facebookId ?? "")
            let localUrl = URL(string: localUrlString)
            // TODO: Fix grabbing User's Auth
            //                Alamofire.request(localUrl!).response(completionHandler: { (response) in
            //                    let json = try? JSONSerialization.jsonObject(with: response.data!, options: [])
            //
            //                    if let userFields = json as? [Any] {
            //                        let userFieldsDictionary = userFields[0] as! [String: Any]
            //                        self.userloggedIn.username = userFieldsDictionary["username"] as? String
            //                        self.userloggedIn.firstName = userFieldsDictionary["firstname"] as? String
            //                        self.userloggedIn.lastName = userFieldsDictionary["lastname"] as? String
            //                    }
            //
            //                    maintabbarVC.userloggedIn = self.userloggedIn
            //
            //                    self.present(maintabbarVC, animated: false, completion: nil)
            //
            //                })
            if let maintabbarVC: MainTabBarController = UIStoryboard(name: "Main",
                                                                    bundle: nil).instantiateViewController(
                                                                        withIdentifier: "MainTabBarController") as? MainTabBarController {
                // Hardcoded
                self.userloggedIn.username = "SFNathan"
                self.userloggedIn.firstName = "Nathan"
                self.userloggedIn.lastName = "Nguyen"
                maintabbarVC.userloggedIn = self.userloggedIn
                print("Logging in with user: ")
                print("FacebookId: " + self.userloggedIn.facebookId!)
                print("First Name: " + self.userloggedIn.firstName!)
                print("Last Name: " + self.userloggedIn.lastName!)
                self.present(maintabbarVC, animated: false, completion: nil)
            }
        }
    }
    private func didLogin(method: String, info: String) {
        let message = "Successfully logged in with \(method). " + info
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Done", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
