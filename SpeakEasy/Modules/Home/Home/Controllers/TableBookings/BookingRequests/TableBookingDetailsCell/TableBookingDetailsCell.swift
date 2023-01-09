//
//  TableBookingDetailsCell.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 09/01/23.
//

import UIKit

class TableBookingDetailsCell: UITableViewCell {

    @IBOutlet weak var bottleMenuBtn: UIButtonDeviceClass!
    @IBOutlet weak var viewInviteFrdCollection: UIView!
    @IBOutlet weak var searchFrdView: UIView!
    @IBOutlet weak var inviteFrdCollectionView: UICollectionView!
    @IBOutlet weak var searcFrdBtn: UIButton!
    @IBOutlet weak var maleGuestCountLbl: UILabelDeviceClass!
    @IBOutlet weak var femaleGuestCountLbl: UILabelDeviceClass!
    @IBOutlet weak var femaleGuestMinusBtn: UIButton!
    @IBOutlet weak var femaleGuestPlusBtn: UIButton!
    @IBOutlet weak var maleMinusBtn: UIButton!
    @IBOutlet weak var malePlusBtn: UIButton!
    @IBOutlet weak var itsOnMeView: UIView!
    @IBOutlet weak var equalSplitView: UIView!
    @IBOutlet weak var customSplitView: UIView!
    @IBOutlet weak var itsOnMeLbl: UILabel!
    @IBOutlet weak var itsOnMeInfoLbl: UILabel!
    @IBOutlet weak var equalSplitLbl: UILabel!
    @IBOutlet weak var equalSplitInfoLbl: UILabel!
    @IBOutlet weak var customSplitLbl: UILabel!
    @IBOutlet weak var customSplitInfoLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
       
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    func setGuestdata(noOfMale: Int,noOfFemale: Int) {
        self.femaleGuestCountLbl.text = "\(noOfFemale)"
        self.maleGuestCountLbl.text = "\(noOfMale)"
    }
    
    func setCostSpliteView(costType: costSpliteType) {
        if costType == .itsMe {
            self.itsOnMeView.backgroundColor = Constant.Color.selectedDrinkColor
            self.itsOnMeLbl.textColor = .white
            self.itsOnMeInfoLbl.textColor = .white
            self.equalSplitView.backgroundColor = .white
            self.equalSplitLbl.textColor = Constant.Color.selectedDrinkColor
            self.equalSplitInfoLbl.textColor = Constant.Color.selectedDrinkColor
            self.customSplitView.backgroundColor = .white
            self.customSplitLbl.textColor = Constant.Color.selectedDrinkColor
            self.customSplitInfoLbl.textColor = Constant.Color.selectedDrinkColor
        } else if costType == .EqualSplite {
            self.itsOnMeView.backgroundColor = .white
            self.itsOnMeLbl.textColor = Constant.Color.selectedDrinkColor
            self.itsOnMeInfoLbl.textColor = Constant.Color.selectedDrinkColor
            self.equalSplitView.backgroundColor = Constant.Color.selectedDrinkColor
            self.equalSplitLbl.textColor = .white
            self.equalSplitInfoLbl.textColor = .white
            self.customSplitView.backgroundColor = .white
            self.customSplitLbl.textColor = Constant.Color.selectedDrinkColor
            self.customSplitInfoLbl.textColor = Constant.Color.selectedDrinkColor
        } else if costType == .customSplite {
            self.itsOnMeView.backgroundColor = .white
            self.itsOnMeLbl.textColor = Constant.Color.selectedDrinkColor
            self.itsOnMeInfoLbl.textColor = Constant.Color.selectedDrinkColor
            self.equalSplitView.backgroundColor = .white
            self.equalSplitLbl.textColor = Constant.Color.selectedDrinkColor
            self.equalSplitInfoLbl.textColor = Constant.Color.selectedDrinkColor
            self.customSplitView.backgroundColor = Constant.Color.selectedDrinkColor
            self.customSplitLbl.textColor = .white
            self.customSplitInfoLbl.textColor = .white
        }
    }
    
}
