//
//  PremiumMarqueeLabel.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 18/06/26.
//

import UIKit

final class PremiumMarqueeLabel: UIView {

    // MARK: - Public

    var font: UIFont = Constant.Font.geistMedium(size: 20) {
        didSet {
            label.font = font
            duplicateLabel.font = font
            setNeedsLayout()
        }
    }

    var textColor: UIColor = .white {
        didSet {
            label.textColor = textColor
            duplicateLabel.textColor = textColor
        }
    }

    var animationDelay: TimeInterval = 1.0

    /// points / second
    var animationSpeed: CGFloat = 30

    var trailingSpacing: CGFloat = 40

    // MARK: - Private

    private let scrollView = UIScrollView()
    private let label = UILabel()
    private let duplicateLabel = UILabel()
    private var isAnimating = false
    private var pendingStart = false

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    deinit {
        stopAnimation()
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: font.lineHeight)
    }
}

// MARK: - Setup

private extension PremiumMarqueeLabel {

    func setup() {
        clipsToBounds = true

        scrollView.isScrollEnabled = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)

        label.font = font
        label.textColor = textColor
        label.numberOfLines = 1
        label.textAlignment = .left
        scrollView.addSubview(label)

        duplicateLabel.font = font
        duplicateLabel.textColor = textColor
        duplicateLabel.numberOfLines = 1
        duplicateLabel.textAlignment = .left
        duplicateLabel.isHidden = true
        scrollView.addSubview(duplicateLabel)
    }
}

// MARK: - Layout

extension PremiumMarqueeLabel {

    override func layoutSubviews() {
        super.layoutSubviews()

        guard bounds.width > 0, bounds.height > 0 else { return }

        scrollView.frame = bounds

        let labelWidth = label.intrinsicContentSize.width

        if labelWidth > bounds.width {
            let gap = trailingSpacing
            label.frame = CGRect(x: 0, y: 0, width: labelWidth, height: bounds.height)
            duplicateLabel.text = label.text
            duplicateLabel.isHidden = false
            duplicateLabel.frame = CGRect(
                x: labelWidth + gap,
                y: 0,
                width: labelWidth,
                height: bounds.height
            )
            scrollView.contentSize = CGSize(
                width: labelWidth + gap + labelWidth,
                height: bounds.height
            )
        } else {
            duplicateLabel.isHidden = true
            label.textAlignment = .center
            label.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
            scrollView.contentSize = bounds.size
        }

        if pendingStart {
            pendingStart = false
            startAnimationIfNeeded()
        }
    }
}

// MARK: - Public

extension PremiumMarqueeLabel {

    func setText(_ text: String?) {
        stopAnimation()
        label.text = text
        duplicateLabel.text = text
        scrollView.contentOffset = .zero
        pendingStart = true
        setNeedsLayout()
    }

    func stop() {
        stopAnimation()
    }
}

// MARK: - Animation

private extension PremiumMarqueeLabel {

    func stopAnimation() {
        scrollView.layer.removeAllAnimations()
        scrollView.contentOffset = .zero
        isAnimating = false
        pendingStart = false
    }

    func startAnimationIfNeeded() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        guard !isAnimating else { return }

        let labelWidth = label.intrinsicContentSize.width
        guard labelWidth > bounds.width else { return }

        let distance = labelWidth + trailingSpacing
        let duration = TimeInterval(distance / animationSpeed)

        isAnimating = true

        // Use CAKeyframeAnimation for true seamless loop
        // UIView.animate .repeat does not reset contentOffset
        let animation = CAKeyframeAnimation(keyPath: "bounds.origin.x")
        animation.values = [0, distance]
        animation.keyTimes = [0, 1]
        animation.duration = duration
        animation.beginTime = CACurrentMediaTime() + animationDelay
        animation.repeatCount = .infinity
        animation.calculationMode = .linear
        animation.fillMode = .backwards
        scrollView.layer.add(animation, forKey: "marqueeScroll")
    }
}
