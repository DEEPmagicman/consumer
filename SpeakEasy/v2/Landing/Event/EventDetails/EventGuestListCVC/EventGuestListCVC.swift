//
//  EventGuestListCVC.swift
//  eventDeatilModule
//
//  Created by MAC on 06/02/26.
//

import UIKit

class EventGuestListCVC: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var attendeesName: UILabel!
    @IBOutlet weak var bgView: UIView!

    private var gradientLayer: CAGradientLayer?

    override func awakeFromNib() {
        super.awakeFromNib()

        imageView.layer.cornerRadius = imageView.frame.height / 2
        imageView.clipsToBounds = true

        bgView.layer.cornerRadius = bgView.frame.height / 2
        bgView.clipsToBounds = true

        attendeesName.textAlignment = .center
        attendeesName.textColor = .white
        attendeesName.font = UIFont.boldSystemFont(ofSize: 14)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        gradientLayer?.removeFromSuperlayer()
    }

    func configure(with attendee: Attendee) {

        if let imageKey = attendee.consumerUserImage?.key,
           !imageKey.isEmpty {

            imageView.isHidden = false
            attendeesName.isHidden = true

            imageView.sd_setImage(with: URL(string: imageKey))

        } else {

            imageView.isHidden = true
            bgView.isHidden = false
            attendeesName.isHidden = false

            attendeesName.text = getInitials(from: attendee)
            applyGradient(for: attendee.id ?? UUID().uuidString)
        }
    }

    private func getInitials(from attendee: Attendee) -> String {
        let first = attendee.firstName?.prefix(1).uppercased() ?? ""
        let last = attendee.lastName?.prefix(1).uppercased() ?? ""
        return first + last
    }

    private func applyGradient(for id: String) {

        gradientLayer?.removeFromSuperlayer()

        let colors = gradientColors(for: id)

        let gradient = CAGradientLayer()
        gradient.frame = bgView.bounds
        gradient.cornerRadius = bgView.bounds.height / 2
        gradient.colors = colors.map { $0.cgColor }
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)

        bgView.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
    }

    private func gradientColors(for id: String) -> [UIColor] {

        let palettes: [[UIColor]] = [
            [UIColor.systemPurple, UIColor.systemPink],
            [UIColor.systemBlue, UIColor.systemTeal],
            [UIColor.systemOrange, UIColor.systemRed],
            [UIColor.systemGreen, UIColor.systemMint],
            [UIColor.systemIndigo, UIColor.systemBlue],
            [UIColor.systemPink, UIColor.systemOrange]
        ]

        let index = abs(id.hashValue) % palettes.count
        return palettes[index]
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = bgView.bounds
        gradientLayer?.cornerRadius = bgView.bounds.height / 2
    }
}
