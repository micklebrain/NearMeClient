//
//  ViewController.swift
//  NearMe
//
//  Created by Nathan Nguyen on 4/18/17.
//  Copyright © 2017 Nathan Nguyen. All rights reserved.
//

import UIKit
import CoreLocation
import AWSMobileHubHelper
import AWSDynamoDB

//func authorizationStatus() -> ClAuthorizationStatus

class MapTrackerViewController: UIViewController, CLLocationManagerDelegate {
    
    var locationManager : CLLocationManager!
    var firstUser : Person!
    @IBOutlet weak var trackingToggle: UIButton!
    var table: Table?
    var item: Locations = Locations()
    var currentUser = Person()
    
    override func viewDidLoad() {
        super.viewDidLoad()
//      Do any additional setup after loading the view, typically from a nib.

//  self.insertSampleDataWithCompletionHandler({(errors: [NSError]?) -> Void in
//            var message: String = "20 sample items were added to your table."
//            if errors != nil {
//                message = "Failed to insert sample items to your table."
//            }
//            let alartController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
//            let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
//            alartController.addAction(dismissAction)
//            self.present(alartController, animated: true, completion: nil)
//        })
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        currentUser.firstName = "Sally"
        determineMyCurrentLocation()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
 
    //Location Management
    func determineMyCurrentLocation() {
        
        locationManager = CLLocationManager()
        locationManager!.delegate = self
        locationManager!.desiredAccuracy = kCLLocationAccuracyBest
        locationManager!.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager?.startUpdatingLocation()
            //locationManager.startUpdatingHeading()
        }
    }
    
    // Use Latitude, Longitutde
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations:[CLLocation]) {
//        
//        let objectMapper = AWSDynamoDBObjectMapper.default()
//        var errors: [NSError] = []
//        let group: DispatchGroup = DispatchGroup()
//        
//        let userLocation:CLLocation = locations[0] as CLLocation
//        
//        locationManager.stopUpdatingLocation()
//        
//        item._userId = AWSIdentityManager.default().identityId!
//        item._itemId = NoSQLSampleDataGenerator.randomSampleStringWithAttributeName("itemId")
//        item._latitude = userLocation.coordinate.latitude as NSNumber
//        item._longitude = userLocation.coordinate.longitude as NSNumber
//        
//        group.enter()
//        
//        objectMapper.save(item, completionHandler: {(error: Error?) -> Void in
//            if error != nil {
//                DispatchQueue.main.async {
//                    errors.append(error as NSError!)
//                }
//            }
//            
//        })
//    }
    
    //Use descriptive location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let userLocation:CLLocation = locations[0] as CLLocation
        
        CLGeocoder().reverseGeocodeLocation(manager.location!, completionHandler: {(placemarks, error)->Void in
            
            if (error != nil) {
                print("Reverse geocoder failed with error" + (error?.localizedDescription)!)
                return
            }
            
            if (placemarks?.count)! > 0 {
                let pm = placemarks?[0]
                self.displayLocationInfo(placemark: pm, userLocation: userLocation)
            } else {
                print("Problem with the data received from geocoder")
            }
        })
    }
    
    func displayLocationInfo(placemark: CLPlacemark?, userLocation:CLLocation) {
        
        if let containsPlacemark = placemark {
            
            //How to periodically update location?
         //   locationManager.stopUpdatingLocation()
            let locality = (containsPlacemark.locality != nil) ? containsPlacemark.locality : ""
            let postalCode = (containsPlacemark.postalCode != nil) ? containsPlacemark.postalCode : ""
            let administrativeArea = (containsPlacemark.administrativeArea != nil) ? containsPlacemark.administrativeArea : ""
            let country = (containsPlacemark.country != nil) ? containsPlacemark.country : ""
   
            
            let objectMapper = AWSDynamoDBObjectMapper.default()
            var errors: [NSError] = []
            let group: DispatchGroup = DispatchGroup()
            
            item._userId = AWSIdentityManager.default().identityId!
            item._itemId = NoSQLSampleDataGenerator.randomSampleStringWithAttributeName("itemId")
            item._username = currentUser.firstName
            item._postalCode = postalCode
            item._administrativeArea = administrativeArea
            item._country = country
            item._locality = locality
            item._latitude = userLocation.coordinate.latitude as NSNumber
            item._longitude = userLocation.coordinate.longitude as NSNumber
            
            group.enter()
            
            objectMapper.save(item, completionHandler: {(error: Error?) -> Void in
                if error != nil {
                    DispatchQueue.main.async {
                        errors.append(error! as NSError)
                    }
                }
            })
            
            print(locality! + "\n")
            print(postalCode! + "\n")
            print(administrativeArea! + "\n")
            print(country! + "\n")
            
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error while updating location " + error.localizedDescription)
    }
    
    @IBAction func goOffline(_ sender: Any) {
        
        locationManager.stopUpdatingLocation()
        
        currentUser.online = !currentUser.online
        
        if (currentUser.online == true) {
            trackingToggle.titleLabel?.text = "Online"
        } else {
            trackingToggle.titleLabel?.text = "Offline"
        }
        
    }
    
    //Sample data insert
    func insertSampleDataWithCompletionHandler(_ completionHandler: @escaping (_ errors: [NSError]?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        var errors: [NSError] = []
        let group: DispatchGroup = DispatchGroup()
        _ = 20
        
        let itemForGet: Locations! = Locations()
        
        itemForGet._userId = AWSIdentityManager.default().identityId!
        itemForGet._itemId = "demo-itemId-500000"
        itemForGet._category = NoSQLSampleDataGenerator.randomPartitionSampleStringWithAttributeName("Category")
        itemForGet._latitude = NoSQLSampleDataGenerator.randomSampleNumber()
        itemForGet._longitude = NoSQLSampleDataGenerator.randomSampleNumber()
        itemForGet._name = NoSQLSampleDataGenerator.randomSampleStringWithAttributeName("name")
        
        group.enter()
        
        objectMapper.save(itemForGet, completionHandler: {(error: Error?) -> Void in
            if let error = error as NSError? {
                DispatchQueue.main.async(execute: {
                    errors.append(error)
                })
            }
            group.leave()
        })
        
        //        for _ in 1..<numberOfObjects {
        //
        //            let item: Locations = Locations()
        //            item._userId = AWSIdentityManager.default().identityId!
        //            item._itemId = NoSQLSampleDataGenerator.randomSampleStringWithAttributeName("itemId")
        //            item._category = NoSQLSampleDataGenerator.randomPartitionSampleStringWithAttributeName("Category")
        //            item._latitude = NoSQLSampleDataGenerator.randomSampleNumber()
        //            item._longitude = NoSQLSampleDataGenerator.randomSampleNumber()
        //            item._name = NoSQLSampleDataGenerator.randomSampleStringWithAttributeName("name")
        //
        //            group.enter()
        //
        //            objectMapper.save(item, completionHandler: {(error: Error?) -> Void in
        //                if error != nil {
        //                    DispatchQueue.main.async(execute: {
        //                        errors.append(error! as NSError)
        //                    })
        //                }
        //            })
        //        }
        
        group.notify(queue: DispatchQueue.main, execute: {
            if errors.count > 0 {
                completionHandler(errors)
            }
            else {
                completionHandler(nil)
            }
        })
    }
    
}


    


