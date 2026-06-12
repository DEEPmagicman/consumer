//
//  HomeSkeletonView.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 14/05/26.
//

import Foundation
import UIKit

final class HomeSkeletonView: UIView {

    private var shimmerViews: [ShimmerViewV3] = []
    private var didBuildLayout = false
    private var lastLayoutSize: CGSize = .zero
    private var shouldAnimate = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        guard window != nil else {
            return
        }

        didBuildLayout = false
        setNeedsLayout()

        if shouldAnimate {
            DispatchQueue.main.async { [weak self] in
                self?.startShimmer()
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard window != nil else {
            return
        }

        guard bounds.width > 0,
              bounds.height > 0 else {
            return
        }

        let widthChanged =
            abs(bounds.width - lastLayoutSize.width) > 0.5

        guard !didBuildLayout ||
              widthChanged else {
            return
        }

        didBuildLayout = true
        lastLayoutSize = bounds.size
        rebuildLayout()
    }

    func startShimmer() {
        shouldAnimate = true
        isHidden = false
        setNeedsLayout()
        layoutIfNeeded()

        shimmerViews.forEach {
            $0.startShimmer()
        }
    }

    func stopShimmer() {
        shouldAnimate = false

        shimmerViews.forEach {
            $0.stopShimmer()
        }

        isHidden = true
    }
}

// MARK: - Layout

private extension HomeSkeletonView {

    func setupView() {
        backgroundColor = UIColor(
            red: 9.0 / 255.0,
            green: 15.0 / 255.0,
            blue: 16.0 / 255.0,
            alpha: 1
        )

        isUserInteractionEnabled = true
    }

    func rebuildLayout() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        shimmerViews.forEach {
            $0.stopShimmer()
            $0.removeFromSuperview()
        }

        shimmerViews.removeAll()

        let width = bounds.width
        let pad: CGFloat = 16
        let cardSpacing: CGFloat = 12
        let cardWidth = min(
            160,
            max(
                124,
                (width - pad * 2 - cardSpacing * 2) / 2.35
            )
        )

        let headerY = safeAreaInsets.top
        let filterY = safeAreaInsets.top + 50
        let firstSectionY = filterY + 30 + 32

        addTopHeader(y: headerY)
        addFilterRow(y: filterY)

        var y = addSection(
            y: firstSectionY,
            titleWidth: 158,
            cardWidth: cardWidth,
            cardSpacing: cardSpacing
        )

        y = addSection(
            y: y + 38,
            titleWidth: 138,
            cardWidth: cardWidth,
            cardSpacing: cardSpacing
        )

        _ = addSection(
            y: y + 38,
            titleWidth: 178,
            cardWidth: cardWidth,
            cardSpacing: cardSpacing
        )

        CATransaction.commit()

        if shouldAnimate {
            shimmerViews.forEach {
                $0.startShimmer()
            }
        }
    }

    func addTopHeader(y: CGFloat) {
        let pad: CGFloat = 16
        let headerHeight: CGFloat = 40
        let avatarSize: CGFloat = 30
        let avatarY = y + (headerHeight - avatarSize) / 2

        addBlock(
            frame: CGRect(
                x: pad,
                y: avatarY,
                width: avatarSize,
                height: avatarSize
            ),
            corner: avatarSize / 2
        )

        addBlock(
            frame: CGRect(
                x: pad + avatarSize + 12,
                y: avatarY + 7,
                width: min(134, bounds.width * 0.36),
                height: 16
            ),
            corner: 8
        )

        let buttonSize: CGFloat = 32

        addBlock(
            frame: CGRect(
                x: bounds.width - 14 - buttonSize,
                y: y + (headerHeight - buttonSize) / 2,
                width: buttonSize,
                height: buttonSize
            ),
            corner: buttonSize / 2
        )
    }

    func addFilterRow(y: CGFloat) {
        let pad: CGFloat = 16
        let chipHeight: CGFloat = 30
        let chipSpacing: CGFloat = 8
        let cityChipWidth: CGFloat = 95
        let dateChipWidth = min(
            142,
            bounds.width - pad * 2 - cityChipWidth - chipSpacing
        )

        addBlock(
            frame: CGRect(
                x: pad,
                y: y,
                width: cityChipWidth,
                height: chipHeight
            ),
            corner: chipHeight / 2
        )

        addBlock(
            frame: CGRect(
                x: pad + cityChipWidth + chipSpacing,
                y: y,
                width: dateChipWidth,
                height: chipHeight
            ),
            corner: chipHeight / 2
        )
    }

    func addSection(
        y: CGFloat,
        titleWidth: CGFloat,
        cardWidth: CGFloat,
        cardSpacing: CGFloat
    ) -> CGFloat {

        let pad: CGFloat = 16
        let buttonSize: CGFloat = 40
        let rowTop = y + 58

        addBlock(
            frame: CGRect(
                x: pad,
                y: y,
                width: min(titleWidth, bounds.width - pad * 2 - 70),
                height: 24
            ),
            corner: 12
        )

        addBlock(
            frame: CGRect(
                x: bounds.width - pad - buttonSize,
                y: y - 8,
                width: buttonSize,
                height: buttonSize
            ),
            corner: buttonSize / 2
        )

        for index in 0..<3 {
            let x = pad + CGFloat(index) * (cardWidth + cardSpacing)

            addEventCard(
                x: x,
                y: rowTop,
                width: cardWidth
            )
        }

        return rowTop + cardWidth + 62
    }

    func addEventCard(
        x: CGFloat,
        y: CGFloat,
        width: CGFloat
    ) {

        addBlock(
            frame: CGRect(
                x: x,
                y: y,
                width: width,
                height: width
            ),
            corner: 8
        )

        let venueY = y + width + 9

        addBlock(
            frame: CGRect(
                x: x,
                y: venueY,
                width: width * 0.66,
                height: 12
            ),
            corner: 6
        )

        addBlock(
            frame: CGRect(
                x: x,
                y: venueY + 19,
                width: width * 0.86,
                height: 16
            ),
            corner: 8
        )

        addBlock(
            frame: CGRect(
                x: x,
                y: venueY + 42,
                width: width * 0.52,
                height: 12
            ),
            corner: 6
        )
    }

    func addBlock(
        frame: CGRect,
        corner: CGFloat
    ) {

        let shimmerView = ShimmerViewV3(
            frame: frame.integral
        )

        shimmerView.layer.cornerRadius = corner
        shimmerView.layer.cornerCurve = .continuous
        addSubview(shimmerView)
        shimmerViews.append(shimmerView)
    }
}
