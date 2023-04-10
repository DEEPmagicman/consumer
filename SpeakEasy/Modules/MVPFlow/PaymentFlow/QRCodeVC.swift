//
//  QRCodeVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 09/02/23.
//

import UIKit
import SDWebImage
import PassKit

final class QRCodeVC: UIViewController {

    @IBOutlet private weak var venueImg: UIImageView!
    @IBOutlet private weak var venueLogoImg: UIImageView!
    @IBOutlet private weak var ticketDetailLbl: UILabel!
    @IBOutlet private weak var QRImg: UIImageView!
    @IBOutlet private weak var ticketListTableView: UITableView!
    @IBOutlet private weak var ticketListHeight: NSLayoutConstraint!
    @IBOutlet private weak var addToWalletBtn: PKAddPassButton!    
    @IBOutlet private weak var eventDetailsLbl: UILabel!

    var venueName = ""
    var bookingId = ""
    var venueAttachment = ""
    var venueLogo = ""
    var selectedTickets = [AppClipTicket]()
    private var ticketListHeightObservation: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        QRImg.image = generateQRCode(from: bookingId)
        loadImage()
        addToWalletBtn.addPassButtonStyle = .blackOutline
        ticketListTableView.register(UINib(nibName: "TicketDetailTVC", bundle: nil), forCellReuseIdentifier: "TicketDetailTVC")
        ticketListHeightObservation = ticketListTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.ticketListHeight.constant = self.ticketListTableView.contentSize.height
            self.ticketListTableView.layoutIfNeeded()
        }
        addToWalletBtn.addTarget(self, action: #selector(addToWalletBtnTapped), for: .touchUpInside)
        let tap = UITapGestureRecognizer(target: self, action: #selector(onClickEventDetail))
        eventDetailsLbl.isUserInteractionEnabled = true
        eventDetailsLbl.addGestureRecognizer(tap)
    }
    
    @objc private func onClickEventDetail() {
        // TODO: navigate to event detail page
    }
    
    @objc private func addToWalletBtnTapped() {
        // TODO: add to wallet API
    }
    
    private func loadImage() {
        venueImg.sd_setImage(with: URL(string: self.venueAttachment.imageURL),completed: nil)
        venueLogoImg.sd_setImage(with: URL(string: self.venueLogo.imageURL),completed: nil)
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
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
    
    @IBAction private func onBtnShare(_ sender: Any) {
       let msgText = """
Thank you for checking into \(venueName) with Speakeasy!

Access Your Ticket Here: https://appclip.speakeasygo.com/ticket-qrcode-generate?qrFor=booking&bookingId=\(bookingId)

Download Speaskeasy on the Apple App Store to stay updated on covers and wait times at your favorite venues. We hope to see you there!

Link to App: https://apps.apple.com/us/app/speakeasy-go/id1642351956
"""
        Utility.main.shareSocialWith(text: msgText)
    }
    
    @IBAction private func onClickClose(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension QRCodeVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        selectedTickets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketDetailTVC", for: indexPath) as! TicketDetailTVC
        cell.titleLbl.text = selectedTickets[indexPath.row].name
        cell.subTitleLbl.text = selectedTickets[indexPath.row].description
        cell.quantityLbl.text = "\(selectedTickets[indexPath.row].selectedQuantity ?? 0)x"
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        return cell
    }
}
