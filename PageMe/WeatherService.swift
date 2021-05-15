//
//  WeatherService.swift
//  PageMe
//
//  Created by Yuna Kim on 5/14/21.
//

import CoreLocation
import Foundation

let mwBase = "https://www.metaweather.com"
let searchEndpoint = "/api/location/search/"
let weatherEndpoint = "/api/location/"

protocol WeatherServiceDelegate: AnyObject {
    func weather(_ service: WeatherService,
                 _ report: WeatherReport)
    func weatherFailed(_ service: WeatherService)
    
    func search(_ service: WeatherService,
                _ found: [Location])
    func searchFailed(_ service: WeatherService)
}

class WeatherService {
    weak var delegate: WeatherServiceDelegate?
    
    func weather(at location: CLLocation) {
        let (city, woeID) = findCity(at: location)
        guard city != nil else {
            delegate?.weatherFailed(self)
            return
        }
        
        let weatherURL = URL(string: mwBase + weatherEndpoint + String(woeID!))
        let data = sendSynchronous(to: weatherURL!)
        guard let data = data else {
            delegate?.weatherFailed(self)
            return
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let report: WeatherReport = try! decoder.decode(WeatherReport.self, from: data)
        delegate?.weather(self, report)
    }
    
    func findCity(at location: CLLocation) -> (String?, Int?) {
        let lat = location.coordinate.latitude
        let long = location.coordinate.longitude
        
        print("Lat: \(lat)\tLong: \(long)")

        let searchURL = URL(string: mwBase + searchEndpoint + "?lattlong=\(lat),\(long)")
        let data = sendSynchronous(to: searchURL!)
        
        guard let data = data else {
            return (nil, nil)
        }
        
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        if let array = json as? [Any],
           let first = array.first {
            let dict = first as! [String: Any]
            let city = dict["title"] as! String
            let woeID = dict["woeid"] as! Int
            return (city, woeID)
        } else {
            return (nil, nil)
        }
    }
    
    func searchLocations(_ searchTerm: String) {
        let searchURL = URL(string: mwBase + searchEndpoint + "?query=\(searchTerm)")
        let data = sendSynchronous(to: searchURL!)
        
        guard let data = data else {
            delegate?.searchFailed(self)
            return
        }
        
        let decoder = JSONDecoder()
        let results: [Location] = try! decoder.decode([Location].self, from: data)
        print(results)
        delegate?.search(self, results)
    }
    
    func sendSynchronous(to url: URL) -> Data? {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        let sem = DispatchSemaphore(value: 0)
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: url,
                                        completionHandler: {d, r, e in
                                            data = d
                                            response = r
                                            error = e
                                            sem.signal()
                                        })
        dataTask.resume()
        sem.wait()
        
        if let error = error {
            print("err: \(error.localizedDescription)")
            return nil
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("error: \(String(describing: response))")
            return nil
        }
        
        return data
    }
}
