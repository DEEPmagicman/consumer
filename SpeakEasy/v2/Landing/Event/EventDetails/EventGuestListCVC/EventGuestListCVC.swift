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

    override func awakeFromNib() {
        super.awakeFromNib()

        imageView.layer.cornerRadius = imageView.frame.height / 2
        imageView.clipsToBounds = true

        attendeesName.layer.cornerRadius = imageView.frame.height / 2
        attendeesName.clipsToBounds = true
        attendeesName.textAlignment = .center
        attendeesName.backgroundColor = UIColor.systemGray5
        attendeesName.textColor = .black
    }

    func configure(with attendee: Attendee) {

        if let imageKey = attendee.consumerUserImage?.key,
           !imageKey.isEmpty {

            imageView.isHidden = false
            attendeesName.isHidden = true

            imageView.sd_setImage(
                with: URL(string: imageKey),
                placeholderImage: nil
            )

        } else {

            imageView.isHidden = true
            attendeesName.isHidden = false

            attendeesName.text = getInitials(from: attendee)
        }
    }

    private func getInitials(from attendee: Attendee) -> String {

        let first = attendee.firstName ?? ""
        let last = attendee.lastName ?? ""

        let firstInitial = first.prefix(1).uppercased()
        let lastInitial = last.prefix(1).uppercased()

        return firstInitial + lastInitial
    }
}
