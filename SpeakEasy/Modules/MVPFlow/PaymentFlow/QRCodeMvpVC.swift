//
//  QRCodeMvpVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 09/02/23.
//

import UIKit
import SDWebImage

final class QRCodeMvpVC: UIViewController {

    @IBOutlet weak var venueImg: UIImageView!
    @IBOutlet weak var venueLogoImg: UIImageView!
    @IBOutlet weak var ticketTitleLbl: UILabel!
    @IBOutlet weak var ticketSubTitle: UILabel!
    @IBOutlet weak var ticketQuantityLbl: UILabel!
    @IBOutlet weak var ticketDetailLbl: UILabel!
    @IBOutlet weak var QRImg: UIImageView!
    
    var isGeneralAdmission = false
    var totalTicket = 1
    var ticketPrice = 90
    var venueName = ""
    var bookingId = ""
    var venueAttachment = ""
    var venueLogo = ""
    var ticketInfo = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        if isGeneralAdmission {
            ticketDetailLbl.text = "When it’s your turn present the above QR code to be scanned in."
            ticketTitleLbl.text = "General Admission"
        } else {
            ticketDetailLbl.text = "Walk up to front of line and present the above QR code to be scanned in."
            ticketTitleLbl.text = "VIP Skip the Line"
        }
        ticketSubTitle.text = ticketInfo
        ticketQuantityLbl.text = "\(totalTicket)x"
        QRImg.image = generateQRCode(from: bookingId)
        loadImage()
    }
    
    func loadImage() {
        let imgStr = "https://speakeasy-storage.s3.amazonaws.com/\(self.venueAttachment)"
        let logoStr = "https://speakeasy-storage.s3.amazonaws.com/\(self.venueLogo)"
        venueImg.sd_setImage(with: URL(string: imgStr),completed: nil)
        venueLogoImg.sd_setImage(with: URL(string: logoStr),completed: nil)
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
    
    @IBAction func onBtnShare(_ sender: Any) {
       let msgText = """
Thank you for checking into \(venueName) with Speakeasy!

Access Your Ticket Here: https://appclip.speakeasygo.com/ticket-qrcode-generate?qrFor=booking&bookingId=\(bookingId)

Download Speaskeasy on the Apple App Store to stay updated on covers and wait times at your favorite venues. We hope to see you there!

Link to App: https://apps.apple.com/us/app/speakeasy-go/id1642351956
"""
        
        Utility.main.shareSocialWith(text: msgText)
    }
    
    @IBAction func onClickClose(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

