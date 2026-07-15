//
//  PaginationShimmerFooterView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 28/05/26.
//

import UIKit

final class PaginationShimmerFooterView:
UICollectionReusableView {

    private var leftCard: OrderCardShimmerContentView?
    private var rightCard: OrderCardShimmerContentView?
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

    func releaseResources() {
        leftCard?.releaseResources()
        rightCard?.releaseResources()
        NSLayoutConstraint.deactivate(shimmerConstraints)
        shimmerConstraints.removeAll()
        leftCard?.removeFromSuperview()
        rightCard?.removeFromSuperview()
        leftCard = nil
        rightCard = nil
    }

    private func updateShimmerState() {
        guard window != nil,
              !isHidden else {
            releaseResources()
            return
        }

        let cards = ensureCards()
        cards.left.setShimmeringEnabled(true)
        cards.right.setShimmeringEnabled(true)
    }

    private func ensureCards() -> (
        left: OrderCardShimmerContentView,
        right: OrderCardShimmerContentView
    ) {
        if let leftCard,
           let rightCard {
            return (leftCard, rightCard)
        }

        releaseResources()

        let leftCard = OrderCardShimmerContentView()
        let rightCard = OrderCardShimmerContentView()

        [
            leftCard,
            rightCard
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        shimmerConstraints = [
            leftCard.topAnchor.constraint(
                equalTo: topAnchor
            ),
            leftCard.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 24
            ),
            rightCard.topAnchor.constraint(
                equalTo: topAnchor,
                constant: 40
            ),
            rightCard.leadingAnchor.constraint(
                equalTo: leftCard.trailingAnchor,
                constant: 14
            ),
            rightCard.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -24
            ),
            rightCard.widthAnchor.constraint(
                equalTo: leftCard.widthAnchor
            ),
            rightCard.bottomAnchor.constraint(
                equalTo: bottomAnchor
            )
        ]
        NSLayoutConstraint.activate(shimmerConstraints)

        self.leftCard = leftCard
        self.rightCard = rightCard
        return (leftCard, rightCard)
    }
}
