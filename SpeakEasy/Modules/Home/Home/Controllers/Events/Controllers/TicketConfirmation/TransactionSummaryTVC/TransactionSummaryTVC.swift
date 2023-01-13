//
//  TransactionSummaryTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 9/7/22.
//

import UIKit

class TransactionSummaryTVC: UITableViewCell {

    @IBOutlet weak var headerLbl: UILabelDeviceClass!
    @IBOutlet weak var totalLbl: UILabelDeviceClass!
    @IBOutlet weak var totalPriceLbl: UILabelDeviceClass!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setDataForInvite(itsFree: Bool) {
        if itsFree {
            self.headerLbl.text = "Your Split (0%)"
            self.totalPriceLbl.text = "$ 0"
        } else {
            self.headerLbl.text = "Your Split (50%)"
            self.totalPriceLbl.text = "$ 1,081.50"
        }
        self.totalLbl.text = "You pay:"
    }
    
}
