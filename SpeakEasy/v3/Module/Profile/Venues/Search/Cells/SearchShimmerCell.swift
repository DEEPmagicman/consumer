//
//  SearchVenueShimmerCell.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 04/06/26.
//

import UIKit

final class SearchShimmerCell: UITableViewCell {

    private let imageSkeleton = UIView()
    private let titleSkeleton = UIView()
    private let subtitleSkeleton = UIView()

    private let shimmerLayer = CAGradientLayer()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        [imageSkeleton, titleSkeleton, subtitleSkeleton].forEach {
            $0.layer.sublayers?
                .filter { $0.name == "shimmer" }
                .forEach { $0.removeFromSuperlayer() }
        }
    }

    private func setup() {

        backgroundColor = .clear
        selectionStyle = .none

        [imageSkeleton, titleSkeleton, subtitleSkeleton].forEach {

            $0.backgroundColor = UIColor.white.withAlphaComponent(0.07)
            $0.layer.cornerRadius = 6
            $0.clipsToBounds = true
            $0.translatesAutoresizingMaskIntoConstraints = false

            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([

            imageSkeleton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageSkeleton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            imageSkeleton.widthAnchor.constraint(equalToConstant: 44),
            imageSkeleton.heightAnchor.constraint(equalToConstant: 44),

            titleSkeleton.leadingAnchor.constraint(equalTo: imageSkeleton.trailingAnchor, constant: 12),
            titleSkeleton.topAnchor.constraint(equalTo: imageSkeleton.topAnchor, constant: 4),
            titleSkeleton.widthAnchor.constraint(equalToConstant: 160),
            titleSkeleton.heightAnchor.constraint(equalToConstant: 14),

            subtitleSkeleton.leadingAnchor.constraint(equalTo: titleSkeleton.leadingAnchor),
            subtitleSkeleton.topAnchor.constraint(equalTo: titleSkeleton.bottomAnchor, constant: 10),
            subtitleSkeleton.widthAnchor.constraint(equalToConstant: 80),
            subtitleSkeleton.heightAnchor.constraint(equalToConstant: 10),

            contentView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    func startShimmer() {
        prepareForReuse()
        
        [imageSkeleton, titleSkeleton, subtitleSkeleton].forEach {
            addShimmer(to: $0)
        }
    }
    
    private func addShimmer(to view: UIView) {

        view.layer.sublayers?
            .filter { $0.name == "shimmer" }
            .forEach { $0.removeFromSuperlayer() }

        let gradient = CAGradientLayer()

        gradient.name = "shimmer"
        gradient.frame = view.bounds

        gradient.colors = [
            UIColor.white.withAlphaComponent(0.05).cgColor,
            UIColor.white.withAlphaComponent(0.20).cgColor,
            UIColor.white.withAlphaComponent(0.05).cgColor
        ]

        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)

        gradient.locations = [0, 0.5, 1]

        view.layer.addSublayer(gradient)

        let animation = CABasicAnimation(keyPath: "transform.translation.x")

        animation.fromValue = -250
        animation.toValue = 250
        animation.duration = 1.1
        animation.repeatCount = .infinity

        gradient.add(animation, forKey: "shimmer")
    }
}
