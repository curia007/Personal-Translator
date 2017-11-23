//
//  SpeechProcessor.swift
//  Personal Translator Watch Extension
//
//  Created by Carmelo Uria on 11/19/17.
//  Copyright © 2017 Carmelo I. Uria. All rights reserved.
//

import Foundation

class SpeechProcessor
{
    private var sessionDataTask: URLSessionDataTask?
    private let session:  URLSession = URLSession(configuration: URLSessionConfiguration.default)
    
    private let GOOGLE_API_KEY: String = "AIzaSyApcfHFfHx8th-mIZkGJZcNQrHBMLsx7CU"
    private let GOOGLE_OAUTH_URL: String = "https://www.googleapis.com/auth/cloud-platform"
    private let GOOGLE_RECOGNIZE_URL: String = "https://speech.googleapis.com/v1/speech:recognize?key"

    func recognize(data: Data, locale: Locale, completionHandler: @escaping ((Data?, URLResponse?, Error?)) -> Void)
    {
        let urlString : String = GOOGLE_RECOGNIZE_URL + "=" + GOOGLE_API_KEY
        if let url: URL = URL(string: urlString)
        {
            var request: URLRequest = URLRequest(url: url)
            request.httpMethod = "POST"
            
            if let languagueCode: String = locale.languageCode
            {
                let config: [String : Any] = createConfigOjbect(languagueCode)
                let audio: [String : Any] = createAudioObject(data)
            
                let content: [String : Any] = ["config" : config, "audio" : audio]
            
                debugPrint("<#function> content: \(content)")
                
                do
                {
                    let jsonData: Data = try JSONSerialization.data(withJSONObject: content, options: .prettyPrinted)
            
                        request.httpBody = jsonData
                }
                catch
                {
                    print("<\(#function)> error: \(error)")
                    return
                }
            
                self.sessionDataTask = self.session.dataTask(with: request, completionHandler: completionHandler)
                sessionDataTask?.resume()
            }
        }
    }
    
    // MARK: - private methods
    
    private func createConfigOjbect(_ languageCode: String) -> [String : Any]
    {
        var configuration: [String : Any] = [:]
        
        configuration["encoding"] = "LINEAR16"
        configuration["sampleRateHertz"] = 1600
        configuration["languageCode"] = languageCode
        
        return configuration
    }
    
    private func createAudioObject(_ data : Data) -> [String : Any]
    {
        var audio: [String : Any] = [:]
        audio["content"] = data.base64EncodedString()
        
        return audio
    }
}
