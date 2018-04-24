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
import AWSDynamoDB
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
    var userloggedIn: User?
    
    // A default location to use when location permission is not granted.
    let defaultLocation = CLLocation(latitude: -33.869405, longitude: 151.199)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tbc = self.tabBarController as! MainTabBarController
        self.userloggedIn = tbc.userloggedIn
        
        locationManager = CLLocationManager()
        locationManager!.delegate = self
        locationManager!.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50;
        locationManager!.requestAlwaysAuthorization()
        placesClient = GMSPlacesClient.shared()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager?.startUpdatingLocation()
        }
        
        let objectMapper = AWSDynamoDBObjectMapper.default()
        
    }
    
    func pullfacebookInfo() {
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
                        var name = data["name"] as! String
                        var splitName = name.components(separatedBy: " ")
                        let firstName = splitName.removeFirst()
                        print("logged in user name is \(String(describing: name))")
        
                        let FBid = data["id"] as? String
                        print("Facebook id is \(String(describing: FBid))")
        
                        self.userloggedIn = User()
                        self.userloggedIn?.firstName = firstName
                        self.userloggedIn?.username = "Tester"
                        self.userloggedIn?.facebookId = FBid
                    }
    
                })
                connection.start()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
                    if (!self.likelyPlaces.contains(place) && !place.name.contains("St") && !place.name.contains("street") && !place.name.contains("Ave")) {
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
    
        
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

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

extension NearbyLocationsViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
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
    
    override func viewDidAppear(_ animated: Bool) {
        placesTableView.delegate = self as? UITableViewDelegate
        placesTableView.dataSource = self
        placesTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return likelyPlaces.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        
            self.userloggedIn?.buildingOccupied = placesTableView.cellForRow(at: indexPath)?.textLabel?.text
           //updateLocation(locality: (self.userloggedIn?.buildingOccupied)!)
            self.userloggedIn?.floor = Int(floorNumber.text!)
            tbc.userloggedIn = self.userloggedIn
            tbc.selectedIndex = 2

    }
    
    func updateLocation(locality: String) {
        
        let localityTrimmed = locality.replacingOccurrences(of: " ", with: "")
        
        let url = URL(string: "https://crystal-smalltalk.herokuapp.com/updateLocation")
        
        let userDetails : Parameters = [
            "firstName": self.userloggedIn?.firstName,
            "username": self.userloggedIn?.username,
            "facebookId": self.userloggedIn?.facebookId,
            "locality": locality,
            "sex": "MALE"
        ]
        
        Alamofire.request(url!, method: .post, parameters: userDetails, encoding: JSONEncoding.default)
            .response { response in
                print(response.response?.statusCode)
        }
    
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = segue.destination as! UserProfileViewController
        controller.userLoggedIn = self.userloggedIn
    }
    
}
