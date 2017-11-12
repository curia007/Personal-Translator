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

    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var pickerView: UIPickerView!
    
    var elements: [String] = []
    
    private let translator: Translator = Translator()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        pickerView.showsSelectionIndicator = true
        
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
                                            self.elements.append(countryCode)
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
    


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        debugPrint("<\(#function)> identifier: \(String(describing: segue.identifier))")
        
        if (segue.identifier == "UnwindSegueIdentifier")
        {
            if let mainViewController: MainViewController = segue.destination as? MainViewController
            {
                let index: Int = pickerView.selectedRow(inComponent: 0)
                mainViewController.currentLocale = Locale(identifier: elements[index])
            }
        }
    }
    

    // MARK: - UIPickerViewDelegate methods
    
    //func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    //{
    //    return Locale.current.localizedString(forLanguageCode: elements[row])
    //}
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        debugPrint("<\(#function)> elements[\(row)]: \(elements[row])")
        //self.dismiss(animated: true) {
        //    debugPrint("<\(#function)> dismissing picker")
            //self.performSegue(withIdentifier: "TEST", sender: nil)
        //}
        doneButton.isHidden = false
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString?
    {
        if let countryString: String = Locale.current.localizedString(forLanguageCode: elements[row])
        {
            let attributes: [NSAttributedStringKey : Any] = [NSAttributedStringKey.foregroundColor : UIColor.white, NSAttributedStringKey.font : UIFont.preferredFont(forTextStyle: .largeTitle)]
            let country: NSAttributedString = NSAttributedString(string: countryString, attributes: attributes)
            
            return country
        }
        
        return NSAttributedString(string: elements[row])
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
