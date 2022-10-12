//
//  HeaderView.swift
//  SpeakEasy-Consumer
//
//  Created by M.Usman Bin Rehan on 28/08/2022.
//

import UIKit

class HeaderView: UIView {

    @IBOutlet weak var lblLabel: UILabelDeviceClass!
    @IBOutlet weak var imgIcon: UIImageView!
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "HeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }

    func setData(data: HeaderOption){
        self.lblLabel.text = data.label
        self.imgIcon.image = data.icon
    }
}
