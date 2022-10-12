//
//  ViewRewardTable.swift
//  SpeakEasy
//
//  Created by M.Usman Bin Rehan on 7/28/22.
//

import UIKit

class ViewRewardTable: UIView {

    @IBOutlet weak var viewBackGround: UIView!
    @IBOutlet weak var lblTableNumber: UILabel!
    @IBOutlet weak var lblTableCapacity: UILabel!
    @IBOutlet weak var imgUnavailable: UIImageView!
    @IBOutlet weak var btnTable: UIButton!
    
    let availableColor = UIColor(red:55/255, green:124/255, blue:246/255, alpha:1)
    let unavailableColor = UIColor(red:52/255, green:50/255, blue:52/255, alpha:1)
    let selectedColor = UIColor(red:255/255, green:255/255, blue:255/255, alpha:1)
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "ViewRewardTable", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
   
}
//MARK: - Helper methods
extension ViewRewardTable {
    func setData(data: TableAttributes){
        self.lblTableNumber.text = data.tableNumber
        self.lblTableCapacity.text = "\(data.tableCapacity)"
        
        if data.tableStatus == .available {
            self.imgUnavailable.isHidden = true
            
            if data.isSelected {
                self.viewBackGround.backgroundColor = self.selectedColor
            }
            else {
                self.viewBackGround.backgroundColor = self.availableColor
            }
            self.viewBackGround.borderColor = .clear
        }
        else {
            self.viewBackGround.borderColor = self.availableColor
            self.viewBackGround.backgroundColor = self.unavailableColor
            self.imgUnavailable.isHidden = false
        }
    }
}
