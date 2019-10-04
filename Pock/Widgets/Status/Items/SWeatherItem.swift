//
//  SWeatherItem.swift
//  Pock
//
//  Created by Yusuf Özgül on 2.10.2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults
import CoreLocation
import Alamofire

class SWeatherItem: NSObject, StatusItem, CLLocationManagerDelegate {
    
    /// Core
    private var refreshTimer: Timer?
    private var manager: CLLocationManager!
    private var location: CLLocation!
    
    /// UI
    private var weatherLabel: NSTextField!
    private var currentTemp: String = "⏳"
    
    private let icons = ["Tornado": "💨", "Tropical Storm" : "💨", "Hurricane" : "💨", "Strong Storms" : "⛈", "Thunder and Hail" : "⛈", "Rain to Snow Showers" : "🌨", "Rain / Sleet" : "🌨", "Wintry Mix Snow / Sleet" : "🌨", "Freezing Drizzle" : "🌨", "Freezing Rain" : "🌨", "Hail" : "🌨", "Sleet" : "🌨", "Drizzle" : "🌧", "Light Rain" : "🌧", "Rain" : "🌧", "Scattered Flurries" : "❄️", "Light Snow" : "❄️", "Blowing / Drifting Snow" : "❄️", "Snow" : "❄️", "Blowing Dust / Sandstorm" : "💨", "Foggy" : "💨", "Haze / Windy" : "💨", "Smoke / Windy" : "💨", "Breezy" : "💨", "Blowing Spray / Windy" : "💨", "Frigid / Ice Crystals" : "💨", "Cloudy" : "☁️", "Mostly Cloudy" : "🌥", "Partly Cloudy" : "⛅️", "Clear" : "☀️", "Sunny" : "☀️", "Fair / Mostly Clear" : "🌤", "Fair / Mostly Sunny" : "🌤", "Mixed Rain & Hail" : "🌨", "Hot" : "☀️", "Isolated Thunderstorms" : "🌦", "Thunderstorms" : "🌦", "Heavy Rain" : "🌧", "Heavy Snow" : "❄️", "Blizzard" : "❄️", "Not Available (N/A)" : "❔", "Scattered Showers" : "🌧", "Scattered Snow Showers" : "❄️", "Scattered Thunderstorms" : "⛈"]

    

    override  init() {
        super.init()
        self.didLoad()
        self.reload()
    }
    
    deinit {
        didUnload()
    }
    
    func didLoad() {
        // Required else it will lose reference to button currently being displayed
        if weatherLabel == nil {
            weatherLabel = NSTextField()
            weatherLabel.frame = CGRect(origin: .zero, size: CGSize(width: 100, height: 44))
            weatherLabel.font = NSFont.systemFont(ofSize: 13)
            weatherLabel.backgroundColor = .clear
            weatherLabel.isBezeled = false
            weatherLabel.isEditable = false
            weatherLabel.sizeToFit()
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true, block: { [weak self] _ in
                self?.reload()
                self?.updateWeather()
            })
        }
        let status = CLLocationManager.authorizationStatus()
        if status == .restricted || status == .denied {
            print("User permission not given")
            return
        }

        if !CLLocationManager.locationServicesEnabled() {
            print("Location services not enabled")
            return
        }
        manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.startUpdatingLocation()
        
    }
    
    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            let lastLocation = locations.last!
            location = lastLocation
            if location != nil {
                updateWeather()
            }
    }

        func locationManager(_: CLLocationManager, didFailWithError error: Error) {
            print(error)
        }

        func locationManager(_: CLLocationManager, didChangeAuthorization _: CLAuthorizationStatus) {
            if location != nil {
                updateWeather()
            }
        }
    
    func didUnload() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    var enabled: Bool{ return Defaults[.showWeatherItem] }
    private var useCelcius: Bool{ return Defaults[.weatherUseCelcius] }
    
    var title: String  { return "weather" }
    
    var view: NSView { return weatherLabel }
    
    func action() {
        if !isProd { print("[Pock]: Weather Status icon tapped!") }
    }
    
    func updateWeather()
    {
        if location != nil
        {
            let urlString = "https://api.weather.com/v1/geocode/\(location.coordinate.latitude)/\(location.coordinate.longitude)/aggregate.json?apiKey=e45ff1b7c7bda231216c7ab7c33509b8&products=conditionsshort,fcstdaily10short,fcsthourly24short,nowlinks"
            AF.request(urlString).responseJSON { (response) in
                if response.error == nil
                {
                    do
                    {
                        let jsonDescoder = JSONDecoder()
                        let weather = try jsonDescoder.decode(WeatherResponse.self, from: response.data!)
                        
                        if let dayWeather = weather.fcsthourly24short?.forecasts?.first
                        {
                            if self.useCelcius
                            {
                                self.currentTemp = (self.icons[dayWeather.iconName ?? ""] ?? "") + String((dayWeather.metric?.temp)!) + "°C"
                            }
                            else
                            {
                                self.currentTemp = (self.icons[dayWeather.iconName ?? ""] ?? "") + String((dayWeather.imperial?.temp)!) + "°F"
                            }
                            self.reload()
                        }
                    }
                    catch
                    {
                        print(error.localizedDescription)
                    }
                    
                }
                else
                {
                    print(response.error?.localizedDescription ?? "Error")
                }
            }
        }
    }
    
    func reload()
    {
        weatherLabel?.stringValue = currentTemp
        weatherLabel?.sizeToFit()
    }
    
}
