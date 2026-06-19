//
//  QRTicketTableViewCell.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 11/06/26.
//

import UIKit

class QRTicketTableViewCell: UITableViewCell {
    
    @IBOutlet weak var ticketNameLbl: UILabel!
    @IBOutlet weak var discriptionLbl: UILabel!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var totalTicketCountLbl: UILabel!
    @IBOutlet weak var priceLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        setupTextBehavior()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        ticketNameLbl.text = nil
        discriptionLbl.text = nil
        totalTicketCountLbl.text = nil
        priceLbl.text = nil
        priceLbl.isHidden = true
        discriptionLbl.superview?.isHidden = true
    }

    func configure(
        title: String?,
        description: String?,
        quantity: Int
    ) {
        ticketNameLbl.text = title?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        totalTicketCountLbl.text = "\(quantity)"
        priceLbl.text = nil
        priceLbl.isHidden = true

        let cleanDescription = description?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? ""

        discriptionLbl.text = cleanDescription
        discriptionLbl.superview?.isHidden = cleanDescription.isEmpty
    }

    private func setupTextBehavior() {
        ticketNameLbl.numberOfLines = 0
        ticketNameLbl.lineBreakMode = .byWordWrapping
        ticketNameLbl.adjustsFontSizeToFitWidth = false
        ticketNameLbl.setContentCompressionResistancePriority(
            .required,
            for: .vertical
        )

        discriptionLbl.numberOfLines = 2
        discriptionLbl.lineBreakMode = .byWordWrapping
        discriptionLbl.setContentCompressionResistancePriority(
            .required,
            for: .vertical
        )

        priceLbl.isHidden = true
        priceLbl.text = nil
    }
    
}
