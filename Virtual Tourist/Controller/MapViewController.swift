//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Mario Arndt on 06.12.22.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var pins: [Pin] = []
    var dataController : DataController = (UIApplication.shared.delegate as! AppDelegate).dataController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addPin(gestureRecognizer:)))
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
        loadPins()
        setupMap()
    }
    
    
    @IBAction func deletePins(_ sender: Any) {
        mapView.removeAnnotations(mapView.annotations)
    }
    
    
    // Pin a location and save it
    @objc func addPin(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let location = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            let pin = Pin(context: dataController.viewContext)
            pin.latitude = coordinate.latitude
            pin.longitude = coordinate.longitude
            mapView.addAnnotation(pin)
            mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2DMake(pin.latitude, pin.longitude),
                                                 span: MKCoordinateSpan(latitudeDelta: mapView.region.span.latitudeDelta,
                                                                        longitudeDelta: mapView.region.span.longitudeDelta)), animated: true)
            
            do {
                try dataController.viewContext.save()
            } catch {
                showAlert(message: error.localizedDescription, title: "Error saving the pin")
            }
        }
    }
    
    
    // Fetching the last location and span
    func setupMap() {
        let latitude = UserDefaults.standard.double(forKey: "Latitude")
        let longitude = UserDefaults.standard.double(forKey: "Longitude")
        let latitudeDelta = UserDefaults.standard.double(forKey: "LatitudeDelta")
        let longitudeDelta = UserDefaults.standard.double(forKey: "LongitudeDelta")
        
        mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2DMake(latitude, longitude),
                                             span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)), animated: true)
    }
    
    
    // Load pins
    func loadPins(){
        do {
            pins = try dataController.viewContext.fetch(Pin.fetchRequest())
            for pin in pins { mapView.addAnnotation(pin) }
        }
        catch {
            showAlert(message: error.localizedDescription, title: "Error retrieving pins")
        }
    }
    
    
    // Save the map location and span
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        UserDefaults.standard.set(mapView.centerCoordinate.latitude, forKey: "Latitude")
        UserDefaults.standard.set(mapView.centerCoordinate.longitude, forKey: "Longitude")
        UserDefaults.standard.set(mapView.region.span.latitudeDelta, forKey: "LatitudeDelta")
        UserDefaults.standard.set(mapView.region.span.longitudeDelta, forKey: "LongitudeDelta")
    }
    
    
    // Select pin -> Call PhotoViewController
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let selectedPin = view.annotation as! Pin
        let photoViewController = self.storyboard!.instantiateViewController(withIdentifier: "PhotoViewController") as! PhotoViewController
        photoViewController.pin = selectedPin
        self.present(photoViewController, animated: true, completion: nil)
    }
    
    
    // Show the locations as pins
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

            let reuseId = "pin"
            var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

            if pinView == nil {
                pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                pinView!.pinTintColor = .red
            }
            else {
                pinView!.annotation = annotation
            }

            return pinView
        }
    
}

