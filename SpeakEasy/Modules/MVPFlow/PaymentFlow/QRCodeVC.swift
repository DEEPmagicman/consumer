//
//  QRCodeVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 09/02/23.
//

import UIKit
import SDWebImage
import PassKit

protocol QRCodeVCNavigationDelegate: AnyObject {
    func navigateToEventDetail(eventId: String)
}

final class QRCodeVC: UIViewController {

    @IBOutlet private weak var titleLbl: UILabel!
    @IBOutlet private weak var dateLbl: UILabel!
    @IBOutlet private weak var venueNameLbl: UILabel!
    @IBOutlet private weak var venueImg: UIImageView!
    @IBOutlet private weak var venueLogoImg: UIImageView!
    @IBOutlet private weak var QRImg: UIImageView!
    @IBOutlet private weak var ticketListTableView: UITableView!
    @IBOutlet private weak var ticketListHeight: NSLayoutConstraint!
    @IBOutlet private weak var addToWalletBtn: PKAddPassButton!
    @IBOutlet private weak var eventDetailsLbl: UILabel!
    @IBOutlet private weak var venueImgHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var QRToImgBottomConstraint: NSLayoutConstraint!

    var venueName = ""
    var bookingId = ""
    var venueAttachment = ""
    var venueLogo = ""
    var selectedTickets = [AppClipTicket]()
    var type: PaymentIntentType = .appClip
    weak var delegate: QRCodeVCNavigationDelegate?
    private var ticketListHeightObservation: NSKeyValueObservation?
    private var pass: PKPass?

    override func viewDidLoad() {
        super.viewDidLoad()
        QRImg.image = generateQRCode(from: bookingId)
        loadImage()
        addToWalletBtn.addPassButtonStyle = .blackOutline
        switch type {
        case .appClip:
            titleLbl.text = venueName
            dateLbl.isHidden = true
            venueNameLbl.isHidden = true
            eventDetailsLbl.isHidden = true
            venueImgHeightConstraint.constant = 320
            QRToImgBottomConstraint.constant = -100
        case .singleTickedEvent:
            titleLbl.text = "Event"
            dateLbl.text = "Date"
            dateLbl.isHidden = false
            venueNameLbl.text = venueName
            venueNameLbl.isHidden = false
            eventDetailsLbl.isHidden = false
            venueImgHeightConstraint.constant = 390
            QRToImgBottomConstraint.constant = -170
        case .tieredTickedEvent:
            break
        }
        venueNameLbl.text = venueName
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
        delegate?.navigateToEventDetail(eventId: "EVE-AYXQIY")
        dismiss(animated: true)
    }
    
    @objc private func addToWalletBtnTapped() {
        guard let url = URL(string: APIBuilder.appClipAppleWallet(bookingId)) else { return }
        let pkl = PKPassLibrary()
        if let pass = pass {
            if pkl.containsPass(pass) {
                Alert.showToast("Ticket already Added", vc: self)
            } else {
                presentAddPKPass(pass)
            }
            return
        }
        Loader.show()
        URLSession.shared.fetchData(at: url) { [weak self] data, error in
            guard let self = self else {
                Loader.hide()
                return
            }
            if let data = data {
                do {
                    let pass = try PKPass(data: data)
                    Loader.hide()
                    self.presentAddPKPass(pass)
                    self.pass = pass
                } catch {
                    Loader.hide()
                    Alert.showAlertSheet(style: .alert, title: "Incorrect data", message: "")
                }
            } else {
                Loader.hide()
                Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
            }
        }
    }
    
    private func presentAddPKPass(_ pass: PKPass) {
        if let vc = PKAddPassesViewController(pass: pass) {
            DispatchQueue.main.async {
                vc.delegate = self
                self.present(vc, animated: true)
            }
        }
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
        dismiss(animated: true)
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

extension QRCodeVC: PKAddPassesViewControllerDelegate {
    func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
        controller.dismiss(animated: true)
        let pkl = PKPassLibrary()
        if let pass = pass, pkl.containsPass(pass) {
            Alert.showToast("Ticket added to wallet", vc: self)
        }
    }
}
