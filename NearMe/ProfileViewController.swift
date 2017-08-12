//
//  ProfileViewController.swift
//  NearMe
//
//  Created by Nathan Nguyen on 6/13/17.
//  Copyright © 2017 Nathan Nguyen. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var FoodPickerView: UIPickerView!
    @IBOutlet weak var nameLabel: UILabel!
    
    public var currentUserProfile : User?
    var suggestedResturants : [googleLocation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.FoodPickerView.delegate = self
        self.FoodPickerView.dataSource = self
        
        pullSuggestedResturants()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        nameLabel.text = currentUserProfile?.firstName
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func requestResturant () {
        let urlString = URL(string: "https://nearme-1498669488601.appspot.com/requestResturant")
        
        if let url = urlString {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    print(error)
                } else {
                    if let usableData = data {
                        print(usableData) //JSONSerialization
                        let json = try? JSONSerialization.jsonObject(with: usableData, options: JSONSerialization.ReadingOptions.allowFragments)
                        
                        if let dictionary = json as? [String: Any] {
                            print(dictionary["content"])
                        }
                    }
                }
            }
              task.resume()
        }
        
    }
    
    // Find Nearby resturant from Google
    func pullSuggestedResturants () {
        // Getting nearby food locations
        let urlString = URL(string:"https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=33.892260,-84.491042&radius=1000&type=restaurant&keyword=burgers&key=AIzaSyCSLA7M3BdjNuDVRMtvAq2LLcrkLbkDhE8")
        
        if let url = urlString {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    print(error)
                } else {
                    if let usableData = data {
                        print(usableData) //JSONSerialization
                        let json = try? JSONSerialization.jsonObject(with: usableData, options: JSONSerialization.ReadingOptions.allowFragments)
                        
                        if let dictionary = json as? [String: Any] {
                            if let array = dictionary["results"] as? [Any] {
                                for nestedDictionary in array {
                                    if let anotherNestedDictionary = nestedDictionary as? [String: Any] {
                                        let resturantName = anotherNestedDictionary["name"]
                                        let resturantRating = anotherNestedDictionary["rating"]
                                        let googleId = anotherNestedDictionary["id"]
                                       
                                        let searchedResturant = googleLocation()
                                        searchedResturant.name = resturantName as? String
                                        searchedResturant.rating = resturantRating as? Int
                                        searchedResturant.googleId = googleId as? Int
                                        
                                        self.suggestedResturants.append(searchedResturant)
                                    }
                                    
                                }
                            }
                        }
                    }
                }
            }
            task.resume()
        }
        self.FoodPickerView.reloadAllComponents()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return (self.suggestedResturants.count)
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return suggestedResturants[row].name
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
