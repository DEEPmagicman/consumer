//
//  DynamicFonts.swift
//  Racing
//
//  Created by Mac Book on 26/10/2020.
//  Copyright © 2020 Mac Book. All rights reserved.
//

import UIKit

class UILabelDeviceClass : UILabel {
    
    @IBInspectable var iPhoneFontSize:CGFloat = 0
    @IBInspectable var iPhoneFontWeight:String = "regular" {
        didSet {
            overrideFontSize(iPhoneFontSize, iPhoneFontWeight)
        }
    }
    @IBInspectable var isCircular:Bool = false
    @IBInspectable var isShadowed:Bool = false
    
    func overrideFontSize(_ fontSize:CGFloat, _ fontWeight:String) {
        self.font = Utility.main.getDeviceSpecificFont(fontWeight: fontWeight, fontSize: fontSize)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.isCircular{
            let height = self.frame.height
            self.layer.cornerRadius = CGFloat(height / 2.0)
            self.clipsToBounds = true
        }
        if self.isShadowed {
            self.layer.shadowColor = UIColor.white.cgColor
            self.layer.shadowOffset = .zero
            self.layer.shadowRadius = 6
            self.layer.shadowOpacity = 1
        }
        else {
            self.layer.shadowColor = UIColor.clear.cgColor
            self.layer.shadowOffset = .zero
            self.layer.shadowRadius = 0
            self.layer.shadowOpacity = 0
        }
    }
}
class UITextFieldDeviceClass : UITextField {
    
    @IBInspectable var iPhoneFontSize:CGFloat = 0
    @IBInspectable var iPhoneFontWeight:String = "regular" {
        didSet {
            overrideFontSize(iPhoneFontSize, iPhoneFontWeight)
        }
    }
    @IBInspectable var isCircular:Bool = false
    
    func overrideFontSize(_ fontSize:CGFloat, _ fontWeight:String) {
        self.font = Utility.main.getDeviceSpecificFont(fontWeight: fontWeight, fontSize: fontSize)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.isCircular{
            let height = self.frame.height
            self.layer.cornerRadius = CGFloat(height / 2.0)
            self.clipsToBounds = true
        }
    }
}
class UIButtonDeviceClass : UIButton {
    
    @IBInspectable var iPhoneFontSize:CGFloat = 0
    @IBInspectable var iPhoneFontWeight:String = "regular" {
        didSet {
            overrideFontSize(iPhoneFontSize, iPhoneFontWeight)
        }
    }
    @IBInspectable var isCircular:Bool = false
    
    func overrideFontSize(_ fontSize:CGFloat, _ fontWeight:String) {
        self.titleLabel?.font = Utility.main.getDeviceSpecificFont(fontWeight: fontWeight, fontSize: fontSize)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.isCircular{
            let height = self.frame.height
            self.layer.cornerRadius = CGFloat(height / 2.0)
            self.clipsToBounds = true
        }
        overrideFontSize(iPhoneFontSize, iPhoneFontWeight)
    }
}
class UIButtonPlainDeviceClass : UIButton {
    
    @IBInspectable var iPhoneFontSize:CGFloat = 0
    @IBInspectable var iPhoneFontWeight:String = "regular" {
        didSet {
            overrideFontSize(iPhoneFontSize, iPhoneFontWeight)
        }
    }
    @IBInspectable var isCircular:Bool = false
    
    func overrideFontSize(_ fontSize:CGFloat, _ fontWeight:String) {
        self.titleLabel?.font = Utility.main.getDeviceSpecificFont(fontWeight: fontWeight, fontSize: fontSize)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.isCircular{
            let height = self.frame.height
            self.layer.cornerRadius = CGFloat(height / 2.0)
            self.clipsToBounds = true
        }
        self.tintColor = .clear
        self.setTitleColor(.white, for: .selected)
        self.backgroundColor = .clear
    }
}
class UIButtonEnableDisableDeviceClass : UIButton {
    
    @IBInspectable var iPhoneFontSize:CGFloat = 0
    @IBInspectable var iPhoneFontWeight:String = "regular" {
        didSet {
            overrideFontSize(iPhoneFontSize, iPhoneFontWeight)
        }
    }
    @IBInspectable var isCircular:Bool = false
    
    func overrideFontSize(_ fontSize:CGFloat, _ fontWeight:String) {
        self.titleLabel?.font = Utility.main.getDeviceSpecificFont(fontWeight: fontWeight, fontSize: fontSize)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.isCircular{
            let height = self.frame.height
            self.layer.cornerRadius = CGFloat(height / 2.0)
            self.clipsToBounds = true
        }
        
        self.tintColor = .clear
        
        if self.isEnabled{
            self.setTitleColor(.white, for: .selected)
            self.backgroundColor = Global.APP_COLOR
        }
        else{
            self.setTitleColor(.white, for: .normal)
            self.backgroundColor = .darkGray
        }
    }
}

class UIButtonSelectedUnSelectedDeviceClass : UIButton {
    
    @IBInspectable var iPhoneFontSize:CGFloat = 0
    @IBInspectable var iPhoneFontWeight:String = "regular" {
        didSet {
            overrideFontSize(iPhoneFontSize, iPhoneFontWeight)
        }
    }
    @IBInspectable var isCircular:Bool = false
    
    func overrideFontSize(_ fontSize:CGFloat, _ fontWeight:String) {
        self.titleLabel?.font = Utility.main.getDeviceSpecificFont(fontWeight: fontWeight, fontSize: fontSize)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.isCircular{
            let height = self.frame.height
            self.layer.cornerRadius = CGFloat(height / 2.0)
            self.clipsToBounds = true
        }
        
        self.tintColor = .clear
        
        if self.isSelected{
            self.setTitleColor(.white, for: .selected)
            self.backgroundColor = Global.APP_COLOR
        }
        else{
            self.setTitleColor(.white, for: .normal)
            self.backgroundColor = .darkGray
        }
    }
}

class UITextViewDeviceClass : UITextView {
    
    @IBInspectable var iPhoneFontSize:CGFloat = 0
    @IBInspectable var iPhoneFontWeight:String = "regular" {
        didSet {
            overrideFontSize(iPhoneFontSize, iPhoneFontWeight)
        }
    }
    @IBInspectable var isCircular:Bool = false
    
    func overrideFontSize(_ fontSize:CGFloat, _ fontWeight:String) {
        self.font = Utility.main.getDeviceSpecificFont(fontWeight: fontWeight, fontSize: fontSize)
    }
}
