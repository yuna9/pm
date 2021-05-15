//
//  CurrentLocationViewController.swift
//  PageMe
//
//  Created by Yuna Kim on 2/9/21.
//

import CoreLocation
import UIKit

class CurrentLocationViewController: UIViewController,
                                     CLLocationManagerDelegate,
                                     WeatherServiceDelegate {
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var conditionsLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var hiLoLabel: UILabel!
    
    var timer: Timer?
    var customLocation: Location?
    
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: Error?
    
    var weatherService = WeatherService()
    var weatherReport: WeatherReport?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        weatherService.delegate = self
        getLocation()
    }
    
    // MARK:- Actions
    @IBAction func getLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            showLocationServicesDeniedAlert()
            return
        default:
            break
        }
        
        if updatingLocation {
            stopLocationManager()
        } else {
            location = nil
            lastLocationError = nil
            startLocationManager()
        }
        updateLabels()
    }
    
    // MARK: - WeatherServiceDelegate
    func weather(_ service: WeatherService,
                 _ report: WeatherReport) {
        print(report)
        weatherReport = report
        updateLabels()
    }
    func weatherFailed(_ service: WeatherService) {}
    func search(_ service: WeatherService, _ found: [Location]) {}
    func searchFailed(_ service: WeatherService) {}
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("didFailWithError \(error.localizedDescription)")
        
        if (error as NSError).code == CLError.locationUnknown.rawValue {
            return
        }
        lastLocationError = error
        stopLocationManager()
        updateLabels()
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        var distance = CLLocationDistance(Double.greatestFiniteMagnitude)
        if let location = location {
            distance = newLocation.distance(from: location)
        }
        
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
            lastLocationError = nil
            location = newLocation
            
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
                print("*** We're done!")
                stopLocationManager()
            }
            updateLabels()
        } else if distance < 1 {
            let timeInterval = newLocation.timestamp.timeIntervalSince(
                location!.timestamp)
            if timeInterval > 10 {
                print("*** Force done!")
                stopLocationManager()
                updateLabels()
            }
        }
    }
    
    // MARK:- Helper Methods
    
    func updateLabels() {
        if location != nil {
            messageLabel.text = ""
        } else {
            let statusMessage: String
            if let error = lastLocationError as NSError? {
                if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
                    statusMessage = "Location Services Disabled"
                } else {
                    statusMessage = "Error Getting Location"
                }
            } else if !CLLocationManager.locationServicesEnabled() {
                statusMessage = "Location Services Disabled"
            } else if updatingLocation {
                statusMessage = "Searching..."
            } else {
                statusMessage = ""
            }
            messageLabel.text = statusMessage
        }
        
        if let report = weatherReport {
            cityLabel.text = report.city
            let forecast = report.forecasts.first!
            conditionsLabel.text = forecast.conditions
            tempLabel.text = String(forecast.currentTemp)
            hiLoLabel.text = "Hi:\(forecast.maxTemp) Lo:\(forecast.minTemp)"
        }
    }
    
    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(
            title: "Location Services Disabled",
            message: "Please enable location services for this app in Settings.",
            preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default,
                                     handler: nil)
        alert.addAction(okAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy =
                kCLLocationAccuracyHundredMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
            
            timer = Timer.scheduledTimer(timeInterval: 60,
                                         target: self,
                                         selector: #selector(didTimeOut),
                                         userInfo: nil,
                                         repeats: false)
        }
    }
    
    func stopLocationManager() {
        if updatingLocation {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
            if let timer = timer {
                timer.invalidate()
            }
            if let location = location {
                weatherService.weather(at: location)
            }
        }
    }
    
    @objc func didTimeOut() {
        print("***Time out")
        if location == nil {
            stopLocationManager()
            lastLocationError = NSError(
                domain: "PageMeErrorDomain",
                code: 1,
                userInfo: nil)
            updateLabels()
        }
    }
}
