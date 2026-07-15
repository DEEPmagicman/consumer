//
//  OrderCardShimmerCell.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 28/05/26.
//

import UIKit

final class OrderCardShimmerCell:
UICollectionViewCell {
    
    private var shimmerView: OrderCardShimmerContentView?
    private var shimmerConstraints: [NSLayoutConstraint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    deinit {
        releaseResources()
    }

    override var isHidden: Bool {
        didSet {
            updateShimmerState()
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateShimmerState()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        releaseResources()
        updateShimmerState()
    }

    private func setupUI() {

        backgroundColor = .clear
    }

    private func updateShimmerState() {
        guard window != nil,
              !isHidden else {
            releaseResources()
            return
        }

        ensureShimmerView().setShimmeringEnabled(true)
    }

    private func ensureShimmerView() -> OrderCardShimmerContentView {
        if let shimmerView {
            return shimmerView
        }

        let shimmerView = OrderCardShimmerContentView()
        shimmerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(shimmerView)

        shimmerConstraints = [
            shimmerView.topAnchor.constraint(
                equalTo: contentView.topAnchor
            ),
            shimmerView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor
            ),
            shimmerView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor
            ),
            shimmerView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor
            )
        ]
        NSLayoutConstraint.activate(shimmerConstraints)

        self.shimmerView = shimmerView
        return shimmerView
    }

    func releaseResources() {
        shimmerView?.releaseResources()
        NSLayoutConstraint.deactivate(shimmerConstraints)
        shimmerConstraints.removeAll()
        shimmerView?.removeFromSuperview()
        shimmerView = nil
    }
}
