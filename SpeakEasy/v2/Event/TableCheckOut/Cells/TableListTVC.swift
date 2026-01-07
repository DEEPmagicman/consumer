//
//  TableListTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 05/01/26.
//

import UIKit

class TableListTVC: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var tableName: UILabel!
    @IBOutlet weak var totalAmount: UILabel!
    @IBOutlet weak var secondAmountLbl: UILabel!
    @IBOutlet weak var tableDetailLbl: UILabel!
    @IBOutlet weak var tableDescriptionLbl: UILabel!
    @IBOutlet weak var bookBtn: UIButton!
    
    let infoTextAttributes: [NSAttributedString.Key: Any] = [
        .font: AppFont.font(weight: .regular, size: 12),
        .foregroundColor: UIColor(hex: "#D2D5DB")
    ]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        containerView.layer.cornerRadius = 10
        containerView.clipsToBounds = true
        bookBtn.layer.cornerRadius = 16
        bookBtn.clipsToBounds = true
        tableName.text = "Dance Floor"
        totalAmount.text = "$200.00"
        secondAmountLbl.text = "$2,000 min."
        tableDetailLbl.text = ""
        tableDescriptionLbl.text = "Second-row dance floor tables for up to 12 guests"
        
        tableDetailLbl.attributedText = buildGuestsTimeText(
            guests: "10 to 12 guests",
            time: "9:00 PM - 11:00 PM"
        )
    }
    
    func makeIconAttachment(systemName: String) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: systemName)?
            .withTintColor(UIColor(hex: "#D2D5DB"), renderingMode: .alwaysOriginal)

        attachment.bounds = CGRect(x: 0, y: -2, width: 14, height: 14)
        return attachment
    }
    
    func buildGuestsTimeText(
        guests: String,
        time: String
    ) -> NSAttributedString {

        let text = NSMutableAttributedString()

        // icon
        text.append(NSAttributedString(attachment: makeIconAttachment(systemName: "person.2")))

        // space after icon
        text.append(NSAttributedString(string: " ", attributes: infoTextAttributes))

        // guests text
        text.append(NSAttributedString(string: guests, attributes: infoTextAttributes))

        // exact gap between guest & time (image jaisa)
        text.append(NSAttributedString(string: "  ", attributes: infoTextAttributes))

        // icon
        text.append(NSAttributedString(attachment: makeIconAttachment(systemName: "clock")))

        // space after icon
        text.append(NSAttributedString(string: " ", attributes: infoTextAttributes))

        // time text
        text.append(NSAttributedString(string: time, attributes: infoTextAttributes))

        return text
    }

}
