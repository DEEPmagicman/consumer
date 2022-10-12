//
//  DressCodeTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 8/31/22.
//

import UIKit

class DressCodeTVC: UITableViewCell {
    @IBOutlet weak var lblDressCode: UILabelDeviceClass!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func setData(data: DressCodeDataSet) {
        self.lblDressCode.text = data.dressCode
    }
    
}
