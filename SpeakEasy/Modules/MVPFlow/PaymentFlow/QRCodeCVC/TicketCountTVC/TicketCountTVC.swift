//
//  TicketTypeTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Sanjay on 01/03/24.
//

import UIKit

class TicketCountTVC: UITableViewCell {
    
    @IBOutlet weak var ticketNameLbl: UILabel!
    @IBOutlet weak var ticketCountLbl: UILabel!
    @IBOutlet weak var infoLbl: UILabel!
    @IBOutlet weak var separatorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
}
