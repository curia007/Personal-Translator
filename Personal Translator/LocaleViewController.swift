//
//  LocaleViewController.swift
//  Personal Translator
//
//  Created by Carmelo Uria on 11/9/17.
//  Copyright © 2017 Carmelo I. Uria. All rights reserved.
//

import UIKit

class LocaleViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource
{

    @IBOutlet weak var pickerView: UIPickerView!
    
    var elements: [Locale] = []
    
    private let translator: Translator = Translator()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        translator.supportedLanguages { (data, response, error) in
            
            if (error == nil)
            {
                if (data != nil)
                {
                    do
                    {
                        let json: Any = try JSONSerialization.jsonObject(with: data!, options: [JSONSerialization.ReadingOptions.mutableContainers])
                        
                        debugPrint("<\(#function)> json: \(json)")
                        
                        if let jsonResult = json as? Dictionary<String, Any>
                        {
                            //debugPrint("json: \(jsonResult)")
                            
                            if let dataValue = jsonResult["data"] as? Dictionary<String, Any>
                            {
                                //debugPrint("language codes: \(dataValue)")
                                
                                if let languages = dataValue["languages"] as? [Dictionary<String, Any>]
                                {
                                    for language in languages
                                    {
                                        if let countryCode = language["language"] as? String
                                        {
                                            //debugPrint("countrycode = \(countryCode)")
                                            self.elements.append(Locale(identifier: countryCode))
                                        }
                                    }
                                    
                                    
                                }
                                
                                OperationQueue.main.addOperation {
                                    self.pickerView.reloadAllComponents()
                                }
                            }
                        }
                    }
                    catch let jsonError
                    {
                        print("<#function> \(jsonError)")
                    }
                }
            }
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: - UIPickerViewDelegate methods
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        let locale: Locale = elements[row]
        
        return Locale.current.localizedString(forLanguageCode: locale.languageCode!)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        debugPrint("<\(#function)>")
    }
    
    // MARK: - UIPickerViewDataSource methods
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        debugPrint("<\(#function)>")
        
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        debugPrint("\(#function)")
        
        return elements.count
    }

}
