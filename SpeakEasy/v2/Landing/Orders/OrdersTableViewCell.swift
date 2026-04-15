//
//  OrdersTableViewCell.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 07/04/26.
//

import UIKit

final class OrdersTableViewCell: UITableViewCell {
    
    @IBOutlet weak var backgroungImage: UIImageView!
    @IBOutlet weak var eventTitle: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var locationName: UILabel!
    @IBOutlet weak var ticketLbl: UILabel!
    @IBOutlet weak var premiumExperienceLbl: UILabel!
    @IBOutlet weak var dotLbl: UILabel!
    @IBOutlet weak var upComingView: UIView!
    @IBOutlet weak var upComingLbl: UILabel!
    @IBOutlet weak var contentBgView: UIView!
    
    private let shimmerOverlay = ShimmerView()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        setupShimmer()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shimmerOverlay.frame = contentView.bounds
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        backgroungImage.sd_cancelCurrentImageLoad()
        backgroungImage.image = nil
        
        eventTitle.text = nil
        time.text = nil
        locationName.text = nil
        ticketLbl.text = nil
        premiumExperienceLbl.text = nil
        
        upComingView.isHidden = false
        upComingLbl.text = nil
        
        hideShimmer()
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        upComingView.clipsToBounds = true
        upComingView.layer.cornerRadius = 10
        
        premiumExperienceLbl.isHidden = true
        dotLbl.isHidden = true
    }
    
    private func setupShimmer() {
        shimmerOverlay.isUserInteractionEnabled = false
        shimmerOverlay.isHidden = true
        shimmerOverlay.layer.cornerRadius = 16
        shimmerOverlay.clipsToBounds = true
        contentBgView.addSubview(shimmerOverlay)
    }
    
    func showShimmer() {
        shimmerOverlay.isHidden = false
        shimmerOverlay.startAnimating()
        
        backgroungImage.image = nil
        eventTitle.text = nil
        time.text = nil
        locationName.text = nil
        ticketLbl.text = nil
        premiumExperienceLbl.text = nil
        upComingLbl.text = nil
    }
    
    func hideShimmer() {
        shimmerOverlay.stopAnimating()
        shimmerOverlay.isHidden = true
    }
    
    func configure(with booking: Booking, isUpcoming: Bool) {
        hideShimmer()
        
        upComingView.isHidden = false
        upComingLbl.text = isUpcoming ? "Upcoming" : "Past"
        
        if isUpcoming {
            upComingView.backgroundColor = UIColor(hex: "#00C950").withAlphaComponent(0.2)
            upComingLbl.textColor = UIColor(hex: "#05DF72")
        } else {
            upComingView.backgroundColor = UIColor(hex: "#A1A1A1").withAlphaComponent(0.2)
            upComingLbl.textColor = UIColor(hex: "#A1A1A1")
        }
        
        locationName.text = booking.venueObject?.name ?? ""
        ticketLbl.text = "\(booking.bookingHasItem.count) Ticket\(booking.bookingHasItem.count > 1 ? "s" : "")"
        
        premiumExperienceLbl.isHidden = true
        dotLbl.isHidden = true
        
        if booking.bookingType == "TABLE" {
            premiumExperienceLbl.isHidden = false
            dotLbl.isHidden = false
            premiumExperienceLbl.text = "Premium Experience"
            ticketLbl.text = "Table Reservation"
        }
        
        if booking.eventId == nil {
            if booking.isCompedTicket == true, let inviteLink = booking.inviteLink {
                eventTitle.text = inviteLink.name
                
//                let date = inviteLink.date?.convertDateFormat(
//                    from: .yyyyMMddTHHmmssSSSz,
//                    to: .MMMD
//                ) ?? ""
//                
//                let timeValue = inviteLink.date?.convertDateFormat(
//                    from: .yyyyMMddTHHmmssSSSz,
//                    to: .hmma
//                ) ?? ""
                
                let formatted = inviteLink.date?.convertDateFormat(
                    from: .yyyyMMddTHHmmssSSSz,
                    to: .EEEEMMMMDDAT
                ) ?? ""

                time.text = formatted
                
//                time.text = "\(date) • \(timeValue)"

            } else if booking.bookingType == "TABLE" {
                eventTitle.text = Constant.String.tableReservation
                
                let formatted =
                    booking.floorPlanTimeSlotBooking?.first?.floorPlanTableTimeSlot.date.convertDateFormat(
                        from: .YYYYMMDD,
                        to: .EEEEMMMMDDAT,
                        isUTC: true,
                        customTimeZone: booking.venueObject?.useTimezone ?? ""
                    ) ??
                    booking.createdAt.convertDateFormat(
                        from: .yyyyMMddTHHmmssSSSz,
                        to: .EEEEMMMMDDAT,
                        isUTC: true,
                        customTimeZone: booking.venueObject?.useTimezone ?? ""
                    )
                
                time.text = formatted
                
            } else {
                eventTitle.text = Constant.String.liveCoverTicket
                
                let formatted = booking.createdAt.convertDateFormat(
                    from: .yyyyMMddTHHmmssSSSz,
                    to: .EEEEMMMMDDAT
                )
                
                time.text = formatted
            }
            
            let venueImage = (booking.venueObject?.venueAttachment?.first?.key ?? "").imageURL
            backgroungImage.sd_setImage(
                with: URL(string: venueImage),
                placeholderImage: UIImage(named: "newSpeakeasy")
            ) { [weak self] _, _, _, _ in
            
            }
            
        } else {
            eventTitle.text = booking.event?.title ?? "Untitled Event"
            
            let formatted = booking.event?.startDateTime.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .EEEEMMMMDDAT,
                useDayLightSavingTime: true,
                customTimeZone: booking.venueObject?.useTimezone ?? ""
            ) ?? ""
            
            time.text = formatted
            
            let flyer = (booking.event?.flyer?.key ?? "").imageURL
            backgroungImage.sd_setImage(
                with: URL(string: flyer),
                placeholderImage: Constant.Icon.uploadImage
            ) { [weak self] _, _, _, _ in
                
            }
        }
    }
}
