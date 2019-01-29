//
//  ViewController.swift
//  CardNumberScanner
//
//  Created by Sahand Raeisi on 1/29/19.
//  Copyright © 2019 Sahand Raeisi. All rights reserved.
//

import UIKit
import SwiftyTesseract
import SwiftyTesseractRTE
import AVFoundation
import AudioToolbox
import SHNDStuffs

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    
        SHNDNavigationBarGradient(firstColor: .purple, secondColor: .blue, tintColor: .white, isHorizontal: true)
        let navTitleBuilder = NavigationTitleViewBuilder(title: "Ansar OCR",
                                                         desc: "Ansar Bank",
                                                         titleFont: UIFont(name: "Papyrus", size: 18)!,
                                                         descFont: UIFont(name: "Kailasa", size: 10)!,
                                                         titleTextColor: .white,
                                                         descTextColor: .white)
        SHNDNavigationCustomTitleView(builder: navTitleBuilder)
    }
}

