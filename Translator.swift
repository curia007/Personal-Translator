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
    
    private let GOOGLE_API_KEY: String = "API_KEY"
    private let GOOGLE_URL: String = "GOOGLE_URL"
    
    
    func translate(text: String, source: String, target: String, completionHandler: @escaping ((Data?, URLResponse?, Error?)) -> Void)
    {
        // convert text
        let urlText: String = text.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        let url: URL? = self.googleTranslate(text: urlText, source: source, target: target)
        
        if (url != nil)
        {
            self.sessionDataTask = self.session.dataTask(with: url!, completionHandler: completionHandler)
            sessionDataTask?.resume()

        }
        
    }
    
    private func googleTranslate(text: String, source: String, target: String) -> URL?
    {
        
        let urlString: String = GOOGLE_URL + GOOGLE_API_KEY + "&source=\(source)" + "&target=\(target)&q=\(text)"
        let url: URL? = URL(string: urlString)
        
        return url!
    }
    
    private func bluemixTranslate(text: String, source: String, target: String) -> URL?
    {
        return nil
    }
}
