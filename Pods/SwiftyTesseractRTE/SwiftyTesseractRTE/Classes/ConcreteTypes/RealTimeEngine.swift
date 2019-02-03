//
//  RealTimeEngine.swift
//  SwiftyTesseractRTE
//
//  Created by Steven Sherry on 3/5/18.
//  Copyright © 2018 Steven Sherry. All rights reserved.
//

import SwiftyTesseract
import AVFoundation

/// A class to perform real-time optical character recognition
public class RealTimeEngine: NSObject {
  
  // MARK: - Private variables
  /// Used as a container to hold the last N frames OCR results to verify stability of recognition accuracy,
  /// where N is defined by the raw value of the RecognitionReliability set by the user during initialization.
  private var recognitionQueue: RecognitionQueue<String>
  
  // MARK: - Private constants
  private let swiftyTesseract: SwiftyTesseract
  private let imageProcessor: AVSampleProcessor
  private let avManager: AVManager
  
  // MARK: - Public variables
  /// The region within the AVCaptureVideoPreviewLayer that OCR is to be performed. If using a UIView to
  /// define the region of interest this **must** be assigned as the UIView's frame and
  /// be a subview of the the AVCaptureVideoPreviewLayer's parent view.
  public var regionOfInterest: CGRect?

  /// Sets recognition to be running or not. Default is **true**. Setting the value to false will
  /// allow the preview to be active without processing incoming video frames.
  /// If it is not desired for recognition to be active after initialization, set this
  /// value to false immediately after creating an instance of SwiftyTesseractRTE
  public var recognitionIsActive: Bool = true
  
  /// The quality of the previewLayer video session. The default is set to .medium. Changing this
  /// setting will only affect how the video is displayed to the user and will not affect the 
  /// results of OCR if set above `.medium`. Setting the quality higher will result in decreased performance.
  public var cameraQuality: AVCaptureSession.Preset {
    get {
      return avManager.cameraQuality
    }
    set {
      avManager.cameraQuality = newValue
    }
  }
  
  /// Action to be performed after successful recognition
  public var onRecognitionComplete: ((String) -> ())?

  // MARK: Initializers

  /// Primary Initializer - Uses SwiftyTesseractRTE defaults
  /// - Parameters:
  ///   - swiftyTesseract:    Instance of SwiftyTesseract
  ///   - desiredReliability: The desired reliability of the recognition results.
  ///   - cameraQuality:      The desired camera quality output to be seen by the end user. The default is `.medium`.
  ///   Anything higher than `.medium` has no impact on recognition reliability
  ///   - onRecognitionComplete: Action to be performed after successful recognition
  public convenience init(swiftyTesseract: SwiftyTesseract,
                          desiredReliability: RecognitionReliability,
                          cameraQuality: AVCaptureSession.Preset,
                          onRecognitionComplete: ((String) -> ())? = nil) {
    
    let recognitionQueue = RecognitionQueue<String>(desiredReliability: desiredReliability)
    let videoManager = VideoManager(cameraQuality: cameraQuality)
    
    self.init(swiftyTesseract: swiftyTesseract,
              recognitionQueue: recognitionQueue,
              avManager: videoManager,
              onRecognitionComplete: onRecognitionComplete)
  }

  /// - Parameters:
  ///   - swiftyTesseract:    Instance of SwiftyTesseract
  ///   - desiredReliability: The desired reliability of the recognition results.
  ///   - imageProcessor:     Performs conversion and processing from `CMSampleBuffer` to `UIImage`
  ///   - cameraQuality:      The desired camera quality output to be seen by the end user. The default is .medium.
  ///                         Anything higher than .medium has no impact on recognition reliability
  ///   - onRecognitionComplete: Action to be performed after successful recognition
  public convenience init(swiftyTesseract: SwiftyTesseract,
                          desiredReliability: RecognitionReliability,
                          imageProcessor: AVSampleProcessor,
                          cameraQuality: AVCaptureSession.Preset = .medium,
                          onRecognitionComplete: ((String) -> ())? = nil) {
    
    let recognitionQueue = RecognitionQueue<String>(desiredReliability: desiredReliability)
    let avManager = VideoManager(cameraQuality: cameraQuality)
    
    self.init(swiftyTesseract: swiftyTesseract,
              recognitionQueue: recognitionQueue,
              imageProcessor: imageProcessor,
              avManager: avManager,
              onRecognitionComplete: onRecognitionComplete)
  }
  
  /// - Parameters:
  ///   - swiftyTesseract: Instance of SwiftyTesseract
  ///   - desiredReliability: The desired reliability of the recognition results.
  ///   - avManager: Manages the AVCaptureSession
  ///   - onRecognitionComplete: Action to be performed after successful recognition
  public convenience init(swiftyTesseract: SwiftyTesseract,
                          desiredReliability: RecognitionReliability,
                          avManager: AVManager,
                          onRecognitionComplete: ((String) -> ())? = nil) {
    
    let recognitionQueue = RecognitionQueue<String>(desiredReliability: desiredReliability)
    
    self.init(swiftyTesseract: swiftyTesseract,
              recognitionQueue: recognitionQueue,
              avManager: avManager,
              onRecognitionComplete: onRecognitionComplete)
  }
  
  /// - Parameters:
  ///   - swiftyTesseract: Instance of SwiftyTesseract
  ///   - desiredReliability: The desired reliability of the recognition results.
  ///   - imageProcessor: Performs conversion and processing from `CMSampleBuffer` to `UIImage`
  ///   - avManager: Manages the AVCaptureSession
  ///   - onRecognitionComplete: Action to be performed after successful recognition
  public convenience init(swiftyTesseract: SwiftyTesseract,
                          desiredReliability: RecognitionReliability,
                          imageProcessor: AVSampleProcessor,
                          avManager: AVManager,
                          onRecognitionComplete: ((String) -> ())? = nil) {
    
    let recognitionQueue = RecognitionQueue<String>(desiredReliability: desiredReliability)
    
    self.init(swiftyTesseract: swiftyTesseract,
              recognitionQueue: recognitionQueue,
              imageProcessor: imageProcessor,
              avManager: avManager,
              onRecognitionComplete: onRecognitionComplete)
  }
  
  
  init(swiftyTesseract: SwiftyTesseract,
       recognitionQueue: RecognitionQueue<String>,
       imageProcessor: AVSampleProcessor = ImageProcessor(),
       avManager: AVManager,
       onRecognitionComplete: ((String) -> ())? = nil) {
    
    self.swiftyTesseract = swiftyTesseract
    self.recognitionQueue = recognitionQueue
    self.imageProcessor = imageProcessor
    self.avManager = avManager
    self.onRecognitionComplete = onRecognitionComplete
    super.init()
    
    if type(of: avManager) == VideoManager.self {
      self.avManager.delegate = self
    }
  }
  
  // MARK: - Public functions
  /// Stops the camera preview
  public func stopPreview() {
    avManager.captureSession.stopRunning()
  }
  
  /// Restarts the camera preview
  public func startPreview() {
    avManager.captureSession.startRunning()
  }
  
  /// Binds SwiftyTesseractRTE AVCaptureVideoPreviewLayer to UIView.
  ///
  /// - Parameter view: The view to present the live preview
  public func bindPreviewLayer(to view: UIView) {
    view.layer.addSublayer(avManager.previewLayer)
    avManager.previewLayer.frame = view.bounds
  }
}
  // Helper functions
extension RealTimeEngine {
  private func performOCR(on sampleBuffer: CMSampleBuffer) {
    guard
      recognitionIsActive,
      let croppedImage = convertAndCrop(sampleBuffer)
    else { return }
    
    enqueueAndEvalutateRecognitionResults(from: croppedImage)
  }
  
  private func convertAndCrop(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
    guard
        let processedImage = imageProcessor.convertToGrayscaleUiImage(from: sampleBuffer)?.binarise.increaseContrast.noiseReducted,
      let regionOfInterest = regionOfInterest
    else { return nil }
    
    return imageProcessor.crop(processedImage,
                               toBoundsOf: regionOfInterest,
                               containedIn: avManager.previewLayer)
  }
  
  private func enqueueAndEvalutateRecognitionResults(from image: UIImage) {
    swiftyTesseract.performOCR(on: image) { [weak self] recognizedString in
      guard
        let recognizedString = recognizedString,
        let self = self
      else { return }

      self.recognitionQueue.enqueue(recognizedString)
      
      guard
        self.recognitionQueue.allValuesMatch,
        let result = self.recognitionQueue.dequeue()
      else { return }
      
      self.onRecognitionComplete?(result)
      self.recognitionQueue.clear()
    }
  }
}

extension RealTimeEngine: AVCaptureVideoDataOutputSampleBufferDelegate {
  
  /// Provides conformance to `AVCaptureVideoDataOutputSampleBufferDelegate`
  /// - Parameters:
  ///   - output: `AVCaptureOutput`
  ///   - sampleBuffer: `CMSampleBuffer`
  ///   - connection: `AVCaptureConnection`
  public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    performOCR <=< sampleBuffer
  }
  
}

extension UIImage {
    
    var increaseContrast: UIImage {
        let inputImage = CIImage(image: self)!
        let parameters = [ "inputContrast": NSNumber(value: 2)]
        let outputImage = inputImage.applyingFilter("CIColorControls", parameters: parameters)
        
        let context = CIContext(options: nil)
        let img = context.createCGImage(outputImage, from: outputImage.extent)!
        return UIImage(cgImage: img)
    }
    
    var binarise: UIImage {
        let glContext = EAGLContext(api: .openGLES2)!
        let ciContext = CIContext(eaglContext: glContext, options: [CIContextOption.outputColorSpace : NSNull()])
        let filter = CIFilter(name: "CIPhotoEffectMono")
        filter!.setValue(CIImage(image: self), forKey: "inputImage")
        let outputImage = filter!.outputImage
        let cgimg = ciContext.createCGImage(outputImage!, from: (outputImage?.extent)!)
        
        return UIImage(cgImage: cgimg!)
    }
//
//    func binarise() -> UIImage {
//
//
//    }
    
    var noiseReducted: UIImage? {
        guard let openGLContext = EAGLContext(api: .openGLES2) else { return self }
        let ciContext = CIContext(eaglContext: openGLContext)
        
        guard let noiseReduction = CIFilter(name: "CINoiseReduction") else { return self }
        noiseReduction.setValue(CIImage(image: self), forKey: kCIInputImageKey)
        noiseReduction.setValue(0.02, forKey: "inputNoiseLevel")
        noiseReduction.setValue(0.40, forKey: "inputSharpness")
        
        if let output = noiseReduction.outputImage,
            let cgImage = ciContext.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
        }
        return nil
    }
}


extension UIImage {
    
    func toGrayScale() -> UIImage {
        
        let greyImage = UIImageView()
        greyImage.image = self
        let context = CIContext(options: nil)
        let currentFilter = CIFilter(name: "CIPhotoEffectNoir")
        currentFilter!.setValue(CIImage(image: greyImage.image!), forKey: kCIInputImageKey)
        let output = currentFilter!.outputImage
        let cgimg = context.createCGImage(output!,from: output!.extent)
        let processedImage = UIImage(cgImage: cgimg!)
        greyImage.image = processedImage
        
        return greyImage.image!
    }
    
    func scaleImage() -> UIImage {
        
        let maxDimension: CGFloat = 640
        var scaledSize = CGSize(width: maxDimension, height: maxDimension)
        var scaleFactor: CGFloat
        
        if self.size.width > self.size.height {
            scaleFactor = self.size.height / self.size.width
            scaledSize.width = maxDimension
            scaledSize.height = scaledSize.width * scaleFactor
        } else {
            scaleFactor = self.size.width / self.size.height
            scaledSize.height = maxDimension
            scaledSize.width = scaledSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        self.draw(in: CGRect(x: 0, y: 0, width: scaledSize.width, height: scaledSize.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
    
    func orientate(img: UIImage) -> UIImage {
        
        if (img.imageOrientation == UIImage.Orientation.up) {
            return img;
        }
        
        UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale)
        let rect = CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
        img.draw(in: rect)
        
        let normalizedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return normalizedImage
        
    }
}
