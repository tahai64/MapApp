//
//  ViewController.swift
//  MapApp
//
//  Created by Taha Ishfaq on 2020-04-25.
//  Copyright © 2020 Taha Ishfaq. All rights reserved.
//
// Main objectives are to get permissions from user to show location of user on the map,
// show user location on the map, and to update both map and user location as user moves
// from user's starting point to the destination as chosen by the user.

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var AddressLabel: UILabel!
    
    let locationManager = CLLocationManager()
    var prevLocation: CLLocation?
    
    var directionsArray: [MKDirections] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkLocationServices()
        self.AddressLabel.layer.cornerRadius = 20
    }
    
    func locationAlert( title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Enable Location", style: .default, handler: { (Action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func setupLocationManager(){
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func centerViewOnUserLocation(){
        if let location = locationManager.location?.coordinate{
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: 10000, longitudinalMeters: 10000)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func checkLocationServices(){
        if CLLocationManager.locationServicesEnabled(){
            setupLocationManager()
            checkLocationAuthorization()
        }else{
            func viewDidAppear(_ animated: Bool){
                locationAlert(title: "Enable Location", message: "Location services are required for this app")
            }
        }
    }
    
    func checkLocationAuthorization(){
        switch CLLocationManager.authorizationStatus(){
        case .denied:
            func viewDidAppear(_ animated: Bool){
                locationAlert(title: "Enable Location", message: "Location services are required for this app")
            }
            break
        case .restricted:
            func viewDidAppear(_ animated: Bool){
                locationAlert(title: "Enable Location", message: "Location services are required for this app")
            }
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            centerViewOnUserLocation()
            locationManager.startUpdatingLocation()
            prevLocation = getCenterLocation(for: mapView)
            break
        case .authorizedAlways:
            break
        @unknown default:
            break
        }
    }
    
    func getDirections(){
        guard let location = locationManager.location?.coordinate else {
            func viewDidAppear(_ animated: Bool){
                locationAlert(title: "Enable Location", message: "Location services are required for this app")
            }
            return
        }
        
        let request = makeDirectionRequest(from: location)
        let directions = MKDirections(request: request)
        resetMapView(withNew: directions)
        
        directions.calculate{[ unowned self ] (response, error) in
            guard let response = response else { return } /// show response not avaible
            
            for route in response.routes{
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    func makeDirectionRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request{
        let destinationCoordinate = getCenterLocation(for: mapView).coordinate
        let startingPoint = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingPoint)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        
        return request
    }
    
    func resetMapView(withNew directions: MKDirections){
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map{ $0.cancel()}
    }
    
    @IBAction func StartButtonPressed(_ sender: Any) {
        getDirections()
    }
    
    func getCenterLocation(for mapview: MKMapView) -> CLLocation{
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
}



extension ViewController: CLLocationManagerDelegate{

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus){
        checkLocationAuthorization()
    }
}

extension ViewController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getCenterLocation(for: mapView)
        let geoCoder = CLGeocoder()
        
        guard let prevLocation = self.prevLocation else {
            return
        }
        
        guard center.distance(from: prevLocation) > 50 else {
            return
        }
        
        self.prevLocation = center
        geoCoder.cancelGeocode()
        
        geoCoder.reverseGeocodeLocation(center){ [weak self] (placemarks, error) in
            guard let self = self else {
                return
            }
            
            if let _ = error{
                /// show alert to user
                return
            }
            
            guard let placemark = placemarks?.first else{
                //// show alert to user
                return
            }
            
            let streetNumber = placemark.subThoroughfare ?? ""
            let streetName = placemark.thoroughfare ?? ""
            
            DispatchQueue.main.async {
                self.AddressLabel.text = "\(streetNumber) \(streetName)"
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer{
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        
        return renderer
    }
}
