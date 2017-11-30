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
    private let IBM_USERNAME: String = ""
    private let IBM_PASSWORD: String = ""
    
    private let GOOGLE_RECOGNIZE_URL: String = "https://speech.googleapis.com/v1/speech:recognize?key"
    private let IBM_RECOGNIZE_URL: String = "https://stream.watsonplatform.net/speech-to-text/api/v1/recognize"
    
    func recognize(_ data: Data, locale: Locale, completionHandler: @escaping ((Data?, URLResponse?, Error?)) -> Void)
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
            
                let content: [String : Any] = ["audio" : audio, "config" : config]
            
                if (JSONSerialization.isValidJSONObject(content) == true)
                {
                    debugPrint("JSON is valid")
                }
                
                debugPrint("<\(#function)> content: \(content)")
                
                do
                {
                    let jsonData: Data = try JSONSerialization.data(withJSONObject: content, options: .sortedKeys)
            
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
    
    func recognize(_ model : String,  locale: Locale, data: Data, completionHandler: @escaping ((Data?, URLResponse?, Error?)) -> Void)
    {
        //https://stream.watsonplatform.net/speech-to-text/api/v1/recognize?model=en-US_NarrowbandModel&inactivity_timeout=30000

        if let languageCode: String = locale.languageCode
        {
            let languageModel : String = languageCode + "_" + model

            debugPrint("<\(#function)> model: \(languageModel)")

            let urlString : String = IBM_RECOGNIZE_URL + "&inactivity_timeout=30000"
            if let url: URL = URL(string: urlString)
            {

                let authorization: String = "Basic " + IBM_USERNAME + ":" + IBM_PASSWORD
                var request: URLRequest = URLRequest(url: url)
                request.httpMethod = "POST"
            
                request.addValue(authorization, forHTTPHeaderField: "Authorization")
                request.addValue("audio/basic", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
            
                let content: [String] = [data.base64EncodedString()]
                
                if (JSONSerialization.isValidJSONObject(content) == true)
                {
                    debugPrint("JSON is valid")
                }
                
                debugPrint("<\(#function)> content: \(content)")
            
                do
                {
                    let jsonData: Data = try JSONSerialization.data(withJSONObject: content, options: .sortedKeys)
                    
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
        configuration["sampleRateHertz"] = 44100
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
