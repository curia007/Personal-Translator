//
//  SpeakViewController.swift
//  Personal Translator
//
//  Created by Carmelo Uria on 11/9/17.
//  Copyright © 2017 Carmelo I. Uria. All rights reserved.
//

import UIKit
import Speech

import AudioKit
import AudioKitUI

class SpeakViewController: UIViewController, SFSpeechRecognitionTaskDelegate
{

    @IBOutlet weak var outputPlot: EZAudioPlot!
    
    var currentLocale: Locale = Locale.current
    
    private let speechProcessor: SpeechProcessor = SpeechProcessor()
    
    private let microphone: AKMicrophone = AKMicrophone()
    
    private var tracker: AKFrequencyTracker!
    private var silence: AKBooster!

    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        AKSettings.audioInputEnabled = true
        tracker = AKFrequencyTracker(microphone)
        silence = AKBooster(tracker, gain: 0)

        do
        {
            try speechProcessor.startRecording(Locale.current, target: currentLocale)
        }
        catch
        {
            print("<\(#function)> error: \(error)")
        }
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        AudioKit.output = silence
        AudioKit.start()
        setupPlot()
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
        AudioKit.stop()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setupPlot()
    {
        let plot: AKNodeOutputPlot = AKNodeOutputPlot(microphone, frame: outputPlot.bounds)
        plot.plotType = .buffer
        plot.shouldFill = true
        plot.shouldMirror = true
        plot.color = UIColor.blue
        plot.gain = 3.0
        plot.backgroundColor = UIColor.clear
        outputPlot.addSubview(plot)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: - SFSpeechRecognitionTaskDelegate methods
    
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool)
    {
        debugPrint("<>\(#function) successfully: \(successfully)")
    }
    
    func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask)
    {
        debugPrint("<\(#function)> task: \(task)")

    }
    
    func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask)
    {
        debugPrint("<\(#function)> task: \(task)")

    }
    
    func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask)
    {
        debugPrint("<\(#function)>")
    }
    
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult)
    {
        debugPrint("<\(#function)> recognition result: \(recognitionResult)")
    }
}
