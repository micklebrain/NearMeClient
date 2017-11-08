//
//  NearbyPeopleViewController.swift
//  NearMe
//
//  Created by Nathan Nguyen on 6/13/17.
//  Copyright © 2017 Nathan Nguyen. All rights reserved.
//

import UIKit
import AWSDynamoDB
import CoreLocation
import AWSS3
import FacebookCore
import FacebookLogin
import FacebookCore
import FBSDKLoginKit
import Alamofire
import SwiftyJSON

class NearbyPeopleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    
    let section = ["Friends", "Potential Friends"]
    //add collegaues, same school
    var locationManager : CLLocationManager!
    var people: [Person] = []
    var results: [AWSDynamoDBObjectModel]?
    var strangersAround = Set<Person>()
//  Using NSMutableSet because AWS
    var friendsAround = NSMutableSet()
//    var strangers = NSMutableSet()
    var userLoggedIn: User?
    var currentUserLocation: CLLocation?
    var headshot : UIImage?
    @IBOutlet weak var PeopleNearbyTableView: UITableView!
    @IBOutlet weak var presenceSwitch: UISwitch!
    @IBOutlet weak var CurrentLocationLabel: UILabel!

//  TODO: implement single signon
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getLocation()
        
        self.PeopleNearbyTableView.delegate = self
        self.PeopleNearbyTableView.dataSource = self
        
        if let accessToken = AccessToken.current {
            print(AccessToken.current?.userId)
        }
    
//        pullNearByPeople()
        
//        let date = Date().addingTimeInterval(60)
//        let timer = Timer(timeInterval: 5, target: self, selector: #selector(pullNearByPeople), userInfo: 60, repeats: true)
    }
    
    func getLocation() {
        
        Alamofire.request("https://httpbin.org/get").responseJSON { response in
            print("Request: \(String(describing: response.request))")   // original url request
            print("Response: \(String(describing: response.response))") // http url response
            print("Result: \(response.result)")                         // response serialization result
            
            if let json = response.result.value {
                print("JSON: \(json)") // serialized json response
            }
            
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                print("Data: \(utf8Text)") // original server data as UTF8 string
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Check if location services is on first
        determineMyCurrentLocation()
        downloadImages()
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func viewProfile(_ sender: Any) {
        
    }
    
    func pullFacebookInfo () {
        if(FBSDKAccessToken.current() != nil)
        {
            print(FBSDKAccessToken.current().permissions)
            let nathanFBId = "1367878021"
            let TraceyFBid = "109582432994026"
            let graphRequest = FBSDKGraphRequest(graphPath: TraceyFBid, parameters: ["fields" : "id, name, email"])
   
            let connection = FBSDKGraphRequestConnection()
            
            connection.add(graphRequest, completionHandler: { (connection, result, error) -> Void in
                let data = result as! [String : AnyObject]
                let name = data["name"] as? String
                let email = data["email"] as? String
                print("logged in user name is \(String(describing: name))")
                
                let FBid = data["id"] as? String
                print("Facebook id is  \(String(describing: FBid))")
            })
            connection.start()
        }
    }
    
    func downloadImages () {
        let transferManager = AWSS3TransferManager.default()
        
        let downloadingFileUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("headshot1.jpg")
        let downloadRequest = AWSS3TransferManagerDownloadRequest()
        
        downloadRequest?.bucket = "nearme-pictures"
        downloadRequest?.key = "headshot2.jpg"
        downloadRequest?.downloadingFileURL = downloadingFileUrl
        
        // TODO: Cache images
        // Image was downloaded after the cell was returned
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
            print("Download complete for: \(String(describing: downloadRequest?.key))")
            return nil
        })
        
        self.headshot = UIImage(contentsOfFile: downloadingFileUrl.path)
    }
    
    
    //  MARK: - Location tracking
    @IBAction func presenceSwitch(_ sender: Any) {
        self.userLoggedIn?.online = !(self.userLoggedIn?.online as! (Bool)) as NSNumber
        updateOnlineStatus()
    }
    
    func updateOnlineStatus () {
        if (userLoggedIn!.online.boolValue) {
            presenceSwitch.isOn = true
            determineMyCurrentLocation()
        } else {
            presenceSwitch.isOn = false
            locationManager.stopUpdatingLocation()
        }
    }
    
    func determineMyCurrentLocation() {
        
        locationManager = CLLocationManager()
        locationManager!.delegate = self
        locationManager!.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters;
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
            
            //  TODO: Periodically update location
            //  locationManager.stopUpdatingLocation()
            let locality = (containsPlacemark.locality != nil) ? containsPlacemark.locality : ""
            let postalCode = (containsPlacemark.postalCode != nil) ? containsPlacemark.postalCode : ""
            let administrativeArea = (containsPlacemark.administrativeArea != nil) ? containsPlacemark.administrativeArea : ""
            let country = (containsPlacemark.country != nil) ? containsPlacemark.country : ""
            
            let objectMapper = AWSDynamoDBObjectMapper.default()
            var errors: [NSError] = []
            //Use Group for threading?
            let group: DispatchGroup = DispatchGroup()
            
            let latitude = userLocation.coordinate.latitude
            let longitutde = userLocation.coordinate.longitude
            currentUserLocation = CLLocation(latitude: latitude, longitude: longitutde)
//          userLoggedIn?.location = CLLocation(latitude: latitude, longitude: longitutde)
//          userLoggedIn?.userID = AWSIdentityManager.default().identityId!
//          userLoggedIn.itemId = NoSQLSampleDataGenerator.randomSampleStringWithAttributeName("itemId")
//          userLoggedIn?.username = currentUser?.username
            
            userLoggedIn = User()
            
            userLoggedIn?.userID = 2 as NSNumber
            userLoggedIn?.username = "Sally"
            userLoggedIn?.firstName = userLoggedIn?.username
            //      userLoggedIn?.lastName = "Tracey"
            //        userLoggedIn?.occupation = "developer"
//          userLoggedIn?.online = true as Bool as NSNumber
            //        userLoggedIn?.relationshipStatus = "single"
            userLoggedIn?.facebookId = 1367878021 as NSNumber
            //        self.friendsAround.add(2)
            //        userLoggedIn?.friends = self.friendsAround
            
//          User's Locaiton
            userLoggedIn?.postalCode = postalCode
            userLoggedIn?.administrativeArea = administrativeArea
            userLoggedIn?.country = country
            userLoggedIn?.locality = locality
            userLoggedIn?.latitude = userLocation.coordinate.latitude as NSNumber
            userLoggedIn?.longitude = userLocation.coordinate.longitude as NSNumber
            
            objectMapper.save(userLoggedIn!, completionHandler: {(error: Error?) -> Void in
                if error != nil {
                    DispatchQueue.main.async {
                        errors.append(error! as NSError)
                    }
                }
            })
            
            self.CurrentLocationLabel.text = locality
            
            pullNearByPeople()
        }
    }
    
    //  Scans all of table
    func scanNearbyUsers (_ completeionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void) {
        
        let objectMapper = AWSDynamoDBObjectMapper.default()
        let scanExpression = AWSDynamoDBScanExpression()
//      scanExpression.filterExpression = "online = :val"
//      scanExpression.expressionAttributeValues = [":val": "true"]
        
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
                    
                    let facebookId = "\(modelDictionary["facebookId"]!)"

                    let userLatitude = CLLocationDegrees("\(modelDictionary["latitude"]!)")
                    //  (self.table?.orderedAttributeKeys as Any)
                    let userLongitude = CLLocationDegrees("\(modelDictionary["longitude"]!)")
                    let userLocation = CLLocation(latitude: userLatitude!, longitude: userLongitude!)
                    let isOnline = "\(modelDictionary["online"]!)"
                    
                    newPerson.location = userLocation
                    newPerson.firstName = "\(modelDictionary["firstName"]!)"
                    newPerson.sex = sex(rawValue: "\(modelDictionary["sex"]!)")
                    newPerson.facebookId = facebookId
                    
                    newPerson.headshotImage = self.getUserPicture(facebookId: facebookId)
                    
                    // newPerson.online = "\(modelDictionary["online"])"
                    
                    if (newPerson.firstName != self.userLoggedIn?.firstName && isOnline == "1") {
                        let distanceApart = newPerson.location?.distance(from: (self.currentUserLocation)!)
                        
                        var aMile = CLLocationDistance()
                        aMile.add(1609)
                        
                        if (self.currentUserLocation != nil) {
                            if (distanceApart?.isLess(than: aMile))!{
                                self.strangersAround.insert(newPerson)
                            }
                        }
                    }
                }
                self.PeopleNearbyTableView.reloadData()
            }
        }
    
        //  Scan accounts table
        scanNearbyUsers(completionHandler)
        
    }

    @IBAction func connect(_ sender: Any) {
        let profileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        self.present(profileVC, animated: false, completion: nil)
    }
    
//  Mark: Filter
    @IBAction func filter(_ sender: Any) {
        
        while self.strangersAround.contains(where: { $0.sex == sex.male }) {
        
            let foundPerson = self.strangersAround.first(where: { $0.sex == sex.male })
            strangersAround.remove(foundPerson!)
        }
        
        self.PeopleNearbyTableView.reloadData()
    
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.section[section]
    }
    
    //  MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return self.section.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    // TODO: Ternary Operator
        if (section == 0) {
            return self.friendsAround.count
        } else {
            return self.strangersAround.count
        }
    }
    
    func getUserPicture (facebookId : String) -> UIImage {
        
        var headshot = #imageLiteral(resourceName: "headshot2")
    
        var pictureUrl = "http://graph.facebook.com/"
        
        pictureUrl += facebookId
        pictureUrl += "/picture?type=large"
        
        var url = URL(string: pictureUrl)
        
        if let url = url {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    print(error)
                } else {
                    if let usableData = data {
                        headshot  = UIImage(data: usableData)!
                    }
                }
            }
            
        
        task.resume()
            
        return headshot
    }
        return headshot
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserTableViewCell
        
//      TODO: Check why view gets loaded without images - bug
        if (indexPath.section == 0) {
            cell.nameLabel.text = "Friend's Name"
            cell.headshotViewImage.image = self.headshot
            cell.headshotViewImage.layer.cornerRadius = 15.0
            cell.headshotViewImage.layer.borderWidth = 3
            cell.headshotViewImage.layer.borderColor = UIColor.black.cgColor
            cell.connectButton.titleLabel?.text = "reconnect"
        } else {
            cell.nameLabel.text = self.strangersAround[strangersAround.index(self.strangersAround.startIndex, offsetBy: indexPath.row)].firstName
            cell.headshotViewImage.image = self.strangersAround[strangersAround.index(self.strangersAround.startIndex, offsetBy: indexPath.row)].headshotImage

            cell.headshotViewImage.layer.cornerRadius = 15.0
            cell.headshotViewImage.layer.borderWidth = 3
            cell.headshotViewImage.layer.borderColor = UIColor.black.cgColor
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let profileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        
        let selectedUser = User()
        let selectedCell = PeopleNearbyTableView.cellForRow(at: indexPath) as! UserTableViewCell
        selectedUser?.firstName = selectedCell.nameLabel.text
        selectedUser?.location = userLoggedIn?.location
        profileVC.currentUserProfile = selectedUser
        self.present(profileVC, animated: false, completion: nil)
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
