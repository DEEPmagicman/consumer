//
//  ticketTypeTableViewCell.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 26/01/23.
//

import UIKit

class ticketTypeTableViewCell: UITableViewCell {

    @IBOutlet weak var ticketTypeLbl: UILabel!
    @IBOutlet weak var infoLbl: UILabel!
    @IBOutlet weak var ticketPriceLbl: UILabel!
    @IBOutlet weak var ticketPlusMinusView: UIView!
    @IBOutlet weak var minusBtn: UIButton!
    @IBOutlet weak var plusBtn: UIButton!
    @IBOutlet weak var totalTicketLbl: UILabel!
    @IBOutlet weak var hotVenueLbl: UILabel!
    @IBOutlet weak var lblExtraFeesValue: UILabel!
    @IBOutlet weak var bgView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
