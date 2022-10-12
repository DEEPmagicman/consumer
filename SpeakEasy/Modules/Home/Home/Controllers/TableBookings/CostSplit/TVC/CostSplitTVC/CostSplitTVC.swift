//
//  CostSplitTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 06/09/2022.
//

import UIKit

class CostSplitTVC: UITableViewCell {

    @IBOutlet weak var imgUser: UIImageView!
    @IBOutlet weak var lblName: UILabelDeviceClass!
    @IBOutlet weak var tfDiscount: UITextField!
    @IBOutlet weak var lblPrice: UILabelDeviceClass!
    
    var tagValue = 1
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setData(data: CostSplitModel) {
        
        self.lblName.text = data.name
        self.tfDiscount.text = data.discount
        self.lblPrice.text = data.price
        self.imgUser.image = UIImage(named: data.img)
        self.tfDiscount.isEnabled = tagValue == 3 ? true : false
    }
    
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
}
