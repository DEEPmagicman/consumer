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
    @IBOutlet weak var noteView: UILabel!
    @IBOutlet weak var eventImgView: UIImageView!
    @IBOutlet weak var viewTicketBtn : UIButton!
    
    var booking: Booking?
    var venueDetails: ClipVenue?
    var event: Event?
    var bookingId: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        if let id = self.bookingId {
            getBooking(id: "93f6f680-5440-4efc-a5f2-d67af29be773")
        }
    }
    
    private func setupData() {

        guard let booking = booking else { return }
        venueDetails = booking.venueObject
        venueLogoImg.sd_setImage(
            with: URL(string: (venueDetails?.logo?.key ?? "").imageURL),
            placeholderImage: Constant.Icon.uploadImage
        )

        venueName.text = venueDetails?.name ?? ""
        venueName2.text = venueDetails?.name ?? ""
        eventTitleLbl.text = event?.title ?? ""
        eventImgView.sd_setImage(
            with: URL(string: (event?.flyer?.key ?? "").imageURL),
            placeholderImage: Constant.Icon.uploadImage
        )
        if let hexColor = event?.whiteLabelColor {
            let color = UIColor(hex: hexColor)
            viewTicketBtn.backgroundColor = color
        }
        
        noteView.text = booking.note ?? ""
        if let customText = event?.venue?.dressCode,
           !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {

            dateandtimeLbl.text = """
            Take a piece of E11EVEN with you anywhere you go HERE

            DRESS CODE:
            Upscale and stylish nightlife attire. No oversized clothing, including but not limited to T-shirts and pants. No beachwear permitted, such as shorts, tank tops, flip-flops, baseball caps, jerseys, etc.

            NOTICE OF FILMING AND PHOTOGRAPHY
            Video and photography may occur while on E11EVEN Miami premises. Your attendance constitutes your consent to be photographed, filmed, and/or otherwise recorded and gives E11EVEN all usage rights at their discretion.
            
                        NOTICE OF FILMING AND PHOTOGRAPHY
                        Video and photography may occur while on E11EVEN Miami premises. Your attendance constitutes your consent to be photographed, filmed, and/or otherwise recorded and gives E11EVEN all usage rights at their discretion.
            
            
                        NOTICE OF FILMING AND PHOTOGRAPHY
                        Video and photography may occur while on E11EVEN Miami premises. Your attendance constitutes your consent to be photographed, filmed, and/or otherwise recorded and gives E11EVEN all usage rights at their discretion.
            
                        NOTICE OF FILMING AND PHOTOGRAPHY
                        Video and photography may occur while on E11EVEN Miami premises. Your attendance constitutes your consent to be photographed, filmed, and/or otherwise recorded and gives E11EVEN all usage rights at their discretion.
            
                        NOTICE OF FILMING AND PHOTOGRAPHY
                        Video and photography may occur while on E11EVEN Miami premises. Your attendance constitutes your consent to be photographed, filmed, and/or otherwise recorded and gives E11EVEN all usage rights at their discretion.
            
                        NOTICE OF FILMING AND PHOTOGRAPHY
                        Video and photography may occur while on E11EVEN Miami premises. Your attendance constitutes your consent to be photographed, filmed, and/or otherwise recorded and gives E11EVEN all usage rights at their discretion.
            """

        } else {

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
            ) ?? "LATE"

            dateandtimeLbl.text = "\(dateText ?? "") at \(startTime ?? "") - \(endTime)"
        }
    }
    

    @IBAction func onClickViewtTicket(_ sender: Any) {
        
    }
    
    
    @IBAction func onClickCloseBtn(_ sender: Any) {
        self.dismiss(animated: false)
    }
    
    private func getBooking(id: String) {
        PaymentPresenter.getBooking(bookingId: id) { [weak self] isSuccess, errMsg, booking in
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
