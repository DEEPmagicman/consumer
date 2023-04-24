//
//  BookingDetailTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 27/09/2022.
//

import UIKit

class BookingDetailTVC: UITableViewCell {

    @IBOutlet weak var userNoteLbl: UILabelDeviceClass!
    @IBOutlet weak var have6BottelNote: UILabelDeviceClass!
    @IBOutlet weak var extraSpaceView: UIView!
    @IBOutlet weak var middleLineView: UIView!
    @IBOutlet weak var extraSpacetop: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    func userNoteAndrequestHide() {
        self.userNoteLbl.isHidden = true
        self.have6BottelNote.isHidden = true
        self.extraSpaceView.isHidden = true
        self.middleLineView.isHidden = true
        self.extraSpacetop.isHidden = true
    }
    
}
