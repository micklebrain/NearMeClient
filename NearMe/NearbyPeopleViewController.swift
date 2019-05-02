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
import GooglePlaces
import Starscream

class NearbyPeopleViewController: UIViewController, WebSocketDelegate {
    
    var userLoggedIn: User!
    let section = ["Friends", "Strangers"]
    let filterOptions = ["Female", "Male"]
    var locationManager : CLLocationManager!
    var strangersAround = Set<User>()
    var friendsAround: [User] = []
    var defaultHeadshot : UIImage?
    var headshots = [String: UIImage]()
    var currentUserLocation: CLLocation?
    var count = 0
    var actInd = UIActivityIndicatorView()
    var profileImage: UIImage?
    var timer = Timer()
    var userCacheURL: URL?
    let refreshControl = UIRefreshControl()
    let userCacheQueue = OperationQueue()
    var socket: WebSocket?
    
    @IBOutlet weak var PeopleNearbyTableView: UITableView!
    @IBOutlet weak var peopleCounter: UILabel!
    @IBOutlet weak var presenceSwitch: UISwitch!
    @IBOutlet weak var currentLocation: UIButton!
    @IBOutlet weak var floorLabel: UILabel!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //Current User Info
        let tbc = self.tabBarController as! MainTabBarController
        self.userLoggedIn = tbc.userloggedIn
        pullFacebookInfo()
        //Current User Info
        
        let checkedInLocation = self.userLoggedIn.buildingOccupied ?? "Check In"
        self.currentLocation.setTitle(checkedInLocation, for: .normal)
        
        //Table View
        self.PeopleNearbyTableView.delegate = self
        self.PeopleNearbyTableView.dataSource = self
        
        self.PeopleNearbyTableView.decelerationRate = .fast
        
        //self.floorLabel.text?.append(String(userLoggedIn.floor))
        
        if #available(iOS 10.0, *) {
            self.PeopleNearbyTableView.refreshControl = refreshControl
        } else {
            self.PeopleNearbyTableView.addSubview(refreshControl)
        }
        
        self.refreshControl.addTarget(self, action: #selector(refreshUsersNearby), for: .valueChanged)
        //Table View
        
        /*Location Services*/
        //Check if location services is allowed to update location
        activateLocationServices()
        
        //Load first time
        refreshUsersNearby()
        
        //Refresh Nearby Userevery 60 seconds
//        self.timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: { (Timer) in
//            self.refreshUsersNearby()
//        })
        /*Location Services*/
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        let tbc = self.tabBarController as! MainTabBarController
        let checkedInLocation = tbc.userloggedIn?.buildingOccupied ?? "Check In"
        self.currentLocation.setTitle(checkedInLocation, for: .normal)
        
    }
    
    func activateActivityIndicatorView() {
        
        self.actInd = UIActivityIndicatorView()
        self.actInd.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        self.actInd.center = self.view.center
        self.actInd.hidesWhenStopped = true
        self.actInd.style =
            UIActivityIndicatorView.Style.gray
        self.view.addSubview(actInd)
        self.actInd.startAnimating()
        
    }
    
    //MARK: WebSocket
    func websocketDidConnect(socket: WebSocketClient) {
        socket.write(string: "Connected through IOS")
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        
    }
    //WebSocket
    
    @objc func refreshUsersNearby () {
        
        //Implement caching
        self.friendsAround.removeAll()
        self.strangersAround.removeAll()
        pullNearbyUsers()
        self.count = self.friendsAround.count + self.strangersAround.count
        
        self.refreshControl.endRefreshing()
        self.actInd.stopAnimating()
        self.actInd.removeFromSuperview()
        
    }
    
    func pullNearbyUsers () {
        
        //Activity Indicator
        actInd.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        actInd.center = self.view.center
        actInd.hidesWhenStopped = true
        actInd.style =
            UIActivityIndicatorView.Style.gray
        self.view.addSubview(actInd)
        self.actInd.startAnimating()
        //Activity Indicator
        
        //User
        userLoggedIn?.friends = ["Nathan"]
        
        let buildingOccupied = userLoggedIn?.buildingOccupied != nil ? userLoggedIn.buildingOccupied : ""
        let firstName = self.userLoggedIn?.firstName ?? ""
        let userName = self.userLoggedIn.username ?? ""
        let facebookId = self.userLoggedIn?.facebookId ?? ""
        
//        let userDetails : Parameters = [
//            "firstname": firstName,
//            "username": userName,
//            "facebookId": facebookId,
//            "locality": buildingOccupied ]
        
        let wifiipAddress = Util.getIFAddresses()[1]
        let localPullNearbyUsersUrl = URL(string: "http://\(wifiipAddress):8080/pullNearbyUsers?locality=SanFrancisco")
        let pullNearbyUsersUrl = URL(string: "https://crystal-smalltalk.herokuapp.com/pullNearbyUsers?locality=SanFrancisco")
        let allUsersUrl = URL(string: "https://crystal-smalltalk.herokuapp.com/pullAllUsers")
        
//        Alamofire.request(pullNearbyUsersUrl!, method: .post, parameters: userDetails, encoding: JSONEncoding.default)
            Alamofire.request(allUsersUrl!, method: .get)
            .responseJSON{ response in
                if response.response?.statusCode == 200 {
                    if let json = response.result.value {
                        let users = json as! [Any]
                        
                        self.count = users.count
                        let numberoccupied = "# Occupied: " + String(self.count)
                        self.peopleCounter.text = String(describing: numberoccupied)
                        
                        var usersFacebookIds = [String]()
                    
                        for someUser in users {
                            let userDetails = someUser as! [String: Any]
                            let newPerson = User()
                            let facebookId = userDetails["facebookId"] as! String
                            usersFacebookIds.append(facebookId)
                            
                            if (facebookId != self.userLoggedIn?.facebookId) {
                                newPerson.username = userDetails["username"] as? String
                                newPerson.firstName = userDetails["firstname"] as? String
                                newPerson.lastName = userDetails["lastname"] as? String
                                newPerson.facebookId = userDetails["facebookId"] as? String
                                newPerson.school = userDetails["school"] as? String
                                newPerson.employer = userDetails["employer"] as? String
                                
                                self.friendsAround.append(newPerson)
                                // TODO: Call on seperate thread
                                self.getUserFBPicture(facebookId: newPerson.facebookId!)
                            }
                            
                            if (self.userCacheURL != nil) {
                                self.userCacheQueue.addOperation {
                                    if let stream = OutputStream(url: self.userCacheURL!, append: false) {
                                        stream.open()
                                        JSONSerialization.writeJSONObject(json, to: stream, options: [.prettyPrinted], error: nil)
                                        stream.close()
                                    }
                                }
                            }
                        }
                        
                        self.actInd.stopAnimating()
                        
                        DispatchQueue.main.async {
                            self.PeopleNearbyTableView.reloadData()
                            //                            let indexPath = IndexPath(row: 0, section: 0)
                            //                            self.PeopleNearbyTableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.fade)
                        }
                        
                    }
                    //If happens show cached data
                } else if response.response?.statusCode == 503 {
                    
                    // Try to display cached data
                    if (self.userCacheURL != nil) {
                        self.userCacheQueue.addOperation {
                            if let stream = InputStream(url: self.userCacheURL!) {
                                stream.open()
                                
                                let users = (try? JSONSerialization.jsonObject(with: stream, options: [])) as? [[String: Any]]
                                for user in users! {
                                    let facebookId = user["facebookId"] as! String
                                    if (facebookId != self.userLoggedIn?.facebookId) {
                                        let friend = User()
                                        friend.locality = user["locality"] as? String
                                        friend.firstName = user["firstName"] as? String
                                        friend.lastName = user["lastName"] as? String
                                        friend.facebookId = user["facebookId"] as? String
                                        self.getUserFBPicture(facebookId: friend.facebookId!)
                                        self.friendsAround.append(friend)
                                    }
                                }
                                stream.close()
                            }
                            
                        }
                        
                        DispatchQueue.main.async {
                            self.PeopleNearbyTableView.reloadData()
                            //                            let indexPath = IndexPath(row: 0, section: 0)
                            //                            self.PeopleNearbyTableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.fade)
                        }
                        
                    } else { // No cached data is around so display nobody around users
                        let person = User()
                        person.firstName = "Nobody"
                        person.lastName = "Around"
                        person.school = "None"
                        person.facebookId = "none"
                        self.friendsAround.append(person)
                        self.strangersAround.insert(person)
                        self.actInd.stopAnimating()
                    }
                }
        }
        
    }
    
    func pullFacebookInfo () {
        
        let nathanFBId = "1367878021"
        let nathan2FBId = "111006779636650"
        let TraceyFBid = "109582432994026"
        
        if(FBSDKAccessToken.current() != nil)
        {
        
            FBSDKAccessToken.current()?.userID
            
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
        activateLocationServices()
    }
    
    func getUserFBPicture (facebookId : String) {
        
        // Solve threading to update fb image when complete
        var headshot = #imageLiteral(resourceName: "empty-headshot")
        var pictureUrl = "http://graph.facebook.com/"
        pictureUrl += facebookId
        pictureUrl += "/picture?type=large"
        
        let url = URL(string: pictureUrl)
        
        if let url = url {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    print(error!)
                } else {
                    if let usableData = data {
                        if (UIImage(data: usableData) != nil) {
                            headshot = UIImage(data: usableData)!
                            self.headshots[facebookId] = headshot
                            
                            let user = self.friendsAround.remove(at:
                            self.friendsAround.firstIndex(where: { (user) -> Bool in
                                user.facebookId == facebookId
                            })!)
                            user.headshot = headshot
                            self.friendsAround.append(user)
                            
                            let friendIndexPath = IndexPath(row: self.friendsAround.count, section: 0)
                            DispatchQueue.main.async {
                            if let _ = self.PeopleNearbyTableView.cellForRow(at: friendIndexPath) {
                                    self.PeopleNearbyTableView.reloadRows(at: [friendIndexPath], with: UITableView.RowAnimation.automatic)
                                }
                            }
                        } else {
                            print("Image cannot be used for user ")
                            print(facebookId)
                        }
                    } else {
                        print("Image cannot be used for user ")
                        print(facebookId)
                    }
                }
            }
            task.resume()
        }
        
    }
    
    func activateLocationServices() {
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters;
        locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager?.startUpdatingLocation()
        }
        
    }       
    
    //  MARK: - Location tracking
    @IBAction func presenceSwitch(_ sender: Any) {
        self.tabBarController?.selectedIndex = 1
        self.userLoggedIn?.online = !self.userLoggedIn.online!
        updateOnlineStatus()
    }
    
    func updateOnlineStatus () {
        let url = URL(string: "https://crystal-smalltalk.herokuapp.com/updateOnlineStatus")
        
        let userDetails : Parameters = [
            "facebookId": self.userLoggedIn.facebookId!,
            "online": false
        ]
        
        Alamofire.request(url!, method: .post, parameters: userDetails, encoding: JSONEncoding.default)
        
        if (userLoggedIn!.online ?? true) {
            presenceSwitch.isOn = true
            activateLocationServices()
        } else {
            presenceSwitch.isOn = false
            locationManager.stopUpdatingLocation()
        }
    }
    
    func trackUserLocation (placemark: CLPlacemark?, userLocation: CLLocation) {
        
        if let userPlacemark = placemark {
            
            let locality = (userPlacemark.locality != nil) ? userPlacemark.locality : ""
            //            let postalCode = (containsPlacemark.postalCode != nil) ? containsPlacemark.postalCode : ""
            //            let administrativeArea = (containsPlacemark.administrativeArea != nil) ? containsPlacemark.administrativeArea : ""
            //            let country = (containsPlacemark.country != nil) ? containsPlacemark.country : ""
            
            let latitude:Double  = userLocation.coordinate.latitude
            let longitutde:Double = userLocation.coordinate.longitude
            
            let userDetails : Parameters = [
                "userName": self.userLoggedIn?.username ?? "",
                "locality": locality ?? ""
            ]
            
            //Track Location
            let wifiipAddress = Util.getIFAddresses()[1]
            let trackURL = "http://\(wifiipAddress):8080/track?longitude=\(longitutde)&latitude=\(latitude)"
            let herokuTrackURL = "https://crystal-smalltalk.herokuapp.com/track?longitude=\(longitutde)&latitude=\(latitude)"
            Alamofire.request(herokuTrackURL, method: .post, parameters: userDetails, encoding: JSONEncoding.default).response { (response) in
               // print(response.error!)
                print(response.response?.statusCode)
            }
            
            //Update User's Location
            userLoggedIn.lastLocation = userLocation
            userLoggedIn.lastPlacemark = placemark
            
            currentUserLocation = CLLocation(latitude: latitude, longitude: longitutde)
            
        }
        
    }
    
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let userLocation:CLLocation = locations[0] as CLLocation
        
        //Update to get user's current location not managers
        CLGeocoder().reverseGeocodeLocation(userLocation, completionHandler: {(placemarks, error)->Void in
            
            if (error != nil) {
                print("Reverse geocoder failed with error: " + (error?.localizedDescription)!)
                return
            }
            
            if (placemarks?.count)! > 0 {
                let pm = placemarks?[0]
                //TODO: Dosnt always update location
                var latitude = pm?.location?.coordinate.latitude
                var longitude = pm?.location?.coordinate.longitude
                self.trackUserLocation(placemark: pm, userLocation: userLocation)
            } else {
                print("Problem with the data received from geocoder")
            }
        })
        
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
        
        if (indexPath.section == 0) {
            
            cell.userDetails.numberOfLines = 0
            
            cell.userDetails.text? =
            self.friendsAround[friendsAround.index(self.friendsAround.startIndex, offsetBy: indexPath.row)].firstName! + " " +
                self.friendsAround[friendsAround.index(self.friendsAround.startIndex, offsetBy: indexPath.row)].lastName! + "\n"
            
            cell.userDetails.text? +=
                self.friendsAround[friendsAround.index(self.friendsAround.startIndex, offsetBy: indexPath.row)].school! + "\n"
            
            cell.userDetails.text? +=
                self.friendsAround[friendsAround.index(self.friendsAround.startIndex, offsetBy: indexPath.row)].employer!
            
            // cell.schoolLabel.text = self.friendsAround[friendsAround.index(self.friendsAround.startIndex, offsetBy: indexPath.row)].school!
            
            let facebookId = self.friendsAround[friendsAround.index(self.friendsAround.startIndex, offsetBy: indexPath.row)].facebookId ?? ""
            
            // Get Headshot if there is facebookId
            if (facebookId != "") {

                cell.headshotViewImage.image = self.friendsAround[friendsAround.index(self.friendsAround.startIndex, offsetBy: indexPath.row)].headshot
        
                let headshotCornerRadius = CGFloat(15.0)
                let headshotBorderWidth = CGFloat(3)
                
                cell.headshotViewImage.layer.cornerRadius = headshotCornerRadius
                cell.headshotViewImage.layer.borderWidth = headshotBorderWidth
                cell.headshotViewImage.layer.borderColor = UIColor.black.cgColor
                
            } else {
                print("Facebook ID not found")
            }
            
            let appUser = User()
            appUser.facebookId = self.friendsAround[friendsAround.index(self.friendsAround.startIndex, offsetBy: indexPath.row)].facebookId
            cell.user = appUser
            
            // Keeps flashing
            // cell.connectButton.titleLabel?.text = "Reconnect"
        } else {
            cell.userDetails.text? = self.strangersAround[strangersAround.index(self.strangersAround.startIndex, offsetBy: indexPath.row)].firstName! + " " +
                self.friendsAround[friendsAround.index(self.friendsAround.startIndex, offsetBy: indexPath.row)].lastName!
            cell.headshotViewImage.image = self.strangersAround[strangersAround.index(self.strangersAround.startIndex, offsetBy: indexPath.row)].headshot
            cell.userDetails.text? = self.friendsAround[friendsAround.index(self.friendsAround.startIndex, offsetBy: indexPath.row)].school!
            cell.headshotViewImage.layer.cornerRadius = 15.0
            cell.headshotViewImage.layer.borderWidth = 3
            cell.headshotViewImage.layer.borderColor = UIColor.black.cgColor
            let appUser = User()
            appUser.facebookId = self.friendsAround[friendsAround.index(self.friendsAround.startIndex, offsetBy: indexPath.row)].facebookId
            cell.user = appUser
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let profileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SelectProfileViewController") as! ProfileViewController
        let selectedUser = User()
        let selectedCell = PeopleNearbyTableView.cellForRow(at: indexPath) as! UserTableViewCell
        selectedUser.firstName = selectedCell.userDetails.text
        selectedUser.location = userLoggedIn?.location
        selectedUser.headshot = selectedCell.headshotViewImage.image!
        selectedUser.facebookId = selectedCell.user?.facebookId
        profileVC.userSelected = selectedUser
        let maintabVC = self.tabBarController as! MainTabBarController
        maintabVC.userloggedIn = self.userLoggedIn
        self.tabBarController?.modalPresentationStyle = .popover
        self.tabBarController?.present(profileVC, animated: false, completion: nil)
        //        let tbc = self.tabBarController as! MainTabBarController
        //        tbc.selectedUser = selectedUser
        //        self.tabBarController?.selectedIndex = 1
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.refreshControl.endRefreshing()
        self.actInd.stopAnimating()
        self.actInd.removeFromSuperview()
//        self.PeopleNearbyTableView.reloadRows(at: [friendIndexPath], with: UITableView.RowAnimation.automatic)
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
