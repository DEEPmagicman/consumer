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
        releaseImageResources()
        venueLabel.text = nil
        titleLabel.text = nil
        dateLabel.text = nil
        badgeView.isHidden = true
    }

    deinit {
        releaseImageResources()
    }

    func configure(with event: Event) {
        let scale = UIScreen.main.scale
        let targetSize = CGSize(
            width: 160 * scale,
            height: 120 * scale
        )

        eventImageView.sd_setImage(
            with: URL(string: (event.flyer?.key ?? "").imageURL),
            placeholderImage: Constant.Icon.uploadImage,
            options: [.scaleDownLargeImages],
            context: [
                .imageThumbnailPixelSize: NSValue(cgSize: targetSize)
            ]
        )

        venueLabel.text = event.displayVenueName.uppercased()
        titleLabel.text = event.title
        dateLabel.text = event.eventCardDateText()
        actionLabel.text = "View event"
        badgeLabel.text = "PREMIUM AVAILABLE"
        badgeView.isHidden = event.isPremium != true
    }

    func releaseImageResources() {
        eventImageView.sd_cancelCurrentImageLoad()
        eventImageView.image = Constant.Icon.uploadImage
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

}
