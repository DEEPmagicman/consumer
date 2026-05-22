//
//  EventCollectionViewCell.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 14/05/26.
//
//
//  EventCollectionViewCell.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 23/12/25.
//

import UIKit

final class EventCollectionViewCell: UICollectionViewCell {

    enum ContentType {
        case event(Event)
        case venue(ClipVenue)
        case premiumExperience(Event)
    }
    
    enum ScreenType {
        case discover
        case normal
    }


    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var eventName: UILabel!
    @IBOutlet weak var eventDate: UILabel!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        image.image = nil

        eventName.text = nil
        eventDate.text = nil
        venueName.text = nil
    }

    func configure(with type: ContentType, screenType: ScreenType = .discover) {

        switch type {

        case .event(let event):
            setupData(event: event)

        case .venue(let venue):
            setupVenue(venue)

        case .premiumExperience(let event):
            setupPremiumExperience(event)
        }
    }
}

// MARK: - Private

private extension EventCollectionViewCell {

    func setupUI() {

        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
    }

    func setupData(event: Event) {

        image.sd_setImage(
            with: URL(string: (event.flyer?.key ?? "").imageURL),
            placeholderImage: Constant.Icon.uploadImage
        )

        venueName.text = event.venue?.name.uppercased()
        eventName.text = event.title

        eventDate.text = formattedDate(
            customText: event.openTimeCustomText,
            startDate: event.startDateTime,
            timezone: event.venue?.useTimezone ?? ""
        )
    }

    func setupPremiumExperience(_ event: Event) {
        image.sd_setImage(
            with: URL(string: (event.flyer?.key ?? "").imageURL),
            placeholderImage: Constant.Icon.uploadImage
        )

        venueName.text = "PREMIUM EXPERIENCE"
        eventName.text = event.title

        eventDate.text = formattedDate(
            customText: event.openTimeCustomText,
            startDate: event.startDateTime,
            timezone: event.venue?.useTimezone ?? ""
        )
    }

    func setupVenue(_ venue: ClipVenue) {
        eventName.isHidden = true
        eventDate.isHidden = true
        venueName.text = venue.name.uppercased()

        let logoUrl = URL(
            string: "\(SharedURL.amazonStorage)\(venue.logo?.key ?? "")"
        )

        let imageUrl = URL(
            string: "\(SharedURL.amazonStorage)\(venue.venueAttachment?.first?.key ?? "")"
        )

        image.sd_setImage(
            with: imageUrl,
            placeholderImage: UIImage(named: "newSpeakeasy")
        )
    }

    func formattedDate(
        customText: String?,
        startDate: String,
        timezone: String
    ) -> String {

        if let customText,
           !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return customText
        }

        return startDate.convertDateFormat(
            from: .yyyyMMddHHmmss,
            to: .EEEMMMD,
            customTimeZone: timezone
        )
    }
}
