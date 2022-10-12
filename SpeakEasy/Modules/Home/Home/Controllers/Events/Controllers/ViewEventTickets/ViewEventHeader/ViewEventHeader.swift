//
//  ViewEventHeader.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 9/4/22.
//

import Foundation
import UIKit

class ViewEventHeader: UIView {
    
    @IBOutlet weak var btnDescription: UIButtonDeviceClass!
    @IBOutlet weak var btnCloseDescription: UIButtonDeviceClass!
    @IBOutlet weak var lblDescription: UILabelDeviceClass!
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "ViewEventHeader", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
    
    @IBAction func onBtnViewDescription(_ sender: UIButtonDeviceClass) {
        self.btnDescription.isHidden = true
        self.btnCloseDescription.isHidden = false
        UIView.animate(withDuration: 0.25, delay: 0, options: UIView.AnimationOptions.curveEaseInOut) {
            self.updatedLable()
        }
    }
    @IBAction func onBtnCloseDescription(_ sender: UIButtonDeviceClass) {
        self.btnDescription.isHidden = false
        self.btnCloseDescription.isHidden = true
        UIView.animate(withDuration: 0.25, delay: 0, options: UIView.AnimationOptions.curveEaseInOut) {
            self.updatedLable()
        }
    }
    private func updatedLable() {
        self.lblDescription.isHidden = !self.lblDescription.isHidden
        self.layoutIfNeeded()
    }
}

