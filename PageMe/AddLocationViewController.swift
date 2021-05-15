//
//  AddLocationViewController.swift
//  PageMe
//
//  Created by Yuna Kim on 5/15/21.
//

import UIKit
import CoreData

protocol AddLocationDelegate: AnyObject {
    func addLocation(_ controller: AddLocationViewController,
                     didFinishAdding location: Location)
}

class AddLocationViewController: UITableViewController,
                                 UISearchBarDelegate,
                                 WeatherServiceDelegate {
    @IBOutlet weak var searchBar: UISearchBar!

    var delegate: AddLocationDelegate?
    var weatherService = WeatherService()
    var searchResults = [Location]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        weatherService.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchBar.becomeFirstResponder()
    }
    
    // MARK: - WeatherServiceDelegate
    func weather(_ service: WeatherService, _ report: WeatherReport) {}
    func weatherFailed(_ service: WeatherService) {}
    func searchFailed(_ service: WeatherService) {}
    
    func search(_ service: WeatherService, _ found: [Location]) {
        searchResults = found
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultIdentifier", for: indexPath)

        let location = searchResults[indexPath.row]
        let label = cell.viewWithTag(10) as! UILabel
        label.text = location.name

        return cell
    }
    
    override func tableView(_ tableView: UITableView,
                            canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("search clicked", searchBar.text!)
        weatherService.searchLocations(searchBar.text!)
    }
    
    func searchBar(_ searchBar: UISearchBar,
                   textDidChange searchText: String) {
        print("text change", searchText)
    }
    
    // MARK: - Actions
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let location = searchResults[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.addLocation(self, didFinishAdding: location)
    }

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
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
