//
//  CheckOutClipVC.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 26/01/23.
//

import UIKit
import PassKit

final class CheckOutClipVC: UIViewController {

    @IBOutlet weak var phoneNoLbl: UILabel!
    @IBOutlet weak var ticketTitleLbl: UILabel!
    @IBOutlet weak var ticketPriceLbl: UILabel!
    @IBOutlet weak var totalPriceLbl: UILabel!
    @IBOutlet weak var payBtn: PKPaymentButton!
    
    var phoneNo = ""
    var totalTicket = 1
    var ticketPrice = 90

    override func viewDidLoad() {
        super.viewDidLoad()
        phoneNoLbl.text = phoneNo
        ticketTitleLbl.text = "\(totalTicket)x VIP Skip the Line"
        ticketPriceLbl.text = "$\(totalTicket * ticketPrice)"
        totalPriceLbl.text = "$\(totalTicket * ticketPrice)"
        payBtn.addTarget(self, action: #selector(onClickPay), for: .touchUpInside)
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func onClickPay() {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String(describing: "QRCodeClipVC")) as? QRCodeClipVC {
            vc.totalTicket = totalTicket
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
