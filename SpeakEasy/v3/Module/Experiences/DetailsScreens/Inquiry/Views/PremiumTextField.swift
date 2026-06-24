//
//  PremiumTextField.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 19/06/26.
//

import UIKit

class PremiumTextField: UIView {

    private let cardView = GradientBorderCardView()

    private let iconView = UIImageView()

    private let titleLabel = UILabel()

    let textField = UITextField()

    var leftImage: UIImage? {
        didSet {
            let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .light)
            iconView.image = leftImage?
                .withConfiguration(config)
                .withRenderingMode(.alwaysTemplate)
        }
    }

    var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }
    
    var viewCornerRadius: CGFloat = 14 {
        didSet {
            cardView.glassCornerRadius = viewCornerRadius
        }
    }

    var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        cardView.clipsToBounds = true
        cardView.glassCornerRadius = viewCornerRadius
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

        iconView.tintColor = UIColor.white.withAlphaComponent(0.95)
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 16, weight: .light)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(iconView)

        titleLabel.font = Constant.Font.geistRegular(size: 14)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.95)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        textField.font = Constant.Font.geistMedium(size: 15)
        textField.textColor = .white
        textField.backgroundColor = .clear
        textField.borderStyle = .none
        textField.textAlignment = .right
        textField.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(textField)

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

            textField.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 10),
            textField.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            textField.centerYAnchor.constraint(equalTo: cardView.centerYAnchor)
        ])
    }
}
