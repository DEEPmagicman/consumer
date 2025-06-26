//
//  ticketTypeTableViewCell.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 26/01/23.
//

import UIKit

class ticketTypeTableViewCell: UITableViewCell {

    @IBOutlet weak var ticketTypeLbl: UILabel!
    @IBOutlet weak var infoLbl: UILabel!
    @IBOutlet weak var ticketPriceLbl: UILabel!
    @IBOutlet weak var ticketPlusMinusView: UIView!
    @IBOutlet weak var minusBtn: UIButton!
    @IBOutlet weak var plusBtn: UIButton!
    @IBOutlet weak var totalTicketLbl: UILabel!
    @IBOutlet weak var hotVenueLbl: UILabel!
    @IBOutlet weak var lblExtraFeesValue: UILabel!
    @IBOutlet weak var bgView: ShadowView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

class ShadowView: UIView {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
//        self.cornerRadius = 8
        clipsToBounds = true
        layer.masksToBounds = false
    }
    
//    override func becomeFirstResponder() -> Bool {
//        addOuterShadow()
//        return super.becomeFirstResponder()
//    }
//
//    override func resignFirstResponder() -> Bool {
//        removeOuterShadow()
//        return super.resignFirstResponder()
//    }
    
    func addOuterShadow() {
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor.lightGray.cgColor
        layer.shadowColor = UIColor.white.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowOpacity = 1
        layer.shadowRadius = 4
    }
    
    func removeOuterShadow() {
        layer.borderWidth = 0
        layer.shadowColor = nil
        layer.shadowOffset = CGSize.zero
        layer.shadowOpacity = 0
        layer.shadowRadius = 0
        layer.shadowPath = nil
    }
}
