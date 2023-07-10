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
    func navigateToEventDetail(eventId: String, venueDetail: ClipVenue?, event: Event?)
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

    var bookingId = ""
    var type: PaymentIntentType = .appClip
    var booking: Booking?
    weak var delegate: QRCodeVCNavigationDelegate?
    private var ticketListHeightObservation: NSKeyValueObservation?
    private var pass: PKPass?
    private var gradient: CAGradientLayer?
    private var venueImgHeightObservation: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        gradient = venueImg.setGradientColor()
        getBooking(id: bookingId)
        venueImgHeightObservation = venueImg.observe(\.bounds, options: []) { [weak self] _, _ in
            self?.gradient = self?.venueImg.setGradientColor()
        }
        setupData()
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
    
    private func setupData() {
        QRImg.image = generateQRCode(from: bookingId)
        if let booking = booking {
            switch type {
            case .appClip:
                venueImg.sd_setImage(with: URL(string: (booking.venueObject?.venueAttachment.first?.key ?? "").imageURL),completed: nil)
                venueLogoImg.sd_setImage(with: URL(string: (booking.venueObject?.logo?.key ?? "").imageURL),completed: nil)
                if booking.isCompedTicket == true, let inviteLink = booking.inviteLink {
                    titleLbl.text = inviteLink.name
                    dateLbl.isHidden = false
                    venueNameLbl.isHidden = false
                    dateLbl.text = inviteLink.date.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .EEEMMMD)
                } else {
                    titleLbl.text = booking.venueObject?.name
                    dateLbl.isHidden = true
                    venueNameLbl.isHidden = true
                }
                eventDetailsLbl.isHidden = true
                venueImgHeightConstraint.constant = 320
                QRToImgBottomConstraint.constant = -100
            case .singleTickedEvent:
                venueImg.sd_setImage(with: URL(string: (booking.event?.flyer?.key ?? "").imageURL),completed: nil)
                titleLbl.text = booking.event?.title
                dateLbl.text = booking.event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .EEEMMMD, useDayLightSavingTime: true, customTimeZone: booking.venueObject?.useTimezone ?? "")
                dateLbl.isHidden = false
                venueNameLbl.text = booking.venueObject?.name
                venueNameLbl.isHidden = false
                eventDetailsLbl.isHidden = false
                venueImgHeightConstraint.constant = 390
                QRToImgBottomConstraint.constant = -170
            case .tieredTickedEvent:
                break
            }
            venueNameLbl.text = booking.venueObject?.name
        }
    }
    
    @objc private func onClickEventDetail() {
        delegate?.navigateToEventDetail(eventId: booking?.event?.eventId ?? "", venueDetail: booking?.venueObject, event: booking?.event)
        dismiss(animated: true)
    }
    
    private func getBooking(id: String) {
        if booking == nil {
            Loader.show()
        }
        PaymentPresenter.getBooking(bookingId: id) { [weak self] isSuccess, errMsg, booking in
            Loader.hide()
            guard let self = self else { return }
            if isSuccess {
                self.booking = booking
                self.setupData()
                self.ticketListTableView.reloadData()
            } else {
                self.eventDetailsLbl.isHidden = true
            }
        }
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
        var msgText = ""
        switch type {
        case .appClip:
            msgText = """
     Thank you for checking into \(booking?.venueObject?.name ?? "Venue") with Speakeasy!

     Access Your Ticket Here: \(String(format: APIBuilder.QAWebURL, bookingId))

     Download Speakeasy on the Apple App Store to stay updated on covers and wait times at your favorite venues. We hope to see you there!

     Link to App: \(APIBuilder.appStoreURL)
     """
        case .singleTickedEvent, .tieredTickedEvent:
            msgText = """

        You’re going to \(booking?.event?.title.capitalized ?? "EVENT")! \(UserDefault.shared.user?.firstName ?? "") \(UserDefault.shared.user?.lastName ?? "") has sent you a ticket:

        Access your ticket here: \(String(format: APIBuilder.QAWebURL, bookingId))

        Download Speakeasy for easy entry at \(booking?.venueObject?.name ?? "Venue"):
         \(APIBuilder.appStoreURL)

        Enjoy & live life LIVE!
        """
        }
        Utility.main.shareSocialWith(text: msgText)
    }
    
    @IBAction private func onClickClose(_ sender: Any) {
        dismiss(animated: true)
    }
}

extension QRCodeVC: UITableViewDelegate, UITableViewDataSource {
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

extension QRCodeVC: PKAddPassesViewControllerDelegate {
    func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
        controller.dismiss(animated: true)
        let pkl = PKPassLibrary()
        if let pass = pass, pkl.containsPass(pass) {
            Alert.showToast("Ticket added to wallet", vc: self)
        }
    }
}
