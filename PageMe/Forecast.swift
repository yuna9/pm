//
//  Forecast.swift
//  PageMe
//
//  Created by Yuna Kim on 5/15/21.
//

import Foundation

struct Location: Codable {
    enum CodingKeys: String, CodingKey {
        case name = "title"
        case woeID = "woeid"
    }
    
    let name: String
    let woeID: Int
}

struct WeatherReport: Codable {
    enum CodingKeys: String, CodingKey {
        case time, sunRise, sunSet
        case city = "title"
        case forecasts = "consolidatedWeather"
    }
    
    let city: String
    let time: String // TODO: Date
    let sunRise: String
    let sunSet: String
    let forecasts: [Forecast]
    
    func richText() -> String {
        var output = ""
        output += "City: \(city)\n"
        output += "Local time: \(time)\n"
        
        let f = forecasts.first!
        output += f.richText()
        return output
    }
}

struct Forecast: Codable {
    enum CodingKeys: String, CodingKey {
        case windSpeed, windDirection, minTemp, maxTemp,
             airPressure,humidity, visibility, predictability
        case date = "applicableDate"
        case conditions = "weatherStateName"
        case windCompass = "windDirectionCompass"
        case currentTemp = "theTemp"
    }
    
    let date: String // TODO: Date
    let conditions: String
    var windSpeed, windDirection: Float
    let windCompass: String
    let minTemp, maxTemp, currentTemp: Float
    let airPressure, humidity, visibility: Float
    let predictability: Int
    
    func richText() -> String {
        var output = ""
        output += "Weather on \(date)\n"
        output += "\(conditions)\n"
        output += "\(currentTemp)\n"
        output += "H:\(maxTemp) L:\(minTemp)\n"
        return output
    }
}
