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
    
    private var engine: RealTimeEngine!
    private var excludeLayer: CAShapeLayer!
    private var flashlightButton: UIButton!
    private var recognitionButton: UIButton!
    private var recognitionTitleLabel: UILabel!
    private var recognitionLabel: UILabel!
    private var recognitionIsRunning = false {
        didSet {
            let recognitionButtonText = recognitionIsRunning ? "Stop Running" : "Start Recognition"
            DispatchQueue.main.async { [weak self] in
                self?.recognitionButton.setTitle(recognitionButtonText, for: .normal)
            }
            engine.recognitionIsActive = recognitionIsRunning
        }
    }
    @IBOutlet weak var cameraView:UIView!
    @IBOutlet weak var interestRegion:UIView!
    @IBOutlet weak var interestRegionWidth:NSLayoutConstraint!
    @IBOutlet weak var interestRegionHeight:NSLayoutConstraint!
    

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
        
        setUI()
    }
    
    private func setUI() {
        
        recognitionButton = UIButton()
        recognitionButton.setTitleColor(view.tintColor, for: .normal)
        recognitionButton.setTitle("Start Recognition", for: .normal)
        recognitionButton.addTarget(self, action: #selector(recognitionButtonTapped(_:)), for: .touchUpInside)
        
        recognitionTitleLabel = UILabel()
        recognitionTitleLabel.text = "Recognition Text:"
        recognitionTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        recognitionTitleLabel.textColor = .white
        
        recognitionLabel = UILabel()
        recognitionLabel.textAlignment = .center
        recognitionLabel.numberOfLines = 20
        recognitionLabel.textColor = .white
        recognitionLabel.text = "Let's Do This!"
        
        let stackView = UIStackView(arrangedSubviews: [recognitionButton, recognitionTitleLabel, recognitionLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 8.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        stackView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor).isActive = true
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        
        interestRegion.addGestureRecognizer(panGesture)
        interestRegion.layer.borderWidth = 1.0
        interestRegion.layer.cornerRadius = 4.0
        interestRegion.layer.borderColor = UIColor.white.cgColor
        interestRegion.backgroundColor = .clear
        
        excludeLayer = CAShapeLayer()
        excludeLayer.fillRule = .evenOdd
        excludeLayer.fillColor = UIColor.black.cgColor
        excludeLayer.opacity = 0.7
    }
    
    private func realTimeEngineSetUp() {
        let swiftyTesseract = SwiftyTesseract(language: .english)
        engine = RealTimeEngine(swiftyTesseract: swiftyTesseract, desiredReliability: .verifiable) { [weak self] recognizedString in
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            DispatchQueue.main.async {
                self?.recognitionLabel.text = recognizedString
            }
            self?.recognitionIsRunning = false
        }
        engine.recognitionIsActive = false
        engine.startPreview()
    }
    
    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        let translate = sender.translation(in: interestRegion)
        
        UIView.animate(withDuration: 0) {
            self.interestRegionWidth.constant += translate.x
            self.interestRegionHeight.constant += translate.y
        }
        
        sender.setTranslation(.zero, in: interestRegion)
        viewDidLayoutSubviews()
 //       informationLabel.isHidden = true
    }
    
    @objc func recognitionButtonTapped(_ sender: Any) {
        recognitionIsRunning.toggle()
    }
    
}

