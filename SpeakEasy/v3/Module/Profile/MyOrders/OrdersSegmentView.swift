//
//  OrdersSegmentView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 25/05/26.
//

import UIKit

final class OrdersSegmentView: UIControl {

    var onIndexChanged: ((Int) -> Void)?

    private let backgroundLayer = CAGradientLayer()
    private let borderLayer = CAGradientLayer()
    private let selectedView = UIView()
    private let selectedGradientLayer = CAGradientLayer()
    private let ticketsLabel = UILabel()
    private let tablesLabel = UILabel()

    private var selectedLeading: NSLayoutConstraint!
    private var selectedIndex: Int = 0
    private let viewBorderWidth: CGFloat = 1.5

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

        // Update background gradient
        backgroundLayer.frame = bounds
        backgroundLayer.cornerRadius = bounds.height / 2

        // Update border gradient
        borderLayer.frame = bounds
        borderLayer.cornerRadius = bounds.height / 2

        // Update selected view
        selectedView.layer.cornerRadius = selectedView.bounds.height / 2
        selectedView.layer.masksToBounds = true

        // Update selected gradient
        selectedGradientLayer.frame = selectedView.bounds
        selectedGradientLayer.cornerRadius = selectedView.bounds.height / 2
    }

    private func setupUI() {
        // Setup main container with gradient borders
        setupContainer()
        
        // Setup selected indicator view
        setupSelectedView()
        
        // Setup labels
        setupLabels()
        
        // Setup constraints
        setupConstraints()
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        addGestureRecognizer(tapGesture)
    }

    private func setupContainer() {
        
        // Background gradient layer (dark semi-transparent)
        backgroundLayer.borderWidth = 0.2
        backgroundLayer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        
        backgroundLayer.colors = [
            UIColor.black.withAlphaComponent(0.30).cgColor,
            UIColor.black.withAlphaComponent(0.16).cgColor
        ]
        backgroundLayer.startPoint = CGPoint(x: 0, y: 0)
        backgroundLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(backgroundLayer, at: 0)

        borderLayer.colors = [
            UIColor.white.withAlphaComponent(1.0).cgColor,
            UIColor.white.withAlphaComponent(0.5).cgColor
        ]
        borderLayer.startPoint = CGPoint(x: 0, y: 0)
        borderLayer.endPoint = CGPoint(x: 1, y: 1)
        borderLayer.cornerRadius = 0
        borderLayer.masksToBounds = true

        // Create border mask
        let borderPath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: bounds.height / 2
        )
        let innerPath = UIBezierPath(
            roundedRect: bounds.insetBy(dx: viewBorderWidth, dy: viewBorderWidth),
            cornerRadius: (bounds.height - viewBorderWidth * 2) / 2
        )
        
        let shape = CAShapeLayer()
        shape.fillRule = .evenOdd
        shape.path = {
            let path = UIBezierPath()
            path.append(borderPath)
            path.append(innerPath.reversing())
            return path.cgPath
        }()
        
        borderLayer.mask = shape
        layer.insertSublayer(borderLayer, at: 1)

        clipsToBounds = true
    }

    private func setupSelectedView() {
        // Selected view with gradient
        selectedGradientLayer.colors = [
            UIColor(hex: "#FFFFFF").withAlphaComponent(0.08).cgColor,
            UIColor(hex: "#FFFDFD").withAlphaComponent(0.03).cgColor
        ]
        selectedGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        selectedGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        selectedGradientLayer.cornerRadius = 0
        
        selectedView.backgroundColor = .clear
        selectedView.layer.addSublayer(selectedGradientLayer)
        
        // Subtle border on selected view
        selectedView.layer.borderWidth = 0.8
        selectedView.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
        
        selectedView.translatesAutoresizingMaskIntoConstraints = false
        selectedView.isUserInteractionEnabled = false
        addSubview(selectedView)
    }

    private func setupLabels() {
        // Configure Tickets label
        configureLabel(ticketsLabel, text: "Tickets")
        addSubview(ticketsLabel)

        // Configure Tables label
        configureLabel(tablesLabel, text: "Tables")
        addSubview(tablesLabel)
    }

    private func setupConstraints() {
        selectedLeading = selectedView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4)

        NSLayoutConstraint.activate([
            // Selected view constraints
            selectedLeading,
            selectedView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            selectedView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            selectedView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5, constant: -4),

            // Tickets label constraints
            ticketsLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            ticketsLabel.topAnchor.constraint(equalTo: topAnchor),
            ticketsLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            ticketsLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5),

            // Tables label constraints
            tablesLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            tablesLabel.topAnchor.constraint(equalTo: topAnchor),
            tablesLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            tablesLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5)
        ])

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
        selectedLeading.constant = index == 0 ? 6 : (bounds.width / 2)

        updateLabels()

        let animations = {
            self.layoutIfNeeded()
        }

        if animated {
            // Smooth spring animation for liquid glass effect
            UIView.animate(
                withDuration: 0.32,
                delay: 0,
                usingSpringWithDamping: 0.82,
                initialSpringVelocity: 0.48,
                options: [.curveEaseOut, .beginFromCurrentState],
                animations: animations,
                completion: nil
            )
        } else {
            animations()
        }
    }

    private func updateLabels() {
        // Smooth alpha transitions
        ticketsLabel.alpha = selectedIndex == 0 ? 1.0 : 0.45
        tablesLabel.alpha = selectedIndex == 1 ? 1.0 : 0.45
    }

    @objc private func onTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self)
        let index = point.x < bounds.midX ? 0 : 1

        guard index != selectedIndex else { return }

        setSelectedIndex(index, animated: true)
        onIndexChanged?(index)
    }
}
