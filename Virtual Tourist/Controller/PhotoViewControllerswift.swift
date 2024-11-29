//
//  PhotoViewControllerswift.swift
//  Virtual Tourist
//
//  Created by Mario Arndt on 06.12.22.
//

import UIKit
import MapKit
import CoreData

class PhotoViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var nophotosLabel: UILabel!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    var dataController : DataController = (UIApplication.shared.delegate as! AppDelegate).dataController
    var pin: Pin!
    var photos: [Image] = []
    var numberOfCellsPerRow = 0.0
    var numberPhotos = 0
    var page = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        mapView.delegate = self
        
        // Organize layout of collection view
        var numberOfCellsPerRow = 3.0
        if UIApplication.shared.statusBarOrientation.isLandscape {
            numberOfCellsPerRow = 5.0
        }
        flowLayout.minimumInteritemSpacing = 0.005
        flowLayout.minimumLineSpacing = 0.005
        let horizontalSpacing = flowLayout.scrollDirection == .vertical ? flowLayout.minimumInteritemSpacing : flowLayout.minimumLineSpacing
        let cellWidth = (view.frame.width - max(0, numberOfCellsPerRow - 1) * horizontalSpacing) / numberOfCellsPerRow
        flowLayout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        
        setupMap()
        newCollectionButton.isEnabled = false
        nophotosLabel.isHidden = true
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        if fetchPhotos() == 0 {
            loadPhotoList()
        } else {
            // Number of photos in Core Data
            numberPhotos = photos.count
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.reloadData()
    }
    
    
    @IBAction func newCollectionPressed(_ sender: Any) {
        newCollectionButton.isEnabled = false
        deletePhotos()
        loadPhotoList()
    }
    
    @IBAction func backPressed(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    
    // Set up map
    func setupMap() {
        let latitudeDelta = UserDefaults.standard.double(forKey: "LatitudeDelta")
        let longitudeDelta = UserDefaults.standard.double(forKey: "LongitudeDelta")
        mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2DMake(pin.latitude, pin.longitude),
                                             span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)), animated: true)
        mapView.addAnnotation(pin)
    }
    
    
    // Delete all photos for a location in Core Data
    func deletePhotos() {
        for photo in photos {
            dataController.viewContext.delete(photo)
            do {
                try self.dataController.viewContext.save()
            } catch {
                self.showAlert(message: error.localizedDescription, title: "Error deleting photos")
            }
        }
        photos = []
        numberPhotos = 0
    }
    
    
    // Download a list of photos for a location
    func loadPhotoList() {
        ClientFlickr.downloadList(lat: pin.latitude, lon: pin.longitude, page: page, completion: { result in
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            switch result {
            case .success(let downloadPhotos):
                self.page = Int.random(in: 1...min(downloadPhotos.pages,4000/30))
                let arrayPhotos = downloadPhotos.photo
                self.numberPhotos = arrayPhotos.count
                if self.numberPhotos > 0 {
                    self.collectionView.reloadData()
                    self.loadPhotoImage(photoURL: arrayPhotos)
                } else {
                    self.nophotosLabel.isHidden = false
                }
                
            case .failure(let error):
                self.showAlert(message: error.localizedDescription, title: "Error loading photos")
            }
        })
        
    }
    
    
    // Download photos for a location
    func loadPhotoImage(photoURL: [Photo]) {
        for photo in photoURL {
            ClientFlickr.downloadImage(request: URL(string: photo.url!)!, completion: { result in
                switch result {
                case .success(let image):
                    self.saveImage(data: image, url: photo.url!, completion: { success in
                        if success {
                            self.fetchPhotos()
                            self.collectionView.reloadData()
                        }
                    })
                    
                case .failure(let error):
                    self.showAlert(message: error.localizedDescription, title: "Error loading photos")
                }
            })
        }
    }
    
    
    // Save photo in Core Data
    func saveImage(data: Data, url: String, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let image = Image(context: self.dataController.viewContext)
            image.data = UIImage(data: data)!.pngData()
            image.pin = self.pin
            
            do {
                try self.dataController.viewContext.save()
            } catch {
                self.showAlert(message: error.localizedDescription, title: "Error saving photos")
            }
            completion(true)
        }
        
    }
    
    
    // Load photos from Core Data
    func fetchPhotos() -> Int {
        let fetchRequest: NSFetchRequest<Image> = Image.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        do {
            let result = try dataController.viewContext.fetch(fetchRequest)
            photos = result
        }
        catch {
            self.showAlert(message: error.localizedDescription, title: "Error fetching photos")
        }
        return photos.count
    }
    
    
    // MARK: collection methods
    
    // Number of photos in Core Data
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if numberPhotos == photos.count {
            newCollectionButton.isEnabled = true
        }
        return photos.count
    }
    
    // Create a cell for each photo
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        
        if photos.count < numberPhotos {
            cell.photoImageView.image = UIImage(named: "Placeholder")
        } else {
            let photo = self.photos[(indexPath as NSIndexPath).row]
            if let image = photo.data {
                cell.photoImageView.image = UIImage(data: image)
            }
        }
        
        return cell
    }
    
    
    // Tap on a photo -> delete photo
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        dataController.viewContext.delete(photos[indexPath.row])
        numberPhotos -= 1
        
        do {
            try dataController.viewContext.save()
        }
        catch {
            self.showAlert(message: error.localizedDescription, title: "Error deleting photos")
        }
        photos.remove(at: indexPath.row)
        collectionView.reloadData()
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

