//
//  Translator.swift
//  Personal Translator
//
//  Created by Carmelo I. Uria on 8/15/16.
//  Copyright © 2016 Carmelo I. Uria. All rights reserved.
//

import Foundation

class Translator
{
    private var sessionDataTask: URLSessionDataTask?
    private let session:  URLSession = URLSession(configuration: URLSessionConfiguration.default)
    
    private let GOOGLE_API_KEY: String = "AIzaSyApcfHFfHx8th-mIZkGJZcNQrHBMLsx7CU"
    private let GOOGLE_URL: String = "https://translation.googleapis.com/language/translate/v2?key"
    private let GOOGLE_SUPPORTED_LANGUAGES = "https://translation.googleapis.com/language/translate/v2/languages?key"
    
    func translate(text: String, source: String, target: String, completionHandler: @escaping ((Data?, URLResponse?, Error?)) -> Void)
    {
        // convert text
        let urlText: String = text.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        if let url: URL = self.googleTranslate(text: urlText, source: source, target: target)
        {
            self.sessionDataTask = self.session.dataTask(with: url, completionHandler: completionHandler)
            sessionDataTask?.resume()
        }
        
    }
    
    func supportedLanguages(_ completionHandler: @escaping ((Data?, URLResponse?, Error?)) -> Void)
    {
        if let url = URL(string: GOOGLE_SUPPORTED_LANGUAGES + "=" + GOOGLE_API_KEY)
        {
            self.sessionDataTask = self.session.dataTask(with: url, completionHandler: completionHandler)
            sessionDataTask?.resume()
        }
        
    }
    
    private func googleTranslate(text: String, source: String, target: String) -> URL?
    {
        
        let urlString: String = GOOGLE_URL + "=" + GOOGLE_API_KEY + "&source=\(source)" + "&model=nmt&target=\(target)&q=\(text)"
        if let url: URL = URL(string: urlString)
        {
            return url
        }
    
        return nil
    }
    
    private func bluemixTranslate(text: String, source: String, target: String) -> URL?
    {
        return nil
    }
}
