//
//  NotificationTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 8/30/22.
//

import UIKit

class CitySelectionTableCell: UITableViewCell {

    @IBOutlet weak var lblCity: UILabelDeviceClass!
    @IBOutlet weak var imgCity: UIImageView!
    @IBOutlet weak var containtView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setData(data: CitySelection) {
        self.lblCity.text = data.name
        self.imgCity.image = UIImage(named: data.img)
    }
    
    func setDataCity(data: City, hideCityImg: Bool = false) {
        self.lblCity.text = data.name
        self.imgCity.image = UIImage(named: "New York, NY 1")
        self.imgCity.isHidden = hideCityImg
    }

}
