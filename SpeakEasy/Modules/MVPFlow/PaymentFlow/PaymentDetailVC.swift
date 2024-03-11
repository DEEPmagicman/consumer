//
//  PaymentDetailVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 10/04/23.
//

import UIKit

final class PaymentDetailVC: UIViewController {
    
    @IBOutlet private weak var mainImg: UIImageView!
    @IBOutlet private weak var titleLbl: UILabel!
    @IBOutlet private weak var dateLbl: UILabel!
    @IBOutlet private weak var venueNameLbl: UILabel!
    @IBOutlet private weak var totalPriceLbl: UILabel!
    @IBOutlet private weak var ticketListTableView: UITableView!
    @IBOutlet private weak var ticketListHeight: NSLayoutConstraint!
    @IBOutlet private weak var paymentMethodImg: UIImageView!
    @IBOutlet private weak var purchaseDateLbl: UILabel!

    var booking: Booking?
    private var ticketListHeightObservation: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        if booking?.bookingType != "TABLE_BOOKING" {
            getBooking(id: booking?.id ?? 0)
        }
        setUpData()
        totalPriceLbl.text = "\(booking?.venueObject?.venueSettings?.currencySymbol ?? "$")\(booking?.totalPrice)"
        ticketListTableView.register(UINib(nibName: "TicketDetailTVC", bundle: nil), forCellReuseIdentifier: "TicketDetailTVC")
        ticketListHeightObservation = ticketListTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.ticketListHeight.constant = self.ticketListTableView.contentSize.height
            self.ticketListTableView.layoutIfNeeded()
        }
    }
    
    private func setUpData() {
        if let booking = booking {
            if booking.eventId == nil {
                if booking.isCompedTicket == true, let inviteLink = booking.inviteLink {
                    titleLbl.text = inviteLink.name
                    dateLbl.text = inviteLink.date.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .MMddyyyy)
                    mainImg.image = Constant.Icon.liveCover
                } else if booking.bookingType == "TABLE_BOOKING" {
                    titleLbl.text = Constant.String.tableReservation
                    dateLbl.text = booking.createdAt.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .MMddyyyy)
                    mainImg.sd_setImage(with: URL(string: (booking.venueObject?.venueAttachment?.first?.key ?? "").imageURL))
                } else {
                    titleLbl.text = Constant.String.liveCoverTicket
                    dateLbl.text = booking.createdAt.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .MMddyyyy)
                    mainImg.image = Constant.Icon.liveCover
                }
            } else {
                titleLbl.text = booking.event?.title ?? "Untitle Event"
                dateLbl.text = booking.event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .EEEMMMD, useDayLightSavingTime: true, customTimeZone: booking.venueObject?.useTimezone ?? "")
                mainImg.sd_setImage(with: URL(string: (booking.event?.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
            }
            venueNameLbl.text = "\(booking.venueObject?.name ?? ""), \(booking.venueObject?.city ?? "")"
        }
        paymentMethodImg.image = booking?.paymentType?.paymentImg
        purchaseDateLbl.text = booking?.createdAt.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .MMddyyyy)
    }
    
    private func getBooking(id: Int) {
        if booking == nil {
            Loader.show()
        }
        PaymentPresenter.getBooking(bookingId: id) { [weak self] isSuccess, errMsg, booking in
            Loader.hide()
            guard let self = self else { return }
            self.booking = booking
            self.setUpData()
            self.ticketListTableView.reloadData()
        }
    }

    @IBAction func onClickBack(_ sender: Any) {
        dismiss(animated: true)
    }
}

extension PaymentDetailVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        booking?.uniqueTickets.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketDetailTVC", for: indexPath) as! TicketDetailTVC
        cell.titleLbl.text = booking?.uniqueTickets[indexPath.row].ticketName
        cell.subTitleLbl.text = booking?.ticketDetails?.first(where: { $0.ticketId == booking?.uniqueTickets[indexPath.row].ticketId })?.ticketDescription
        cell.quantityLbl.text = "\(booking?.uniqueTickets[indexPath.row].selectedQuantity ?? 0)x"
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        return cell
    }
}
