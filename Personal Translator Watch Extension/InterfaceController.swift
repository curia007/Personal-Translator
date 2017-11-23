//
//  InterfaceController.swift
//  Personal Translator Watch Extension
//
//  Created by Carmelo Uria on 11/8/17.
//  Copyright © 2017 Carmelo I. Uria. All rights reserved.
//

import WatchKit
import Foundation

import AVFoundation

class InterfaceController: WKInterfaceController
{

    @IBOutlet var interfaceScene: WKInterfaceSCNScene!
    
    private var scene: SCNScene!
    
    private var speechSynthesisVoice : AVSpeechSynthesisVoice?
    
    private var currentLocale : Locale = Locale.current

    private let speechSynthesizer: AVSpeechSynthesizer = AVSpeechSynthesizer()
    private let speechProcessor: SpeechProcessor = SpeechProcessor()

    override func awake(withContext context: Any?)
    {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        speechSynthesisVoice = AVSpeechSynthesisVoice(identifier: currentLocale.languageCode!)
        
        // TEST
        let utterance: AVSpeechUtterance = AVSpeechUtterance(string: "Bond, James Bond")
        utterance.voice = speechSynthesisVoice
        speechSynthesizer.speak(utterance)
        
        setupView()
        setupScene()
        setupFire()
        
        let fileManager: FileManager = FileManager.default

        let options: [AnyHashable: Any] = [WKAudioRecorderControllerOptionsActionTitleKey: "Translate"]
        let url : URL = URL(string: fileManager.temporaryDirectory.absoluteString + "input.wav")!
        debugPrint("<\(#function)> url: \(url)")
        
        self.presentAudioRecorderController(withOutputURL: url, preset: .highQualityAudio, options: options) { (isComplete, error) in
                debugPrint("<\(#function)> isComplete: \(isComplete) error: \(String(describing: error))")
                if (isComplete)
                {
                    self.speechToText(url.absoluteString)
                }
            
        }
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

    // MARK: - private methods
    
    private func setupView()
    {
        interfaceScene.showsStatistics = false
        interfaceScene.autoenablesDefaultLighting = true
        interfaceScene.delegate = self
        interfaceScene.isPlaying = true
    }
    
    private func setupFire()
    {
        let fire: SCNParticleSystem =
            SCNParticleSystem(named: "fire.scnp", inDirectory:
                nil)!
        
        fire.birthLocation = .surface

        let transform: SCNMatrix4 = SCNMatrix4MakeTranslation(0.0, 0.0, 0.0)
        scene.addParticleSystem(fire, transform: transform)
    }

    private func setupScene()
    {
        scene = SCNScene()
        interfaceScene.scene = scene
    }
    
    private func speechToText(_ file: String)
    {
        guard let url : URL = URL(string: file) else
        {
            print("<\(#function)> file could not be found...")
            return
        }
        
        let fileManager: FileManager = FileManager.default
        guard let data: Data = fileManager.contents(atPath: url.relativePath) else
        {
            print("<\(#function)> file could not be found...")
            return
        }
        
        let locale: Locale = Locale(identifier: "es")
        speechProcessor.recognize(data: data, locale: locale) { (responseData, response, error) in
            if (error == nil)
            {
                if let returnData : Data = responseData
                {
                    do
                    {
                        let json: Any = try JSONSerialization.jsonObject(with: returnData, options: [JSONSerialization.ReadingOptions.mutableContainers])
                    
                        debugPrint("<\(#function)> json: \(json)")
                    }
                    catch
                    {
                        print("<\(#function)> error: \(error)")
                    }
                }
            }
            else
            {
                print("<#function> error: \(String(describing: error))")
            }
        }
    }
}

// MARK: - SCNSceneRendererDelegate Extension

extension InterfaceController: SCNSceneRendererDelegate
{
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
    {
        //debugPrint("<\(#function)> update at time: \(time)")
    }
}

