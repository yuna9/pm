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
        switch segue.identifier {
        case "AddLocation":
            let controller = segue.destination as! AddLocationViewController
            controller.delegate = self
        case "WeatherView":
            let rowIndex = tableView.indexPathForSelectedRow!.row
            if rowIndex != 0 {
                let controller = segue.destination as! WeatherViewController
                controller.customLocation = cities[rowIndex-1]
            }
        default:
            break
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
            afterDelay(0.3) {
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // Can edit
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Disallow editing the "Current Location" row
        return indexPath.row != 0
    }

    // Editing
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteCity(indexPath.row-1)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }


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

    // MARK: - Helpers
    func deleteCity(_ index: Int) {
        cities.remove(at: index)
        let item = places.remove(at: index)
        managedObjectContext.delete(item)
        do {
            try managedObjectContext.save()
        } catch {
            fatalCoreDataError(error)
        }
    }
}
