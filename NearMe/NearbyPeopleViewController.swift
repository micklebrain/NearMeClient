//
//  NearbyPeopleViewController.swift
//  NearMe
//
//  Created by Nathan Nguyen on 6/13/17.
//  Copyright © 2017 Nathan Nguyen. All rights reserved.
//

import UIKit
import CoreLocation
import FacebookCore
import FacebookLogin
import Alamofire
import SwiftyJSON
import FBSDKLoginKit

class NearbyPeopleViewController: UIViewController {
    
    var userLoggedIn: User!
    let section = ["Friends", "Strangers"]
    let filterOptions = ["Female", "Male"]
    //add collegaues, same school
    var locationManager : CLLocationManager!
    var strangersAround = Set<User>()
    //Using NSMutableSet because AWS
    var friendsAround = Set<User>()
    var defaultHeadshot : UIImage?
    var headshots = [String: UIImage]()
    var currentUserLocation: CLLocation?
    var count = 0
    var actInd = UIActivityIndicatorView()
    let refreshControl = UIRefreshControl()
    //var results: [AWSDynamoDBObjectModel]?

    @IBOutlet weak var PeopleNearbyTableView: UITableView!
    @IBOutlet weak var peopleCounter: UILabel!
    @IBOutlet weak var presenceSwitch: UISwitch!
    @IBOutlet weak var CurrentLocationLabel: UILabel!
    @IBOutlet weak var filterPickerView: UIPickerView!
    @IBOutlet weak var floorLabel: UILabel!
    
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
    
        //self.floorLabel.text?.append(String(userLoggedIn.floor))
        
        if #available(iOS 10.0, *) {
            self.PeopleNearbyTableView.refreshControl = refreshControl
        } else {
            self.PeopleNearbyTableView.addSubview(refreshControl)
        }
        
        self.refreshControl.addTarget(self, action: #selector(refreshUsersNearby), for: .valueChanged)
        
        userLoggedIn?.headshot = #imageLiteral(resourceName: "empty-headshot")
        //getUserPicture(facebookId: (userLoggedIn?.facebookId)!)
        
        //Check if location services is on first
        determineMyCurrentLocation()
        
        getLocation()
        
        if let accessToken = AccessToken.current {
            print(AccessToken.current?.userId)
        }
        
        pullFacebookInfo()
        
//        let mainQueue = DispatchQueue.main
//        let deadline = DispatchTime.now() + .seconds(5)
//        mainQueue.asyncAfter(deadline: deadline) {
//            self.actInd.stopAnimating()
//        }
        
//        mainQueue.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true, block: { (Timer) in
                //refresh every 30 seconds
                self.refreshUsersNearby()
            })
//        }
        
    }
    
    //Fix refreshing, indicator dosnt always stop correctly
    func refreshUsersNearby () {
        //Implement caching
//        self.actInd.startAnimating()
        self.friendsAround.removeAll()
        self.strangersAround.removeAll()
        pullNearByPeople()
        self.count = self.friendsAround.count + self.strangersAround.count
        self.PeopleNearbyTableView.reloadData()
        self.refreshControl.endRefreshing()
        self.actInd.stopAnimating()
        self.actInd.removeFromSuperview()
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
                    if (connection?.urlResponse != nil && connection?.urlResponse.statusCode == 200) {
                    let data = result as! [String : AnyObject]
                    let name = data["name"] as? String
                    let email = data["email"] as? String
                    let picture = data["picture"] as? Any
                    print("logged in user name is \(String(describing: name))")

                    let FBid = data["id"] as? String
                    print("Facebook id is  \(String(describing: FBid))")
                    }
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
        
        //Check if location services is on first
        determineMyCurrentLocation()
        
        //refresh every 30 seconds
//        self.timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true, block: { (Timer) in
//            self.refreshUsersNearby()
//        })
    }
    
    //  MARK: - Location tracking
    @IBAction func presenceSwitch(_ sender: Any) {
        let nearbyPeopleVC:UserProfileViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UserProfileViewController") as! UserProfileViewController
        self.present(nearbyPeopleVC, animated: false, completion: nil)
        self.userLoggedIn?.online = !self.userLoggedIn.online
        updateOnlineStatus()
    }
    
    func updateOnlineStatus () {
        if (userLoggedIn!.online) {
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
            
//            let objectMapper = AWSDynamoDBObjectMapper.default()
            var errors: [NSError] = []
            //Use Group for threading?
            let group: DispatchGroup = DispatchGroup()
            
            let latitude = userLocation.coordinate.latitude
            let longitutde = userLocation.coordinate.longitude
            currentUserLocation = CLLocation(latitude: latitude, longitude: longitutde)
            
//          User's Location
            userLoggedIn?.postalCode = postalCode
            userLoggedIn?.administrativeArea = administrativeArea
            userLoggedIn?.country = country
            userLoggedIn?.locality = locality
            userLoggedIn?.latitude = userLocation.coordinate.latitude as NSNumber
            userLoggedIn?.longitude = userLocation.coordinate.longitude as NSNumber
            
            self.CurrentLocationLabel.text = userLoggedIn?.buildingOccupied
            
            pullNearByPeople()
        }
    }
    
    func activateActivityIndicatorView() {
        
        self.actInd = UIActivityIndicatorView()
        self.actInd.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        self.actInd.center = self.view.center
        self.actInd.hidesWhenStopped = true
        self.actInd.activityIndicatorViewStyle =
            UIActivityIndicatorViewStyle.gray
        self.view.addSubview(actInd)
        self.actInd.startAnimating()
        
    }

    //When no internet connection then change label to no internet connection
    
    func pullNearByPeople () {
        

//        let utilities = Util()
//        let wifiAddress = utilities.getWiFiAddress() as! String
//        let url = URL(string: "http://" + wifiAddress + ":8080/updateLocation")
        
        let localUrl = URL(string: "http://localhost:8080/pullNearbyUsers")
        let url = URL(string: "https://crystal-smalltalk.herokuapp.com/pullNearbyUsers")

        userLoggedIn?.friends = ["Nathan"]
        
        let userDetails : Parameters = [
            "firstname": self.userLoggedIn?.firstName,
            "username": self.userLoggedIn?.username,
            "facebookId": self.userLoggedIn?.facebookId,
            "locality": self.userLoggedIn?.buildingOccupied
        ]
        
        actInd.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        actInd.center = self.view.center
        actInd.hidesWhenStopped = true
        actInd.activityIndicatorViewStyle =
            UIActivityIndicatorViewStyle.gray
        self.view.addSubview(actInd)
        self.actInd.startAnimating()
        
        //Act Indicator will continue to run
        //Clogging server
        Alamofire.request(url!, method: .post, parameters: userDetails, encoding: JSONEncoding.default)
            .responseJSON{ response in
                if response.response?.statusCode == 200 {
                if let json = response.result.value {
                    print("JSON: \(json)")
                    let users = json as! [Any]
                    for someUser in users {
                        let userDetails = someUser as! [String: Any]
                        var newPerson = User()
                        let facebookId = userDetails["facebookId"] as! String
                        
                        if (facebookId != self.userLoggedIn?.facebookId) {
                            newPerson.firstName = userDetails["firstName"] as! String
                            newPerson.lastName = userDetails["lastName"] as! String
                            newPerson.facebookId = userDetails["facebookId"] as! String

                            newPerson.headshotImage = self.getUserFBPicture(facebookId: newPerson.facebookId!)

                           // newPerson.school = userDetails["school"] as! String
                            newPerson.headshotImage = self.getUserFBPicture(facebookId: newPerson.facebookId!)

                            self.friendsAround.insert(newPerson)
                        }
                        // } else {
                        // self.strangersAround.insert(newPerson)
                    }
                    self.count = self.friendsAround.count + self.strangersAround.count
//                    if (self.count == 0) {
//                        var person = User()
//                        person.firstName = "Nobody"
//                        person.lastName = "Around"
//                        person.school = "None"
//                        person.facebookId = "none"
//                        person.headshotImage = #imageLiteral(resourceName: "empty-headshot")
//                        self.friendsAround.insert(person)
//                        self.strangersAround.insert(person)
//                    }
                    let numberoccupied = "# Occupied: " + String(self.count)
                    self.peopleCounter.text = String(describing: numberoccupied)
                    self.PeopleNearbyTableView.reloadData()
                    self.actInd.stopAnimating()
                }
                } else {
                    var person = User()
                    person.firstName = "Nobody"
                    person.lastName = "Around"
                    person.school = "None"
                    person.facebookId = "none"
                    person.headshotImage = #imageLiteral(resourceName: "empty-headshot")
                    self.friendsAround.insert(person)
                    self.strangersAround.insert(person)
                    self.PeopleNearbyTableView.reloadData()
                    self.actInd.stopAnimating()
                }
        }
        
    }
    
    func getUserFBPicture (facebookId : String) -> UIImage {
        
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
    
    //  Mark: Filter
    @IBAction func filter(_ sender: Any) {
        
        while self.strangersAround.contains(where: { $0.sex == sex.male }) {
            let foundPerson = self.strangersAround.first(where: { $0.sex == sex.male })
            strangersAround.remove(foundPerson!)
        }
         
        self.PeopleNearbyTableView.reloadData()
        
    }
    
    //    func getLocation() {
    //
    //        Alamofire.request("https://httpbin.org/get").responseJSON { response in
    //            print("Request: \(String(describing: response.request))")   // original url request
    //            print("Response: \(String(describing: response.response))") // http url response
    //            print("Result: \(response.result)")                         // response serialization result
    //
    //            if let json = response.result.value {
    //                print("JSON: \(json)") // serialized json response
    //            }
    //
    //            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
    //                print("Data: \(utf8Text)") // original server data as UTF8 string
    //            }
    //        }
    //    }
    
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
            self.refreshControl.endRefreshing()
            self.actInd.stopAnimating()
            return self.friendsAround.count
        } else {
            self.refreshControl.endRefreshing()
            self.actInd.stopAnimating()
            return self.strangersAround.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserTableViewCell
        
        self.refreshControl.endRefreshing()
        self.actInd.stopAnimating()
        //      TODO: Check why view gets loaded without images - bug
        if (indexPath.section == 0) {
            cell.nameLabel.text = self.friendsAround[friendsAround.index(self.friendsAround.startIndex, offsetBy: indexPath.row)].firstName! + " " +
                self.friendsAround[friendsAround.index(self.friendsAround.startIndex, offsetBy: indexPath.row)].lastName!
           // cell.schoolLabel.text = self.friendsAround[friendsAround.index(self.friendsAround.startIndex, offsetBy: indexPath.row)].school!
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
//          cell.connectButton.titleLabel?.text = "Reconnect"
        } else {
            cell.nameLabel.text = self.strangersAround[strangersAround.index(self.strangersAround.startIndex, offsetBy: indexPath.row)].firstName! + " " +
                self.friendsAround[friendsAround.index(self.friendsAround.startIndex, offsetBy: indexPath.row)].lastName!
            cell.headshotViewImage.image = self.strangersAround[strangersAround.index(self.strangersAround.startIndex, offsetBy: indexPath.row)].headshotImage
            cell.schoolLabel.text = self.friendsAround[friendsAround.index(self.friendsAround.startIndex, offsetBy: indexPath.row)].school!
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
        selectedUser.firstName = selectedCell.nameLabel.text
        selectedUser.location = userLoggedIn?.location
        profileVC.userloggedIn = selectedUser
        self.present(profileVC, animated: false, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.refreshControl.endRefreshing()
        self.actInd.stopAnimating()
        self.actInd.removeFromSuperview()
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.refreshControl.endRefreshing()
        self.actInd.stopAnimating()
        self.actInd.removeFromSuperview()
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
