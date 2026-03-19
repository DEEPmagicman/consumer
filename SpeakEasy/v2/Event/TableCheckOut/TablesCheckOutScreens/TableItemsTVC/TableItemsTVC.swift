//
//  TableItemsTVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 18/03/26.
//

import UIKit

class TableItemsTVC: UITableViewCell {
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var guestLbl: UILabel!
    @IBOutlet weak var minimumSpendLbl: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
}
