//
//  QRCodeClipVC.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 26/01/23.
//

import UIKit

final class QRCodeClipVC: UIViewController {

    @IBOutlet private weak var venueImg: UIImageView!
    @IBOutlet private weak var venueLogoImg: UIImageView!
    @IBOutlet private weak var ticketDetailLbl: UILabel!
    @IBOutlet private weak var ticketTitleLbl: UILabel!
    @IBOutlet private weak var ticketSubTitleLbl: UILabel!
    @IBOutlet private weak var ticketQuantityLbl: UILabel!
    @IBOutlet private weak var QRImg: UIImageView!
    
    var isGeneralAdmission = false
    var venueAttachment = ""
    var venueLogo = ""
    var ticketInfo = ""
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
        ticketSubTitleLbl.text = ticketInfo
        ticketQuantityLbl.text = "\(totalTicket)x"
        QRImg.image = generateQRCode(from: bookingId)
        loadImage()
    }
    
    func loadImage() {
        DispatchQueue.global().async {
            guard let imgUrl = URL(string: "https://speakeasy-storage.s3.amazonaws.com/\(self.venueAttachment)"), let logoUrl = URL(string: "https://speakeasy-storage.s3.amazonaws.com/\(self.venueLogo)") else { return }
            do {
                let imgData = try Data(contentsOf: imgUrl)
                let logoData = try Data(contentsOf: logoUrl)
                DispatchQueue.main.async {
                    self.venueImg.image = UIImage(data: imgData)
                    self.venueLogoImg.image = UIImage(data: logoData)
                }
            } catch {}
        }
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 10, y: 10)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        return nil
    }
}
