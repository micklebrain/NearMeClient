//
//  ProfileViewController.swift
//  NearMe
//
//  Created by Nathan Nguyen on 6/13/17.
//  Copyright © 2017 Nathan Nguyen. All rights reserved.
//

import UIKit
import CoreLocation
import GoogleMaps
import GooglePlaces
import Alamofire
import AlamofireSwiftyJSON
import FacebookLogin
import FacebookCore
import FBSDKLoginKit

class NearbyLocationsViewController: UIViewController {
    
    @IBOutlet weak var placesTableView: UITableView!
    @IBOutlet weak var floorNumber: UILabel!
    @IBOutlet weak var floorStepper: UIStepper!
    
    var suggestedResturants : [googleLocation] = []
    //Pull from Cache 
    var resturantsAround : [String] = []
    
    var latitude : Double?
    var longitude : Double?
    var radius : String?
    var apiKey : String?
    var locationManager : CLLocationManager!
    var currentUserLocation: CLLocation?
    var placesClient: GMSPlacesClient!
    var zoomLevel: Float = 15.0
    var likelyPlaces: [GMSPlace] = []
    var selectedPlace: GMSPlace?
    var userloggedIn = User()
    
    // A default location to use when location permission is not granted.
    let defaultLocation = CLLocation(latitude: -33.869405, longitude: 151.199)
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let tbc = self.tabBarController as! MainTabBarController
        // Crashes After first logging in through facebook b/c null value
        if (self.userloggedIn != nil && tbc.userloggedIn != nil) {
            self.userloggedIn = tbc.userloggedIn!
            
            pullfacebookInfo()
            getUsername()
            
            locationManager = CLLocationManager()
            locationManager!.delegate = self
            locationManager!.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = 50;
            locationManager!.requestAlwaysAuthorization()
            placesClient = GMSPlacesClient.shared()
            
            if CLLocationManager.locationServicesEnabled() {
                locationManager?.startUpdatingLocation()
            }
        }
        
    }
    
    private func getUsername() {
        
        let url = URL(string: "https://crystal-smalltalk.herokuapp.com/sync")
        
        let userDetails : Parameters = [
            "facebookId": self.userloggedIn.facebookId!
        ]
        
        Alamofire.request(url!, method: .post, parameters: userDetails, encoding: JSONEncoding.default)
            .responseString{ response in
                if let data = response.result.value{
                    self.userloggedIn.username = data
                }
        }
        
    }
    
    private func pullfacebookInfo() {
        
        //Crashes without internet connection
        if(FBSDKAccessToken.current() != nil)
        {
            print(FBSDKAccessToken.current().permissions)
            // Graph Path : "me" is going to get current user logged in
            let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields" : "id, name, email"])
            let connection = FBSDKGraphRequestConnection()
            
            connection.add(graphRequest, completionHandler: { (connection, result, error) -> Void in
                if (connection?.urlResponse != nil && connection?.urlResponse.statusCode == 200) {
                    let data = result as! [String : AnyObject]
                    let name = data["name"] as! String
                    let email = data["email"] as! String
                    print(email)
                    let gender = data["gender"]
                    var splitName = name.components(separatedBy: " ")
                    let firstName = splitName.removeFirst()
                    print("logged in user name is \(String(describing: name))")
                    
                    let FBid = data["id"] as? String
                    print("Facebook id is \(String(describing: FBid))")
                    
                    self.userloggedIn.firstName = firstName
                    self.userloggedIn.facebookId = FBid
                }
                
            })
            connection.start()
        }
        
    }
    
    func listLikelyPlaces() {
        
        likelyPlaces.removeAll()
        
        placesClient.currentPlace(callback:  { (placeLikelihoods, error) -> Void in
            
            if let error = error {
                print("Current Place error: \(error.localizedDescription)")
                return
            }
            
            if let likelihoodList = placeLikelihoods {
                for likelihood in likelihoodList.likelihoods {
                    let place = likelihood.place
                    if (!self.likelyPlaces.contains(place)
                        && !(place.name?.contains("St"))!
                        && !(place.name?.contains("street"))!
                        && !(place.name?.contains("Ave"))!) {
                        self.likelyPlaces.append(place)
                    }
                }
                self.placesTableView.reloadData()
            }
            
        })
        
    }
    
    @IBAction func floorChanged(_ sender: Any) {
        self.floorNumber.text = Int(self.floorStepper.value).description
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateLocation(locality: String) {
        
        _ = locality.replacingOccurrences(of: " ", with: "")
        
        let url = URL(string: "https://crystal-smalltalk.herokuapp.com/updateLocation")
        
        let userDetails : Parameters = [
            "firstname": self.userloggedIn.firstName!,
            "username": self.userloggedIn.username!,
            "facebookId": self.userloggedIn.facebookId!,
            "locality": locality
        ]
        
        let tbc = self.tabBarController as! MainTabBarController
        tbc.userloggedIn?.buildingOccupied = locality
        
        Alamofire.request(url!, method: .post, parameters: userDetails, encoding: JSONEncoding.default)
            .response { response in
                print(response.response?.statusCode)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        placesTableView.delegate = self as! UITableViewDelegate
        placesTableView.dataSource = self
        placesTableView.reloadData()
    }
    
}

extension NearbyLocationsViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        
        let _ = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                         longitude: location.coordinate.longitude,
                                         zoom: zoomLevel)
        
        listLikelyPlaces()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
    
}

extension NearbyLocationsViewController : UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if likelyPlaces.count == 0 {
            return 1
        }
        return likelyPlaces.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if likelyPlaces.count == 0 {
            let cell = placesTableView.dequeueReusableCell(withIdentifier: "place", for: indexPath)
            cell.textLabel?.text = "Please enable location services"
            return cell
        }
        let cell = placesTableView.dequeueReusableCell(withIdentifier: "place", for: indexPath)
        let collectionItem = likelyPlaces[indexPath.row]
        cell.textLabel?.text = collectionItem.name
        
        return cell
    }
    
    // Show only the first five items in the table (scrolling is disabled in IB).
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.placesTableView.frame.size.height/5
    }
    
    // Make table rows display at proper height if there are less than 5 items.
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if (section == placesTableView.numberOfSections - 1) {
            return 1
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Index out of range exception?
        selectedPlace = likelyPlaces[indexPath.row]
        
        let tbc = self.tabBarController as! MainTabBarController
        tbc.userloggedIn = self.userloggedIn
        self.userloggedIn.buildingOccupied = placesTableView.cellForRow(at: indexPath)?.textLabel?.text
        self.userloggedIn.floor = Int(floorNumber.text!)
        
        updateLocation(locality: (self.userloggedIn.buildingOccupied)!)
        tbc.selectedIndex = 1
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = segue.destination as! UserProfileViewController
        controller.userSelected = self.userloggedIn
    }
    
}

extension NearbyLocationsViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return (self.resturantsAround.count)
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return resturantsAround[row]
    }
    
}

