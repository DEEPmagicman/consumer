//
//  EventCVC.swift
//  SpeakEasy-Consumer
//
//  Created by M.Usman Bin Rehan on 28/08/2022.
//

import UIKit

class EventCVC: UICollectionViewCell {
    
    @IBOutlet weak var imgEventCover: UIImageView!
    @IBOutlet weak var lblPerformerName: UILabelDeviceClass!
    @IBOutlet weak var lblVenueName: UILabelDeviceClass!
    @IBOutlet weak var lblEventDate: UILabelDeviceClass!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func setData(data: TopEventDataSet) {
        self.imgEventCover.image = data.imgEventCover
        self.lblPerformerName.text = data.lblPerformerName
        self.lblVenueName.text = "\(data.lblVenueName ?? "") \(Constants.localizedCity)"
        self.lblEventDate.text = data.lblEventDate
    }
}
