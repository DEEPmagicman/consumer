//
//  QRCodeClipVC.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 26/01/23.
//

import UIKit

final class QRCodeClipVC: UIViewController {

    @IBOutlet private weak var venueLbl: UILabel!
    @IBOutlet private weak var ticketDetailLbl: UILabel!
    @IBOutlet private weak var ticketTitleLbl: UILabel!
    @IBOutlet private weak var ticketPriceLbl: UILabel!
    @IBOutlet private weak var ticketQuantityLbl: UILabel!
    
    var isGeneralAdmission = false
    var totalTicket = 1
    var ticketPrice = 90

    override func viewDidLoad() {
        super.viewDidLoad()
        if isGeneralAdmission {
            ticketDetailLbl.text = "When it’s your turn present the above QR code to be scanned in."
            ticketTitleLbl.text = "General Admission"
        } else {
            ticketDetailLbl.text = "Walk up to front of line and present the above QR code to be scanned in."
            ticketTitleLbl.text = "VIP Skip the Line"
        }
        ticketPriceLbl.text = "$\(ticketPrice)"
        ticketQuantityLbl.text = "\(totalTicket)x"
    }
}
