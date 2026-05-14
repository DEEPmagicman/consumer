//
//  HomeSkeletonView.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 14/05/26.
//

import Foundation
import UIKit

final class HomeSkeletonView: UIView {

    private var allShimmerViews: [ShimmerView] = []
    private var didSetup = false

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !didSetup, bounds.width > 0 else { return }
        didSetup = true
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear

        let W       = bounds.width
        let pad: CGFloat = 16
        var y: CGFloat   = 60
        // 1. FILTER CHIPS
//        let chipWidths: [CGFloat] = [110, 90]
//        var chipX: CGFloat = pad
//        for cw in chipWidths {
//            makeGlass(CGRect(x: chipX, y: y, width: cw, height: 34), corner: 17)
//            chipX += cw + 10
//        }
//        y += 34 + 28
        
        // 2. "EVENTS TONIGHT" header
        make(CGRect(x: pad, y: y, width: 160, height: 16), corner: 8)
        makeGlass(CGRect(x: W - pad - 36, y: y - 10, width: 36, height: 36), corner: 18)
        y += 16 + 16

        // 3. EVENT CARDS — portrait, 3 visible (last one partial)
        let cardW: CGFloat = (W - pad * 2 - 12 * 2) / 2.4
        let cardH: CGFloat = cardW
        var cardX: CGFloat = pad

        for i in 0..<3 {
            make(CGRect(x: cardX, y: y, width: cardW, height: cardH), corner: 14)

            let tx  = cardX
            let ty1 = y + cardH + 8
            let ty2 = ty1 + 18

            makeBright(CGRect(x: tx, y: ty1, width: cardW * 0.85, height: 14), corner: 6)
            make(CGRect(x: tx, y: ty2, width: cardW * 0.65, height: 11), corner: 5)

            cardX += cardW + 12
            _ = i
        }

        y += cardH + 8 + 18 + 11 + 28

        // 4. BANNER CARD (Premium Experiences style)
        let bannerH: CGFloat = 80
        makeGlass(CGRect(x: pad, y: y, width: W - pad * 2, height: bannerH), corner: 18)
        make(CGRect(x: pad + 16, y: y + 16, width: 48, height: 48), corner: 10)
        let btx = pad + 16 + 48 + 14
        makeBright(CGRect(x: btx, y: y + 16, width: 160, height: 14), corner: 6)
        make(CGRect(x: btx, y: y + 16 + 20, width: 200, height: 11), corner: 5)
        make(CGRect(x: btx, y: y + 16 + 20 + 17, width: 100, height: 11), corner: 5)
        makeGlass(CGRect(x: W - pad - 16 - 24, y: y + 16, width: 24, height: 24), corner: 12)

        y += bannerH + 28

        // 5. "EVENTS IN CITY" header
        make(CGRect(x: pad, y: y, width: 200, height: 16), corner: 8)
        makeGlass(CGRect(x: W - pad - 36, y: y - 10, width: 36, height: 36), corner: 18)
        y += 16 + 16

        // 6. SQUARE CARDS — 3 across
        let sqW: CGFloat = (W - pad * 2 - 10 * 2) / 3
        let sqH: CGFloat = sqW
        var sqX: CGFloat = pad

        for _ in 0..<3 {
            make(CGRect(x: sqX, y: y, width: sqW, height: sqH), corner: 12)
            make(CGRect(x: sqX, y: y + sqH + 8, width: sqW * 0.75, height: 11), corner: 5)
            make(CGRect(x: sqX, y: y + sqH + 8 + 16, width: sqW * 0.55, height: 10), corner: 5)
            sqX += sqW + 10
        }
    }

    private func make(_ frame: CGRect, corner: CGFloat = 8) {
        let sv = ShimmerView(frame: frame)
        sv.layer.cornerRadius = corner
        sv.clipsToBounds = true
        addSubview(sv)
        allShimmerViews.append(sv)
    }

    private func makeBright(_ frame: CGRect, corner: CGFloat = 6) {
        let sv = ShimmerView(frame: frame, lighter: true)
        sv.layer.cornerRadius = corner
        sv.clipsToBounds = true
        addSubview(sv)
        allShimmerViews.append(sv)
    }

    private func makeGlass(_ frame: CGRect, corner: CGFloat = 12) {
        let sv = ShimmerView(frame: frame)
        sv.layer.cornerRadius  = corner
        sv.layer.cornerCurve   = .continuous
        sv.clipsToBounds       = true
        // Liquid Glass tint: subtle white/blue overlay
        sv.backgroundColor     = UIColor(white: 1, alpha: 0.07)
        sv.layer.borderWidth   = 0.75
        sv.layer.borderColor   = UIColor(white: 1, alpha: 0.12).cgColor
        addSubview(sv)
        allShimmerViews.append(sv)
    }

    func startShimmer() {
        isHidden = false
        allShimmerViews.forEach { $0.startAnimating() }
    }

    func stopShimmer() {
        allShimmerViews.forEach { $0.stopAnimating() }
        isHidden = true
    }
}
