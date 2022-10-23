//
//  ImportantDatesCVC.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 28/08/2022.
//

import UIKit

//Dummy Data
struct CustomDate {
    var dateImg: UIImage?
    var dateTitle: String
}

class ImportantDatesCVC: UICollectionViewCell {

    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var lblDOB: UILabelDeviceClass!
    @IBOutlet weak var lblBirthday: UILabelDeviceClass!
    
    //Dummy date
    var datesArray = [
        CustomDate( dateImg: UIImage(named:"paulsXS"), dateTitle: "Paul's Birthday"),
        CustomDate( dateImg: UIImage(named:"conormXS"), dateTitle: "Conor's Birthday"),
        CustomDate( dateImg: UIImage(named:"danawXS"), dateTitle: "Dana's Birthday")
    ]
    
    func setData(index: Int) {
        if index == 0 {
            self.imgProfile.image = UIImage(named: "Birthday")
            self.lblBirthday.text = "Your  birthday"
        }
        else {
            self.imgProfile.image = datesArray[index-1].dateImg
            self.lblBirthday.text = datesArray[index-1].dateTitle
        }
    }
}
