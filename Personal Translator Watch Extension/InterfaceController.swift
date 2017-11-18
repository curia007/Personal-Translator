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
        
        let fileManager: FileManager = FileManager()

        let options: [AnyHashable: Any] = [WKAudioRecorderControllerOptionsActionTitleKey: "Translate"]
        let url : URL = URL(string: fileManager.temporaryDirectory.absoluteString + "input.wav")!
        self.presentAudioRecorderController(withOutputURL: url, preset: .highQualityAudio, options: options) { (isComplete, error) in
            debugPrint("<\(#function)> isComplete: \(isComplete) error: \(String(describing: error))")
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

}

// MARK: - SCNSceneRendererDelegate Extension

extension InterfaceController: SCNSceneRendererDelegate
{
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
    {
    }
}

