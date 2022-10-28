//
//  TopEventCVC.swift
//  SpeakEasy-Consumer
//
//  Created by M.Usman Bin Rehan on 28/08/2022.
//

import UIKit

class TopEventCVC: UICollectionViewCell {

    @IBOutlet weak var imgEventCover: UIImageView!
    @IBOutlet weak var lblPerformerName: UILabelDeviceClass!
    @IBOutlet weak var lblVenueName: UILabelDeviceClass!
    @IBOutlet weak var imgBrandLogo: UIImageView!
    @IBOutlet weak var lblEventDate: UILabelDeviceClass!
    @IBOutlet weak var currentLiveEventFires: UIStackView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func setData(data: TopEventDataSet) {
        self.imgEventCover.image = data.imgEventCover
        self.lblPerformerName.text = data.lblPerformerName
        self.lblVenueName.text = "\(data.lblVenueName ?? "") \(Constants.localizedCity)"
        self.imgBrandLogo.image = data.imgBrandLogo
        self.lblEventDate.text = data.lblEventDate
        self.lblEventDate.textColor = data.isLive ?? false ? Global.APP_COLOR_PINK : Global.APP_COLOR_GREY_LIGHT
        self.currentLiveEventFires.isHidden = !(data.isLive ?? false)
    }

}
