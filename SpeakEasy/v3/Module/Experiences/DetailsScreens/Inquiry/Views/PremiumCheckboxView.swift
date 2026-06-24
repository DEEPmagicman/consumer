//
//  PremiumCheckboxView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 24/06/26.
//

import UIKit

final class PremiumCheckboxView: UIView {

    var isChecked: Bool = false {
        didSet { updateAppearance() }
    }

    var onToggle: ((Bool) -> Void)?

    private let box   = UIView()
    private let tick  = UIImageView()
    private let label = UILabel()

    var labelText: String = "" {
        didSet { label.text = labelText }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        // Box
        box.layer.cornerRadius  = 4
        box.layer.borderWidth   = 0.8
        box.layer.borderColor   = UIColor.white.withAlphaComponent(0.2).cgColor
        box.backgroundColor     = .black
        box.translatesAutoresizingMaskIntoConstraints = false

        // Tick
        tick.image              = UIImage(systemName: "checkmark")
        tick.tintColor          = .white
        tick.contentMode        = .scaleAspectFit
        tick.isHidden           = true
        tick.translatesAutoresizingMaskIntoConstraints = false

        // Label
        label.numberOfLines     = 0
        label.font              = Constant.Font.geistRegular(size: 10)
        label.textColor         = UIColor.white.withAlphaComponent(0.9)
        label.translatesAutoresizingMaskIntoConstraints = false

        addSubview(box)
        box.addSubview(tick)
        addSubview(label)

        NSLayoutConstraint.activate([
            box.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            box.topAnchor.constraint(equalTo: topAnchor, constant: 1),
            box.widthAnchor.constraint(equalToConstant: 14),
            box.heightAnchor.constraint(equalToConstant: 14),

            tick.centerXAnchor.constraint(equalTo: box.centerXAnchor),
            tick.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            tick.widthAnchor.constraint(equalToConstant: 12),
            tick.heightAnchor.constraint(equalToConstant: 12),

            label.leadingAnchor.constraint(equalTo: box.trailingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    private func updateAppearance() {
        UIView.animate(withDuration: 0.15) {
            if self.isChecked {
                self.box.backgroundColor   = UIColor.white.withAlphaComponent(0.15)
                self.box.layer.borderColor = UIColor.white.cgColor
            } else {
                self.box.backgroundColor   = .black
                self.box.layer.borderColor = UIColor.white.withAlphaComponent(0.45).cgColor
            }
        }
        tick.isHidden = !isChecked
    }

    @objc private func handleTap() {
        isChecked.toggle()
        onToggle?(isChecked)
    }
}
