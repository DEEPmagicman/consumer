//
//  MainTableTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 9/6/22.
//

import UIKit

class MainTableTVC: UITableViewCell {
    
    @IBOutlet weak var viewBackground: UIView!
    @IBOutlet weak var lblTableNumber: UILabelDeviceClass!
    @IBOutlet weak var lblNumberOfSeats: UILabelDeviceClass!
    @IBOutlet weak var lblTimeSlots: UILabelDeviceClass!
    @IBOutlet weak var lblMinSpeed: UILabelDeviceClass!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setData(data: TableAttributes){
        if data.isSelected {
            self.viewBackground.backgroundColor = .white
            self.lblTableNumber.textColor = .black
            self.lblNumberOfSeats.textColor = .black
            self.lblTimeSlots.textColor = .black
            self.lblMinSpeed.textColor = .black
        }else{
            self.viewBackground.backgroundColor = .black
            self.lblTableNumber.textColor = .white
            self.lblNumberOfSeats.textColor = .white
            self.lblTimeSlots.textColor = .white
            self.lblMinSpeed.textColor = .white
        }
        self.lblTableNumber.text = data.tableNumber
        self.lblNumberOfSeats.text = "\(data.tableCapacity) seats"
        self.lblTimeSlots.text = data.timeSlot
        self.lblMinSpeed.text = data.minimumSpend
    }
}
