//
//  PaymentTableViewCell.swift
//  SpeakEasy-Consumer
//
//  Created by Mac on 23/05/24.
//

import UIKit

final class PaymentTableViewCell: UITableViewCell {
    
    @IBOutlet weak var paymentIcon: UIImageView!
    @IBOutlet weak var paymentType: UILabel!
    @IBOutlet weak var defaultLbl: UILabel!
    @IBOutlet weak var navigateBtn: UIButton!
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var headerLbl: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setUi(isSetting: Bool) {
        if isSetting {
            self.editBtn.isHidden = true
            self.headerLbl.isHidden = true
            self.defaultLbl.isHidden = false
            self.navigateBtn.isHidden = false
        } else {
            self.defaultLbl.isHidden = true
            self.navigateBtn.isHidden = true
            self.editBtn.isHidden = false
            self.headerLbl.isHidden = false
        }
    }
}
