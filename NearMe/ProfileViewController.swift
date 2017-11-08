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
    //Pull from Cache 
    var resturantsAround : [String] = []
    
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
        let urlString = URL(string: "https://nearmecrystal.appspot.com/requestResturant")
        
        if let url = urlString {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    print(error)
                } else {
                    if let usableData = data {
                        print(usableData) //JSONSerialization
                        let json = try? JSONSerialization.jsonObject(with: usableData, options: JSONSerialization.ReadingOptions.allowFragments)
                        
                        if let dictionary = json as? [Any] {
                            for value in dictionary {
                                print(value)
                            }
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
        
        let resturantsUrl = URL(string:"https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=37.7806579%2C-122.4070832&radius=500&type=restaurant&key=AIzaSyBWdayUxe65RUQLv4QL6GcB_UXoxVlhaW0")
        
        let localUrlString = URL(string:"http://nearmecrystal.appspot.com/pull")
        
        /*
        let headers = [
            "cache-control": "no-cache",
            "postman-token": "1aeb2087-632a-fa1d-d41d-b986d65d4dfc"
        ]
        
        let request = NSMutableURLRequest(url: NSURL(string: "https://nearmecrystal.appspot.com/pull")! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error)
            } else {
                let httpResponse = response as? HTTPURLResponse
                print(httpResponse)
            }
        })
        
        dataTask.resume()
 */
        
        //Completion Handler
        if let url = localUrlString {
            let task = URLSession.shared.dataTask(with: localUrlString!) { (data, response, error) in
                if error != nil {
                    print(error)
                } else {
                    if let usableData = data {
                        let json = try? JSONSerialization.jsonObject(with: usableData, options: JSONSerialization.ReadingOptions.allowFragments)
                        if let dictionary = json as? [Any] {
                            for nestednestedDictionary in dictionary {
                                if let location = nestednestedDictionary as? [String: Any] {
                                    self.resturantsAround.append(location["name"] as! String)
                                }
                            }
             
                        }
                    }
                }
            }
            task.resume()

            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: {
                self.FoodPickerView.reloadAllComponents()
            })
        }
    }
    

    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return (self.resturantsAround.count)
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return resturantsAround[row]
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
