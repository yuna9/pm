//
//  CitiesViewController.swift
//  PageMe
//
//  Created by Yuna Kim on 5/14/21.
//

import UIKit
import CoreData

class CitiesViewController: UITableViewController,
                            AddLocationDelegate {
    var managedObjectContext: NSManagedObjectContext!
    var places = [Place]()
    var cities = [Location]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fetchRequest = NSFetchRequest<Place>()
        fetchRequest.entity = Place.entity()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            places = try managedObjectContext.fetch(fetchRequest)
        } catch {
            fatalCoreDataError(error)
        }
        cities = places.map { Location(name: $0.name, woeID: Int($0.woeID)) }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddLocation" {
            let controller = segue.destination as! AddLocationViewController
            controller.delegate = self
        }
    }

    // MARK: - AddLocation Delegate
    func addLocation(_ controller: AddLocationViewController, didFinishAdding location: Location) {
        cities.append(location)
        let place = Place(context: managedObjectContext)
        place.name = location.name
        place.woeID = Int32(location.woeID)
        do {
            try managedObjectContext.save()
            afterDelay(0.6) {
                self.tableView.reloadData()
                self.dismiss(animated: true, completion: nil)
            }
        } catch {
            fatalCoreDataError(error)
        }
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cities.count + 1
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CityIdentifier", for: indexPath)
        let label = cell.viewWithTag(10) as! UILabel
        
        if indexPath.row == 0 {
            return cell
        }
        
        let location = cities[indexPath.row-1]
        label.text = location.name
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
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
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
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
