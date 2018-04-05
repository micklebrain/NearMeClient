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

class NearbyPeopleViewController: UIViewController {
    
    let section = ["Friends", "Strangers"]
    let filterOptions = ["Female", "Male"]
    //add collegaues, same school
    var locationManager : CLLocationManager!
    var people: [Person] = []
    var results: [AWSDynamoDBObjectModel]?
    var strangersAround = Set<Person>()
//  Using NSMutableSet because AWS
    var friendsAround = Set<Person>()
//  var strangers = NSMutableSet()
    var userLoggedIn: User?
    var currentUserLocation: CLLocation?
    var headshot : UIImage?
    var count = 0
    var loadingView: UIView = UIView()
    var container: UIView = UIView()
    var actInd: UIActivityIndicatorView = UIActivityIndicatorView()
    var defaultHeadshot : UIImage?
    var headshots = [String: UIImage]()
    
    @IBOutlet weak var PeopleNearbyTableView: UITableView!
    @IBOutlet weak var peopleCounter: UILabel!
    @IBOutlet weak var presenceSwitch: UISwitch!
    @IBOutlet weak var CurrentLocationLabel: UILabel!
    @IBOutlet weak var filterPickerView: UIPickerView!
    
    var profileImage: UIImage?
    
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tbc = self.tabBarController as! MainTabBarController
        self.userLoggedIn = tbc.userloggedIn
        
        self.PeopleNearbyTableView.delegate = self
        self.PeopleNearbyTableView.dataSource = self
        
        self.filterPickerView.delegate = self
        self.filterPickerView.dataSource = self
    
        userLoggedIn?.headshot = #imageLiteral(resourceName: "empty-headshot")
        getUserPicture(facebookId: (userLoggedIn?.facebookId)!)
        
        //Check if location services is on first
        determineMyCurrentLocation()
        
        getLocation()
        
        if let accessToken = AccessToken.current {
            print(AccessToken.current?.userId)
        }
        
        pullFacebookInfo()
        
        let mainQueue = DispatchQueue.main
        let deadline = DispatchTime.now() + .seconds(5)
        mainQueue.asyncAfter(deadline: deadline) {
            self.container.isHidden = true
        }
        
//        mainQueue.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true, block: { (Timer) in
                self.friendsAround.removeAll()
                self.strangersAround.removeAll()
                self.pullNearByPeople()
                self.count = self.friendsAround.count + self.strangersAround.count
                self.PeopleNearbyTableView.reloadData()
            })
//        }
        
    }
    
    @IBAction func refresh(_ sender: Any) {
        //Implement caching later
        self.friendsAround.removeAll()
        self.strangersAround.removeAll()
        pullNearByPeople()
        self.count = self.friendsAround.count + self.strangersAround.count
        self.PeopleNearbyTableView.reloadData()
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
    
    func pullFacebookInfo () {
        let nathanFBId = "1367878021"
        let nathan2FBId = "111006779636650"
        let TraceyFBid = "109582432994026"
        
        if(FBSDKAccessToken.current() != nil)
        {
            print(FBSDKAccessToken.current().permissions)
            print(FBSDKAccessToken.current().tokenString)
            
            let graphRequest = FBSDKGraphRequest(graphPath: nathanFBId, parameters: ["fields" : "id, name, email,picture"])

            let connection = FBSDKGraphRequestConnection()

            connection.add(graphRequest, completionHandler: { (connection, result, error) -> Void in
                let data = result as! [String : AnyObject]
                let name = data["name"] as? String
                let email = data["email"] as? String
                let picture = data["picture"] as? Any
                print("logged in user name is \(String(describing: name))")

                let FBid = data["id"] as? String
                print("Facebook id is  \(String(describing: FBid))")
            })
            connection.start()
        }
        
//        let photographRequest = FBSDKGraphRequest(graphPath: nathanFBId, parameters: ["fields" : "photo"])
//
//        let connection2 = FBSDKGraphRequestConnection()
//        connection2.add(photographRequest, completionHandler: { (connection, result, error) -> Void in
//            let data = result as! [String: AnyObject]
//        })
//        connection2.start()
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
        let nearbyPeopleVC:UserProfileViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UserProfileViewController") as! UserProfileViewController
        self.present(nearbyPeopleVC, animated: false, completion: nil)
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
            
//          User's Location
            userLoggedIn?.postalCode = postalCode
            userLoggedIn?.administrativeArea = administrativeArea
            userLoggedIn?.country = country
            userLoggedIn?.locality = locality
            userLoggedIn?.latitude = userLocation.coordinate.latitude as NSNumber
            userLoggedIn?.longitude = userLocation.coordinate.longitude as NSNumber
            
//            objectMapper.save(userLoggedIn!, completionHandler: {(error: Error?) -> Void in
//                if error != nil {
//                    DispatchQueue.main.async {
//                        errors.append(error! as NSError)
//                    }
//                }
//            })
            
            self.CurrentLocationLabel.text = userLoggedIn?.buildingOccupied
            
            pullNearByPeople()
        }
    }

    func pullNearByPeople () {
        
        //AWS DynamoDB
        //table = LocationsTable()
        //Move logic to Backend
//        let completionHandler = {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
//
//            if let error = error {
//                var errorMessage = "Failed to retrieve items. \(error.localizedDescription)"
//                if (error.domain == AWSServiceErrorDomain && error.code == AWSServiceErrorType.accessDeniedException.rawValue) {
//                    errorMessage = "Access denied. You are not allowed to perform this operation."
//                    print(errorMessage)
//                }
//            }
//            else if response!.items.count == 0 {
//                print("No items match your criteria. Insert more sample data and try again.")
//            }
//            else {
//                self.results = response?.items
//                for result in self.results! {
//                    let model = result
//                    let modelDictionary: [AnyHashable: Any] = model.dictionaryValue
//
//                    // _ = self.table?.tableAttributeName!(self.table!.orderedAttributeKeys[10])
//                    let newPerson = Person()
//
//                    let facebookId = "\(modelDictionary["facebookId"]!)"
//
//                    let userLatitude = CLLocationDegrees("\(modelDictionary["latitude"]!)")
//                    //  (self.table?.orderedAttributeKeys as Any)
//                    let userLongitude = CLLocationDegrees("\(modelDictionary["longitude"]!)")
//                    let userLocation = CLLocation(latitude: userLatitude!, longitude: userLongitude!)
//                    let isOnline = "\(modelDictionary["online"]!)"
//
//                    newPerson.location = userLocation
//                    newPerson.firstName = "\(modelDictionary["firstName"]!)"
//                    newPerson.sex = sex(rawValue: "\(modelDictionary["sex"]!)")
//                    newPerson.facebookId = facebookId
//
//                    newPerson.headshotImage = self.getUserPicture(facebookId: facebookId)
//
//                    // newPerson.online = "\(modelDictionary["online"])"
//
//                    //Check distance apart from user
//                    if (newPerson.firstName != self.userLoggedIn?.firstName && isOnline == "1") {
//                        let distanceApart = newPerson.location?.distance(from: (self.currentUserLocation)!)
//
//                        var aMile = CLLocationDistance()
////                        aMile.add(1609)
//                          aMile.add(10000)
//                        if (self.currentUserLocation != nil) {
//                            if (distanceApart?.isLess(than: aMile))!{
//                                self.strangersAround.insert(newPerson)
//                            }
//                        }
//                    }
//                }
//                self.PeopleNearbyTableView.reloadData()
//            }
//        }
    
        //Scan actualy Prod DynamoDB
//       scanNearbyUsers(completionHandler)
        
//        let utilities = Util()
//        let wifiAddress = utilities.getWiFiAddress() as! String
//        let url = URL(string: "http://" + wifiAddress + ":8080/updateLocation")
        
        //Roomwifi
//        let url = URL(string: "http://192.168.1.18:8080/pullAccounts")
        //NoiseBridge
//        let url = URL(string: "http://10.20.1.137:8080/pullAccounts")
        //Brannan lobby wifi
//        let url = URL(string: "http://10.12.228.178:8080/pullAccounts")
        //Heroku
        let url = URL(string: "https://crystal-smalltalk.herokuapp.com/pullAccounts")
        userLoggedIn?.friends = ["Nathan"]
        
        let userDetails : Parameters = [
            "firstName": self.userLoggedIn?.firstName,
            "username": self.userLoggedIn?.username,
            "facebookId": self.userLoggedIn?.facebookId,
            "locality": self.userLoggedIn?.buildingOccupied,
            "sex": "MALE"
        ]
        
        loadingView.frame = CGRect(x: 100, y: 100, width: 100, height: 100)
        loadingView.center = self.view.center
        loadingView.backgroundColor = UIColor.blue
        loadingView.layer.cornerRadius = 10
        actInd.activityIndicatorViewStyle =
            UIActivityIndicatorViewStyle.whiteLarge
        actInd.center = self.view.center
        loadingView.addSubview(actInd)
        
        container.frame = CGRect(x: 100, y: 100, width: 100, height: 100)
        container.center = self.view.center
        container.layer.cornerRadius = 10
        container.backgroundColor = UIColor.red
        container.addSubview(actInd)

        self.view.addSubview(container)
        actInd.startAnimating()
        
        Alamofire.request(url!, method: .post, parameters: userDetails, encoding: JSONEncoding.default)
            .responseJSON{ response in
                if let json = response.result.value {
                    print("JSON: \(json)")
                    let users = json as! [Any]
                    for someUser in users {
                        let userDetails = someUser as! [String: Any]
                        var newPerson = Person()
                        let facebookId = userDetails["facebookId"] as! String
                        
                        if (facebookId != self.userLoggedIn?.facebookId) {
                            newPerson.firstName = userDetails["firstName"] as! String
                            newPerson.lastName = userDetails["lastName"] as! String
                            newPerson.facebookId = userDetails["facebookId"] as! String
                            newPerson.school = userDetails["school"] as! String
                            newPerson.headshotImage = self.getUserPicture(facebookId: newPerson.facebookId!)
                            self.friendsAround.insert(newPerson)
                        }
                        // } else {
                        // self.strangersAround.insert(newPerson)
                    }
                    self.count = self.friendsAround.count + self.strangersAround.count
//                    if (self.count == 0) {
//                        var person = Person()
//                        person.firstName = "Nobody Around"
//                        person.headshotImage = #imageLiteral(resourceName: "empty-headshot")
//                        self.friendsAround.insert(person)
//                        self.strangersAround.insert(person)
//                    }
                    let numberoccupied = "# Occupied: " + String(self.count)
                    self.peopleCounter.text = String(describing: numberoccupied)
                    self.PeopleNearbyTableView.reloadData()
                }
        }
        
//            } else {
//                var person = Person()
//                person.firstName = "Nobody Around"
//                person.headshotImage = #imageLiteral(resourceName: "empty-headshot")
//                self.friendsAround.insert(person)
//                self.strangersAround.insert(person)
//                self.PeopleNearbyTableView.reloadData()
//            }
//        }
    
    }
    
    func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }

    @IBAction func viewProfile(_ sender: Any) {
        
        let profileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UserProfileViewController") as! UserProfileViewController
        profileVC.userLoggedIn = self.userLoggedIn
        
        self.present(profileVC, animated: false, completion: nil)
        
    }
    
    @IBAction func connect(_ sender: Any) {
        let profileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ProfileViewController") as! NearbyLocationsViewController
        self.present(profileVC, animated: false, completion: nil)
    }
    
    func getUserPicture (facebookId : String) -> UIImage {
        
        //Solve threading to update fb image when complete
        
        var headshot = #imageLiteral(resourceName: "empty-headshot")
        var pictureUrl = "http://graph.facebook.com/"
//        pictureUrl += (userLoggedIn?.facebookId)!
        pictureUrl += facebookId
        pictureUrl += "/picture?type=large"
        
        var url = URL(string: pictureUrl)
        
        if let url = url {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    print(error)
                } else {
                    if let usableData = data {
                        if (UIImage(data: usableData) != nil) {
                            headshot = UIImage(data: usableData)!
                            self.headshots[facebookId] = headshot
                            DispatchQueue.main.async {
                               self.PeopleNearbyTableView.reloadData()
                            }
                        }
                    }
                }
            }

            task.resume()

        }
        
        return headshot
    }

    func randomImage () -> UIImage {
        
        var images = [#imageLiteral(resourceName: "headshot2"), #imageLiteral(resourceName: "headshot3"), #imageLiteral(resourceName: "headshot1")]
        let randomNumber:UInt32 = arc4random_uniform(3)
        let index:Int = Int(randomNumber)
        return images[index]
        
    }
    
    //  Mark: Filter
    @IBAction func filter(_ sender: Any) {
        
        while self.strangersAround.contains(where: { $0.sex == sex.male }) {
            let foundPerson = self.strangersAround.first(where: { $0.sex == sex.male })
            strangersAround.remove(foundPerson!)
        }
         
        self.PeopleNearbyTableView.reloadData()
        
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
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {}
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

struct MyProfileRequest: GraphRequestProtocol {
    var graphPath: String
    
    var parameters: [String : Any]?
    var accessToken: AccessToken?
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    
    struct Response: GraphResponseProtocol {
        init(rawResponse: Any?) {
            
        }
    }
}

extension NearbyPeopleViewController : CLLocationManagerDelegate {
    
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
        
        //How to put this on the main thread
        self.PeopleNearbyTableView.reloadData()
    }
    
}

extension NearbyPeopleViewController : UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.section[section]
    }
    
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserTableViewCell
        
        //      TODO: Check why view gets loaded without images - bug
        if (indexPath.section == 0) {
            cell.nameLabel.text = self.friendsAround[friendsAround.index(self.friendsAround.startIndex, offsetBy: indexPath.row)].firstName! + " " +
                self.friendsAround[friendsAround.index(self.friendsAround.startIndex, offsetBy: indexPath.row)].lastName!
            cell.schoolLabel.text = self.friendsAround[friendsAround.index(self.friendsAround.startIndex, offsetBy: indexPath.row)].school!
            let headshot = headshots[self.friendsAround[friendsAround.index(self.friendsAround.startIndex, offsetBy: indexPath.row)].facebookId!]
            if (headshot != nil) {
                cell.headshotViewImage.image = headshots[self.friendsAround[friendsAround.index(self.friendsAround.startIndex, offsetBy: indexPath.row)].facebookId!]
            } else {
                cell.headshotViewImage.image = #imageLiteral(resourceName: "empty-headshot")
            }
            cell.headshotViewImage.layer.cornerRadius = 15.0
            cell.headshotViewImage.layer.borderWidth = 3
            cell.headshotViewImage.layer.borderColor = UIColor.black.cgColor
            //Keeps flashing
//            cell.connectButton.titleLabel?.text = "Reconnect"
        } else {
            cell.nameLabel.text = self.strangersAround[strangersAround.index(self.strangersAround.startIndex, offsetBy: indexPath.row)].firstName
            //  cell.occupationLabel.text = self.strangersAround[strangersAround.index(self.strangersAround.startIndex, offsetBy: indexPath.row)].
            
            cell.headshotViewImage.image = self.strangersAround[strangersAround.index(self.strangersAround.startIndex, offsetBy: indexPath.row)].headshotImage
            
            cell.headshotViewImage.layer.cornerRadius = 15.0
            cell.headshotViewImage.layer.borderWidth = 3
            cell.headshotViewImage.layer.borderColor = UIColor.black.cgColor
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let profileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ProfileViewController") as! NearbyLocationsViewController
        
        let selectedUser = User()
        let selectedCell = PeopleNearbyTableView.cellForRow(at: indexPath) as! UserTableViewCell
        selectedUser?.firstName = selectedCell.nameLabel.text
        selectedUser?.location = userLoggedIn?.location
        profileVC.userloggedIn = selectedUser
        self.present(profileVC, animated: false, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (indexPath.row == 0) {
            self.actInd.stopAnimating()
            self.container.isHidden = true
            self.loadingView.isHidden = true
        }
    }
    
}

extension NearbyPeopleViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.filterOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return filterOptions[row]
    }
    
}
