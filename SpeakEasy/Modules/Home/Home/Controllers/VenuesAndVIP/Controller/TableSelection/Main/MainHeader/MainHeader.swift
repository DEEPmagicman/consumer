//
//  MainHeader.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 9/6/22.
//


import UIKit

class MainHeader: UIView {

    @IBOutlet weak var lblLabel: UILabelDeviceClass!
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "MainHeader", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }

    func setData(){
//        self.lblLabel.text = data.label
    }
}
