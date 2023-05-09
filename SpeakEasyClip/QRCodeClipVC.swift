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
    @IBOutlet private weak var ticketListTableView: UITableView!
    @IBOutlet private weak var ticketListHeight: NSLayoutConstraint!
    @IBOutlet private weak var QRImg: UIImageView!

    var venueAttachment = ""
    var venueLogo = ""
    var venueName = ""
    var bookingId = ""
    var selectedAppClipTickets = [AppClipTicket]()
    private var ticketListHeightObservation: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        ticketListTableView.register(UINib(nibName: "TicketDetailTVC", bundle: nil), forCellReuseIdentifier: "TicketDetailTVC")
        ticketListHeightObservation = ticketListTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.ticketListHeight.constant = self.ticketListTableView.contentSize.height
            self.ticketListTableView.layoutIfNeeded()
        }
        QRImg.image = generateQRCode(from: bookingId)
        loadImage()
    }
    
    @IBAction func onBtnShare(_ sender: Any) {
        let msgText = """
        Thank you for checking into \(venueName) with Speakeasy!

        Access Your Ticket Here: https://appclip.speakeasygo.com/ticket-qrcode-generate?qrFor=booking&bookingId=\(bookingId)

        Download Speakeasy on the Apple App Store to stay updated on covers and wait times at your favorite venues. We hope to see you there!

        Link to App: https://apps.apple.com/us/app/speakeasy-go/id1642351956
        """
        shareSocialWith(text: msgText)
    }
    
    func shareSocialWith(text: String) {
        let textToShare = [text]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = view
        self.present(activityViewController, animated: true, completion: nil)
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

extension QRCodeClipVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       selectedAppClipTickets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketDetailTVC", for: indexPath) as! TicketDetailTVC
        cell.titleLbl.text = selectedAppClipTickets[indexPath.row].name
        cell.subTitleLbl.text = selectedAppClipTickets[indexPath.row].description
        cell.quantityLbl.text = "\(selectedAppClipTickets[indexPath.row].selectedQuantity ?? 0)x"
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        return cell
    }
}
