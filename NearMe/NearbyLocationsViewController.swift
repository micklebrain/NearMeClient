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
    @IBOutlet weak var currentLocationLabel: UILabel!
    @IBOutlet weak var currentLocationTextField: UITextField!
    
    var suggestedResturants: [GoogleLocation] = []
    //Pull from Cache 
    var resturantsAround: [String] = []
    
    var latitude: Double?
    var longitude: Double?
    var radius: String?
    var apiKey: String?
    var locationManager: CLLocationManager!
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
        
        self.currentLocationTextField.delegate = self
        
        if let tbc = self.tabBarController as? MainTabBarController {
        // Crashes After first logging in through facebook b/c null value
        
        let newUser = User()
        self.userloggedIn = tbc.userloggedIn ?? newUser
            
            pullfacebookInfo()
            AccountAPIHandler.getUsername(facebookId: self.userloggedIn.facebookId!, completion: ({ username in
                self.userloggedIn.username = username
            }))
            locationManager = CLLocationManager()
            locationManager!.delegate = self
            locationManager!.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = 50
            locationManager!.requestAlwaysAuthorization()
            placesClient = GMSPlacesClient.shared()
            
            if CLLocationManager.locationServicesEnabled() {
                locationManager?.startUpdatingLocation()
            }
        }
                
        self.currentLocationLabel.text =  self.userloggedIn.buildingOccupied
    }
    
    private func pullfacebookInfo() {
        
        //Crashes without internet connection
        if(AccessToken.current != nil) {
            // Graph Path : "me" is going to get current user logged in
            let graphRequest = GraphRequest(graphPath: "me", parameters: ["fields": "id, name, email"])
            let connection = GraphRequestConnection()
            
            connection.add(graphRequest, completionHandler: { (connection, result, _) -> Void in
                if (connection?.urlResponse != nil && connection?.urlResponse.statusCode == 200) {
                    if let data = result as? [String: AnyObject] {
                        if let name = data["name"] as? String {
                        var splitName = name.components(separatedBy: " ")
                        let firstName = splitName.removeFirst()
    //                    let email = data["email"] as! String
    //                    let gender = data["gender"]
                        
                        let FBid = data["id"] as? String
                        
                        self.userloggedIn.firstName = firstName
                        self.userloggedIn.facebookId = FBid
                        }
                    }
                }
                
            })
            connection.start()
        }
        
    }
    
    func listLikelyPlaces() {
        
        likelyPlaces.removeAll()
        
        placesClient.currentPlace(callback: { (placeLikelihoods, error) -> Void in
            
            if let error = error {
                print("Places Client error: \(error.localizedDescription)")
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
                print("\(self.likelyPlaces.count) likely places around ")
                print(self.likelyPlaces)
                self.placesTableView.reloadData()
            }
            
        })
        
    }
    
    @IBAction func updateLocation(_ sender: Any) {
        
        let building = currentLocationTextField.text ?? ""
        self.userloggedIn.buildingOccupied = building
        let locality = self.userloggedIn.locality ?? ""
        let longitude = self.userloggedIn.longitude ?? 0.0
        let latitude = self.userloggedIn.latitude ?? 0.0
        let postalCode = self.userloggedIn.postalCode ?? 0
        
        LocationAPIHandler.updateLocation(user: self.userloggedIn,
                                          locality: locality,
                                          longitude: longitude,
                                          latitude: latitude,
                                          building: building,
                                          zipCode: postalCode)
        
        if let tbc = self.tabBarController as? MainTabBarController {
            self.currentLocationTextField.text = ""
            tbc.selectedIndex = 0
        }
        
    }
    
    @IBAction func floorChanged(_ sender: Any) {
        self.floorNumber.text = Int(self.floorStepper.value).description
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        placesTableView.delegate = self as? UITableViewDelegate
        placesTableView.dataSource = self
        placesTableView.reloadData()
    }
    
}

extension NearbyLocationsViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        let location: CLLocation = locations.last!
//
//        self.userloggedIn.latitude = location.coordinate.latitude
//        self.userloggedIn.longitude = location.coordinate.longitude
//
//        _ = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
//                                         longitude: location.coordinate.longitude,
//                                         zoom: zoomLevel)
        
        let userLocation: CLLocation = locations[0] as CLLocation
        
        //Update to get user's current location not managers
        CLGeocoder().reverseGeocodeLocation(userLocation, completionHandler: {(placemarks, error) -> Void in
            
            if (error != nil) {
                print("Reverse geocoder failed with error: " + (error?.localizedDescription)!)
                return
            }
            
            if (placemarks?.count)! > 0 {
                let pm = placemarks?[0]
                // TODO: Dosnt always update location
                let latitude = pm?.location?.coordinate.latitude
                let longitude = pm?.location?.coordinate.longitude
                self.userloggedIn.latitude = latitude
                self.userloggedIn.longitude = longitude
                self.userloggedIn.locality = pm?.locality
                self.userloggedIn.postalCode = Int ((pm?.postalCode)!)
            } else {
                print("Problem with the data received from geocoder")
            }
        })
        
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
        case .authorizedWhenInUse: print("Application is authorized to use location")
        @unknown default:
            fatalError()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Location Manager did fail error: \(error.localizedDescription)")
    }
    
}

extension NearbyLocationsViewController: UITableViewDataSource, UITableViewDelegate {
    
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
        if let tbc = self.tabBarController as? MainTabBarController {
            tbc.userloggedIn = self.userloggedIn
            self.userloggedIn.buildingOccupied = placesTableView.cellForRow(at: indexPath)?.textLabel?.text
            
            let longitude = self.userloggedIn.longitude ?? 0
            let latitude = self.userloggedIn.latitude ?? 0
            let postalCode = self.userloggedIn.postalCode ?? 0
            let locality = self.userloggedIn.locality ?? ""
            
            LocationAPIHandler.updateLocation(user: self.userloggedIn,
                                              locality: locality,
                                              longitude: longitude,
                                              latitude: latitude,
                                              building: (selectedPlace?.name)!,
                                              zipCode: postalCode)
            
            tbc.selectedIndex = 0
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? UserProfileViewController {
            controller.userSelected = self.userloggedIn
        }
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

extension NearbyLocationsViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ scoreText: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
}
