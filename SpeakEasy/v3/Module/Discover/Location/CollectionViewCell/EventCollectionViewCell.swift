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
import SDWebImage

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
    @IBOutlet weak var venueLogoImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let imageSide = max(0, floor(contentView.bounds.width - 1))
        if abs(imageViewWidthConstraint.constant - imageSide) > 0.5 {
            imageViewWidthConstraint.constant = imageSide
            imageViewHeightConstraint.constant = imageSide
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        image.sd_cancelCurrentImageLoad()
        venueLogoImage.sd_cancelCurrentImageLoad()
        image.image = nil
        venueLogoImage.image = nil
        venueLogoImage.isHidden = true

        eventName.isHidden = false
        eventDate.isHidden = false
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

        image.layer.cornerRadius = 12
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        venueLogoImage.clipsToBounds = true
        venueLogoImage.contentMode = .scaleAspectFit
        venueLogoImage.isHidden = true
        venueName.numberOfLines = 1
        venueName.lineBreakMode = .byTruncatingTail
        venueName.setContentCompressionResistancePriority(.required, for: .vertical)
        eventName.numberOfLines = 2
        eventName.lineBreakMode = .byTruncatingTail
        eventName.setContentCompressionResistancePriority(.required, for: .vertical)
        eventDate.numberOfLines = 1
        eventDate.lineBreakMode = .byTruncatingTail
        eventDate.setContentCompressionResistancePriority(.required, for: .vertical)
        eventDate.font = Constant.Font.geistMedium(size: 11)
    }

    func setupData(event: Event) {
        eventName.isHidden = false
        eventDate.isHidden = false
        venueLogoImage.isHidden = true
        venueLogoImage.image = nil

//        image.sd_setImage(
//            with: URL(string: (event.flyer?.key ?? "").imageURL),
//            placeholderImage: Constant.Icon.uploadImage
//        )

        let transformer = SDImageResizingTransformer(
            size: CGSize(width: 300, height: 300),
            scaleMode: .aspectFill
        )

        image.sd_setImage(
            with:  URL(string: (event.flyer?.key ?? "").imageURL),
            placeholderImage: Constant.Icon.uploadImage,
            context: [
                .imageTransformer: transformer
            ]
        )
        
//        venueName.text = event.venue?.name.uppercased()
        venueName.text = event.venue?.name
        eventName.text = event.title

        eventDate.text = formattedDate(
            customText: event.openTimeCustomText,
            startDate: event.startDateTime,
            timezone: event.venue?.useTimezone ?? ""
        )
    }

    func setupPremiumExperience(_ event: Event) {
        eventName.isHidden = false
        eventDate.isHidden = false
        venueLogoImage.isHidden = true
        venueLogoImage.image = nil

//        image.sd_setImage(
//            with: URL(string: (event.flyer?.key ?? "").imageURL),
//            placeholderImage: Constant.Icon.uploadImage
//        )
        
        let transformer = SDImageResizingTransformer(
            size: CGSize(width: 300, height: 300),
            scaleMode: .aspectFill
        )

        image.sd_setImage(
            with: URL(string: (event.flyer?.key ?? "").imageURL),
            placeholderImage: Constant.Icon.uploadImage,
            context: [
                .imageTransformer: transformer
            ]
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
        venueName.text = venue.name

        let logoKey = venue.logo?.key ?? ""
        let logoUrl = URL(string: "\(SharedURL.amazonStorage)\(logoKey)")
        venueLogoImage.isHidden = logoKey.isEmpty
        venueLogoImage.image = nil

        let imageUrl = URL(
            string: "\(SharedURL.amazonStorage)\(venue.venueAttachment?.first?.key ?? "")"
        )

        let transformer = SDImageResizingTransformer(
            size: CGSize(width: 300, height: 300),
            scaleMode: .aspectFill
        )

        image.sd_setImage(
            with: imageUrl,
            placeholderImage: UIImage(named: "appLogo"),
            context: [
                .imageTransformer: transformer
            ]
        )
        
//        image.sd_setImage(
//            with: imageUrl,
//            placeholderImage: UIImage(named: "appLogo")
//        )

        if logoKey.isEmpty {
            venueLogoImage.sd_cancelCurrentImageLoad()
        } else {
//            venueLogoImage.sd_setImage(
//                with: logoUrl,
//                placeholderImage: nil
//            )
            venueLogoImage.sd_setImage(
                with: logoUrl,
                placeholderImage: nil,
                context: [
                    .imageTransformer: transformer
                ]
            )
        }
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
