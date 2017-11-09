//
//  SpeechProcessor.swift
//  Personal Translator
//
//  Created by Carmelo I. Uria on 9/10/16.
//  Copyright © 2016 Carmelo I. Uria. All rights reserved.
//

import Foundation

import AVFoundation
import Speech

class SpeechProcessor : NSObject, SFSpeechRecognizerDelegate
{
    private let voiceSynthesizer: AVSpeechSynthesizer = AVSpeechSynthesizer()
    private let audioEngine = AVAudioEngine()

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private var locale: Locale?

    override init()
    {
        self.locale = Locale.current
        self.speechRecognizer = SFSpeechRecognizer(locale: self.locale!)
    }
    
    init(locale: Locale)
    {
        super.init()
        
        self.locale = locale
        self.speechRecognizer = SFSpeechRecognizer(locale: self.locale!)
        
        do
        {
            try setup()
        }
        catch
        {
            
        }
    }
    
    public func speak(text: String)
    {
        let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: text)
        self.voiceSynthesizer.speak(speechUtterance)
    }
    
    public func speak(_ text: String, locale : Locale)
    {
        let deviceLocale: Locale = Locale.current
        let translator : Translator = Translator()
        
        var source: String = "en"
        var target: String = "en"
        
        if (deviceLocale.languageCode != nil)
        {
            source = deviceLocale.languageCode!
        }
        
        if (locale.languageCode != nil)
        {
            target = locale.languageCode!
        }
        
        if (source == target)
        {
            speak(text: text)
            return
        }
        
        translator.translate(text: text, source: source, target: target) { (data, response, error) in
            if (error == nil)
            {
                if (data != nil)
                {
                    do {
                        var json: Any?
                        
                        try json = JSONSerialization.jsonObject(with: data!, options: [JSONSerialization.ReadingOptions.mutableContainers])
                        
                        if let jsonResult = json as? Dictionary<String, Any>
                        {
                            debugPrint("json: \(jsonResult)")
                            
                            if let dataValue = jsonResult["data"] as? Dictionary<String, Any>
                            {
                                debugPrint("translation: \(dataValue)")
                                
                                if let translations = dataValue["translations"] as? [Dictionary<String, Any>]
                                {
                                    for translation in translations
                                    {
                                        if let translatedText = translation["translatedText"] as? String
                                        {
                                            debugPrint("translatedText = \(translatedText)")
                                            self.speak(text: translatedText)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    catch let jsonError
                    {
                        print(jsonError)
                    }
                    
                }
            }
            else
            {
                debugPrint("error:  \(error.debugDescription)")
            }

        }
    }
    
    public func recognizeSpeech() throws
    {
        // Cancel the previous task if it's running.
        if let recognitionTask = recognitionTask
        {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        // Configure request so that results are returned before audio recording is finished
        recognitionRequest.shouldReportPartialResults = true
        
        // A recognition task represents a speech recognition session.
        // We keep a reference to the task so that it can be cancelled.
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            var text: String = ""
            
            if let result = result
            {
                text = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if (error != nil || isFinal)
            {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                do
                {
                    try audioSession.setCategory(AVAudioSessionCategoryPlayback)
                    let translator: Translator = Translator()

                    translator.translate(text: text, source: "en", target: "es", completionHandler: { (data, response, error) in
                        if (error == nil)
                        {
                            if (data != nil)
                            {
                                do {
                                    var json: Any?
                                    
                                    try json = JSONSerialization.jsonObject(with: data!, options: [JSONSerialization.ReadingOptions.mutableContainers])
                                    
                                    if let jsonResult = json as? Dictionary<String, Any>
                                    {
                                        debugPrint("json: \(jsonResult)")
                                        
                                        if let dataValue = jsonResult["data"] as? Dictionary<String, Any>
                                        {
                                            debugPrint("translation: \(dataValue)")
                                            
                                            if let translations = dataValue["translations"] as? [Dictionary<String, Any>]
                                            {
                                                for translation in translations
                                                {
                                                    if let translatedText = translation["translatedText"] as? String
                                                    {
                                                        debugPrint("translatedText = \(translatedText)")
                                                        self.speak(text: translatedText)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                catch let jsonError
                                {
                                    print(jsonError)
                                }
                                
                            }
                        }
                        else
                        {
                            debugPrint("error:  \(error.debugDescription)")
                        }

                        })
                 }
                catch let error
                {
                    print(error)
                }

            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        try audioEngine.start()
        
    }

    public func recognizeFile(url: URL)
    {
        guard let recognizer = SFSpeechRecognizer() else {
            // A recognizer is not supported for the current locale
            return
        }
        
        if !recognizer.isAvailable
        {
            // The recognizer is not available right now
            return
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        recognizer.recognitionTask(with: request) { (result, error) in
            guard let result = result else {
                // Recognition failed, so check error for details and handle it
                return
            }
            
            if result.isFinal
            {
                // Print the speech that has been recognized so far
                debugPrint("Speech in the file is \(result.bestTranscription.formattedString)")
                
                let translator: Translator = Translator()
                
                translator.translate(text: result.bestTranscription.formattedString, source: "en", target: "es", completionHandler: { (data, response, error) in
                    if (error == nil)
                    {
                        if (data != nil)
                        {
                            do {
                                var json: Any?
                                
                                try json = JSONSerialization.jsonObject(with: data!, options: [JSONSerialization.ReadingOptions.mutableContainers])
                                
                                if let jsonResult = json as? Dictionary<String, Any>
                                {
                                    debugPrint("json: \(jsonResult)")
                                    
                                    if let dataValue = jsonResult["data"] as? Dictionary<String, Any>
                                    {
                                        debugPrint("translation: \(dataValue)")
                                        
                                        if let translations = dataValue["translations"] as? [Dictionary<String, Any>]
                                        {
                                            for translation in translations
                                            {
                                                if let translatedText = translation["translatedText"] as? String
                                                {
                                                    debugPrint("translatedText = \(translatedText)")
                                                    self.speak(text: translatedText)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            catch let jsonError
                            {
                                print(jsonError)
                            }
                            
                        }
                    }
                    else
                    {
                        debugPrint("error:  \(error.debugDescription)")
                    }
                    
                    
                })

            }
        }
    }

    private func authorize()
    {
        SFSpeechRecognizer.requestAuthorization { (status) in
            
            /*
             The callback may not be called on the main thread. Add an
             operation to the main queue to update the record button's state.
             */
            OperationQueue.main.addOperation {
                switch status
                {
                case .authorized:
                    //self.recordButton.isEnabled = true
                    break
                case .denied:
                    //self.recordButton.isEnabled = false
                    //self.recordButton.setTitle("User denied access to speech recognition", for: .disabled)
                    break
                case .restricted:
                    //self.recordButton.isEnabled = false
                    //self.recordButton.setTitle("Speech recognition restricted on this device", for: .disabled)
                    break
                case .notDetermined:
                    //self.recordButton.isEnabled = false
                    //self.recordButton.setTitle("Speech recognition not yet authorized", for: .disabled)
                    break
                }
            }
        }
    }
    
    private func setup() throws
    {
        let audioSession = AVAudioSession.sharedInstance()
        
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        // Configure request so that results are returned before audio recording is finished
        recognitionRequest.shouldReportPartialResults = true
        
        // A recognition task represents a speech recognition session.
        // We keep a reference to the task so that it can be cancelled.
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            
            let isFinal = false
            
            if result != nil
            {
            }
            
            if error != nil || isFinal
            {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
            
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime)in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        try audioEngine.start()
       
        self.recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (SFSpeechRecognitionResult, error) in
            debugPrint("")
        })
    }
    
    // MARK: - SFSpeechRecognizerDelegate Method
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool)
    {
        if (available == true)
        {
            debugPrint("\(#function):  availability did change")
        }
        else
        {
            debugPrint("\(#function) availability DID NOT change")
        }
    }
}
