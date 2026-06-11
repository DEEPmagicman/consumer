//
//  QRTicketTableViewCell.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 11/06/26.
//

import UIKit

class QRTicketTableViewCell: UITableViewCell {
    
    @IBOutlet weak var ticketNameLbl: UILabel!
    @IBOutlet weak var discriptionLbl: UILabel!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var totalTicketCountLbl: UILabel!
    @IBOutlet weak var priceLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
