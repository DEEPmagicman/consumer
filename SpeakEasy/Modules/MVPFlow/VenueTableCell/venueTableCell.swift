//
//  venueTableCell.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 26/01/23.
//

import UIKit

class venueTableCell: UITableViewCell {

    @IBOutlet weak var venueEventImg: UIImageView!
    @IBOutlet weak var liveLbl: UILabelDeviceClass!
    @IBOutlet weak var logoImg: UIImageView!
    @IBOutlet weak var eventNameLbl: UILabelDeviceClass!
    @IBOutlet weak var waitTimeLbl: UILabelDeviceClass!
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    func setData(data: VenuesVIPEventDataSet) {
        self.venueEventImg.image = data.imgEventCover
        self.eventNameLbl.text = data.lblPerformerName
        self.logoImg.image = data.imgBrandLogo
    }

    
}
