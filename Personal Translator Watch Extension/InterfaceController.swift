//
//  InterfaceController.swift
//  Personal Translator Watch Extension
//
//  Created by Carmelo I. Uria on 8/11/16.
//  Copyright © 2016 Carmelo I. Uria. All rights reserved.
//

import WatchKit
import Foundation

import WatchConnectivity

class InterfaceController: WKInterfaceController, WatchConnectivityManagerWatchDelegate
{
    @IBOutlet var imageInterface: WKInterfaceImage!

    
    override func awake(withContext context: Any?)
    {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        // The `WatchConnectivityManager` will provide tailored callbacks to its delegate.
        WatchConnectivityManager.sharedConnectivityManager.delegate = self

    }
    
    override func willActivate()
    {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate()
    {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    private func updateDesignatorApplicationContext()
    {
        let defaultSession = WCSession.default()
        
        do
        {
            try defaultSession.updateApplicationContext([:])
        }
        catch let error as NSError
        {
            print("\(error.localizedDescription)")
        }
    }

    // MARK: WatchConnectivityManagerWatchDelegate

    func watchConnectivityManager(_ watchConnectivityManager: WatchConnectivityManager, testConnectivity message: String)
    {
        
    }
}
