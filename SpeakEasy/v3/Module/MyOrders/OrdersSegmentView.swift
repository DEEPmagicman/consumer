//
//  OrdersSegmentView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 25/05/26.
//

import UIKit

final class OrdersSegmentView: UIControl {

    var onIndexChanged: ((Int) -> Void)?

    private let containerGlassView = LiquidGlassBackgroundView(
        cornerRadius: 24,
        fillColor: UIColor.black.withAlphaComponent(0.18),
        borderColor: UIColor.white.withAlphaComponent(0.2),
        borderWidth: 1,
        tintColor: .clear
    )

    private let selectedGlassView = LiquidGlassBackgroundView(
        cornerRadius: 20,
        fillColor: UIColor.black.withAlphaComponent(0.18),
        borderColor: UIColor.white.withAlphaComponent(0.2),
        borderWidth: 1,
        tintColor: .clear
    )

    private let ticketsLabel = UILabel()
    private let tablesLabel = UILabel()

    private var selectedLeading: NSLayoutConstraint!
    private var selectedIndex: Int = 0

    private let selectedGradientLayer = CAGradientLayer()
    
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

        containerGlassView.cornerRadius = bounds.height / 2
        selectedGlassView.cornerRadius = selectedGlassView.bounds.height / 2
        selectedGradientLayer.frame = selectedGlassView.bounds
        selectedGradientLayer.cornerRadius = selectedGlassView.bounds.height / 2
    }

    private func setupUI() {
        backgroundColor = .clear
        clipsToBounds = false

        containerGlassView.translatesAutoresizingMaskIntoConstraints = false
        containerGlassView.isUserInteractionEnabled = false
        addSubview(containerGlassView)

        selectedGlassView.overrideBackgroundColor = .clear
        selectedGlassView.backgroundColor = UIColor.clear
        selectedGlassView.translatesAutoresizingMaskIntoConstraints = false
        selectedGlassView.isUserInteractionEnabled = false
        addSubview(selectedGlassView)

        selectedGradientLayer.colors = [
            UIColor(hex: "#FFFFFF").withAlphaComponent(0.08).cgColor,
            UIColor(hex: "#FFFDFD").withAlphaComponent(0.03).cgColor
        ]
        selectedGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        selectedGradientLayer.endPoint = CGPoint(x: 1, y: 1)

        selectedGlassView.layer.addSublayer(selectedGradientLayer)
        
        configureLabel(ticketsLabel, text: "Tickets")
        configureLabel(tablesLabel, text: "Experiences")

        addSubview(ticketsLabel)
        addSubview(tablesLabel)

        selectedLeading = selectedGlassView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4)

        NSLayoutConstraint.activate([
            containerGlassView.topAnchor.constraint(equalTo: topAnchor),
            containerGlassView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerGlassView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerGlassView.bottomAnchor.constraint(equalTo: bottomAnchor),

            selectedLeading,
            selectedGlassView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            selectedGlassView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            selectedGlassView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5, constant: -4),

            ticketsLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            ticketsLabel.topAnchor.constraint(equalTo: topAnchor),
            ticketsLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            ticketsLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5),

            tablesLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            tablesLabel.topAnchor.constraint(equalTo: topAnchor),
            tablesLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            tablesLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5)
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        addGestureRecognizer(tapGesture)

        updateLabels()
    }

    private func configureLabel(_ label: UILabel, text: String) {
        label.text = text
        label.textAlignment = .center
        label.font = Constant.Font.geistMedium(size: 14)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
    }

    func setSelectedIndex(_ index: Int, animated: Bool) {
        selectedIndex = index
        selectedLeading.constant = index == 0 ? 4 : bounds.width / 2

        updateLabels()

        let animations = {
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(
                withDuration: 0.32,
                delay: 0,
                usingSpringWithDamping: 0.82,
                initialSpringVelocity: 0.48,
                options: [.curveEaseOut, .beginFromCurrentState],
                animations: animations
            )
        } else {
            animations()
        }
    }

    private func updateLabels() {
        ticketsLabel.alpha = selectedIndex == 0 ? 1.0 : 0.45
        tablesLabel.alpha = selectedIndex == 1 ? 1.0 : 0.45
    }

    @objc private func onTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self)
        let index = point.x < bounds.midX ? 0 : 1

        guard index != selectedIndex else { return }

        AppHaptic.selectionChanged()
        setSelectedIndex(index, animated: true)
        onIndexChanged?(index)
    }
}
