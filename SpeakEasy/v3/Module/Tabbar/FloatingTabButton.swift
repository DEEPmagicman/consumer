//
//  FloatingTabButton.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 21/05/26.
//

import UIKit

final class FloatingTabButton: UIControl {

    private let selectedBgView = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let stackView = UIStackView()

    private var isSmallDevice: Bool {
        UIScreen.main.bounds.width <= 375
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        selectedBgView.layer.cornerRadius = bounds.height / 2
    }

    private func setupUI() {
        selectedBgView.backgroundColor = AppColor.primaryBlackColor.withAlphaComponent(0.58)
        selectedBgView.alpha = 0
        selectedBgView.layer.cornerCurve = .continuous
        selectedBgView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(selectedBgView)

        stackView.axis = .vertical
        stackView.spacing = isSmallDevice ? 1 : 3
        stackView.alignment = .center
        stackView.isUserInteractionEnabled = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: isSmallDevice ? 17 : 19,
            weight: .medium
        )
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = Constant.Font.geistMedium(size: isSmallDevice ? 9 : 10)
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.75
        titleLabel.numberOfLines = 1

        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(titleLabel)

        NSLayoutConstraint.activate([
            selectedBgView.topAnchor.constraint(equalTo: topAnchor),
            selectedBgView.leadingAnchor.constraint(equalTo: leadingAnchor),
            selectedBgView.trailingAnchor.constraint(equalTo: trailingAnchor),
            selectedBgView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 1),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),

            iconView.widthAnchor.constraint(equalToConstant: isSmallDevice ? 18 : 20),
            iconView.heightAnchor.constraint(equalToConstant: isSmallDevice ? 18 : 20)
        ])
    }

    func configure(item: FloatingTabItem) {
        iconView.image = item.icon
        titleLabel.text = item.title
    }

    func setSelected(
        _ selected: Bool,
        selectedColor: UIColor,
        normalColor: UIColor,
        animated: Bool
    ) {
        let changes = {
            self.selectedBgView.alpha = selected ? 1 : 0
            self.iconView.tintColor = selected ? selectedColor : normalColor
            self.titleLabel.textColor = selected ? selectedColor : normalColor
            self.stackView.transform = selected
                ? CGAffineTransform(scaleX: 1.03, y: 1.03)
                : .identity
        }

        if animated {
            UIView.animate(
                withDuration: 0.28,
                delay: 0,
                usingSpringWithDamping: 0.82,
                initialSpringVelocity: 0.5,
                options: [.allowUserInteraction, .curveEaseOut],
                animations: changes
            )
        } else {
            changes()
        }
    }
}
