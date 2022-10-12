//
//  ImportantDatesCVC.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 28/08/2022.
//

import UIKit

class ImportantDatesCVC: UICollectionViewCell {

    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var lblDOB: UILabelDeviceClass!
    @IBOutlet weak var lblBirthday: UILabelDeviceClass!
    
    func setData(index: Int) {
        if index == 0 {
            self.imgProfile.image = UIImage(named: "Birthday")
            self.lblBirthday.text = "Your  birthday"
        }
        else {
            self.imgProfile.image = UIImage(named: "paul")
            self.lblBirthday.text = "Paul’s birthday"
        }
    }
}
