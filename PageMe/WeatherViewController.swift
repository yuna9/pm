//
//  WeatherViewController.swift
//  PageMe
//
//  Created by Yuna Kim on 2/9/21.
//

import CoreLocation
import UIKit
import AudioToolbox
import WebKit

class WeatherViewController: UIViewController,
                             CLLocationManagerDelegate,
                             WeatherServiceDelegate {
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var conditionsLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var hiLoLabel: UILabel!
    @IBOutlet weak var webView: WKWebView!

    var timer: Timer?
    var customLocation: Location?
    
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: Error?
    
    var weatherService = WeatherService()
    var weatherReport: WeatherReport?
    var gettingWeather = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        weatherService.delegate = self
        if customLocation != nil {
            getWeather()
        } else {
            getLocation()
        }
        updateView()
    }
    
    func getWeather() {
        gettingWeather = true
        DispatchQueue.main.async {
            if let customLocation = self.customLocation {
                self.weatherService.weather(forWoe: customLocation.woeID)
            } else if let location = self.location {
                self.weatherService.weather(atCoords: location)
            }
        }
    }
    
    func getLocation() {
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
        updateView()
    }
    
    // MARK: - WeatherServiceDelegate
    func weather(_ service: WeatherService,
                 _ report: WeatherReport) {
        weatherReport = report
        gettingWeather = false
        updateView()
        AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) {}
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
        updateView()
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
                print("Got good location")
                stopLocationManager()
            }
            updateView()
        } else if distance < 1 {
            let timeInterval = newLocation.timestamp.timeIntervalSince(
                location!.timestamp)
            if timeInterval > 10 {
                print("Task timed out, stop locating")
                stopLocationManager()
                updateView()
            }
        }
    }
    
    // MARK:- Helper Methods
    
    func updateView() {
        if location != nil {
            messageLabel.text = ""
        } else {
            let statusMessage: String
            if let error = lastLocationError as NSError? {
                if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
                    statusMessage = "Location Services is disabled"
                } else {
                    statusMessage = "Failed to get your location"
                }
            } else if !CLLocationManager.locationServicesEnabled() {
                statusMessage = "Location Services is disabled"
            } else if updatingLocation || gettingWeather {
                statusMessage = "Getting the latest weather..."
            } else {
                statusMessage = ""
            }
            messageLabel.text = statusMessage
        }
        
        if let report = weatherReport {
            cityLabel.isHidden = false
            conditionsLabel.isHidden = false
            tempLabel.isHidden = false
            hiLoLabel.isHidden = false

            cityLabel.text = report.city
            let forecast = report.forecasts.first!
            conditionsLabel.text = forecast.conditions
            tempLabel.text = tempText(forecast.currentTemp, false)
            hiLoLabel.text = "Hi:\(tempText(forecast.maxTemp, true)) Lo:\(tempText(forecast.minTemp, true))"

            if let url = forecast.conditionsIconURL() {
                webView.load(URLRequest(url: url))
                UIView.animate(withDuration: 0.75) {
                    self.webView.alpha = 1.0
                }
            }
        }
    }
    
    // Formats a Float degrees celsius as a whole number degrees Fahrenheit,
    // with or without degrees notation.
    func tempText(_ celsius: Float, _ bare: Bool) -> String {
        let fahrenheit = Int(round(celsius * 1.8 + 32))
        var output = String(fahrenheit)
        if !bare {
            output += "°F"
        }
        return output
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
            getWeather()
        }
    }
    
    @objc func didTimeOut() {
        print("Timed out")
        if location == nil {
            stopLocationManager()
            lastLocationError = NSError(
                domain: "PageMeErrorDomain",
                code: 1,
                userInfo: nil)
            updateView()
        }
    }
}
