//
//  SpeechProcessor.swift
//  Personal Translator
//
//  Created by Carmelo I. Uria on 9/10/16.
//  Copyright © 2016 Carmelo I. Uria. All rights reserved.
//

import Foundation

import AVFoundation

class SpeechProcessor
{
    private let speechSynthesizer: AVSpeechSynthesizer = AVSpeechSynthesizer()
    
    init()
    {
        
    }
    
    init(locale: Locale)
    {
        
    }
    
    func speck(text: String)
    {
        let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: text)
        self.speechSynthesizer.speak(speechUtterance)
    }
    
}
