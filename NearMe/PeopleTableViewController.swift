//
//  PeopleTableViewController.swift
//  NearMe
//
//  Created by Nathan Nguyen on 4/18/17.
//  Copyright © 2017 Nathan Nguyen. All rights reserved.
//

import UIKit
import AWSDynamoDB

class personCell : UITableViewCell {
    
    @IBOutlet weak var headshot: UIImageView!
    @IBOutlet weak var descriptor: UILabel!
 
}

class PeopleTableViewController: UITableViewController {
    
    var people: [Person] = []
    var table: Table?
    var results: [AWSDynamoDBObjectModel]?
    var peopleAround = Set<Person>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        pullNearByPeople()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func pullNearByPeople () {
        table = LocationsTable()
        
        let index = table!.indexes[0]
        
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
                    let attributeKey = self.table?.tableAttributeName!(self.table!.orderedAttributeKeys[10])
                    print(attributeKey!)
                    print("\(modelDictionary[(self.table?.orderedAttributeKeys[10])!]!)")
                    let newPerson = Person()
                    newPerson.firstName = "\(modelDictionary[(self.table?.orderedAttributeKeys[10])!]!)"
                    self.peopleAround.insert(newPerson)
                }
                print(self.peopleAround)
            }
            
            for aPerson in self.peopleAround {
                self.people.append(aPerson)
            }
            
            self.tableView.reloadData()
        }
        
        index.queryWithPartitionKeyAndFilterWithCompletionHandler?(completionHandler)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.people.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PersonCell", for: indexPath) as! personCell
    
        let nextPerson = people[indexPath.row]
    
            cell.descriptor.text = people[indexPath.row].firstName! + "\n"
        
//        if (nextPerson is EmployedPerson) {
//            let EmployedPerson = nextPerson as! EmployedPerson
//            cell.descriptor.text?.append(EmployedPerson.employer)
//        } else {
//            let Student = nextPerson as! Student
//            cell.descriptor.text?.append(Student.school!)
//        }
        
        cell.headshot.image = #imageLiteral(resourceName: "headshot1")
        
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
