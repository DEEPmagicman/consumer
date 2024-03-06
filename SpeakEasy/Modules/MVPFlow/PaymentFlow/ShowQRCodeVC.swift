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
    @IBOutlet weak var ticketCodeView: UIView!
    @IBOutlet weak var subTotalView: UIView!
    @IBOutlet weak var subTotalAmount: UILabel!
    @IBOutlet weak var processingFeeView: UIView!
    @IBOutlet weak var processingFeeAmount: UILabel!
    @IBOutlet weak var customFeeView: UIView!
    @IBOutlet weak var customFeeName: UILabel!
    @IBOutlet weak var customFeeAmount: UILabel!
    @IBOutlet weak var salesTaxView: UIView!
    @IBOutlet weak var salesTaxAmount: UILabel!
    @IBOutlet weak var totalAmount: UILabel!
    @IBOutlet weak var noFeeView: UIView!
    @IBOutlet weak var venueLogo: UIImageView!
    @IBOutlet weak var monthLbl: UILabel!
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var eventDetailView: UIView!
    @IBOutlet weak var eventTicketDetailsView: UIView!
    @IBOutlet weak var coverTicketDetailsView: UIView!
    @IBOutlet weak var coverTicketLogo: UIImageView!
    @IBOutlet weak var coverTicketDate: UILabel!
    @IBOutlet weak var coverTicketCity: UILabel!
    @IBOutlet weak var ticketTypeLbl: UILabel!
    @IBOutlet weak var qrImageFrame: UIImageView!
    @IBOutlet weak var discountView: UIView!
    @IBOutlet weak var discountAmount: UILabel!
    @IBOutlet weak var bookingTitleLbl: UILabel!
    @IBOutlet weak var salesTaxName: UILabel!
    
    var bookingId = ""
    var type: PaymentIntentType = .appClip
    var booking: Booking?
    private var pass: PKPass?
    private var ticketListHeightObservation: NSKeyValueObservation?
    weak var delegate: QRCodeVCNavigationDelegate?
    private var venueImgHeightObservation: NSKeyValueObservation?
    private var gradient: CAGradientLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
        ticketCodeView.isHidden = true
        getBooking(id: bookingId)
        addToWalletBtn.addPassButtonStyle = .blackOutline
        addToWalletBtn.addTarget(self, action: #selector(addToWalletBtnTapped), for: .touchUpInside)
        ticketListTableView.register(UINib(nibName: "TicketDetailTVC", bundle: nil), forCellReuseIdentifier: "TicketDetailTVC")
        ticketListTableView.delegate = self
        ticketListTableView.dataSource = self
        ticketListHeightObservation = ticketListTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.ticketListHeight.constant = self.ticketListTableView.contentSize.height
            self.ticketListTableView.layoutIfNeeded()
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(qrImageTapped))
        containerView.isUserInteractionEnabled = false
        containerView.addGestureRecognizer(tapGesture)
        gradient = venueImg.setGradientColor()
        venueImgHeightObservation = venueImg.observe(\.bounds, options: []) { [weak self] _, _ in
            self?.gradient = self?.venueImg.setGradientColor()
        }
    }
    
    @objc func qrImageTapped() {
        containerView.isUserInteractionEnabled = false
        flipView()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.flipView()
            self.containerView.isUserInteractionEnabled = true
        }
    }
    
    private func flipView() {
        UIView.transition(with: containerView, duration: 1, options: .transitionFlipFromRight, animations: {[weak self] in
            guard let self = self else { return }
            self.ticketCodeView.isHidden = !self.ticketCodeView.isHidden
            self.qrImage.isHidden = !self.qrImage.isHidden
            self.qrImageFrame.isHidden = !self.qrImageFrame.isHidden
        })
    }
    
    private func setupData() {
        bookingTitleLbl.text = booking?.bookingType == "APPCLIP" || booking?.bookingType == "FREE_APPCLIP" ? "Venue Cover" : "Table Reservation"
        if booking?.bookingType == "INVITE_LINK" {
            bookingTitleLbl.text = booking?.inviteLink?.name ?? "-"
            
        } else if booking?.bookingType == "COMPED_TICKET" {
            bookingTitleLbl.text = booking?.guestList?.name ?? "-"
        }
        
        let string = """
    {
        "id": "\(bookingId)",
        "type": "BOOKING"
    }
"""
        qrImage.image = generateQRCode(from: string)
        backupCode.text = booking?.venueObject?.bookingCode ?? ""
        bookingDateTime.text = "Purchased on \(booking?.createdAt.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .HMMAMMMDD, isUTC: true, customTimeZone: booking?.venueObject?.useTimezone ?? "") ?? "")"
        if booking?.venueObject?.bookingCode ?? "" != "" {
            containerView.isUserInteractionEnabled = true
        }
        venueLogo.sd_setImage(with: URL(string: (booking?.venueObject?.logo?.key ?? "").imageURL),completed: nil)
        coverTicketLogo.sd_setImage(with: URL(string: (booking?.venueObject?.logo?.key ?? "").imageURL),completed: nil)
        if let booking = booking {
            switch type {
            case .appClip:
                venueImg.sd_setImage(with: URL(string: (booking.venueObject?.venueAttachment?.first?.key ?? "").imageURL),completed: nil)
                if booking.isCompedTicket == true, let inviteLink = booking.inviteLink {
                    titleLbl.text = inviteLink.name
                    dateLbl.text = booking.guestList?.startTime.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .DD)
                    monthLbl.text = booking.guestList?.startTime.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .MMM)
                } else {
                    titleLbl.text = booking.venueObject?.name
                    monthLbl.text = booking.createdAt.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .MMM, useDayLightSavingTime: true, customTimeZone: booking.venueObject?.useTimezone ?? "")
                    dateLbl.text = booking.createdAt.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .DD, useDayLightSavingTime: true, customTimeZone: booking.venueObject?.useTimezone ?? "")
                }
                if let note = booking.note, note != "" {
                    noteView.isHidden = false
                    noteLbl.text = note
                } else {
                    noteView.isHidden = true
                }
                venueNameLbl.text = booking.venueObject?.city
                coverTicketDate.text = "-"
                if booking.bookingType == "INVITE_LINK" || booking.bookingType == "COMPED_TICKET" {
                    coverTicketDate.text = "\(booking.guestList?.startTime.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .EEEMMMD, useDayLightSavingTime: true, customTimeZone: booking.venueObject?.useTimezone ?? "") ?? ""), \(booking.guestList?.startTime.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .hmm_a, customTimeZone: booking.venueObject?.useTimezone ?? "") ?? "")"
                } else {
                    coverTicketDate.text = booking.createdAt.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .EEEMMMD, useDayLightSavingTime: true, customTimeZone: booking.venueObject?.useTimezone ?? "")
                }
                coverTicketCity.text = "\(booking.venueObject?.name ?? ""), \(booking.venueObject?.city ?? "")"
                venueLogo.isHidden = false
                eventTicketDetailsView.isHidden = true
                coverTicketDetailsView.isHidden = false
                ticketTypeLbl.text = booking.venueObject?.venueSettings?.isOrganizer == true ? "Organizer Details" : "Venue Details"
            case .singleTickedEvent:
                venueImg.sd_setImage(with: URL(string: (booking.event?.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
                titleLbl.text = booking.event?.title
                monthLbl.text = booking.event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .MMM, useDayLightSavingTime: true, customTimeZone: booking.venueObject?.useTimezone ?? "")
                dateLbl.text = booking.event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .DD, useDayLightSavingTime: true, customTimeZone: booking.venueObject?.useTimezone ?? "")
                venueNameLbl.text = "\((booking.event?.customVenue != nil && booking.venueObject?.venueSettings?.isOrganizer == true) ? "\(booking.event?.customVenue?.name ?? "") by \(booking.venueObject?.name ?? "")" : "\(booking.venueObject?.name ?? "")"), \(booking.event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .hmma, useDayLightSavingTime: true, customTimeZone: booking.venueObject?.useTimezone ?? "") ?? "")"
                venueLogo.isHidden = true
                eventTicketDetailsView.isHidden = false
                coverTicketDetailsView.isHidden = true
                ticketTypeLbl.text = "Event Details"
            case .tieredTickedEvent:
                break
            }
            //            venueNameLbl.text = booking.venueObject?.name
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
    
    private func getBooking(id: String) {
        Loader.show()
        PaymentPresenter.getBooking(bookingId: id) { [weak self] isSuccess, errMsg, booking in
            Loader.hide()
            guard let self = self else { return }
            if isSuccess {
                self.booking = booking
                self.setupData()
                self.setFeeData()
                self.ticketListTableView.reloadData()
            } else {
                self.eventDetailView.isHidden = true
            }
        }
    }
    
    private func setFeeData() {
        totalAmount.text = "-"
        switch booking?.bookingType ?? "" {
        case "FREE_EVENT_TICKET", "FREE_APPCLIP":
            totalAmount.text = "\(booking?.venueObject?.venueSettings?.currencySymbol ?? "$")\((booking?.fees?.total ?? 0).decimalFormat(true))"
        case "EVENT_TICKET":
            if booking?.venueObject?.event?.first?.upfront == false {
                processingFeeView.isHidden = booking?.fees?.processingFee ?? 0 == 0 ? true : false
                salesTaxView.isHidden = booking?.fees?.salesTax ?? 0 == 0 ? true : false
                customFeeView.isHidden = booking?.fees?.customFee ?? 0 == 0 ? true : false
                discountView.isHidden = booking?.fees?.discount ?? 0 == 0 ? true : false
                subTotalView.isHidden = processingFeeView.isHidden && salesTaxView.isHidden && customFeeView.isHidden && discountView.isHidden ? true : false
            }
        case "APPCLIP":
            let ticketId = booking?.bookingHasItem.first?.ticketId
            let ticket = booking?.venueObject?.appClipTicket?.filter({$0.id == ticketId})
            if ticket?.first?.isCustom == true {
                processingFeeView.isHidden = booking?.fees?.processingFee ?? 0 == 0 || booking?.venueObject?.venueSettings?.customCoverTicketFeesSettings?.isProcessingFeePassToCustomer == false  ? true : false
                salesTaxView.isHidden = booking?.fees?.salesTax ?? 0 == 0 || booking?.venueObject?.venueSettings?.customCoverTicketFeesSettings?.isEnableSalesTax == false ? true : false
                customFeeView.isHidden = booking?.fees?.customFee ?? 0 == 0 || booking?.venueObject?.venueSettings?.customCoverTicketFeesSettings?.isEnableCustomFee == false ? true : false
                subTotalView.isHidden = processingFeeView.isHidden && salesTaxView.isHidden && customFeeView.isHidden && discountView.isHidden ? true : false
            } else {
                if booking?.venueObject?.venueSettings?.coverTicketFeesSettings?.isUpFront == false {
                    processingFeeView.isHidden = booking?.fees?.processingFee ?? 0 == 0 || booking?.venueObject?.venueSettings?.coverTicketFeesSettings?.isProcessingFeePassToCustomer == false  ? true : false
                    salesTaxView.isHidden = booking?.fees?.salesTax ?? 0 == 0 || booking?.venueObject?.venueSettings?.coverTicketFeesSettings?.isEnableSalesTax == false ? true : false
                    customFeeView.isHidden = booking?.fees?.customFee ?? 0 == 0 || booking?.venueObject?.venueSettings?.coverTicketFeesSettings?.isEnableCustomFee == false ? true : false
                    subTotalView.isHidden = processingFeeView.isHidden && salesTaxView.isHidden && customFeeView.isHidden && discountView.isHidden ? true : false
                }
            }
        case "TABLE_BOOKING":
            if booking?.venueObject?.venueSettings?.tableBookingFeesSettings?.isUpFront == false {
                processingFeeView.isHidden = booking?.fees?.processingFee ?? 0 == 0 || booking?.venueObject?.venueSettings?.tableBookingFeesSettings?.isProcessingFeePassToCustomer == false  ? true : false
                salesTaxView.isHidden = booking?.fees?.salesTax ?? 0  == 0 || booking?.venueObject?.venueSettings?.tableBookingFeesSettings?.isEnableSalesTax == false ? true : false
                customFeeView.isHidden = booking?.fees?.customFee ?? 0 == 0 || booking?.venueObject?.venueSettings?.tableBookingFeesSettings?.isEnableCustomFee == false ? true : false
                subTotalView.isHidden = processingFeeView.isHidden && salesTaxView.isHidden && customFeeView.isHidden && discountView.isHidden ? true : false
            }
        default:
            break
        }
        
        subTotalAmount.text = "\(booking?.venueObject?.venueSettings?.currencySymbol ?? "$")\((booking?.fees?.subTotal ?? 0).decimalFormat(true))"
        salesTaxAmount.text = "\(booking?.venueObject?.venueSettings?.currencySymbol ?? "$")\((booking?.fees?.salesTax ?? 0).decimalFormat(true))"
        salesTaxName.text = booking?.fees?.salesTaxName ?? "" == "" ? "Sales Tax" : booking?.fees?.salesTaxName
        processingFeeAmount.text = "\(booking?.venueObject?.venueSettings?.currencySymbol ?? "$")\((booking?.fees?.processingFee ?? 0).decimalFormat(true))"
        customFeeAmount.text = "\(booking?.venueObject?.venueSettings?.currencySymbol ?? "$")\((booking?.fees?.customFee ?? 0).decimalFormat(true))"
        customFeeName.text = booking?.fees?.customFeeName ?? "Custom Fee"
        discountAmount.text = "-\(booking?.venueObject?.venueSettings?.currencySymbol ?? "$")\((booking?.fees?.discount ?? 0).decimalFormat(true))"
        noFeeView.isHidden = !(subTotalView.isHidden && salesTaxView.isHidden && processingFeeView.isHidden && customFeeView.isHidden)
        totalAmount.text = "\(booking?.venueObject?.venueSettings?.currencySymbol ?? "$")\((booking?.fees?.total ?? 0).decimalFormat(true))"
    }
    
    @IBAction func onClickClose(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func onClickEventDetails(_ sender: Any) {
        switch type {
        case .appClip:
            delegate?.navigateToVenueDetail(venueId: booking?.venueObject?.id ?? 0, venueUniqueId: booking?.venueObject?.uniqueId ?? "", venueTimeZone: booking?.venueObject?.timezone ?? "")
            dismiss(animated: true)
        case .singleTickedEvent:
            delegate?.navigateToEventDetail(eventId: booking?.event?.eventId ?? 0, venueDetail: booking?.venueObject, event: booking?.event)
            dismiss(animated: true)
        case .tieredTickedEvent:
            break
        }
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
