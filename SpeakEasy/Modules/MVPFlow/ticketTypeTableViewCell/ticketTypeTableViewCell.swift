//
//  ticketTypeTableViewCell.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 26/01/23.
//

import UIKit

class ticketTypeTableViewCell: UITableViewCell {

    @IBOutlet weak var ticketTypeLbl: UILabelDeviceClass!
    @IBOutlet weak var infoLbl: UILabelDeviceClass!
    @IBOutlet weak var ticketPriceLbl: UILabelDeviceClass!
    @IBOutlet weak var lineView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        
    }
    
}
