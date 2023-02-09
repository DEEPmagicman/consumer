//
//  QRCodeMvpVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 09/02/23.
//

import UIKit

final class QRCodeMvpVC: UIViewController {

    @IBOutlet weak var venueLbl: UILabel!
    @IBOutlet weak var ticketDetailLbl: UILabel!
    @IBOutlet weak var ticketPriceLbl: UILabel!
    @IBOutlet weak var ticketTitleLbl: UILabel!
    @IBOutlet weak var ticketQuantityLbl: UILabel!
    @IBOutlet weak var QRImg: UIImageView!

    var isGeneralAdmission = false
    var totalTicket = 1
    var ticketPrice = 90
    var venueName = ""
    var bookingId = ""

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
        QRImg.image = generateQRCode(from: bookingId)
        venueLbl.text = "Welcome to \(venueName)!"
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        return nil
    }
    
    @IBAction func onClickClose(_ sender: Any) {
        for controller in self.navigationController!.viewControllers {
            if controller.isKind(of: MVPVenueListVc.self) {
                self.navigationController?.popToViewController(controller, animated: true)
            }
        }
    }
}

