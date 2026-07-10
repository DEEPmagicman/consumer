//
//  MapTableViewCell.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 18/05/26.
//

import UIKit

class MapEventsTableViewCell: UITableViewCell {

    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var venueLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var badgeView: UIView!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var actionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        eventImageView.sd_cancelCurrentImageLoad()
        eventImageView.image = Constant.Icon.uploadImage
        venueLabel.text = nil
        titleLabel.text = nil
        dateLabel.text = nil
        badgeView.isHidden = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configure(with event: Event) {
        eventImageView.sd_setImage(
            with: URL(string: (event.flyer?.key ?? "").imageURL),
            placeholderImage: Constant.Icon.uploadImage
        )

        venueLabel.text = (event.venue?.name ?? event.customVenue?.name ?? "").uppercased()
        titleLabel.text = event.title
        dateLabel.text = formattedDate(
            customText: event.openTimeCustomText,
            startDate: event.startDateTime,
            timezone: event.venue?.useTimezone ?? ""
        )
        actionLabel.text = "View event"
        badgeLabel.text = "PREMIUM AVAILABLE"
        badgeView.isHidden = event.isPremium != true
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        eventImageView.contentMode = .scaleAspectFill
        eventImageView.clipsToBounds = true
        eventImageView.layer.cornerRadius = 7
//        venueLabel.numberOfLines = 1
//        titleLabel.numberOfLines = 2
//        dateLabel.numberOfLines = 1
        badgeView.layer.cornerRadius = 7
        badgeView.clipsToBounds = true
        styleActionPill()
    }

    private func styleActionPill() {
        actionLabel.textColor = AppColor.primaryWhiteColor
        actionLabel.superview?.backgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.10)
    }

    private func formattedDate(
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
