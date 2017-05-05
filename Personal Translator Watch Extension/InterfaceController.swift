//
//  InterfaceController.swift
//  Personal Translator Watch Extension
//
//  Created by Carmelo I. Uria on 8/11/16.
//  Copyright © 2016 Carmelo I. Uria. All rights reserved.
//

import WatchKit
import Foundation
import AVFoundation

import WatchConnectivity

let AAPLAppConfigurationApplicationGroupsPrimary: String = "group.com.carmelouria.Personal-Translator"

class InterfaceController: WKInterfaceController, WatchConnectivityManagerWatchDelegate
{
    @IBOutlet var imageInterface: WKInterfaceImage!
    @IBOutlet var recordButton: WKInterfaceButton!

    private let voiceSynthesizer: AVSpeechSynthesizer = AVSpeechSynthesizer()
    
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

    private func speak(text: String)
    {
        let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: text)
        self.voiceSynthesizer.speak(speechUtterance)
    }

    // MARK: - IBActions
    
    @IBAction private func startRecording()
    {
        let preset: WKAudioRecorderPreset = WKAudioRecorderPreset.narrowBandSpeech
        let recordName: String = "translate.mp4"
        
        let recordingTime: UInt =  UInt(Date.timeIntervalSinceReferenceDate)

        debugPrint("recording time: \(recordingTime)")
        
        // Get the directory from the app group.
        let directory: URL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AAPLAppConfigurationApplicationGroupsPrimary)!

        let outputURL = directory.appendingPathComponent(recordName)
        
        let weakSelf: InterfaceController = self
        
        debugPrint("outputURL: \(outputURL)")
        
        self.presentAudioRecorderController(withOutputURL: outputURL, preset: preset, options: nil) { (didSave, error) in
            let strongSelf: InterfaceController? = weakSelf
            
            if (!(strongSelf != nil))
            {
                return;
            }
            
            if (didSave)
            {
                /*
                 After saving we need to move the file to our documents directory
                 so that WatchConnectivity can transfer it.
                 */
                
                //let extensionDirectory: URL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!
                
                //let outputExtensionURL: URL = extensionDirectory.appendingPathExtension(recordName)
                
                //var moveError: Error
                
                debugPrint("outputURL: \(outputURL)")
                //debugPrint("outputExtensionURL: \(outputExtensionURL)")
                
                // Move the file.
                
                //do
                //{
                //    try FileManager.default.moveItem(at: outputURL, to: outputExtensionURL)
                //}
                //catch
                //{
                //    print("Failed to move the outputURL to the extension's documents direcotry: \(error)")
                //}
                
                //strongSelf.lastRecordingURL = outputExtensionURL;
                
            
                // Activate the session before transferring the file.
                
                //[[WCSession defaultSession] transferFile:outputExtensionURL metadata:nil];
                WCSession.default().transferFile(outputURL, metadata: nil)
                
           }
            
            if (error != nil)
            {
                print("\(#function) There was an error with the audio recording: \(error ?? "A Recording Issue has taken place..." as! Error)")
            }
      
        }
    }
    
    // Mark: - Audio Preset Helpers
    private func audioRecordingPreset(_ pickerItem: WKPickerItem) -> WKAudioRecorderPreset
    {
        return WKAudioRecorderPreset.narrowBandSpeech
    }
    
    // MARK: - WatchConnectivityManagerWatchDelegate

    func watchConnectivityManager(_ watchConnectivityManager: WatchConnectivityManager, translatedMessage message: String)
    {
        debugPrint("\(#function): watchConnectivity message: \(message) ")
        self.speak(text: message)
    }
}
