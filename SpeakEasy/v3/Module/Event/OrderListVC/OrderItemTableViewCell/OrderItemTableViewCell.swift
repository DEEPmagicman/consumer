//
//  OrderItemTableViewCell.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/05/26.
//

import UIKit

class OrderItemTableViewCell: UITableViewCell {
    
    @IBOutlet weak var totalTicketCountLbl: UILabel!
    @IBOutlet weak var ticketNameLbl: UILabel!
    @IBOutlet weak var priceLbl: UILabel!
//    @IBOutlet weak var extraFeesLbl: UILabel!
    @IBOutlet weak var bgView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        bgView.applyAutoBorderBackground()
        selectionStyle = .none
    }
    
}
