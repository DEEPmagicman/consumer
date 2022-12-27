//
//  PaymentTableViewCell.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 27/12/22.
//

import UIKit

class PaymentTableViewCell: UITableViewCell {

    @IBOutlet weak var paymentIcon: UIImageView!
    @IBOutlet weak var paymentType: UILabel!
    @IBOutlet weak var defaultLbl: UILabel!
    @IBOutlet weak var navigateBtn: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
