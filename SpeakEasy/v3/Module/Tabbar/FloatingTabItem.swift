//
//  FloatingTabItem 2.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 21/05/26.
//

import UIKit

struct FloatingTabItem {
    let title: String
    let icon: UIImage?
}

protocol FloatingCustomTabBarDelegate: AnyObject {
    func floatingCustomTabBar(_ tabBar: FloatingCustomTabBar, didSelect index: Int)
}

final class FloatingCustomTabBar: UIView {

    weak var delegate: FloatingCustomTabBarDelegate?
    
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let tintView = UIView()
    private let borderLayer = CAShapeLayer()
    private let stackView = UIStackView()

    private var buttons: [FloatingTabButton] = []
    private var selectedIndex = 0

    private let selectedColor = UIColor(hex: "#8CB7FF")
    private let normalColor = UIColor(hex: "#D1D1D1")

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

        layer.cornerRadius = bounds.height / 2
        blurView.layer.cornerRadius = bounds.height / 2
        tintView.layer.cornerRadius = bounds.height / 2

        let path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
            cornerRadius: bounds.height / 2
        )

        borderLayer.path = path.cgPath
    }

    private func setupUI() {
        backgroundColor = .clear
        clipsToBounds = false
        
        blurView.clipsToBounds = true
        blurView.alpha = 0.98
        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)
        
        tintView.backgroundColor = UIColor(hex: "#101010").withAlphaComponent(0.62)
        tintView.clipsToBounds = true
        tintView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tintView)

        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = AppColor.primaryWhiteColor.withAlphaComponent(0.22).cgColor
        borderLayer.lineWidth = 0.65
        layer.addSublayer(borderLayer)

        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

            tintView.topAnchor.constraint(equalTo: topAnchor),
            tintView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tintView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tintView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5)
        ])
    }

    func configure(items: [FloatingTabItem]) {
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()

        for (index, item) in items.enumerated() {
            let button = FloatingTabButton()
            button.configure(item: item)
            button.tag = index
            button.addTarget(self, action: #selector(onTap(_:)), for: .touchUpInside)

            buttons.append(button)
            stackView.addArrangedSubview(button)
        }

        setSelected(index: 0, animated: false)
    }

    func setSelected(index: Int) {
        setSelected(index: index, animated: true)
    }

    private func setSelected(index: Int, animated: Bool) {
        selectedIndex = index

        for (buttonIndex, button) in buttons.enumerated() {
            button.setSelected(
                buttonIndex == index,
                selectedColor: selectedColor,
                normalColor: normalColor,
                animated: animated
            )
        }
    }

    @objc private func onTap(_ sender: UIControl) {
        guard sender.tag != selectedIndex else { return }

        AppHaptic.selectionChanged()
        delegate?.floatingCustomTabBar(self, didSelect: sender.tag)
    }
}
