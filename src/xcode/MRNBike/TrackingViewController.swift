//
//  TrackingViewController.swift
//  MRNBike
//
//  Created by Bormeth, Marc on 11.05.17.
//  Copyright © 2017 Marc Bormeth. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreImage

class TrackingViewController: UIViewController {
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var SaveRouteButton: UIButton!
    @IBOutlet weak var DismissButton: UIButton!
    @IBOutlet weak var PauseButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var backGroundImage: UIImageView!
    @IBOutlet weak var statisticView: UIView!
    @IBOutlet weak var wheelRotationLabel: UILabel!
    @IBOutlet weak var burgersLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var co2SavedLabel: UILabel!
    @IBOutlet weak var reportLocation: UIButton!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    var locationManager = LocationManager()
    
    var trackPointsArray = [TrackPoint]() //storing Trackpoints including timestamp

    var elapsedSeconds: Int = 0
    var timerRunBool: Bool = true
    var timer: Timer = Timer()
    var coordinateNew = CLLocation()
    var coordinateLast = CLLocation()
    var metersDistance: Double = 0.0
    
    //Users wheel size from Zoll to cm.
    let wheelInCm = Double(UserDefaults.standard.integer(forKey: "userWheelSize")) * 0.0254
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navItem.title = "Record Route"
        
        statisticView.borderColor = UIColor.lightGray
        statisticView.borderWidth = 1
        
        let context = CIContext(options: nil)
        let currentFilter = CIFilter(name: "CIGaussianBlur")
        let beginImage = CIImage(image: backGroundImage.image!)
        currentFilter!.setValue(beginImage, forKey: kCIInputImageKey)
        currentFilter!.setValue(3, forKey: kCIInputRadiusKey)
        
        let cropFilter = CIFilter(name: "CICrop")
        cropFilter!.setValue(currentFilter!.outputImage, forKey: kCIInputImageKey)
        cropFilter!.setValue(CIVector(cgRect: beginImage!.extent), forKey: "inputRectangle")
        
        let output = cropFilter!.outputImage
        let cgimg = context.createCGImage(output!, from: output!.extent)
        let processedImage = UIImage(cgImage: cgimg!)
        
        backGroundImage.image = processedImage
        
        self.locationManager.delegate = self
        SaveRouteButton.isHidden = true
        DismissButton.isHidden = true
        PauseButton.isHidden = true
        reportLocation.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
    }
  
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        self.saveCollectedDataLocally() // stores collected data in local storage
    }
    
    
    // MARK: - Action
    
  
    @IBAction func startTrackingEvent(_ sender: UIButton) {
        startButton?.isHidden = true
        PauseButton.isHidden = false
        cancelButton.isEnabled =  false
        locationManager.delegate = self
        locationManager.startTracking()
        
        if timerRunBool {
            startTimer(startNew: true)
        } else {
            startTimer(startNew: false)
        }
    }
    
    
    @IBAction func pauseTrackingEvent(_ sender: UIButton) {
        startButton?.isHidden = false
        PauseButton.isHidden = true
        timerRunBool = false
        locationManager.stopTracking()
        timer.invalidate()
    }

    @IBAction func stopTrackingEvent(_ sender: UIButton) {
        self.locationManager.stopTracking()
        locationManager.delegate = nil
        DismissButton.isHidden = false
        SaveRouteButton.isHidden = false
        startButton.isHidden = true
        stopButton.isHidden = true
        PauseButton.isHidden = true
        timer.invalidate()
    }
    
    @IBAction func saveRouteButton(_ sender: UIButton) {
        
        reportLocation.isHidden = false
        SaveRouteButton.isHidden = true
        
        print(UserDefaults.standard.double(forKey: "wheelRotation"))
        var wheelRotation: Double = UserDefaults.standard.double(forKey: "wheelRotation")
        wheelRotation += Double(wheelRotationLabel.text!)!
        UserDefaults.standard.set(wheelRotation, forKey: "wheelRotation")
        print(UserDefaults.standard.double(forKey: "wheelRotation"))
        
        
        var burgers: Double = UserDefaults.standard.double(forKey: "burgers")
        burgers += Double(burgersLabel.text!)!
        UserDefaults.standard.set(burgers, forKey: "burgers")
        
        var distance: Double = UserDefaults.standard.double(forKey: "distance")
        distance += Double(distanceLabel.text!)!
        UserDefaults.standard.set(distance, forKey: "distance")
        
        var treesSaved: Double = UserDefaults.standard.double(forKey: "treesSaved")
        treesSaved += Double(co2SavedLabel.text!)!
        UserDefaults.standard.set(treesSaved, forKey: "treesSaved")
      
        
        upload()
    }
    
    // MARK: - NSCoding
    func saveCollectedDataLocally(){
        if StorageHelper.storeLocally(trackPointsArray: trackPointsArray) {
            trackPointsArray.removeAll() // in order to dispose used memory
        }
    }
    
    // MARK: - Helper Functions

    func startTimer(startNew: Bool) {
        if startNew { elapsedSeconds = 0 }
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateElapsedTime), userInfo: nil, repeats: true)
    }
    
    func updateElapsedTime() {
        elapsedSeconds += 1
        
        if(elapsedSeconds > 0){
            let ti = NSInteger(elapsedSeconds)
            let strSeconds = ti % 60
            let strMinutes = (ti / 60) % 60
            let strHours = (ti / 3600)
            timeLabel.text = String(format: "%0.2d:%0.2d:%0.2d",strHours,strMinutes,strSeconds)
        }
        
        //Claculate new statistic values and update label text
        if (elapsedSeconds % 5) == 0 {
            
            if elapsedSeconds == 5 {
            let trackpointLast = trackPointsArray.first
                coordinateLast = CLLocation(latitude: (trackpointLast?.latitude)!, longitude: (trackpointLast?.longitude)!)
            }
            
            let trackpointNew = trackPointsArray.last
            coordinateNew = CLLocation(latitude: (trackpointNew?.latitude)!, longitude: (trackpointNew?.longitude)!)
          
            metersDistance += coordinateLast.distance(from: coordinateNew)
            
            wheelRotationLabel.text = String(Int(metersDistance / wheelInCm))
            //253 are the calories for 1 hamburger from McDonalds 9048 = (Distance/1609.34*45)/253
            burgersLabel.text = String(round(100*(metersDistance / 9048))/100)
            distanceLabel.text = String(round(100*(metersDistance / 1000))/100)
            //(Distance/1609.34*45)/12.97
            co2SavedLabel.text = String(round(10*(metersDistance / 464))/10)
            
            coordinateLast = coordinateNew
        }
        
    }
    
       
    // MARK: - Cloud storage
    
    func upload() {
        //TODO: Check for connection -> what if there is bad connection?
        
        saveCollectedDataLocally()
        
        if let loadedData = StorageHelper.loadGPS() {
            
            let jsonObj = StorageHelper.generateJSON(tracks: loadedData)
            
            StorageHelper.uploadToHana(scriptName: "importData/bringItToHana.xsjs", paramDict: nil, jsonData: jsonObj)
        }
    }

}


extension TrackingViewController: LocationManagerDelegate {
    func didUpdateLocation(_ location: CLLocationCoordinate2D) {
        let timestamp = Date().timeIntervalSince1970 * 1000 //this one is for HANA
        let currentTrackPoint = TrackPoint(point: location, timestamp: Int64(timestamp))
        
        trackPointsArray.append(currentTrackPoint)
    }
}

