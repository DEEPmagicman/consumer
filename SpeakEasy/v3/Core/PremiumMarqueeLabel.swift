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

    var textAlignment: NSTextAlignment = .center {
        didSet {
            label.textAlignment = textAlignment
            duplicateLabel.textAlignment = textAlignment
            setNeedsLayout()
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
    private let containerView = UIView()
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
        backgroundColor = .clear
        clipsToBounds = true

        scrollView.backgroundColor = .clear
        scrollView.isScrollEnabled = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)

        label.backgroundColor = .clear
        label.font = font
        label.textColor = textColor
        label.numberOfLines = 1
        label.textAlignment = .left
        scrollView.addSubview(label)

        duplicateLabel.backgroundColor = .clear
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
            label.textAlignment = .left
            label.frame = CGRect(x: 0, y: 0, width: labelWidth, height: bounds.height)
            duplicateLabel.text = label.text
            duplicateLabel.textAlignment = .left
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
            label.textAlignment = textAlignment
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

    func install(
        over sourceLabel: UILabel,
        in parentView: UIView? = nil,
        height: CGFloat? = nil,
        horizontalInset: CGFloat? = nil,
        hideSourceLabel: Bool = true
    ) {
        guard containerView.superview == nil,
              let parent = parentView ?? sourceLabel.superview
        else { return }

        let resolvedHeight = height ?? max(
            ceil(sourceLabel.font?.lineHeight ?? font.lineHeight),
            sourceLabel.bounds.height
        )

        font = sourceLabel.font ?? font
        textColor = sourceLabel.textColor
        animationSpeed = 25
        animationDelay = 1.2
        trailingSpacing = 48
        backgroundColor = .clear
        scrollView.backgroundColor = .clear
        label.backgroundColor = .clear
        duplicateLabel.backgroundColor = .clear
        sourceLabel.backgroundColor = .clear

        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear
        containerView.clipsToBounds = true
        containerView.isUserInteractionEnabled = false

        translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(self)
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: containerView.topAnchor),
            leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        if let stackView = parent as? UIStackView,
           let index = stackView.arrangedSubviews.firstIndex(of: sourceLabel) {

            stackView.insertArrangedSubview(containerView, at: index)
            sourceLabel.removeFromSuperview()

            NSLayoutConstraint.activate([
                containerView.heightAnchor.constraint(equalToConstant: resolvedHeight)
            ])

            return
        }

        parent.addSubview(containerView)
        sourceLabel.text = " "
        sourceLabel.numberOfLines = 1
        sourceLabel.lineBreakMode = .byTruncatingTail
        sourceLabel.isHidden = false
        sourceLabel.alpha = hideSourceLabel ? 0 : sourceLabel.alpha

        let leadingConstraint: NSLayoutConstraint
        let trailingConstraint: NSLayoutConstraint
        if let horizontalInset {
            leadingConstraint = containerView.leadingAnchor.constraint(
                equalTo: parent.leadingAnchor,
                constant: horizontalInset
            )
            trailingConstraint = containerView.trailingAnchor.constraint(
                equalTo: parent.trailingAnchor,
                constant: -horizontalInset
            )
        } else {
            leadingConstraint = containerView.leadingAnchor.constraint(equalTo: sourceLabel.leadingAnchor)
            trailingConstraint = containerView.trailingAnchor.constraint(equalTo: sourceLabel.trailingAnchor)
        }

        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: sourceLabel.centerYAnchor),
            leadingConstraint,
            trailingConstraint,
            containerView.heightAnchor.constraint(equalToConstant: resolvedHeight)
        ])
    }

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
