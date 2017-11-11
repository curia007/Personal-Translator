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
class MainViewController: UIViewController, ARSKViewDelegate, CLLocationManagerDelegate, UIPopoverPresentationControllerDelegate
{

    @IBOutlet weak var localeButton: UIButton!
    @IBOutlet weak var speakButton: UIButton!
    @IBOutlet weak var sceneView: ARSKView!
    
    private var currentLocale : Locale = Locale.current
    
    private let speechProcessor: SpeechProcessor = SpeechProcessor()
    private let locationManager: CLLocationManager = CLLocationManager()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        locationManager.delegate = self
        locationManager.startMonitoringSignificantLocationChanges()
        
        localeButton.layer.cornerRadius = 5.0
        localeButton.titleLabel?.text = Locale.current.languageCode
        
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
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.

        if let identifier : String = segue.identifier
        {
            if (identifier == "localeSegueIdentifier")
            {
                if let popoverPresentationController: UIPopoverPresentationController = segue.destination.popoverPresentationController
                {
                    popoverPresentationController.delegate = self
                }
            }
            
            if (identifier == "speakSegueIdentifier")
            {
                if let popoverPresentationController: UIPopoverPresentationController = segue.destination.popoverPresentationController
                {
                    popoverPresentationController.delegate = self
                }
                
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
        
    }
    
    func sessionWasInterrupted(_ session: ARSession)
    {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
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
                        self.localeButton.titleLabel?.text = self.currentLocale.languageCode
                    }
                }
            })
        }
    }
    
    // MARK: - UIPopoverPresentationControllerDelegate methods
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle
    {
        return .none
    }
}
