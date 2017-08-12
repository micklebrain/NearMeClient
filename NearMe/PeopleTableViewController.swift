//
//  PeopleTableViewController.swift
//  NearMe
//
//  Created by Nathan Nguyen on 4/18/17.
//  Copyright © 2017 Nathan Nguyen. All rights reserved.
//

import UIKit
import AWSDynamoDB
import CoreLocation
import AWSS3

class personCell : UITableViewCell {
    
    @IBOutlet weak var headshot: UIImageView!
    @IBOutlet weak var descriptor: UILabel!
 
}

class PeopleTableViewController: UITableViewController, CLLocationManagerDelegate {
    
    var locationManager : CLLocationManager!
    var people: [Person] = []
    var table: Table?
    var results: [AWSDynamoDBObjectModel]?
    var peopleAround = Set<Person>()
    var userLoggedIn: User?
    var currentUserLocation: CLLocation?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        userLoggedIn = User()
        //Check if location services is on first
        determineMyCurrentLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//  MARK: - Location tracking
    func determineMyCurrentLocation() {
        
        locationManager = CLLocationManager()
        locationManager!.delegate = self
        locationManager!.desiredAccuracy = kCLLocationAccuracyBest
        locationManager!.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager?.startUpdatingLocation()
        }
    }
    
//  Multithreading? Concurrent?
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
        let userLocation:CLLocation = locations[0] as CLLocation
        
        //Shouldnt have both
    //    manager.stopUpdatingLocation()
     //   locationManager.stopUpdatingLocation()

        //Update to get user's current location not managers
        CLGeocoder().reverseGeocodeLocation(userLocation, completionHandler: {(placemarks, error)->Void in
            
            if (error != nil) {
                print("Reverse geocoder failed with error: " + (error?.localizedDescription)!)
                return
            }
            
            if (placemarks?.count)! > 0 {
                let pm = placemarks?[0]
                self.updateCurrentUserLocation(placemark: pm, userLocation: userLocation)
            } else {
                print("Problem with the data received from geocoder")
            }
        })
    }
    
    func updateCurrentUserLocation (placemark: CLPlacemark?, userLocation: CLLocation) {
        
        if let containsPlacemark = placemark {
            
//          TODO: Periodically update location
//          locationManager.stopUpdatingLocation()
            let locality = (containsPlacemark.locality != nil) ? containsPlacemark.locality : ""
            let postalCode = (containsPlacemark.postalCode != nil) ? containsPlacemark.postalCode : ""
            let administrativeArea = (containsPlacemark.administrativeArea != nil) ? containsPlacemark.administrativeArea : ""
            let country = (containsPlacemark.country != nil) ? containsPlacemark.country : ""
            
            let objectMapper = AWSDynamoDBObjectMapper.default()
            var errors: [NSError] = []
            let group: DispatchGroup = DispatchGroup()
            
            let latitude = userLocation.coordinate.latitude
            let longitutde = userLocation.coordinate.longitude
            currentUserLocation = CLLocation(latitude: latitude, longitude: longitutde)
//          userLoggedIn?.location = CLLocation(latitude: latitude, longitude: longitutde)
//          userLoggedIn?.userID = AWSIdentityManager.default().identityId!
//          userLoggedIn.itemId = NoSQLSampleDataGenerator.randomSampleStringWithAttributeName("itemId")
            userLoggedIn?.username = "Sion"
            userLoggedIn?.postalCode = postalCode
            userLoggedIn?.administrativeArea = administrativeArea
            userLoggedIn?.country = country
            userLoggedIn?.locality = locality
            userLoggedIn?.latitude = userLocation.coordinate.latitude as NSNumber
            userLoggedIn?.longitude = userLocation.coordinate.longitude as NSNumber
            userLoggedIn?.firstName = userLoggedIn?.username
            group.enter()
    
            objectMapper.save(userLoggedIn!, completionHandler: {(error: Error?) -> Void in
                if error != nil {
                    DispatchQueue.main.async {
                        errors.append(error! as NSError)
                    }
                }
            })
           pullNearByPeople()
        }
    }
    
//  Scans all of table
    func scanNearbyUsers (_ completeionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void) {
        
        let objectMapper = AWSDynamoDBObjectMapper.default()
        let scanExpression = AWSDynamoDBScanExpression()
        
        objectMapper.scan(User.self, expression: scanExpression) { (response: AWSDynamoDBPaginatedOutput?, error: Error?) in
            DispatchQueue.main.async(execute: {
                completeionHandler(response, error as NSError?)
            })
        }
    }
    
    func pullNearByPeople () {
        
        //table = LocationsTable()
        
        let completionHandler = {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
            
            if let error = error {
                var errorMessage = "Failed to retrieve items. \(error.localizedDescription)"
                if (error.domain == AWSServiceErrorDomain && error.code == AWSServiceErrorType.accessDeniedException.rawValue) {
                    errorMessage = "Access denied. You are not allowed to perform this operation."
                    print(errorMessage)
                }
            }
            else if response!.items.count == 0 {
                print("No items match your criteria. Insert more sample data and try again.")
            }
            else {
                self.results = response?.items
                for result in self.results! {
                let model = result
                let modelDictionary: [AnyHashable: Any] = model.dictionaryValue
                // _ = self.table?.tableAttributeName!(self.table!.orderedAttributeKeys[10])
                let newPerson = Person()
                
                let userLatitude = CLLocationDegrees("\(modelDictionary["latitude"]!)")
//                (self.table?.orderedAttributeKeys as Any)
                let userLongitude = CLLocationDegrees("\(modelDictionary["longitude"]!)")
                let userLocation = CLLocation(latitude: userLatitude!, longitude: userLongitude!)
                
                newPerson.location = userLocation
                newPerson.firstName = "\(modelDictionary["firstName"]!)"
                
                if (newPerson.firstName != self.userLoggedIn?.firstName) {
                    let distanceApart = newPerson.location?.distance(from: (self.currentUserLocation)!)
                    
                    var aMile = CLLocationDistance()
                    aMile.add(1609)
                    
                    if (self.currentUserLocation != nil) {
                        if (distanceApart?.isLess(than: aMile))!{
                            self.peopleAround.insert(newPerson)
                        }
                    }
                }
            }
            self.tableView.reloadData()
        }
        }
        
//      Query by userID
//      index.queryWithPartitionKeyAndFilterWithCompletionHandler?(completionHandler)
        
//      Scan with filer
//      table?.scanWithFilterWithCompletionHandler!(completionHandler)
       
//      Scan for all items from table
//      table?.scanWithCompletionHandler!(completionHandler)
        
//      Scan accounts table
        scanNearbyUsers(completionHandler)

    }
    
//  MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.peopleAround.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PersonCell", for: indexPath) as! personCell
        
          cell.descriptor.text = (peopleAround.popFirst()?.firstName)! + "\n"
        
//        if (nextPerson is EmployedPerson) {
//            let EmployedPerson = nextPerson as! EmployedPerson
//            cell.descriptor.text?.append(EmployedPerson.employer)
//        } else {
//            let Student = nextPerson as! Student
//            cell.descriptor.text?.append(Student.school!)
//        }
        
        let transferManager = AWSS3TransferManager.default()
        
        let downloadingFileUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("headshot1.jpg")
        let downloadRequest = AWSS3TransferManagerDownloadRequest()
        
        downloadRequest?.bucket = "nearme-pictures"
        downloadRequest?.key = "headshot2.jpg"
        downloadRequest?.downloadingFileURL = downloadingFileUrl
        
        transferManager.download(downloadRequest!).continueWith(executor : AWSExecutor.mainThread(), block: { (task:AWSTask<AnyObject>) -> Any? in
            if let error = task.error as NSError? {
                if error.domain == AWSS3TransferManagerErrorDomain, let code = AWSS3TransferManagerErrorType(rawValue: error.code) {
                switch code {
                    case .cancelled, .paused:
                        break
                    default:
                        print("Error downloading: \(String(describing: downloadRequest?.key)) Error: \(error)")
                    }
                } else {
                    print("Error downloading: \(String(describing: downloadRequest?.key)) Error: \(error)")
                }
                    return nil
                }
            print("Download complete for: \(downloadRequest?.key)")
            let downloadOutput = task.result
            return nil
        })
        
        cell.headshot.image = UIImage(contentsOfFile: downloadingFileUrl.path)
//      cell.headshot.image = #imageLiteral(resourceName: "headshot1")
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
