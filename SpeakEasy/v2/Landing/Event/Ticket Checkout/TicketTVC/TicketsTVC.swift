//
//  TicketsTVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 06/02/26.
//

import UIKit

struct TicketModel {
    let title: String
    let price: Double
    var quantity: Int
}

class TicketsTVC: UITableViewCell {

    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var priceLbl: UILabel!
    @IBOutlet weak var quantityLbl: UILabel!
    @IBOutlet weak var minusBtn: UIButton!
    @IBOutlet weak var plusBtn: UIButton!
    @IBOutlet weak var minusView: UIView!
    @IBOutlet weak var plusView: UIView!
    
    var onIncrease: (() -> Void)?
    var onDecrease: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configure(ticket: TicketModel) {
        titleLbl.text = ticket.title
        priceLbl.text = "₹\(Int(ticket.price))"
        quantityLbl.text = "\(ticket.quantity)"
    }
    
    func showMinusView(ticket: TicketModel) {
        self.minusView.isHidden = ticket.quantity < 0
        self.quantityLbl.isHidden = ticket.quantity < 0
    }
    
    func hideMinusView() {
        self.minusView.isHidden = true
        self.quantityLbl.isHidden = true
    }
    
    

    @IBAction func onTapPlus(_ sender: Any) {
        onIncrease?()
    }

    @IBAction func onTapMinus(_ sender: Any) {
        onDecrease?()
    }
}

