//
//  OCRAccuraiser.swift
//  CardNumberScanner
//
//  Created by Sahand Raeisi on 1/29/19.
//  Copyright © 2019 Sahand Raeisi. All rights reserved.
//

import UIKit

extension UIImage {
    
    var increaseContrast1: UIImage {
        let inputImage = CIImage(image: self)!
        let parameters = [ "inputContrast": NSNumber(value: 2)]
        let outputImage = inputImage.applyingFilter("CIColorControls", parameters: parameters)
        
        let context = CIContext(options: nil)
        let img = context.createCGImage(outputImage, from: outputImage.extent)!
        return UIImage(cgImage: img)
    }
    
    var noiseReducted1: UIImage? {
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
