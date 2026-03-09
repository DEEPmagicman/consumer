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
    @IBOutlet weak var shimmerView: ShimmerView!
    let infoTextAttributes: [NSAttributedString.Key: Any] = [
        .font: AppFont.font(weight: .regular, size: 12),
        .foregroundColor: UIColor(hex: "#D2D5DB")
    ]
    
    var onBookTap: (() -> Void)?

    
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
        stopShimmer()
    }
    
    func startShimmer() {
          shimmerView.isHidden = false
          shimmerView.startAnimating()
          tableName.isHidden = true
          totalAmount.isHidden = true
          secondAmountLbl.isHidden = true
          tableDetailLbl.isHidden = true
          tableDescriptionLbl.isHidden = true
          bookBtn.isHidden = true
      }

      func stopShimmer() {
          shimmerView.stopAnimating()
          shimmerView.isHidden = true
          tableName.isHidden = false
          totalAmount.isHidden = false
          secondAmountLbl.isHidden = false
          tableDetailLbl.isHidden = false
          tableDescriptionLbl.isHidden = false
          bookBtn.isHidden = false
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
        if !time.isEmpty {
            text.append(NSAttributedString(attachment: makeIconAttachment(systemName: "clock")))
        }

        // space after icon
        text.append(NSAttributedString(string: " ", attributes: infoTextAttributes))

        // time text
        text.append(NSAttributedString(string: time, attributes: infoTextAttributes))

        return text
    }
    
    @IBAction func bookButtonTapped(_ sender: UIButton) {
        onBookTap?()
    }
}
