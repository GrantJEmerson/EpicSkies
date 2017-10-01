//
//  LocationSetterViewController.swift
//  EpicSkies
//
//  Created by Grant Emerson on 7/28/17.
//  Copyright © 2017 com.CelebrityGames. All rights reserved.
//

import UIKit
import MapKit

// MARK: - Public Protocols

public protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class LocationSetterViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: - Properties
    
    @IBOutlet weak var chooseLocationButton: UIButton!
    
    public var locationFinderDelegate: LocationFinderDelegate?
    public var mapView: MKMapView!
    
    private var locationManager = CLLocationManager()
    
    private var resultsSearchController: UISearchController?
    private var selectedPin: MKPlacemark?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = MKMapView(frame: view.frame)
        mapView.delegate = self
        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        view.insertSubview(mapView, at: 0)
        
        let leadingConstraint = NSLayoutConstraint(item: mapView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
        let trailingConstraint = NSLayoutConstraint(item: mapView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
        let topConstraint = NSLayoutConstraint(item: mapView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: mapView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        
        view.addConstraints([leadingConstraint, trailingConstraint, bottomConstraint, topConstraint])
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationsSearchTable
        resultsSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultsSearchController?.searchResultsUpdater = locationSearchTable
        
        let searchBar = resultsSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for a location"
        navigationItem.titleView = resultsSearchController?.searchBar
        
        resultsSearchController?.hidesNavigationBarDuringPresentation = false
        resultsSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        locationSearchTable.mapView = mapView
        locationSearchTable.handleMapSearchDelegate = self
        
        chooseLocationButton.clipsToBounds = true
        chooseLocationButton.layer.cornerRadius = chooseLocationButton.bounds.height / 2.0
        chooseLocationButton.layer.borderColor = UIColor.lightGray.cgColor
        chooseLocationButton.layer.borderWidth = 2.0
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        locationManager.stopUpdatingLocation()
        mapView.removeAnnotations(mapView.annotations)
        mapView.delegate = nil
        mapView.removeFromSuperview()
        mapView = nil
    }
    
    // MARK: - Actions
    
    @IBAction func cancel(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @IBAction func chooseLocation(_ sender: UIButton) {
        guard let selectedLocation = selectedPin?.location else { return }
        locationFinderDelegate?.setLocation(newLocation: selectedLocation)
        self.dismiss(animated: true)
    }
    
}

extension LocationSetterViewController: CLLocationManagerDelegate {
    
    // MARK: - LocationManager Delegate Implementation
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location.coordinate, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}

extension LocationSetterViewController: HandleMapSearch {
    
    // MARK: - Location Setter Delegate Implemenatation
    
    func dropPinZoomIn(placemark: MKPlacemark) {
        
        chooseLocationButton.isEnabled = true
        selectedPin = placemark
        
        mapView.removeAnnotations(mapView.annotations)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        mapView.addAnnotation(annotation)
        
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
    }
}
