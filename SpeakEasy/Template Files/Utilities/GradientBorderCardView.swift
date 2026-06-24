//
//  GradientBorderCardView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 12/05/26.
//

import UIKit

final class GradientBorderCardView: UIView {
    
    var fillColor: CGColor = AuthTheme.cardViewColor.cgColor {
        didSet {
            fillLayer.backgroundColor = fillColor
        }
    }
    
    var showsBlur: Bool = false {
        didSet {
            blurView.isHidden = !showsBlur
        }
    }
    
    var blurAlpha: CGFloat = 0.4 {
        didSet {
            blurView.alpha = blurAlpha
        }
    }
    
    var glassCornerRadius: CGFloat = 34 {
        didSet {
            layer.cornerRadius = glassCornerRadius
            blurView.layer.cornerRadius = glassCornerRadius
            fillLayer.cornerRadius = glassCornerRadius
        }
    }
    
    private let blurView = VisualEffectView(effect: UIBlurEffect(style: .dark))
    
    private let fillLayer = CALayer()
    private let fullBorderLayer = CAShapeLayer()
    
    private let topGlassBorderLayer = CAGradientLayer()
    private let topGlassMaskLayer = CAShapeLayer()
    
    private let bottomGlassBorderLayer = CAGradientLayer()
    private let bottomGlassMaskLayer = CAShapeLayer()
    
    private var borderColors = [
        AppColor.primaryWhiteColor.withAlphaComponent(0).cgColor,
        AppColor.primaryWhiteColor.withAlphaComponent(0.11).cgColor,
        AppColor.primaryWhiteColor.withAlphaComponent(0.20).cgColor,
        AppColor.primaryWhiteColor.withAlphaComponent(0.24).cgColor,
        AppColor.primaryWhiteColor.withAlphaComponent(0).cgColor
    ]
    
    var thinBorder: Bool = false {
        didSet {
            if thinBorder { borderColors = [
                AppColor.primaryWhiteColor.withAlphaComponent(0).cgColor,
                AppColor.primaryWhiteColor.withAlphaComponent(0.06).cgColor,
                AppColor.primaryWhiteColor.withAlphaComponent(0.14).cgColor,
                AppColor.primaryWhiteColor.withAlphaComponent(0.20).cgColor,
                AppColor.primaryWhiteColor.withAlphaComponent(0).cgColor
            ]
            }
            setNeedsLayout()
        }
    }
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear

        layer.cornerRadius = glassCornerRadius
        layer.cornerCurve = .continuous
        layer.masksToBounds = false

        blurView.alpha = blurAlpha
        blurView.isHidden = true
        blurView.colorTintAlpha = 0.02
        blurView.blurRadius = 20
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = glassCornerRadius
        blurView.clipsToBounds = true
        insertSubview(blurView, at: 0)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        addSubview(blurView)
        
        fillLayer.backgroundColor = fillColor
        fillLayer.cornerRadius = glassCornerRadius
        layer.insertSublayer(fillLayer, at: 0)

        fullBorderLayer.fillColor = UIColor.clear.cgColor
        fullBorderLayer.strokeColor = AppColor.primaryWhiteColor.withAlphaComponent(0.10).cgColor
        fullBorderLayer.lineWidth = 0.8
        fullBorderLayer.lineCap = .round
        fullBorderLayer.lineJoin = .round
        layer.addSublayer(fullBorderLayer)

        topGlassBorderLayer.startPoint = CGPoint(x: 0, y: 0.5)
        topGlassBorderLayer.endPoint = CGPoint(x: 1, y: 0.5)
        topGlassBorderLayer.colors = borderColors
        topGlassBorderLayer.locations = [0.0, 0.10, 0.50, 0.96, 1.0]
        topGlassBorderLayer.mask = topGlassMaskLayer
        layer.addSublayer(topGlassBorderLayer)
        
        bottomGlassBorderLayer.startPoint = CGPoint(x: 1, y: 0.5)
        bottomGlassBorderLayer.endPoint = CGPoint(x: 0, y: 0.5)
        bottomGlassBorderLayer.colors = borderColors
        bottomGlassBorderLayer.locations = [0.0, 0.10, 0.50, 0.96, 1.0]
        bottomGlassBorderLayer.mask = bottomGlassMaskLayer

        layer.addSublayer(bottomGlassBorderLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let fullWidth: CGFloat = thinBorder ? 0.3  : 0.8
        let topWidth: CGFloat = thinBorder ? 0.7  : 1.30
        let bottomWidth: CGFloat = thinBorder ? 0.7  : 1.10
        
        blurView.frame = bounds
        blurView.layer.cornerRadius = glassCornerRadius
        blurView.clipsToBounds = true

        fillLayer.frame = bounds
        topGlassBorderLayer.frame = bounds
        bottomGlassBorderLayer.frame = bounds
        
        let rect = bounds.insetBy(dx: 0.75, dy: 0.75)

        fullBorderLayer.path = UIBezierPath(
            roundedRect: rect,
            cornerRadius: glassCornerRadius
        ).cgPath
        fullBorderLayer.lineWidth = fullWidth

        topGlassMaskLayer.path = makeTopHalfBorderPath(rect: rect, radius: glassCornerRadius).cgPath
        topGlassMaskLayer.fillColor = UIColor.clear.cgColor
        topGlassMaskLayer.strokeColor = UIColor.white.cgColor
        topGlassMaskLayer.lineWidth = topWidth
        topGlassMaskLayer.lineCap = .round
        topGlassMaskLayer.lineJoin = .round
        
        bottomGlassMaskLayer.path = makeBottomHalfBorderPath(
            rect: rect,
            radius: glassCornerRadius
        ).cgPath

        bottomGlassMaskLayer.fillColor = UIColor.clear.cgColor
        bottomGlassMaskLayer.strokeColor = UIColor.white.cgColor
        bottomGlassMaskLayer.lineWidth = bottomWidth
        bottomGlassMaskLayer.lineCap = .round
        bottomGlassMaskLayer.lineJoin = .round
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        fillLayer.backgroundColor = fillColor
        fullBorderLayer.strokeColor = AppColor.primaryWhiteColor.withAlphaComponent(0.10).cgColor

        topGlassBorderLayer.colors = borderColors
        
        bottomGlassBorderLayer.colors = borderColors
    }
    
    private func makeTopHalfBorderPath(rect: CGRect, radius: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        
        // left side start, small amount below top-left curve
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + radius + 12))

        // top-left curve
        path.addArc(
            withCenter: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
            radius: radius,
            startAngle: .pi,
            endAngle: -.pi / 2,
            clockwise: true
        )

        // full top border
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))

        // top-right curve
        path.addArc(
            withCenter: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 0,
            clockwise: true
        )

        // right side slightly down
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + radius + 12))

        return path
    }
    
    private func makeBottomHalfBorderPath(
        rect: CGRect,
        radius: CGFloat
    ) -> UIBezierPath {

        let path = UIBezierPath()

        // LEFT BOTTOM
        path.move(
            to: CGPoint(
                x: rect.minX,
                y: rect.maxY - radius - 12
            )
        )

        // bottom-left curve
        path.addArc(
            withCenter: CGPoint(
                x: rect.minX + radius,
                y: rect.maxY - radius
            ),
            radius: radius,
            startAngle: .pi,
            endAngle: .pi / 2,
            clockwise: false
        )

        // bottom line
        path.addLine(
            to: CGPoint(
                x: rect.maxX - radius,
                y: rect.maxY
            )
        )

        // bottom-right curve
        path.addArc(
            withCenter: CGPoint(
                x: rect.maxX - radius,
                y: rect.maxY - radius
            ),
            radius: radius,
            startAngle: .pi / 2,
            endAngle: 0,
            clockwise: false
        )

        // RIGHT BOTTOM
        path.addLine(
            to: CGPoint(
                x: rect.maxX,
                y: rect.maxY - radius - 12
            )
        )

        return path
    }
}
