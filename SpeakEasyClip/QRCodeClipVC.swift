//
//  QRCodeClipVC.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 26/01/23.
//

import UIKit

final class QRCodeClipVC: UIViewController {

    @IBOutlet weak var venueLbl: UILabel!
    @IBOutlet weak var ticketDetailLbl: UILabel!
    @IBOutlet weak var ticketTitleLbl: UILabel!
    @IBOutlet weak var ticketPriceLbl: UILabel!
    @IBOutlet weak var multipleTicketStackHeight: NSLayoutConstraint!
    @IBOutlet weak var previousTicketView: UIView!
    @IBOutlet weak var nextTicketView: UIView!
    @IBOutlet weak var previousTicketNoLbl: UILabel!
    @IBOutlet weak var nextTicketNoLbl: UILabel!
    
    var isGeneralAdmission = false
    var totalTicket = 1
    var currentTicketNo = 1
    var ticketPrice = 90

    override func viewDidLoad() {
        super.viewDidLoad()
        ticketDetailLbl.text = isGeneralAdmission ? "When in’s your turn present the above QR code to be scanned in." : "Walk up to front of line and present the above QR code to be scanned in."
        ticketPriceLbl.text = "$\(ticketPrice)"
        changeTicket()
        let tap = UITapGestureRecognizer(target: self, action: #selector(onClickNextTicket))
        nextTicketView.addGestureRecognizer(tap)
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(onClickPreviousTicket))
        previousTicketView.addGestureRecognizer(tap1)
    }
    
    func changeTicket() {
        if totalTicket > 1 {
            multipleTicketStackHeight.constant = 114
            if currentTicketNo == totalTicket {
                nextTicketView.isHidden = true
            } else {
                nextTicketView.isHidden = false
                nextTicketNoLbl.text = "Ticket \(currentTicketNo + 1)"
            }
            if currentTicketNo <= 1 {
                previousTicketView.isHidden = true
            } else {
                previousTicketView.isHidden = false
                previousTicketNoLbl.text = "Ticket \(currentTicketNo - 1)"
            }
            ticketTitleLbl.text = "\(isGeneralAdmission ? "General Admission" : "VIP Skip the Line") (\(currentTicketNo))"
            // TODO: change QR image from here (for currentTicketNo)
        } else {
            multipleTicketStackHeight.constant = 0
            nextTicketView.isHidden = true
            previousTicketView.isHidden = true
            ticketTitleLbl.text = "\(isGeneralAdmission ? "General Admission" : "VIP Skip the Line")"
        }
        
    }
    
    @objc func onClickNextTicket() {
        if currentTicketNo < totalTicket {
            currentTicketNo += 1
            changeTicket()
        }
    }

    @objc func onClickPreviousTicket() {
        if currentTicketNo <= totalTicket && currentTicketNo > 1 {
            currentTicketNo -= 1
            changeTicket()
        }
    }
}
