//
//  QRCodeClipVC.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 26/01/23.
//

import UIKit

final class QRCodeClipVC: UIViewController {

    @IBOutlet private weak var venueImg: UIImageView!
    @IBOutlet private weak var titleLbl: UILabel!
    @IBOutlet private weak var venueLogoImg: UIImageView!
    @IBOutlet private weak var ticketListTableView: UITableView!
    @IBOutlet private weak var ticketListHeight: NSLayoutConstraint!
    @IBOutlet private weak var QRImg: UIImageView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var ticketCodeView: UIView!
    @IBOutlet weak var ticketCode: UILabel!
    @IBOutlet weak var ticketCreatedTime: UILabel!
    
    var venueAttachment = ""
    var venueLogo = ""
    var venueName = ""
    var bookingId = ""
    var selectedAppClipTickets = [AppClipTicket]()
    private var ticketListHeightObservation: NSKeyValueObservation?
    private var isAlertDisplayed = false
    var bookingCode = String()
    var createdAT = String()

    override func viewDidLoad() {
        super.viewDidLoad()
        containerView.isUserInteractionEnabled = false
        ticketCode.text = bookingCode
        ticketCreatedTime.text = "Purchased on \(createdAT)"
        venueImg.setGradientColor()
        ticketListTableView.register(UINib(nibName: "TicketDetailTVC", bundle: nil), forCellReuseIdentifier: "TicketDetailTVC")
        ticketListHeightObservation = ticketListTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.ticketListHeight.constant = self.ticketListTableView.contentSize.height
            self.ticketListTableView.layoutIfNeeded()
        }
        QRImg.image = generateQRCode(from: bookingId)
        loadImage()
        titleLbl.text = "\(venueName) - Cover"
        ticketCodeView.isHidden = true
//        if bookingCode != "" {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(qrImageTapped))
            containerView.addGestureRecognizer(tapGesture)
//        }
    }
    
    @objc func qrImageTapped() {
        UIView.transition(with: containerView, duration: 1, options: .transitionFlipFromRight, animations: {[weak self] in
            guard let self = self else { return }
            self.ticketCodeView.isHidden = !self.ticketCodeView.isHidden
            self.QRImg.isHidden = !self.QRImg.isHidden
        })
    }
    
    @IBAction func onBtnShare(_ sender: Any) {
        let msgText = """
        Thank you for checking into \(venueName) with Speakeasy!

        Access Your Ticket Here: \(String(format: SharedURL.QAWebURL, bookingId))

        Download Speakeasy on the Apple App Store to stay updated on covers and wait times at your favorite venues. We hope to see you there!

        Link to App: \(SharedURL.appStoreURL)
        """
        shareSocialWith(text: msgText)
    }
    
    func shareSocialWith(text: String) {
        let textToShare = [text]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = view
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    // NOTE: hide venue logo for now
    func loadImage() {
        DispatchQueue.global().async {
            guard let imgUrl = URL(string: "\(SharedURL.amazonStorage)\(self.venueAttachment)") else { return } //                    let logoUrl = URL(string: "\(SharedURL.amazonStorage)\(self.venueLogo)")
            do {
                let imgData = try Data(contentsOf: imgUrl)
//                let logoData = try Data(contentsOf: logoUrl)
                DispatchQueue.main.async {
                    self.venueImg.image = UIImage(data: imgData)
//                    self.venueLogoImg.image = UIImage(data: logoData)
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
                if bookingCode != "" {
                    containerView.isUserInteractionEnabled = true
                }
                return UIImage(ciImage: output)
            }
        }
        return nil
    }
    
    @IBAction func onClickBuyAnother(_ sender: Any) {
        if isAlertDisplayed {
            navigationController?.popToRootViewController(animated: true)
        } else {
            alertPopup("", "Make sure that you've received a booking SMS or take a screen-shot of QR before buying another ticket.")
            isAlertDisplayed = true
        }
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
