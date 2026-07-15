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
    private let shimmerView = ShimmerViewV3(frame: .zero, lighter: true)

    override func awakeFromNib() {
        super.awakeFromNib()

        imageView.layer.cornerRadius = imageView.frame.height / 2
        imageView.clipsToBounds = true

        bgView.layer.cornerRadius = bgView.frame.height / 2
        bgView.clipsToBounds = true

        attendeesName.textAlignment = .center
        attendeesName.textColor = .black
        attendeesName.font = UIFont.systemFont(ofSize: 14)

        shimmerView.translatesAutoresizingMaskIntoConstraints = false
        shimmerView.isHidden = true
        bgView.addSubview(shimmerView)

        NSLayoutConstraint.activate([
            shimmerView.topAnchor.constraint(equalTo: bgView.topAnchor),
            shimmerView.leadingAnchor.constraint(equalTo: bgView.leadingAnchor),
            shimmerView.trailingAnchor.constraint(equalTo: bgView.trailingAnchor),
            shimmerView.bottomAnchor.constraint(equalTo: bgView.bottomAnchor)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        gradientLayer?.removeFromSuperlayer()
        shimmerView.stopShimmer()
        shimmerView.isHidden = true
        imageView.sd_cancelCurrentImageLoad()
        imageView.image = nil
        imageView.isHidden = true
        attendeesName.isHidden = true
        bgView.isHidden = false
    }

    deinit {
        gradientLayer?.removeFromSuperlayer()
        shimmerView.stopShimmer()
        imageView.sd_cancelCurrentImageLoad()
    }

    func configure(with attendee: Attendee) {
        shimmerView.stopShimmer()
        shimmerView.isHidden = true
        bgView.backgroundColor = .white

        if let imageKey = attendee.consumerUserImage?.key,
           !imageKey.isEmpty {

            imageView.isHidden = false
            attendeesName.isHidden = true

            let scale = UIScreen.main.scale

            imageView.sd_setImage(
                with: URL(string: imageKey),
                placeholderImage: nil,
                options: [.scaleDownLargeImages],
                context: [
                    .imageThumbnailPixelSize: NSValue(
                        cgSize: CGSize(width: 80 * scale, height: 80 * scale)
                    )
                ]
            )

        } else {

            imageView.isHidden = true
            bgView.isHidden = false
            attendeesName.isHidden = false

            attendeesName.text = getInitials(from: attendee)
            applyGradient(for: attendee.id ?? UUID().uuidString)
        }
    }

    func configureSkeleton() {
        gradientLayer?.removeFromSuperlayer()
        imageView.sd_cancelCurrentImageLoad()
        imageView.image = nil
        imageView.isHidden = true
        attendeesName.isHidden = true
        bgView.isHidden = false
        bgView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        shimmerView.layer.cornerRadius = bgView.bounds.height / 2
        shimmerView.isHidden = false
        shimmerView.startShimmer()
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
            [UIColor(hex: "#f9d423"), UIColor(hex: "#ff4e50")],
            [UIColor(hex: "#a1ffce"), UIColor(hex: "#faffd1")],
            [UIColor(hex: "#fbc2eb"), UIColor(hex: "#a6c1ee")],
            [UIColor(hex: "#fad0c4"), UIColor(hex: "#ffd1ff")],
            [UIColor(hex: "#89f7fe"), UIColor(hex: "#66a6ff")],
            [UIColor(hex: "#fbc2eb"), UIColor(hex: "#f9d423")],
            [UIColor(hex: "#ffecd2"), UIColor(hex: "#fcb69f")],
            [UIColor(hex: "#a18cd1"), UIColor(hex: "#fbc2eb")]
        ]

        let index = abs(id.hashValue) % palettes.count
        return palettes[index]
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = bgView.bounds
        gradientLayer?.cornerRadius = bgView.bounds.height / 2
        shimmerView.layer.cornerRadius = bgView.bounds.height / 2
    }
}
