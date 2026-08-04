//
//  OrderCardViewModel.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 28/05/26.
//

import UIKit
import SDWebImage

struct OrderCardViewModel {
    let imageURL: String?
    let placeholder: UIImage?
    let badgeText: String?
    let title: String
    let subtitle: String
    let dateText: String?
    let statusText: String?
    let statusBgColor: UIColor?
    let statusTextColor: UIColor?
}

enum EventType {
    case pastEvent
    case premiumEvent
}

final class OrderCardCollectionCell: UICollectionViewCell {

    private let imageView = UIImageView()
    private let countBadge = PaddingLabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let dateLabel = UILabel()
    private let statusBadge = PaddingLabel()
    private var representedImageKey: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    deinit {
        releaseResources()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        releaseResources()

        countBadge.text = nil
        countBadge.isHidden = true

        titleLabel.text = nil
        subtitleLabel.text = nil
        dateLabel.text = nil
        dateLabel.isHidden = false
        statusBadge.text = nil
        statusBadge.isHidden = true
    }

    func releaseResources() {
        imageView.sd_cancelCurrentImageLoad()
        imageView.image = nil
        representedImageKey = nil
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
        countBadge.contentInset = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
        countBadge.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(countBadge)

        titleLabel.textColor = .white
        titleLabel.font = Constant.Font.geistMedium(size: 14)
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .left
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        subtitleLabel.font = Constant.Font.geistMedium(size: 12)
        subtitleLabel.numberOfLines = 1
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)

        dateLabel.textColor = UIColor(hex: "#A1A1A1")
        dateLabel.font = Constant.Font.geistMedium(size: 12)
        dateLabel.numberOfLines = 1
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateLabel)
        
        statusBadge.textColor = .black
        statusBadge.font = AppFont.font(.mono, weight: .medium, size: 9)
        statusBadge.backgroundColor = .white
        statusBadge.layer.cornerRadius = 9
        statusBadge.layer.borderWidth = 1
        statusBadge.layer.borderColor = UIColor.white.withAlphaComponent(0.09).cgColor
        statusBadge.clipsToBounds = true
        statusBadge.contentInset =
            UIEdgeInsets(
                top: 2,
                left: 6,
                bottom: 2,
                right: 6
            )
        statusBadge.isHidden = true
        statusBadge.translatesAutoresizingMaskIntoConstraints =
            false
        imageView.addSubview(statusBadge)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1.2),

            countBadge.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 6),
            countBadge.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -6),
            countBadge.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),

            statusBadge.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 6),
            statusBadge.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -6),
            statusBadge.heightAnchor.constraint(equalToConstant: 18),
            
            subtitleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            titleLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 3),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            dateLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])
    }

    func configure(_ model: OrderCardViewModel) {
        titleLabel.text = model.title
        subtitleLabel.text = model.subtitle

        if let dateText = model.dateText, !dateText.isEmpty {
            dateLabel.text = dateText
            dateLabel.isHidden = false
        } else {
            dateLabel.isHidden = true
        }

        if let badgeText = model.badgeText, !badgeText.isEmpty {
            countBadge.text = badgeText
            countBadge.isHidden = false
        } else {
            countBadge.isHidden = true
        }

        if let text = model.statusText,
           !text.isEmpty {

            statusBadge.text = text
            statusBadge.textColor = model.statusTextColor
            statusBadge.backgroundColor =
                model.statusBgColor

            statusBadge.isHidden = false

        } else {
            statusBadge.isHidden = true
        }

        let screenScale = UIScreen.main.scale
        let imageWidth = max(bounds.width, imageView.bounds.width, 240)
        let imageHeight = max(bounds.height, imageView.bounds.height, imageWidth * 1.2, 288)
        let qualityScale: CGFloat = 2
        let targetPixelSize = CGSize(
            width: imageWidth * screenScale * qualityScale,
            height: imageHeight * screenScale * qualityScale
        )
        let imageURL = model.imageURL ?? ""
        let imageKey = "\(imageURL)|\(Int(targetPixelSize.width))x\(Int(targetPixelSize.height))"
        guard representedImageKey != imageKey else { return }

        representedImageKey = imageKey

        imageView.sd_cancelCurrentImageLoad()

        guard let url = URL(string: imageURL) else {
            imageView.image = Constant.Icon.uploadImage
            return
        }
        
        imageView.sd_setImage(
            with: url,
            placeholderImage: Constant.Icon.uploadImage,
            options: [
                .continueInBackground,
                .scaleDownLargeImages
            ],
            context: [
                .imageThumbnailPixelSize: NSValue(cgSize: targetPixelSize)
            ]
        )
    }
    
    func configureStatusBadge(
        eventType: EventType
    ) -> (text: String?, textColor: UIColor?, backgroundColor: UIColor?) {
        if eventType == .premiumEvent {
            return ("PREMIUM AVAILABLE", UIColor(hex: "#FFF3E0"), UIColor(hex: "#D99935"))
        } else if eventType == .pastEvent {
            return ("PAST EVENT", .black, .white)
        } else {
            return (nil, nil, nil)
        }
    }
    
    func configureDiscoverEvent(_ event: Event) {
        let dateText: String
        let imageURL: String?
        let placeholder: UIImage?

        dateText = event.eventCardDateText()

        imageURL = (event.flyer?.key ?? "").imageURL
        placeholder = Constant.Icon.uploadImage

        let status =
        event.isPremium == true
        ? configureStatusBadge(eventType: .premiumEvent)
        : nil

        configure(
            OrderCardViewModel(
                imageURL: imageURL,
                placeholder: placeholder,
                badgeText: nil,
                title: event.title,
                subtitle: event.displayVenueName.uppercased(),
                dateText: dateText,
                statusText: status?.text,
                statusBgColor: status?.backgroundColor,
                statusTextColor: status?.textColor
            )
        )
    }

    func configureTicket(_ booking: Booking) {
        let ticketCount = booking.bookingHasItem.count

        let dateText: String
        let imageURL: String?
        let placeholder: UIImage?
        let bookingTimezone = Event.normalizedTimezone(
            booking.venueObject?.useTimezone,
            booking.venueObject?.timezone
        )

        if let event = booking.event {
            dateText = event.eventCardDateText(
                timezone: bookingTimezone,
                includeCustomText: false
            )

            imageURL = (event.flyer?.key ?? "").imageURL
            placeholder = Constant.Icon.uploadImage
        } else {
            dateText = booking.createdAt.convertDateFormat(
                from: .yyyyMMddTHHmmssSSSz,
                to: .EEEMMMDATHMMA,
                customTimeZone: bookingTimezone ?? ""
            )

            imageURL = (booking.venueObject?.venueAttachment?.first?.key ?? "").imageURL
            placeholder = UIImage(named: "newSpeakeasy")
        }

        configure(
            OrderCardViewModel(
                imageURL: imageURL,
                placeholder: placeholder,
                badgeText: ticketCount > 0 ? "\(ticketCount)" : nil,
                title: booking.event?.title ?? booking.inviteLink?.name ?? Constant.String.liveCoverTicket,
                subtitle: booking.venueObject?.name ?? "",
                dateText: dateText, statusText: nil, statusBgColor: nil, statusTextColor: nil
            )
        )
    }

    func configureTable(_ booking: Booking) {
        let dateText: String
        let imageURL: String?
        let placeholder: UIImage?
        let bookingTimezone = Event.normalizedTimezone(
            booking.venueObject?.useTimezone,
            booking.venueObject?.timezone
        )

        if let event = booking.event {
            dateText = event.eventCardDateText(
                timezone: bookingTimezone,
                includeCustomText: false
            )

            imageURL = (event.flyer?.key ?? "").imageURL
            placeholder = Constant.Icon.uploadImage
        } else {
            dateText = booking.createdAt.convertDateFormat(
                from: .yyyyMMddTHHmmssSSSz,
                to: .EEEMMMDATHMMA,
                customTimeZone: bookingTimezone ?? ""
            )

            imageURL = (booking.venueObject?.venueAttachment?.first?.key ?? "").imageURL
            placeholder = UIImage(named: "newSpeakeasy")
        }
        
        configure(
            OrderCardViewModel(
                imageURL: imageURL,
                placeholder: placeholder,
                badgeText: nil,
                title: booking.event?.title ?? Constant.String.tableReservation,
                subtitle: booking.venueObject?.name ?? "",
                dateText: dateText, statusText: nil, statusBgColor: nil, statusTextColor: nil
            )
        )
    }
    
    func configureEvent(_ booking: Booking) {
        let dateText: String
        let imageURL: String?
        let placeholder: UIImage?
        var eventType: EventType?
        let bookingTimezone = Event.normalizedTimezone(
            booking.venueObject?.useTimezone,
            booking.venueObject?.timezone
        )

        if let event = booking.event {
            dateText = event.eventCardDateText(
                timezone: bookingTimezone,
                includeCustomText: false
            )

            imageURL = (event.flyer?.key ?? "").imageURL
            placeholder = Constant.Icon.uploadImage
            eventType =
            isPastEvent(
                event,
                timezone: Event.normalizedTimezone(
                    booking.venueObject?.useTimezone,
                    booking.venueObject?.timezone,
                    event.venue?.useTimezone,
                    event.venue?.timezone
                )
            ) ? .pastEvent : nil
        } else {
            dateText = booking.createdAt.convertDateFormat(
                from: .yyyyMMddTHHmmssSSSz,
                to: .EEEMMMDATHMMA,
                customTimeZone: bookingTimezone ?? ""
            )

            imageURL = (booking.venueObject?.venueAttachment?.first?.key ?? "").imageURL
            placeholder = UIImage(named: "newSpeakeasy")
        }

        let status =
        eventType.map {
            configureStatusBadge(eventType: $0)
        }
        
        configure(
            OrderCardViewModel(
                imageURL: imageURL,
                placeholder: placeholder,
                badgeText: nil,
                title: booking.event?.title ?? Constant.String.tableReservation,
                subtitle: booking.venueObject?.name ?? "",
                dateText: dateText,
                statusText: status?.text,
                statusBgColor: status?.backgroundColor,
                statusTextColor: status?.textColor
            )
        )
    }

    private func isPastEvent(
        _ event: Event,
        timezone: String?
    ) -> Bool {

        let endDateText =
        event.endDateTime?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let comparisonText =
        (endDateText?.isEmpty == false)
        ? endDateText
        : event.startDateTime

        guard let comparisonText else { return false }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = DateFormat.yyyyMMddHHmmss.rawValue
        formatter.timeZone =
        TimeZone(identifier: timezone ?? "") ?? .current

        guard let eventDate =
                formatter.date(from: comparisonText)
        else {
            return false
        }

        return eventDate < Date.venueNow(timezone: timezone)
    }
}

final class PaddingLabel: UILabel {
    var contentInset: UIEdgeInsets = .zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInset))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInset.left + contentInset.right,
            height: size.height + contentInset.top + contentInset.bottom
        )
    }
}
