//
//  BookingsCVC.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 30/08/2022.
//

import UIKit

class BookingsCVC: UICollectionViewCell {

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblCount: UILabel!
    @IBOutlet weak var viewBackground: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setData(data: BookingTabBarOption) {
        self.lblTitle.text = data.label
        self.lblCount.text = "\(data.count)"
        
        switch data.isSelected {
        case true:
            self.viewBackground.backgroundColor = UIColor.black
            self.viewBackground.borderWidth = 1
            self.lblTitle.font = Utility.main.getDeviceSpecificFont(fontWeight: "semiBold", fontSize: 15)
        case false:
            self.viewBackground.backgroundColor = UIColor.clear
            self.viewBackground.borderWidth = 0
            self.lblTitle.font = Utility.main.getDeviceSpecificFont(fontWeight: "medium", fontSize: 15)
        }
    }
}
