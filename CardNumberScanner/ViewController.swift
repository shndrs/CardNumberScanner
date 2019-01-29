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
        realTimeEngineSetUp()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let builderObject = ShimmerObject.init(text: "Ansar Bank",
                                               font: UIFont(name: "Papyrus", size: 24)!,
                                               textAlignment: .center, animationDuration: 2,
                                               frame: CGRect(x: 0, y: 0, width: cameraView.frame.width, height: 44),
                                               parentView: cameraView,
                                               mainLabelTextColor: .orange,
                                               maskLabelTextColor: .red)
        
        SHNDShimmerFactory.create(builder: builderObject)
    }

    override func viewDidLayoutSubviews() {
        engine.bindPreviewLayer(to: cameraView)
        engine.regionOfInterest = interestRegion.frame
        cameraView.layer.addSublayer(interestRegion.layer)
        fillOpaqueAroundAreaOfInterest(parentView: cameraView, areaOfInterest: interestRegion)
    }
    
    private func fillOpaqueAroundAreaOfInterest(parentView: UIView, areaOfInterest: UIView) {
        let parentViewBounds = parentView.bounds
        let areaOfInterestFrame = areaOfInterest.frame
        
        let path = UIBezierPath(rect: parentViewBounds)
        let areaOfInterestPath = UIBezierPath(rect: areaOfInterestFrame)
        path.append(areaOfInterestPath)
        path.usesEvenOddFillRule = true
        
        excludeLayer.path = path.cgPath
        parentView.layer.addSublayer(excludeLayer)
    }
    
    @IBAction private func flashButtonPressed(_ sender: UIButton) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                device.torchMode = device.torchMode == .off ? .on : .off
                device.unlockForConfiguration()
            } catch let e {
                print("Error: \(e.localizedDescription)")
            }
        }
        let flashlightButtonTitle = device.torchMode == .off ? "Flashlight On" : "Flashlight Off"
        flashlightButton.titleLabel?.text = flashlightButtonTitle
        flashlightButton.title(for: .normal)
    }
    
    private func setUI() {
        
        recognitionButton = UIButton()
        recognitionButton.setTitleColor(.red, for: .normal)
        recognitionButton.setTitle("Start", for: .normal)
        recognitionButton.addTarget(self, action: #selector(recognitionButtonTapped(_:)), for: .touchUpInside)
        
        recognitionTitleLabel = UILabel()
        recognitionTitleLabel.text = "Card Number"
        recognitionTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        recognitionTitleLabel.textColor = .white
        
        recognitionLabel = UILabel()
        recognitionLabel.textAlignment = .center
        recognitionLabel.numberOfLines = 0
        recognitionLabel.textColor = .white
        recognitionLabel.text = "Your card No. will place here"
        
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
        excludeLayer.opacity = 0.8
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

