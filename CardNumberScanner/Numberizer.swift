//
//  Numberizer.swift
//  CardNumberScanner
//
//  Created by Sahand Raeisi on 1/30/19.
//  Copyright © 2019 Sahand Raeisi. All rights reserved.
//

import UIKit

class Numberizer {
    
    static let shared = Numberizer()
    private init(){}
    
    func Numberize(text:inout String) -> String {
        
        let stringArray = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
        text = ""
        
        for item in stringArray {
            
            if let number = UInt32(item) {
                text = text + String(number)
            }
        }
        
        if text.count == 16 {
            return text
        } else {
            return "Please Try Again!!"
        }
    }
}
