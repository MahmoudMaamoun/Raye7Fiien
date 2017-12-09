//
//  HomeViewController.swift
//  Raye7Feen
//
//  Created by Mahmoud Maamoun on 12/8/17.
//  Copyright © 2017 Mahmoud Maamoun. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
class HomeViewController: UIViewController,GMSMapViewDelegate, CLLocationManagerDelegate,GMSAutocompleteViewControllerDelegate , UITextFieldDelegate , UISearchDisplayDelegate {
    @IBOutlet weak var fromTextField: UITextField!
    @IBOutlet weak var toTextField: UITextField!
    @IBOutlet weak var mapView: GMSMapView!
    var isFrom = false
    var isTo = false
    let locationManager = CLLocationManager()
    var fromMarker = GMSMarker()
    var toMarker = GMSMarker()
    
    var location: CLLocationCoordinate2D? = nil
    var searchBar: UISearchBar?
    var tableDataSource: GMSAutocompleteTableDataSource?
  
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLocation()
        if CLLocationManager.locationServicesEnabled() {
            let timerA = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateLocation), userInfo: nil, repeats: false);
            timerA.fire()
            
        }
        self.mapView.delegate = self
           // Do any additional setup after loading the view.
    }
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        
    }
    var fromPlace : GMSPlace!
    var toPlace : GMSPlace!
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        mapView.clear()
        if isFrom {
            fromTextField.text = place.formattedAddress
            addMarker(coordinate: place.coordinate)
            fromPlace = place
        }
        else if isTo {
            toTextField.text = place.formattedAddress
            addMarker(coordinate: place.coordinate)
            toPlace = place
        }
        dismiss(animated: false, completion: nil)
        
    }
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: false, completion: nil)
        
    }
    func viewController(_ viewController: GMSAutocompleteViewController, didSelect prediction: GMSAutocompletePrediction) -> Bool {
        return true
    }
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true

    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        location = manager.location!.coordinate
        let camera = GMSCameraPosition.camera(withLatitude: locValue.latitude, longitude: locValue.longitude, zoom: 14.0)
        mapView.camera = camera
        mapView.delegate = self
        mapView.isMyLocationEnabled = true
        mapView.clear()
        
        locationManager.stopUpdatingLocation()
    }
    func updateLocation () {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    func addMarker(coordinate:CLLocationCoordinate2D)
    {
        if isFrom {
            
            fromMarker = GMSMarker(position: coordinate)
            fromMarker.map = mapView
            let camera = GMSCameraPosition.camera(withLatitude: coordinate.latitude, longitude: coordinate.longitude, zoom: 14.0)
            mapView.camera = camera
            mapView.isMyLocationEnabled = true
            
        }
        else {
            toMarker = GMSMarker(position: coordinate)
            toMarker.map = mapView
            let camera = GMSCameraPosition.camera(withLatitude: coordinate.latitude, longitude: coordinate.longitude, zoom: 14.0)
            mapView.camera = camera
            mapView.isMyLocationEnabled = true
        }
    // 2 pm bokra 
    }
    func DrawPath() {
        
        mapView.clear()
        fromMarker = GMSMarker(position: fromPlace.coordinate)
        fromMarker.map = mapView
        
        
        toMarker = GMSMarker(position: toPlace.coordinate)
        toMarker.map = mapView
        
        
       
        
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=place_id:\(fromPlace.placeID)&destination=place_id:\(toPlace.placeID)&key=\(Constants.API_KEY)"
        
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!, completionHandler: {
            (data, response, error) in
            if(error != nil){
                print("error")
            }else{
                do{
                    let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [String : AnyObject]
                    let routes = json["routes"] as! NSArray
                    
                    OperationQueue.main.addOperation({
                        for route in routes
                        {
                            let routeOverviewPolyline:NSDictionary = (route as! NSDictionary).value(forKey: "overview_polyline") as! NSDictionary
                            let points = routeOverviewPolyline.object(forKey: "points")
                            let path = GMSPath.init(fromEncodedPath: points! as! String)
                            let polyline = GMSPolyline.init(path: path)
                            polyline.strokeWidth = 3.5
                            let bounds = GMSCoordinateBounds(path: path!)
                            self.mapView!.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 30.0))
                            polyline.geodesic = true
                            
                            polyline.map = self.mapView
                            
                        }
                    })
                }catch let error as NSError{
                    print("error:\(error)")
                }
            }
        }).resume()
        
        
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.tag == 10 {
            let autocompleteController = GMSAutocompleteViewController()
            autocompleteController.delegate = self
            present(autocompleteController, animated: false, completion: nil)
            isFrom = true
            isTo = false

        }
        else {
            let autocompleteController = GMSAutocompleteViewController()
            autocompleteController.delegate = self
            present(autocompleteController, animated: false, completion: nil)
            isFrom = false
            isTo = true
        }
    }
    @IBAction func DrawPath(_ sender: Any) {
        
        if (fromTextField.text?.characters.count)! == 0 {
            
        }
        else if (toTextField.text?.characters.count)! == 0 {
            
            
        }
        else {
            DrawPath()
        }
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
