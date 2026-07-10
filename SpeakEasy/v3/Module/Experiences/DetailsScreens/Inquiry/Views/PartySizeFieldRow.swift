//
//  PartySizeFieldRow.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 24/06/26.
//

import UIKit

final class PartySizeFieldRow: UIView {

    private let cardView   = GradientBorderCardView()
    private let iconView   = UIImageView()
    private let titleLabel = UILabel()
    private let stepper    = PartySizePickerView()

    var onValueChanged: ((Int) -> Void)?

    var currentValue: Int { stepper.count }

    var viewCornerRadius: CGFloat = 14 {
        didSet {
            cardView.glassCornerRadius = viewCornerRadius
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        cardView.glassCornerRadius = viewCornerRadius
    }

    func configure(max: Int) {
        stepper.configure(current: 0, max: max)
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 52).isActive = true

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.fillColor = UIColor.white.withAlphaComponent(0.05).cgColor
        cardView.showsBlur = true
        cardView.blurAlpha = 0.55
        cardView.thinBorder = true
        addSubview(cardView)

        iconView.tintColor              = .white
        iconView.contentMode            = .scaleAspectFit
        
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .light)
        iconView.image = UIImage(resource: .guestIcon)
            .withConfiguration(config)
            .withRenderingMode(.alwaysTemplate)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(iconView)

        titleLabel.text      = "Party size"
        titleLabel.font      = Constant.Font.geistRegular(size: 14)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.95)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        stepper.translatesAutoresizingMaskIntoConstraints = false
        stepper.onValueChanged = { [weak self] val in
            self?.onValueChanged?(val)
        }
        cardView.addSubview(stepper)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),

            iconView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 14),
            iconView.heightAnchor.constraint(equalToConstant: 14),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),

            stepper.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
            stepper.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            stepper.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
}
