//
//  ViewController.swift
//  Personal Translator
//
//  Created by Carmelo I. Uria on 6/26/16.
//  Copyright © 2016 Carmelo I. Uria. All rights reserved.
//

import UIKit
import AVFoundation
import ImageIO
import CoreGraphics

import WatchConnectivity

import CoreLocation

extension CIImage
{
    
    var imageScale: CGSize? {
        
        let s = 1.0
        
        return CGSize(width:s, height:s)
        
    }
}

extension CGImage
{
    
}

extension CGFloat
{
    var degreesToRadians: Double { return Double(self) * .pi / 180 }
    var radiansToDegrees: Double { return Double(self) * 180 / .pi }
}

extension FloatingPoint
{
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, WatchConnectivityManagerPhoneDelegate, G8TesseractDelegate
{
    let dispathQueue: DispatchQueue = DispatchQueue(label: "ImageQueue")

    var detector: CIDetector?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var timer: Timer?
    var images: [CIImage] = []
    var testImage: CIImage? = nil
    
    private var captureDevice : AVCaptureDevice?
    private var captureVideoDataOutput: AVCaptureVideoDataOutput?
    private var captureMovieFileOutput: AVCaptureMovieFileOutput!
    private let captureSession = AVCaptureSession()
 
    private let tesseract: G8Tesseract = G8Tesseract()
    
    private var session: WCSession?

    private let locationManager: CLLocationManager = CLLocationManager()
    
    private var drawLayer: CAShapeLayer?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Loop through all the capture devices on this phone
        let devices: [Any] = self.devices()
        
        for device in devices
        {
            // Make sure this particular device supports video
            if ((device as AnyObject).hasMediaType(AVMediaTypeVideo))
            {
                // Finally check the position and confirm we've got the back camera
                if((device as AnyObject).position == AVCaptureDevicePosition.back)
                {
                    captureDevice = device as? AVCaptureDevice
                }
            }
        }
        
        if (captureDevice != nil)
        {
            beginSession()
        }
        
        // The `WatchConnectivityManager` will provide tailored callbacks to its delegate.
        WatchConnectivityManager.sharedConnectivityManager.delegate = self

        self.detector = CIDetector(ofType: CIDetectorTypeText, context: nil, options: [CIDetectorAccuracy : CIDetectorAccuracyHigh, CIDetectorImageOrientation : Int(1)])
        
        self.timer = Timer(timeInterval: 10, repeats: true, block: { (timer) in
            let superLayer: CALayer? = self.previewLayer?.superlayer
            
            if (self.images.count > 0)
            {
                debugPrint("OCR image count:  \(self.images.count)")
                self.performImageRecognition(images: self.images)
                self.images = []
            }
            
            if (self.previewLayer == nil)
            {
                return
            }
            
            self.removePreviousFeatures(layer: self.previewLayer!)
            
            if (superLayer != nil)
            {
                self.removePreviousFeatures(layer: superLayer!)
            }
            
         })
        
        self.tesseract.delegate = self
        
        RunLoop.main.add(timer!, forMode: .defaultRunLoopMode)
        
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(
            alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
                let deltaTransform = coordinator.targetTransform
                let deltaAngle = atan2f(Float(deltaTransform.b), Float(deltaTransform.a))
                var currentRotation : Float = ((self.previewLayer!.value(forKeyPath: "transform.rotation.z") as AnyObject).floatValue)!
                // Adding a small value to the rotation angle forces the animation to occur in a the desired direction, preventing an issue where the view would appear to rotate 2PI radians during a rotation from LandscapeRight -> LandscapeLeft.
                currentRotation += -1 * deltaAngle + 0.0001;
                self.previewLayer!.setValue(currentRotation, forKeyPath: "transform.rotation.z")
                self.previewLayer!.frame = self.view.bounds
            },
            completion:
            { (UIViewControllerTransitionCoordinatorContext) in
                // Integralize the transform to undo the extra 0.0001 added to the rotation angle.
                var currentTransform : CGAffineTransform = self.view!.transform
                currentTransform.a = round(currentTransform.a)
                currentTransform.b = round(currentTransform.b)
                currentTransform.c = round(currentTransform.c)
                currentTransform.d = round(currentTransform.d)
                self.view!.transform = currentTransform
        })
        
    }
    
    func imageOrientationToExif(orientation: AVCaptureVideoOrientation) -> UIImageOrientation
    {
        switch orientation
        {
        case .landscapeLeft:
            return UIImageOrientation.left
        case .landscapeRight:
            return UIImageOrientation.right
        case .portrait:
            return UIImageOrientation.up
        case .portraitUpsideDown:
            return UIImageOrientation.down
        }
    }
    
    @nonobjc func performImageRecognition(images: [CIImage])
    {
        self.tesseract.language = "eng"
        self.tesseract.engineMode = .tesseractCubeCombined
        self.tesseract.pageSegmentationMode = .auto
        self.tesseract.maximumRecognitionTime = 60.0

        for ciimage in images
        {
            let ciContext: CIContext = CIContext()
            let cgImage: CGImage = ciContext.createCGImage(ciimage, from: ciimage.extent)!
            
            let displayImage: UIImage = UIImage(cgImage: cgImage)
            
            tesseract.image = displayImage
            
            let isRecognized: Bool = tesseract.recognize()
            
            if (isRecognized)
            {
                debugPrint("\(#function):  image is recognized [text: \(tesseract.recognizedText)]")
            }
            
        }
        
    }

    // called asynchronously as the capture output is capturing sample buffers, this method asks the face detector
    // to detect features and for each draw the red border in a layer and set appropriate orientation
    func draw (features: [CIFeature], image: CIImage, cleanAperture: CGRect, orientation: UIDeviceOrientation) -> [CIImage]
    {
        let sublayers: [CALayer]? = self.previewLayer?.sublayers
        var currentSublayer: Int = 0
        var currentFeature: Int = 0
        let sublayersCount: Int? = sublayers?.count
        let featuresCount: Int = features.count
        
        var textImages: [CIImage]? = []
        
        // hide all the face layers
        if (sublayers == nil)
        {
            return textImages!
        }
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        if (featuresCount == 0)
        {
            CATransaction.commit()
            
            return textImages!
        }
        
        let parentFrameSize: CGSize = self.view.frame.size
        let gravity: String? = self.previewLayer?.videoGravity
        let isMirrored: Bool? = previewLayer?.connection.isVideoMirrored
        let previewBox: CGRect = self.videoPreviewBoxForGravity(gravity: gravity!, frameSize: parentFrameSize, apertureSize: cleanAperture.size)
        
        for textFeature in features
        {
            if (textFeature.isKind(of: CITextFeature.self) == false)
            {
                continue
            }
            
            var textRect = textFeature.bounds
            
            var temp: CGFloat = textRect.size.width
            textRect.size.width = textRect.size.height
            textRect.size.height = temp
            
            temp = textRect.origin.x
            textRect.origin.x = textRect.origin.y
            textRect.origin.y = temp
            
            let widthScaleBy: CGFloat = previewBox.size.width / cleanAperture.size.height
            let heightScaleBy: CGFloat = previewBox.size.height / cleanAperture.size.width
            
            textRect.size.width *= widthScaleBy
            textRect.size.height *= heightScaleBy
            
            textRect.origin.x *= widthScaleBy
            textRect.origin.y *= heightScaleBy
            
            if (isMirrored == true)
            {
                textRect = textRect.offsetBy(dx: previewBox.origin.x + previewBox.size.width - textRect.size.width - (textRect.origin.x * 2), dy: previewBox.origin.y)
            }
            else
            {
                textRect = textRect.offsetBy(dx: previewBox.origin.x, dy: previewBox.origin.y)
            }
            
            var featureLayer:CALayer? = nil
            
            // re-use an existing layer if possible
            while ((featureLayer == nil) && (currentSublayer < sublayersCount!))
            {
                let currentLayer: CALayer = sublayers![currentSublayer]
                currentSublayer = currentSublayer + 1
                
                if (currentLayer.name == "TextLayer")
                {
                    featureLayer = currentLayer
                    currentLayer.isHidden = false
                }
            }
            
            if (featureLayer == nil)
            {
                featureLayer = CALayer()
                featureLayer?.contents = UIImage(named: "squarePNG")?.cgImage
                featureLayer?.name = "TextLayer"
                self.previewLayer?.addSublayer(featureLayer!)
            }
            
            featureLayer?.frame = textRect
            
            switch orientation
            {
            case .portrait:
                featureLayer?.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(0.0).degreesToRadians))
                break
            case .portraitUpsideDown:
                featureLayer?.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(180.0).degreesToRadians))
                break
            case .landscapeLeft:
                featureLayer?.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(90.0).degreesToRadians))
                break
            case .landscapeRight:
                featureLayer?.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(-90.0).degreesToRadians))
                break
            case .faceUp:
                break
            case .faceDown:
                break
            default:
                break
            }
            
            currentFeature += 1

            let textImage: CIImage = image.cropping(to: textFeature.bounds)
            textImages?.append(textImage)
        }
        
        CATransaction.commit()

        return textImages!
    }
    
    // MARK: - private methods
    
    private func removePreviousFeatures(layer: CALayer)
    {
        let layers: [CALayer]? = layer.sublayers
        
        if (layers == nil)
        {
            return
        }
        
        for sublayer in layers!
        {
             if (sublayer.name == "TextLayer")
            {
                sublayer.removeFromSuperlayer()
            }
            
            sublayer.removeAllAnimations()
        }
    }
    
    private func scaleImage(image: UIImage, maxDimension: CGFloat) -> UIImage
    {
        
        var scaledSize = CGSize(width: maxDimension, height: maxDimension)
        
        var scaleFactor:CGFloat
        
        if image.size.width > image.size.height
        {
            scaleFactor = image.size.height / image.size.width
            scaledSize.width = maxDimension
            scaledSize.height = scaledSize.width * scaleFactor
        }
        else
        {
            scaleFactor = image.size.width / image.size.height
            scaledSize.height = maxDimension
            scaledSize.width = scaledSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        
        image.draw(in: CGRect(x: 0, y: 0, width: scaledSize.width, height: scaledSize.height))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }

    private func startLocationManager()
    {
        // retrieve babysitter location
        let authorizationStatus:CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        
        if ((authorizationStatus == .denied) ||
            (authorizationStatus == .restricted) ||
            (authorizationStatus == .notDetermined))
            
        {
            self.locationManager.requestWhenInUseAuthorization()
        }
        
        self.locationManager.startMonitoringSignificantLocationChanges()
    }

    private func devices() -> [Any]
    {
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        let devices = AVCaptureDevice.devices()
        print(devices)
        
        return devices!
    }
    
    private func beginSession()
    {
        
        do
        {
            configureDevice()
            let captureDeviceInput: AVCaptureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(captureDeviceInput)
            
        }
        catch
        {
            print("\(#function)::  error: \(error)")
        }
        
        // Make a video data output
        self.captureVideoDataOutput = AVCaptureVideoDataOutput()
        
        // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
        self.captureVideoDataOutput?.videoSettings =  [kCVPixelBufferPixelFormatTypeKey as AnyHashable : NSNumber.init(value: kCMPixelFormat_32BGRA)]
        self.captureVideoDataOutput?.alwaysDiscardsLateVideoFrames = true
        self.captureVideoDataOutput?.setSampleBufferDelegate(self, queue: self.dispathQueue)
        
        if (self.captureSession.canAddOutput(self.captureVideoDataOutput) == true)
        {
            self.captureSession.addOutput(self.captureVideoDataOutput)
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = self.view.layer.bounds
        previewLayer?.needsDisplayOnBoundsChange = true
        previewLayer?.masksToBounds = true
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        self.view.layer.addSublayer(previewLayer!)
        
        captureSession.startRunning()
    }
    
    private func configureDevice()
    {
        if let device = captureDevice
        {
            do
            {
                try device.lockForConfiguration()
                device.focusMode = .continuousAutoFocus
                device.unlockForConfiguration()
               
            }
            catch
            {
                print("\(#function):  error:  \(error)")
            }
        }
    }
    
    private func focusTo(_ value : Float)
    {
        if let device = captureDevice
        {
            do
            {
                
                try device.lockForConfiguration()
                
                device.setFocusModeLockedWithLensPosition(value, completionHandler: { (time) -> Void in
                    
                })
                
                device.unlockForConfiguration()
            }
            catch
            {
                
            }
            
        }
    }
    
    /*
    private func initializeSession() -> WCSession?
    {
        if WCSession.isSupported()
        {
            let session = WCSession.default()
            session.delegate = self
            session.activate()
            
            return session
        }
        
        return nil
    }
    */
    
    private func applyFeatures(features: [CIFeature]?, aperture: CGRect)
    {
        if (features == nil)
        {
            return
        }
        
        if (features?.count == 0)
        {
            return
        }
        
        debugPrint("\(#function):  features: \(features) [aperture: \(aperture)")
        
        for feature in features!
        {
            let textFeature: CITextFeature = feature as! CITextFeature
            debugPrint("\(#function) feature -> \(textFeature.subFeatures)")
            
            if ((textFeature.subFeatures != nil) && ((textFeature.subFeatures?.count)! > 0))
            {
                for subFeature in textFeature.subFeatures!
                {
                    debugPrint("subFeature -> \(subFeature)")
                }
            }
        }
    }
    
    private func videoPreviewBoxForGravity(gravity: String, frameSize: CGSize, apertureSize: CGSize) -> CGRect
    {
        let apertureRatio: CGFloat = apertureSize.height / apertureSize.width
        let viewRatio: CGFloat = frameSize.width / frameSize.height
        
        var size: CGSize = CGSize.zero
        
        if (gravity == AVLayerVideoGravityResizeAspectFill)
        {
            if (viewRatio > apertureRatio)
            {
                size.width = frameSize.width
                size.height = frameSize.width * (frameSize.width / apertureSize.height)
            }
            else
            {
                size.width = apertureSize.height * (frameSize.height / apertureSize.width)
                size.height = frameSize.height
            }
        }
        else if (gravity == AVLayerVideoGravityResizeAspect)
        {
            if (viewRatio > apertureRatio)
            {
                size.width = apertureSize.height * (frameSize.height / apertureSize.width)
                size.height = frameSize.height
            }
            else
            {
                size.width = frameSize.width
                size.height = apertureSize.width * (frameSize.width / apertureSize.height)
            }
        }
        else if (gravity == AVLayerVideoGravityResize)
        {
            size.width = frameSize.width
            size.height = frameSize.height
        }
        
        var videoBox: CGRect = CGRect()
        videoBox.size = size
        
        if (size.width < frameSize.width)
        {
            videoBox.origin.x = (frameSize.width - size.width) / 2
        }
        else
        {
            videoBox.origin.x = (size.width - frameSize.width) / 2
        }
        
        if ( size.height < frameSize.height )
        {
            videoBox.origin.y = (frameSize.height - size.height) / 2
        }
        else
        {
            videoBox.origin.y = (size.height - frameSize.height) / 2
        }
        
        return videoBox;
        
    }
    
    // MARK: - WCSessionDelegate methods
    
    @available(iOS 9.3, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: NSError?)
    {
        debugPrint("\(#function):  activationDidCompleteWithState...")
    }
    
    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: NSError?)
    {
        debugPrint("\(#function):  user data:  \(userInfoTransfer)")
    }
    
    func sessionDidDeactivate(_ session: WCSession)
    {
        
    }
    
    func sessionDidBecomeInactive(_ session: WCSession)
    {
        
    }
    
}

extension ViewController
{
    // MARK: WatchConnectivityManagerDelegate
    
    func watchConnectivityManager(_ watchConnectivityManager: WatchConnectivityManager, updatedWithVideo video: Data)
    {
        DispatchQueue.main.async(execute: {
        })
    }
    
}

extension ViewController
{
    @objc(captureOutput:didOutputSampleBuffer:fromConnection:) func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!)
    {
        //debugPrint("\(#function)")
        
        // get the image
        let pixelBuffer: CVPixelBuffer? = CMSampleBufferGetImageBuffer(sampleBuffer)
        
        let attachmentMode: CMAttachmentMode = CMAttachmentMode(kCMAttachmentMode_ShouldPropagate)
        let attachments : CFDictionary? = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, attachmentMode)! as CFDictionary

        if (pixelBuffer != nil)
        {
            
            //NSDictionary *imageOptions = @{CIDetectorImageOrientation : @(exifOrientation)};
            //NSArray *features = [self.faceDetector featuresInImage:ciImage options:imageOptions];
            
            // make sure your device orientation is not locked.
            //let currentDeviceOrientation: UIDeviceOrientation = UIDevice.current.orientation
            
            let ciImage: CIImage = CIImage(cvPixelBuffer: pixelBuffer!, options: attachments! as? [String : AnyObject])
        
            
            let featureOptions: [String : AnyObject] = [kCGImagePropertyOrientation as String :
                self.imageOrientationToExif(orientation: self.previewLayer!.connection.videoOrientation) as AnyObject]

            //let features: [CIFeature]? = self.detector?.features(in: ciImage)
            let features: [CIFeature]? = self.detector?.features(in: ciImage, options: featureOptions)
            
            if ((features != nil) && (features?.isEmpty != true))
            {
                
                let currentDeviceOrientation: UIDeviceOrientation = UIDevice.current.orientation
                let formatDescription: CMFormatDescription? = CMSampleBufferGetFormatDescription(sampleBuffer)
                
                if (formatDescription != nil)
                {
                    let cleanAperture: CGRect = CMVideoFormatDescriptionGetCleanAperture(formatDescription!, false /*originIsTopLeft == false*/);

                    self.dispathQueue.async {
                        let images: [CIImage] = self.draw(features: features!, image: ciImage, cleanAperture: cleanAperture, orientation: currentDeviceOrientation)
                        debugPrint("number of images: \(images.count)")
                        
                        if (images.count > self.images.count)
                        {
                            self.images = images
                        }
                    }
                }
            }
        }
    }
}
