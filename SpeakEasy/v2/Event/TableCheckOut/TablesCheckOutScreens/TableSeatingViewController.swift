//
//  TableSeatingViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 17/02/26.
//

import UIKit

class TableSeatingViewController: UIViewController {
    
    
    @IBOutlet weak var tableName: UILabel!
//    @IBOutlet weak var totalAmount: UILabel!
//    @IBOutlet weak var secondAmountLbl: UILabel!
    @IBOutlet weak var tableDetailLbl: UILabel!
    @IBOutlet weak var tableDescriptionLbl: UILabel!
    @IBOutlet weak var guestAndTimeLbl: UILabel!
    @IBOutlet weak var maxiMumGuestLbl: UILabel!
    @IBOutlet weak var miniMumAmountLbl: UILabel!
    @IBOutlet weak var feesLbl: UILabel!
    @IBOutlet weak var increaseBtn: UIButton!
    @IBOutlet weak var decreaseBtn: UIButton!
    
    let infoTextAttributes: [NSAttributedString.Key: Any] = [
        .font: AppFont.font(weight: .regular, size: 12),
        .foregroundColor: UIColor(hex: "#D2D5DB")
    ]
    var seatingArea: SeatingArea?
    


    private var currentGuestCount: Int = 0


    override func viewDidLoad() {
        super.viewDidLoad()
        configureData()
    }
    
    
    private func configureData() {
        
        guard let item = seatingArea else { return }
        
        tableName.text = item.name
        tableDescriptionLbl.text = item.highlight?.isEmpty == false
            ? item.highlight
            : item.description
        
        // Pricing
//        if item.hidePricing == true {
////            totalAmount.text = ""
//            secondAmountLbl.text = ""
//        } else {
//            
//            if let deposit = item.depositWithFees {
//                totalAmount.text = "$\(deposit.decimalFormat(true))"
//            } else if let deposit = item.deposit {
//                totalAmount.text = "$\(deposit.decimalFormat(true))"
//            }
//            
//            if let minimum = item.minimum {
//                secondAmountLbl.text = "$\(minimum.decimalFormat(true)) min."
//                miniMumAmountLbl.text = "$\(minimum.decimalFormat(true))"
//            }
//        }
        
        // Guests
        currentGuestCount = item.defaultGuest ?? 1
        maxiMumGuestLbl.text = "Max \(item.maxGuest ?? 0) Guests"
        guestAndTimeLbl.text = "\(currentGuestCount)"
        
        updateGuestButtons()
        
        // Time slot
        if let slot = item.timeSlots?.first,
           let start = slot.startTime,
           let startDate = start.dateFormatter(formate: .yyyyMMddTHHmmssSSSz, isUTC: true) {
            
            let startTime = startDate.string(format: .hmma, isUTC: false)
            
            var endTime = ""
            if let end = slot.endTime,
               let endDate = end.dateFormatter(formate: .yyyyMMddTHHmmssSSSz, isUTC: true) {
                endTime = endDate.string(format: .hmma, isUTC: false)
            }
            
            let finalTime = endTime.isEmpty ? startTime : "\(startTime) - \(endTime)"
            
            tableDetailLbl.attributedText = buildGuestsTimeText(
                guests: "\(item.defaultGuest ?? 1) to \(item.maxGuest ?? 0) Guests",
                time: finalTime
            )
        }
        
        // Fees
        if let deposit = item.depositWithFees,
           let base = item.deposit {
            let fee = deposit - base
            feesLbl.text = "$\(fee.decimalFormat(true))"
        }
    }

    
    private func updateGuestButtons() {
        
        guard let maxGuest = seatingArea?.maxGuest else { return }
        
        increaseBtn.isEnabled = currentGuestCount < maxGuest
        increaseBtn.alpha = currentGuestCount < maxGuest ? 1.0 : 0.5
        
        decreaseBtn.isEnabled = currentGuestCount > 1
        decreaseBtn.alpha = currentGuestCount > 1 ? 1.0 : 0.5
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
    
    func makeIconAttachment(systemName: String) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: systemName)?
            .withTintColor(UIColor(hex: "#D2D5DB"), renderingMode: .alwaysOriginal)

        attachment.bounds = CGRect(x: 0, y: -2, width: 14, height: 14)
        return attachment
    }
    
    @IBAction func onClickIncreaseGuest(_ sender: Any) {
        
        guard let maxGuest = seatingArea?.maxGuest else { return }
            
            if currentGuestCount < maxGuest {
                currentGuestCount += 1
                guestAndTimeLbl.text = "\(currentGuestCount)"
            }
            
            updateGuestButtons()
    }

    @IBAction func onClickCheckoutBtn(_ sender: Any) {
        guard let item = seatingArea else { return }
          
          if item.hideCheckout == true {
              print("Inquiry flow")
          } else {
              print("Proceed to checkout with \(currentGuestCount) guests")
          }
    }

    @IBAction func onClickDecreaseGuest(_ sender: Any) {
        
        if currentGuestCount > 1 {
                currentGuestCount -= 1
                guestAndTimeLbl.text = "\(currentGuestCount)"
            }
            
            updateGuestButtons()
        
    }

    
}
