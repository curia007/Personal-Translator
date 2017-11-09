/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This file contains the `WatchConnectivityManager` class and its delegate which encapsulate the `WatchConnectivity` behavior of the app.
*/

import WatchConnectivity

/**
 The `WatchConnectivityManagerDelegate` protocol enables a `WatchConnectivityManager` object to notify another
 object of changes to the activation state of the default `WCSession`. On iOS the receiver is provided with the
 designator and color selected by the user to identify the watch associated with the default session. On the
 Watch app the receiver is provided with any new morse codes.
 */

protocol WatchConnectivityManagerPhoneDelegate: class
{
    func watchConnectivityManager(_ watchConnectivityManager: WatchConnectivityManager, updatedWithVideo video: Data)
    func watchConnectivityManager(_ watchConnectivityManager: WatchConnectivityManager, testConnectivity message: String)
    func watchConnectivityManager(_ watchConnectivityManager: WatchConnectivityManager, translateText text: String)

    func watchConnectivityManager(_ watchConnectivityManager: WatchConnectivityManager, translate url: URL)

}

protocol WatchConnectivityManagerWatchDelegate: class
{
    func watchConnectivityManager(_ watchConnectivityManager: WatchConnectivityManager, translatedMessage message: String)
}

class WatchConnectivityManager: NSObject, WCSessionDelegate
{
    // MARK: Static Properties
    
    static let sharedConnectivityManager = WatchConnectivityManager()
    
    // MARK: Properties
    
    #if os(iOS)
    weak var delegate: WatchConnectivityManagerPhoneDelegate?
    #else
    weak var delegate: WatchConnectivityManagerWatchDelegate?
    #endif
    
    // MARK: Initialization
    
    private override init()
    {
        super.init()
    }
    
    // MARK: Convenience
    
    func configureDeviceDetailsWithApplicationContext(applicationContext: [String: AnyObject])
    {
        #if os(iOS)
        // Extract relevant values from the application context.
        guard let video = applicationContext["video"] as? Data else {
            // If the expected values are unavailable in the `applicationContext`, inform the delegate using default values.
            //delegate?.watchConnectivityManager(self, updatedWithVideo: nil)
            return
        }
        
        // Inform the delegate.
            delegate?.watchConnectivityManager!(self, updatedWithVideo: video)
        #endif
    }
    
    // MARK: WCSessionDelegate
    @nonobjc func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        print("session (in state: \(session.activationState.rawValue)) received application context \(applicationContext)")
        
        configureDeviceDetailsWithApplicationContext(applicationContext: applicationContext)
        
        // NOTE: The guard is here as `watchDirectoryURL` is only available on iOS and this class is used on both platforms.
        #if os(iOS)
            print("session watch directory URL: \(String(describing: session.watchDirectoryURL?.absoluteString))")
        #endif
    }
    
    @nonobjc func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject] = [:]) {
        #if os(watchOS)
            guard (userInfo["text"] as? Data) != nil else {
                // If the expected values are unavailable in the `userInfo`, then skip it.
                debugPrint("UserInfo does not contain proper dictonary")
                return
            }
            
            // Inform the delegate.
            delegate?.watchConnectivityManager(self, translatedMessage: "Test")
        #else
            debugPrint("\(#function) not watchOS")
        #endif
    }
    
    func session(_ session: WCSession, didReceive file: WCSessionFile)
    {
        debugPrint("Session did receive file: \(file)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any])
    {
        debugPrint("Did get received message")
        #if os(watchOS)
        delegate?.watchConnectivityManager(self, translatedMessage: "James Bond 007")
        #endif
    }
    
    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        if let error = error {
            print("userInfoTransfer Error:  \(error.localizedDescription)")
        } else {
            print("completed userInfoTransfer of \(userInfoTransfer)")
        }
    }
    
    // MARK: WCSessionDelegate - Asynchronous Activation
    
    // The next method is required in order to support asynchronous session activation as well as for quick watch switching.
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("session activation failed with error: \(error.localizedDescription)")
            return
        }
        
        print("session activated with state: \(activationState.rawValue)")
        
        configureDeviceDetailsWithApplicationContext(applicationContext: session.receivedApplicationContext as [String : AnyObject])
        
        // NOTE: The guard is here as `watchDirectoryURL` is only available on iOS and this class is used on both platforms.
        #if os(iOS)
            print("session watch directory URL: \(String(describing: session.watchDirectoryURL?.absoluteString))")
        #endif
    }
    
    #if os(iOS)
    // The next 2 methods are required in order to support quick watch switching.
    func sessionDidBecomeInactive(_ session: WCSession) {
        /*
            The `sessionDidBecomeInactive(_:)` callback indicates sending has been disabled. If your iOS app 
            sends content to its Watch extension it will need to stop trying at this point. This sample 
            doesn’t send content to its Watch Extension so no action is required for this transition.
         */
        
        print("session did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("session did deactivate")
        
        /*
            The `sessionDidDeactivate(_:)` callback indicates `WCSession` is finished delivering content to 
            the iOS app. iOS apps that process content delivered from their Watch Extension should finish
            processing that content and call `activateSession()`. This sample immediately calls 
            `activateSession()` as the data provided by the Watch Extension is handled immediately.
         */
        session.activate()
    }
    #endif
}
