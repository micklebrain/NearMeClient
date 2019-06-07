//
//  ProfileViewController.swift
//  NearMe
//
//  Created by Nathan Thai Nguyen on 4/2/18.
//  Copyright © 2018 Nathan Nguyen. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
    
    var userSelected: User!
    @IBOutlet weak var firstName: UILabel!
    @IBOutlet weak var lastName: UILabel!
    @IBOutlet weak var snapChat: UILabel!
    @IBOutlet weak var instagram: UILabel!
    
    @IBOutlet weak var selectedUserProfileImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (userSelected != nil) {
            self.firstName.text =
                userSelected.firstName!
            self.firstName.text = userSelected.lastName!
//            userDetailsLabel.text? +=
//                userSelected.school! + "\n"
//            userDetailsLabel.text? +=
//            userSelected.employer!
            self.selectedUserProfileImage.image = userSelected.headshot
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func goBack(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
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
