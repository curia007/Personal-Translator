//
//  MainViewController.swift
//  Personal Translator
//
//  Created by Carmelo Uria on 11/7/17.
//  Copyright © 2017 Carmelo I. Uria. All rights reserved.
//

import UIKit

import SpriteKit
import ARKit

import CoreLocation

@available(iOS 11.0, *)
class MainViewController: UIViewController, ARSKViewDelegate, CLLocationManagerDelegate, UIPopoverPresentationControllerDelegate, UIPopoverControllerDelegate
{

    @IBOutlet weak var localeButton: UIButton!
    @IBOutlet weak var speakButton: UIButton!
    @IBOutlet weak var sceneView: ARSKView!
    
    var currentLocale : Locale = Locale.current
    
    private let speechProcessor: SpeechProcessor = SpeechProcessor()
    private let locationManager: CLLocationManager = CLLocationManager()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if (CLLocationManager.locationServicesEnabled() == false)
        {
            // create the alert
            let alert = UIAlertController(title: "Location Services", message: "Location Services is not Available.", preferredStyle: UIAlertControllerStyle.alert)
            
            // add an action (button)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            
            // show the alert
            self.present(alert, animated: true, completion: nil)
        }

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.startMonitoringSignificantLocationChanges()
        
        localeButton.layer.cornerRadius = 5.0
        localeButton.setTitle(currentLocale.localizedString(forIdentifier: currentLocale.languageCode!), for: UIControlState.normal)
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and node count
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true
        
        let scene = TranslatorScene(size: self.view.frame.size)
        sceneView.presentScene(scene)
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
        
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        
        // stop location manager
        locationManager.startUpdatingLocation()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func localeAction(_ sender: Any)
    {
        debugPrint("<\(#function)>")
    }
    
    @IBAction func speakAction(_ sender: Any)
    {
        debugPrint("<\(#function)>")
    }
    
    @IBAction func unwindSegue(unwindSegue: UIStoryboardSegue)
    {
        debugPrint("<\(#function)> unwindSegue: \(String(describing: unwindSegue.identifier)) source: \(unwindSegue.source)")
        
        if let country: String = Locale.current.localizedString(forIdentifier: currentLocale.languageCode!)
        {
            self.localeButton.setTitle(country, for: UIControlState.normal)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.

        if let identifier : String = segue.identifier
        {
            if (identifier == "LocaleSegueIdentifier")
            {
                if let popoverPresentationController: UIPopoverPresentationController = segue.destination.popoverPresentationController
                {
                    popoverPresentationController.delegate = self
                }                
            }
            
            if (identifier == "SpeakSegueIdentifier")
            {
                let destination: SpeakViewController = segue.destination as! SpeakViewController
                
                if let popoverPresentationController: UIPopoverPresentationController = destination.popoverPresentationController
                {
                    popoverPresentationController.delegate = self
                }
                
                destination.currentLocale = self.currentLocale
            }

        }
    }

    // MARK: - ARSKViewDelegate
    
    func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode?
    {
        // Create and configure a node for the anchor added to the view's session.
        
        guard let identifier : String = SceneAnchor.shared.anchorsToIdentifiers[anchor] else
        {
            return nil
        }
        
        self.speechProcessor.speak(identifier, locale: currentLocale)

        let labelNode = SKLabelNode(text: identifier)
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        labelNode.fontName = UIFont.boldSystemFont(ofSize: 8).fontName
        return labelNode
    }
    
    func session(_ session: ARSession, didFailWithError error: Error)
    {
        // Present an error message to the user
        debugPrint("<\(#function)> did fail with error: \(error)")
    }
    
    func sessionWasInterrupted(_ session: ARSession)
    {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        debugPrint("<\(#function)> session was interrupted...")
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession)
    {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    // MARK: - CLLocationManagerDelegate Methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        if let location: CLLocation = locations.first
        {
            let geocoder : CLGeocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
                if let placemark: CLPlacemark = placemarks?.first
                {
                    if let countryCode: String  = placemark.isoCountryCode
                    {
                        self.currentLocale = Locale(identifier: countryCode)
                        
                        self.localeButton.setTitle(self.currentLocale.localizedString(forIdentifier: self.currentLocale.languageCode!), for: UIControlState.normal)
                    }
                }
            })
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        debugPrint("<\(#function)> status: \(status)")
    }
    
    // MARK: - UIPopoverPresentationControllerDelegate methods
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle
    {
        debugPrint("<\(#function)> presentation style: .none")
        return .none
    }
    
    // MARK: - UIPopoverControllerDelegate methods
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController)
    {
        debugPrint("<\(#function)>")

    }
}
