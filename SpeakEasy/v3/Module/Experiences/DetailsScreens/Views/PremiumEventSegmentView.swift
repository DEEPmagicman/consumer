//
//  PremiumEventSegmentViewDelegate.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 18/06/26.
//

import UIKit

protocol PremiumEventSegmentViewDelegate: AnyObject {

    func premiumSegmentView(
        _ view: PremiumEventSegmentView,
        didSelect segment: PremiumEventContainerVC.Segment
    )
}

final class PremiumEventSegmentView: UIView {

    weak var delegate: PremiumEventSegmentViewDelegate?

    // MARK: Views

    private let glassView = LiquidGlassBackgroundView(
        cornerRadius: 24,
        fillColor: UIColor.black.withAlphaComponent(0.18),
        borderColor: UIColor.white.withAlphaComponent(0.2),
        borderWidth: 0.8
    )

    private let selectedView = LiquidGlassBackgroundView(
        cornerRadius: 20,
        fillColor: .clear,
        borderColor: UIColor.white.withAlphaComponent(0.2),
        borderWidth: 0.8
    )

    private let stackView = UIStackView()

    private let mapButton = UIButton(type: .system)

    private let listButton = UIButton(type: .system)

    private let inquiryButton = UIButton(type: .system)

    private var selectedLeading: NSLayoutConstraint!

    private var selectedWidth: NSLayoutConstraint!

    private var selectedIndex = 1
    
    private let selectedGradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let horizontalPadding: CGFloat = 4
        let width = (glassView.bounds.width - (horizontalPadding * 2)) / 3
        
        selectedWidth.constant = width
        selectedLeading.constant = horizontalPadding + (CGFloat(selectedIndex) * width)
        DispatchQueue.main.async {
            self.selectedGradientLayer.frame = self.selectedView.bounds
            self.selectedGradientLayer.cornerRadius = self.selectedView.bounds.height / 2
        }
    }
}

private extension PremiumEventSegmentView {

    func setup() {

        translatesAutoresizingMaskIntoConstraints = false

        addSubview(glassView)

        glassView.clipsToBounds = true
        selectedView.isUserInteractionEnabled = false
        
        glassView.translatesAutoresizingMaskIntoConstraints = false

        selectedView.translatesAutoresizingMaskIntoConstraints = false

        glassView.addSubview(selectedView)

        selectedGradientLayer.colors = [
            UIColor.white.withAlphaComponent(0.18).cgColor,
            UIColor.white.withAlphaComponent(0.08).cgColor
        ]

        selectedGradientLayer.locations = [0, 1]
        selectedGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        selectedGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)

        selectedGradientLayer.masksToBounds = true
        selectedView.layer.insertSublayer(selectedGradientLayer, at: 0)
        
        setupButtons()

        setupConstraints()

        updateSelection(animated: false)
        
    }
}

private extension PremiumEventSegmentView {

    func setupButtons() {

        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false

        glassView.addSubview(stackView)

        configureButton(
            mapButton,
            title: "3D Map",
            tag: 0
        )

        configureButton(
            listButton,
            title: "List",
            tag: 1
        )

        configureButton(
            inquiryButton,
            title: "Inquiry",
            tag: 2
        )

        stackView.addArrangedSubview(mapButton)
        stackView.addArrangedSubview(listButton)
        stackView.addArrangedSubview(inquiryButton)
    }

    func configureButton(
        _ button: UIButton,
        title: String,
        tag: Int
    ) {

        button.tag = tag

        button.setTitle(title, for: .normal)

        button.setTitleColor(
            AppColor.primaryWhiteColor.withAlphaComponent(0.95),
            for: .normal
        )

        button.titleLabel?.font = Constant.Font.geistMedium(size: 14)

        button.backgroundColor = .clear

        button.addTarget(
            self,
            action: #selector(onTap(_:)),
            for: .touchUpInside
        )
    }
}

private extension PremiumEventSegmentView {

    func setupConstraints() {

        NSLayoutConstraint.activate([

            heightAnchor.constraint(equalToConstant: 48),

            glassView.topAnchor.constraint(equalTo: topAnchor),
            glassView.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: trailingAnchor),
            glassView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stackView.topAnchor.constraint(equalTo: glassView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: glassView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: glassView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: glassView.bottomAnchor),

            selectedView.topAnchor.constraint(equalTo: glassView.topAnchor, constant: 4),
            selectedView.bottomAnchor.constraint(equalTo: glassView.bottomAnchor, constant: -4)
        ])

        selectedLeading = selectedView.leadingAnchor.constraint(
            equalTo: glassView.leadingAnchor,
            constant: 4
        )

        selectedWidth = selectedView.widthAnchor.constraint(equalToConstant: 100)

        selectedLeading.isActive = true
        selectedWidth.isActive = true
    }
}

private extension PremiumEventSegmentView {

    func updateSelection(animated: Bool) {

        layoutIfNeeded()

        let horizontalPadding: CGFloat = 4
        let width = (glassView.bounds.width - (horizontalPadding * 2)) / 3

        selectedWidth.constant = width
        selectedLeading.constant = horizontalPadding + (CGFloat(selectedIndex) * width)

        let animations = {

            self.layoutIfNeeded()

            self.mapButton.alpha = self.selectedIndex == 0 ? 1 : 0.72
            self.listButton.alpha = self.selectedIndex == 1 ? 1 : 0.72
            self.inquiryButton.alpha = self.selectedIndex == 2 ? 1 : 0.72

            self.mapButton.titleLabel?.font =
                self.selectedIndex == 0
                ? Constant.Font.geistMedium(size: 14)
                : Constant.Font.geistRegular(size: 14)

            self.listButton.titleLabel?.font =
                self.selectedIndex == 1
                ? Constant.Font.geistMedium(size: 14)
                : Constant.Font.geistRegular(size: 14)

            self.inquiryButton.titleLabel?.font =
                self.selectedIndex == 2
                ? Constant.Font.geistMedium(size: 14)
                : Constant.Font.geistRegular(size: 14)
        }

        if animated {

            UIView.animate(
                withDuration: 0.1,
                delay: 0,
                usingSpringWithDamping: 0.6,
                initialSpringVelocity: 0.5,
                options: .curveEaseOut
            ) {
                animations()
            }

        } else {

            animations()
        }
    }
}

private extension PremiumEventSegmentView {

    @objc
    func onTap(_ sender: UIButton) {

        guard sender.tag != selectedIndex else {
            return
        }

        selectedIndex = sender.tag

        updateSelection(animated: true)

        switch sender.tag {

        case 0:

            delegate?.premiumSegmentView(
                self,
                didSelect: .map
            )

        case 1:

            delegate?.premiumSegmentView(
                self,
                didSelect: .list
            )

        default:

            delegate?.premiumSegmentView(
                self,
                didSelect: .inquiry
            )
        }
    }
}

extension PremiumEventSegmentView {

    func select(
        _ segment: PremiumEventContainerVC.Segment,
        animated: Bool = true
    ) {

        switch segment {

        case .map:
            selectedIndex = 0

        case .list:
            selectedIndex = 1

        case .inquiry:
            selectedIndex = 2
        }

        updateSelection(animated: animated)
    }
}
