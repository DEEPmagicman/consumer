//
//  SkeletonOverlayView.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 27/02/26.
//

import Foundation
import UIKit

final class SkeletonOverlayView: UIView {

    private var blocks: [UIView] = []
    private var targetViews: [UIView] = []
    private var shimmerLayers: [CAGradientLayer] = []

    func show(over parent: UIView, targets: [UIView]) {

        frame = parent.bounds
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundColor = .clear
        isUserInteractionEnabled = false

        parent.addSubview(self)

        targetViews = targets

        buildBlocks()
        updateFrames()
        startShimmer()
    }

    func hide() {
        stopShimmer()
        removeFromSuperview()
        blocks.removeAll()
        targetViews.removeAll()
    }

    private func buildBlocks() {
        blocks.forEach { $0.removeFromSuperview() }
        blocks.removeAll()

        for target in targetViews {
            let block = UIView()
            block.backgroundColor = UIColor.secondarySystemFill
            block.layer.cornerRadius = target.layer.cornerRadius > 0 ? target.layer.cornerRadius : 10
            block.clipsToBounds = true
            addSubview(block)
            blocks.append(block)
        }
    }

    func updateFrames() {
        guard blocks.count == targetViews.count else { return }

        for (index, target) in targetViews.enumerated() {
            guard let superview = target.superview else { continue }
            let convertedFrame = superview.convert(target.frame, to: self)
            blocks[index].frame = convertedFrame
        }

        // keep shimmer layers in sync
        for (i, layer) in shimmerLayers.enumerated() where i < blocks.count {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.frame = blocks[i].bounds
            CATransaction.commit()
        }
    }

    // MARK: - Shimmer
    private func startShimmer() {
        stopShimmer()

        for block in blocks {
            let shimmer = CAGradientLayer()
            shimmer.frame = block.bounds
            shimmer.cornerRadius = block.layer.cornerRadius

            shimmer.colors = [
                UIColor.secondarySystemFill.cgColor,
                UIColor.systemFill.withAlphaComponent(0.9).cgColor,
                UIColor.secondarySystemFill.cgColor
            ]
            shimmer.locations = [0.0, 0.5, 1.0]
            shimmer.startPoint = CGPoint(x: 0, y: 0.5)
            shimmer.endPoint = CGPoint(x: 1, y: 0.5)

            block.layer.addSublayer(shimmer)
            shimmerLayers.append(shimmer)

            let anim = CABasicAnimation(keyPath: "locations")
            anim.fromValue = [-1.0, -0.5, 0.0]
            anim.toValue = [1.0, 1.5, 2.0]
            anim.duration = 1.2
            anim.repeatCount = .infinity
            shimmer.add(anim, forKey: "skeleton.shimmer")
        }
    }

    private func stopShimmer() {
        shimmerLayers.forEach { $0.removeAllAnimations(); $0.removeFromSuperlayer() }
        shimmerLayers.removeAll()
    }
}
