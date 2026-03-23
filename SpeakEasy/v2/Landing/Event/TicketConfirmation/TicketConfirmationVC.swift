//
//  TicketConfirmationVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 09/02/26.
//

import UIKit

class TicketConfirmationVC: UIViewController {
    
    @IBOutlet weak var venueLogoImg: UIImageView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var venueName2: UILabel!
    @IBOutlet weak var dateandtimeLbl: UILabel!
    @IBOutlet weak var eventTitleLbl: UILabel!
    @IBOutlet weak var noteLbl: UILabel!
    @IBOutlet weak var eventImgView: UIImageView!
    @IBOutlet weak var viewTicketBtn: UIButton!
    @IBOutlet weak var viewTicketBtnView: UIView!
    
    var booking: Booking?
    var venueDetails: ClipVenue?
    var event: Event?
    var bookingId: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        getBooking(id: bookingId ?? "be5af872-e29d-4115-93ab-6660d47662eb")
    }
    
    private func setupData() {

        guard let booking = booking else { return }
        venueDetails = booking.venueObject
        venueLogoImg.sd_setImage(
            with: URL(string: (venueDetails?.logo?.key ?? "").imageURL),
            placeholderImage: Constant.Icon.uploadImage
        )
        event = booking.event

        venueName.text = venueDetails?.name ?? ""
        venueName2.text = venueDetails?.name ?? ""
        eventTitleLbl.text = event?.title ?? ""
        eventImgView.sd_setImage(
            with: URL(string: (event?.flyer?.key ?? "").imageURL),
            placeholderImage: Constant.Icon.uploadImage
        )
        if let hexColor = event?.whiteLabelColor {
            let color = UIColor(hex: hexColor)
            viewTicketBtnView.backgroundColor = color
            dateandtimeLbl.textColor = color
        }
        
        let timezone = venueDetails?.useTimezone ?? ""

        let dateText = event?.startDateTime.convertDateFormat(
            from: .yyyyMMddHHmmss,
            to: .EEEMMMD,
            customTimeZone: timezone
        )

        let startTime = event?.startDateTime.convertDateFormat(
            from: .yyyyMMddHHmmss,
            to: .hmma,
            customTimeZone: timezone
        )

        let endTime = event?.endDateTime?.convertDateFormat(
            from: .yyyyMMddHHmmss,
            to: .hmma,
            customTimeZone: timezone
        ) ?? ""

        dateandtimeLbl.text = "\(dateText ?? "") at \(startTime ?? "") - \(endTime)"
        
        noteLbl.text = booking.note ?? ""
        if let customText = event?.venue?.dressCode,
           !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        }
    }
    
    @IBAction func onClickViewtTicket(_ sender: Any) {
        Navigate.to.showQRCode(self, booking: nil, bookingId: self.bookingId ?? "", type: .singleTickedEvent)
    }
    
    @IBAction func onClickCloseBtn(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    private func getBooking(id: String) {
        PaymentPresenter.getBooking(bookingId: id) { [weak self] isSuccess, _, booking in
            guard let self = self else { return }
            if isSuccess {
                self.booking = booking
                self.setupData()
                
            } else {
//                self.eventDetailView.isHidden = true
            }
        }
    }
}
