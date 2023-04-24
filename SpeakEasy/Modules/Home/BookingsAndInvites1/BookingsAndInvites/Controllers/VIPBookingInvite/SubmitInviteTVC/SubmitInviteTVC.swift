//
//  SubmitInviteTVC.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 13/01/23.
//

import UIKit

class SubmitInviteTVC: UITableViewCell {

    @IBOutlet weak var acceptBtn: UIButtonDeviceClass!
    @IBOutlet weak var rejectBtn: UIButton!
    @IBOutlet weak var infoLbl: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    func setData(itsFree: Bool) {
        if itsFree {
            self.infoLbl.text = "Your request is subject to approval from the venue.  Once confirmed by the venue, all bookings are FINAL"
            self.infoLbl.highlightBold(["Once confirmed by the venue, all bookings are FINAL"], size: 15, textColor: .white, addUnderLine: true)
            self.acceptBtn.setTitle("Accept Invitation", for: .normal)
        } else {
            self.infoLbl.highlightBold(["Once confirmed by the venue, all bookings are FINAL"], size: 15, textColor: .white, addUnderLine: true)
            self.acceptBtn.setTitle("Accept & Pay", for: .normal)
        }
    }
    
}
