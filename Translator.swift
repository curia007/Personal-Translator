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
    
    private let GOOGLE_API_KEY: String = "AIzaSyCPAhE8Nc1sUEqEcVgLG6rfvgfEIaEi55M"
    private let GOOGLE_URL: String = "https://www.googleapis.com/language/translate/v2?key="
    
    
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
        // API Key:  AIzaSyDJqoIr8wHi8E8Rpiyuk4MevQKhdF8iQwY
        // source language: en (location)
        // target language:
        //www.googleapis.com/language/translate/v2?key=AIzaSyDJqoIr8wHi8E8Rpiyuk4MevQKhdF8iQwY&source=en&target=es&q=Hello world
        
        let urlString: String = GOOGLE_URL + GOOGLE_API_KEY + "&source=\(source)" + "&target=\(target)&q=\(text)"
        let url: URL? = URL(string: urlString)
        
        return url!
    }
    
    private func bluemixTranslate(text: String, source: String, target: String) -> URL?
    {
        return nil
    }
}
