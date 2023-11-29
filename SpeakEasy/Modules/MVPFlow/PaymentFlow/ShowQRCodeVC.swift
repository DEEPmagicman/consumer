//
//  ShowQRCodeVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 29/11/23.
//

import UIKit
import PassKit

final class ShowQRCodeVC: UIViewController {

    @IBOutlet weak var qrImage: UIImageView!
    @IBOutlet weak var backupCode: UILabel!
    @IBOutlet weak var bookingDateTime: UILabel!
    @IBOutlet weak var addToWalletBtn: PKAddPassButton!
    @IBOutlet weak var ticketListTableView: UITableView!
    @IBOutlet weak var ticketListHeight: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var venueImg: UIImageView!
    @IBOutlet weak var venueNameLbl: UILabel!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var noteView: UIView!
    @IBOutlet weak var noteLbl: UILabel!
    
    var bookingId = ""
    var type: PaymentIntentType = .appClip
    var booking: Booking?
    private var pass: PKPass?
    private var ticketListHeightObservation: NSKeyValueObservation?
    weak var delegate: QRCodeVCNavigationDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addToWalletBtn.addPassButtonStyle = .blackOutline
        addToWalletBtn.addTarget(self, action: #selector(addToWalletBtnTapped), for: .touchUpInside)
        ticketListHeightObservation = ticketListTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.ticketListHeight.constant = self.ticketListTableView.contentSize.height
            self.ticketListTableView.layoutIfNeeded()
        }
    }
    
    private func setupData() {
        qrImage.image = generateQRCode(from: bookingId)
        backupCode.text = booking?.venueObject?.bookingCode ?? ""
        bookingDateTime.text = "Purchased on \(booking?.createdAt.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .HMMAMMMDD) ?? "")"
        if booking?.venueObject?.bookingCode ?? "" != "" {
            containerView.isUserInteractionEnabled = true
        }
        if let booking = booking {
            switch type {
            case .appClip:
                venueImg.sd_setImage(with: URL(string: (booking.venueObject?.venueAttachment.first?.key ?? "").imageURL),completed: nil)
//                venueLogoImg.sd_setImage(with: URL(string: (booking.venueObject?.logo?.key ?? "").imageURL),completed: nil)
                if booking.isCompedTicket == true, let inviteLink = booking.inviteLink {
                    titleLbl.text = inviteLink.name
//                    dateLbl.isHidden = false
                    venueNameLbl.isHidden = false
//                    dateLbl.text = inviteLink.date.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .EEEMMMD)
                } else {
                    titleLbl.text = booking.venueObject?.name
//                    dateLbl.isHidden = true
                    venueNameLbl.isHidden = true
                }
                if let note = booking.note, note != "" {
                    noteView.isHidden = false
                    noteLbl.text = note
                } else {
                    noteView.isHidden = true
                }
//                venueImgHeightConstraint.constant = 320
//                QRToImgBottomConstraint.constant = -100
            case .singleTickedEvent:
                venueImg.sd_setImage(with: URL(string: (booking.event?.flyer?.key ?? "").imageURL),completed: nil)
                titleLbl.text = booking.event?.title
//                dateLbl.text = booking.event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .EEEMMMD, useDayLightSavingTime: true, customTimeZone: booking.venueObject?.useTimezone ?? "")
//                dateLbl.isHidden = false
                venueNameLbl.text = booking.venueObject?.name
                venueNameLbl.isHidden = false
//                venueImgHeightConstraint.constant = 390
//                QRToImgBottomConstraint.constant = -170
            case .tieredTickedEvent:
                break
            }
            venueNameLbl.text = booking.venueObject?.name
        }
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
    
    @objc private func addToWalletBtnTapped() {
        var url = URL(string: "")
        switch type {
        case .appClip:
            url = URL(string: APIBuilder.appClipAppleWallet(booking?.id ?? ""))
        case .singleTickedEvent:
            url = URL(string: APIBuilder.eventAppleWallet(booking?.id ?? ""))
        case .tieredTickedEvent:
            break
        }
        guard let url = url else { return }
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
    
    @IBAction func onClickClose(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func onClickEventDetails(_ sender: Any) {
        delegate?.navigateToEventDetail(eventId: booking?.event?.eventId ?? "", venueDetail: booking?.venueObject, event: booking?.event)
        dismiss(animated: true)
    }
    
    @IBAction func onClickNeedSupport(_ sender: Any) {
        Navigate.externalURL(APIBuilder.supportURL)
    }
}

extension ShowQRCodeVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        booking?.uniqueTickets.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketDetailTVC", for: indexPath) as! TicketDetailTVC
        if booking?.isCompedTicket == true {
            cell.titleLbl.text = Constant.String.compedFreeTicket
            cell.subTitleLbl.text = Constant.String.enjoyYourFreeTicket
        } else {
            cell.titleLbl.text = booking?.uniqueTickets[indexPath.row].ticketName
            cell.subTitleLbl.text = booking?.ticketDetails?.first(where: { $0.ticketId == booking?.uniqueTickets[indexPath.row].ticketId })?.ticketDescription
        }
        cell.quantityLbl.text = "\(booking?.uniqueTickets[indexPath.row].selectedQuantity ?? 0)x"
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        return cell
    }
}


extension ShowQRCodeVC: PKAddPassesViewControllerDelegate {
    func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
        controller.dismiss(animated: true)
        let pkl = PKPassLibrary()
        if let pass = pass, pkl.containsPass(pass) {
            Alert.showToast("Ticket added to wallet", vc: self)
        }
    }
}
