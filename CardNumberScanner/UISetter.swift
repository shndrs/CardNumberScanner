//
//  UISetter.swift
//  CardNumberScanner
//
//  Created by Sahand Raeisi on 1/30/19.
//  Copyright © 2019 Sahand Raeisi. All rights reserved.
//

import UIKit

fileprivate protocol OCRUISetterProtocol {
    var parentView:UIView! { get }
    var interestRegion:UIView! { get }
    var excludeLayer: CAShapeLayer! { get }
    var recognitionButton: UIButton! { get }
    var recognitionTitleLabel: UILabel! { get }
    var recognitionLabel: UILabel! { get }
}

public final class OCRUISetterSetter:OCRUISetterProtocol {
    
    var parentView: UIView!
    var interestRegion: UIView!
    var excludeLayer: CAShapeLayer!
    var recognitionButton: UIButton!
    var recognitionTitleLabel: UILabel!
    var recognitionLabel: UILabel!
    
    typealias SetterClosure = (OCRUISetterSetter) -> Void
    
    init(setterClosure:SetterClosure) {
        setterClosure(self)
    }
}

public final class OCRUISetter {
    
    private var parentView: UIView!
    private var interestRegion: UIView!
    private var excludeLayer: CAShapeLayer!
    private var recognitionButton: UIButton!
    private var recognitionTitleLabel: UILabel!
    private var recognitionLabel: UILabel!
    
    public init(setter: OCRUISetterSetter) {
        
        self.parentView = setter.parentView
        self.interestRegion = setter.interestRegion
        self.excludeLayer = setter.excludeLayer
        self.recognitionButton = setter.recognitionButton
        self.recognitionTitleLabel = setter.recognitionTitleLabel
        self.recognitionLabel = setter.recognitionLabel
    }
    
    public func set() {
        
        recognitionButton.setTitleColor(.red, for: .normal)
        recognitionButton.setTitle("Start", for: .normal)
        
        recognitionTitleLabel.text = "Card Number"
        recognitionTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        recognitionTitleLabel.textColor = .white
        
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
        
        parentView.addSubview(stackView)
        
        stackView.widthAnchor.constraint(equalTo: parentView.widthAnchor).isActive = true
        stackView.centerXAnchor.constraint(equalTo: parentView.centerXAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: parentView.centerYAnchor).isActive = true
        stackView.bottomAnchor.constraint(lessThanOrEqualTo: parentView.bottomAnchor).isActive = true

        interestRegion.layer.borderWidth = 1.0
        interestRegion.layer.cornerRadius = 4.0
        interestRegion.layer.borderColor = UIColor.white.cgColor
        interestRegion.backgroundColor = .clear
        
        excludeLayer.fillRule = .evenOdd
        excludeLayer.fillColor = UIColor.black.cgColor
        excludeLayer.opacity = 0.8
    }
}
