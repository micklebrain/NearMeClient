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

class NearbyLocations: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var placesTableView: UITableView!
    @IBOutlet weak var nameLabel: UILabel!
    
    public var currentUserProfile : User?
    var suggestedResturants : [googleLocation] = []
    //Pull from Cache 
    var resturantsAround : [String] = []
    
    var latitude : Double?
    var longitude : Double?
    var radius : String?
    var apiKey : String?
    var locationManager : CLLocationManager!
    var currentUserLocation: CLLocation?
    var mapView: GMSMapView!
    var placesClient: GMSPlacesClient!
    var zoomLevel: Float = 15.0
    var likelyPlaces: [GMSPlace] = []
    var selectedPlace: GMSPlace?
    // A default location to use when location permission is not granted.
    let defaultLocation = CLLocation(latitude: -33.869405, longitude: 151.199)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager!.delegate = self
        locationManager!.desiredAccuracy = kCLLocationAccuracyBest
//      locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters;
        locationManager.distanceFilter = 50;
        locationManager!.requestAlwaysAuthorization()
        placesClient = GMSPlacesClient.shared()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager?.startUpdatingLocation()
        }
        
        let camera = GMSCameraPosition.camera(withLatitude: self.defaultLocation.coordinate.latitude,
                                              longitude: self.defaultLocation.coordinate.longitude,
                                              zoom: zoomLevel)
        
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        view.addSubview(mapView)
        mapView.isHidden = true
        
        let objectMapper = AWSDynamoDBObjectMapper.default()
        
//        for index in 1...47 {
//            let newUser = User()
//            newUser?.firstName = "Tester" + String(index)
//            newUser?.latitude = 37.787358
//            newUser?.longitude = -122.408227
//            newUser?.locality = "Nothing"
//            newUser?.username = newUser?.firstName
//            newUser?.lastName = "Tester"
//            var errors: [NSError] = []
//            objectMapper.save(newUser!, completionHandler: { (error: Error?) -> Void in
//                if (error != nil) {
//                    DispatchQueue.main.async {
//                        errors.append(error as! NSError)
//                    }
//                }
//            })
//        }
        
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        nameLabel.text = currentUserProfile?.firstName
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //  Multithreading? Concurrent?
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//
//        let userLocation:CLLocation = locations[0] as CLLocation
//        latitude = userLocation.coordinate.latitude
//        longitude = userLocation.coordinate.longitude
//
//         locateNearby()
//        //Shouldnt have both
//        //    manager.stopUpdatingLocation()
//        //   locationManager.stopUpdatingLocation()
//
//        //Update to get user's current location not managers
//        CLGeocoder().reverseGeocodeLocation(userLocation, completionHandler: {(placemarks, error)->Void in
//
//            if (error != nil) {
//                print("Reverse geocoder failed with error: " + (error?.localizedDescription)!)
//                return
//            }
//
//            if (placemarks?.count)! > 0 {
//                let pm = placemarks?[0]
//            } else {
//                print("Problem with the data received from geocoder")
//            }
//        })
//    }
    
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
    
    func locateNearby() {
        
        let gplacesURL = URL(string:"https://maps.googleapis.com/maps/api/place/nearbysearch/json?location="+String(describing: latitude!)+","+String(describing: longitude!)+"&radius=31&key=AIzaSyBWdayUxe65RUQLv4QL6GcB_UXoxVlhaW0")
        
        if let url = gplacesURL {
            let task = URLSession.shared.dataTask(with: gplacesURL!) { (data, response, error) in
                if error != nil {
                    print(error)
                } else {
                    if let usableData = data {
                        let json = try? JSONSerialization.jsonObject(with: usableData, options: JSONSerialization.ReadingOptions.allowFragments)
                        if let dictionary = json as? [String: Any] {
                            self.resturantsAround.removeAll()
                            if let nestedDictionary = dictionary["results"] as? [Any]{
                                for nestednestedDictionary in nestedDictionary {
                                    if let location = nestednestedDictionary as? [String: Any] {
                                        let types: [String] = location["types"] as! [String]
                                            if (!types.contains("locality") && !types.contains("route")) {
                                                self.resturantsAround.append(location["name"] as! String)
                                            }
                                    }
                                }
                                self.resturantsAround.append( "Others")
                            }
                        }
                    }
                }
            }
            task.resume()
            
        }
        
    }
    
    // Find Nearby resturant from Google
    func locateNearbyGCloud () {
        // Getting nearby food locations
        let urlString = URL(string:"https://maps.googleapis.com/maps/api/place/nearbysearch/json?"+"location=33.892260,-84.491042"+"&radius=1000&type=restaurant&keyword=burgers&key=AIzaSyCSLA7M3BdjNuDVRMtvAq2LLcrkLbkDhE8")
        
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
                    if (!self.likelyPlaces.contains(place)) {
                        self.likelyPlaces.append(place)
                    }
                }
                self.placesTableView.reloadData()
            }
        })
        
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

extension NearbyLocations: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            zoom: zoomLevel)
        
        if mapView.isHidden {
            mapView.isHidden = true
            mapView.camera = camera
        } else {
            mapView.animate(to: camera)
        }
        
        listLikelyPlaces()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mapView.isHidden = false
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

extension NearbyLocations : UITableViewDataSource, UITableViewDelegate {
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
        selectedPlace = likelyPlaces[indexPath.row]
        
        mapView.clear()
        if selectedPlace != nil {
            let marker = GMSMarker(position: (self.selectedPlace?.coordinate)!)
            marker.title = selectedPlace?.name
            marker.snippet = selectedPlace?.formattedAddress
            marker.map = mapView
            mapView.isHidden = false
        }
        
        let nearbyPeopleVC:NearbyPeopleViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NearbyPeopleViewController") as! NearbyPeopleViewController
        nearbyPeopleVC.userLoggedIn = User()
        nearbyPeopleVC.userLoggedIn?.buildingOccupied = placesTableView.cellForRow(at: indexPath)?.textLabel?.text
        nearbyPeopleVC.userLoggedIn?.username = self.currentUserProfile?.username
        self.present(nearbyPeopleVC, animated: false, completion: nil)
        
//      listLikelyPlaces()
    }
}
