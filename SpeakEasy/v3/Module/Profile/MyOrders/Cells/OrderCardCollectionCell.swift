//
//  OrderCardCollectionCell.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 27/05/26.
//

import UIKit

final class OrderCardCollectionCell: UICollectionViewCell {

    private let imageView = UIImageView()
    private let countBadge = UILabel()
    private let venueLabel = UILabel()
    private let eventLabel = UILabel()
    private let dateLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.sd_cancelCurrentImageLoad()
        imageView.image = nil
        countBadge.text = nil
        countBadge.isHidden = true
        venueLabel.text = nil
        eventLabel.text = nil
        dateLabel.text = nil
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)

        countBadge.textColor = .white
        countBadge.font = Constant.Font.geistMedium(size: 11)
        countBadge.textAlignment = .center
        countBadge.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        countBadge.layer.cornerRadius = 10
        countBadge.clipsToBounds = true
        countBadge.isHidden = true
        countBadge.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(countBadge)

        eventLabel.textColor = .white
        eventLabel.font = Constant.Font.geistMedium(size: 15)
        eventLabel.numberOfLines = 2
        eventLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(eventLabel)

        venueLabel.textColor = .white.withAlphaComponent(0.9)
        venueLabel.font = Constant.Font.geistMedium(size: 14)
        venueLabel.numberOfLines = 1
        venueLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(venueLabel)
        
        dateLabel.textColor = UIColor(hex: "#A1A1A1")
        dateLabel.font = Constant.Font.geistMedium(size: 14)
        dateLabel.numberOfLines = 1
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateLabel)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),

            countBadge.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 6),
            countBadge.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -6),
            countBadge.heightAnchor.constraint(equalToConstant: 20),
            countBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 34),

            eventLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            eventLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            eventLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            venueLabel.topAnchor.constraint(equalTo: eventLabel.bottomAnchor, constant: 3),
            venueLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            venueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            dateLabel.topAnchor.constraint(equalTo: venueLabel.bottomAnchor, constant: 10),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            dateLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])
    }

    func configureTicket(_ booking: Booking) {
        venueLabel.text = booking.venueObject?.name ?? ""
        eventLabel.text = booking.event?.title ?? booking.inviteLink?.name ?? Constant.String.liveCoverTicket

        let ticketCount = booking.bookingHasItem.count
        countBadge.isHidden = ticketCount <= 0
        countBadge.text = "\(ticketCount)"

        if let event = booking.event {
            dateLabel.text = event.startDateTime.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .MMMDDATHMMA,
                useDayLightSavingTime: true,
                customTimeZone: booking.venueObject?.useTimezone ?? ""
            )

            let flyer = (event.flyer?.key ?? "").imageURL
            print(flyer, (event.flyer?.key ?? ""))
            imageView.sd_setImage(
                with: URL(string: flyer),
                placeholderImage: Constant.Icon.uploadImage
            )
        } else {
            dateLabel.text = booking.createdAt.convertDateFormat(
                from: .yyyyMMddTHHmmssSSSz,
                to: .MMMDDATHMMA
            )

            let venueImage = (booking.venueObject?.venueAttachment?.first?.key ?? "").imageURL
            print("vv", venueImage, (booking.venueObject?.venueAttachment?.first?.key ?? ""))
            imageView.sd_setImage(
                with: URL(string: venueImage),
                placeholderImage: UIImage(named: "newSpeakeasy")
            )
        }
    }

    func configureTable(_ reservation: Booking) {
        venueLabel.text = reservation.venueObject?.name ?? ""
        eventLabel.text = reservation.event?.title ?? Constant.String.tableReservation
        countBadge.isHidden = false
        countBadge.text = "Table"

        if let event = reservation.event {
            dateLabel.text = event.startDateTime.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .MMMDDATHMMA,
                useDayLightSavingTime: true,
                customTimeZone: reservation.venueObject?.useTimezone ?? ""
            )

            let flyer = (event.flyer?.key ?? "").imageURL
            imageView.sd_setImage(
                with: URL(string: flyer),
                placeholderImage: Constant.Icon.uploadImage
            )
        } else {
            dateLabel.text = reservation.createdAt.convertDateFormat(
                from: .yyyyMMddTHHmmssSSSz,
                to: .MMMDDATHMMA
            )

            let venueImage = (reservation.venueObject?.venueAttachment?.first?.key ?? "").imageURL
            imageView.sd_setImage(
                with: URL(string: venueImage),
                placeholderImage: UIImage(named: "newSpeakeasy")
            )
        }
    }
}
