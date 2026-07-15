//
//  OrderCardShimmerContentView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 28/05/26.
//

import UIKit

final class OrderCardShimmerContentView:
    UIView {
    
    private let imageView =
    ShimmerViewV3()
    
    private let titleView =
    ShimmerViewV3()
    
    private let venueView =
    ShimmerViewV3()
    
    private let dateView =
    ShimmerViewV3()

    private var shimmerViews: [ShimmerViewV3] {
        [
            imageView,
            titleView,
            venueView,
            dateView
        ]
    }
    
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
    
    private func setupUI() {
        
        backgroundColor = .clear
        
        shimmerViews.forEach {
            
            $0.translatesAutoresizingMaskIntoConstraints =
            false
            
            addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            
            imageView.topAnchor.constraint(
                equalTo: topAnchor
            ),
            
            imageView.leadingAnchor.constraint(
                equalTo: leadingAnchor
            ),
            
            imageView.trailingAnchor.constraint(
                equalTo: trailingAnchor
            ),
            
            imageView.heightAnchor.constraint(
                equalTo: imageView.widthAnchor,
                multiplier: 1.2
            ),
            
            titleView.topAnchor.constraint(
                equalTo: imageView.bottomAnchor,
                constant: 16
            ),
            
            titleView.leadingAnchor.constraint(
                equalTo: leadingAnchor
            ),
            
            titleView.widthAnchor.constraint(
                equalTo: widthAnchor,
                multiplier: 0.82
            ),
            
            titleView.heightAnchor.constraint(
                equalToConstant: 18
            ),
            
            venueView.topAnchor.constraint(
                equalTo: titleView.bottomAnchor,
                constant: 10
            ),
            
            venueView.leadingAnchor.constraint(
                equalTo: leadingAnchor
            ),
            
            venueView.widthAnchor.constraint(
                equalTo: widthAnchor,
                multiplier: 0.55
            ),
            
            venueView.heightAnchor.constraint(
                equalToConstant: 15
            ),
            
            dateView.topAnchor.constraint(
                equalTo: venueView.bottomAnchor,
                constant: 12
            ),
            
            dateView.leadingAnchor.constraint(
                equalTo: leadingAnchor
            ),
            
            dateView.widthAnchor.constraint(
                equalTo: widthAnchor,
                multiplier: 0.42
            ),
            
            dateView.heightAnchor.constraint(
                equalToConstant: 14
            ),
            
            dateView.bottomAnchor.constraint(
                equalTo: bottomAnchor
            )
        ])
        startShimmering()
    }
    
    private func startShimmering() {
        shimmerViews.forEach { $0.startShimmer() }
    }
    
    private func stopShimmering() {
        shimmerViews.forEach { $0.stopShimmer() }
    }

    func setShimmeringEnabled(_ isEnabled: Bool) {
        if isEnabled {
            startShimmering()
        } else {
            stopShimmering()
        }
    }

    func releaseResources() {
        shimmerViews.forEach { $0.releaseResources() }
        layer.removeAllAnimations()
    }

    override var isHidden: Bool {
        didSet {
            setShimmeringEnabled(!isHidden && window != nil)
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        setShimmeringEnabled(window != nil && !isHidden)
    }
    
    override func willMove(
        toWindow newWindow: UIWindow?
    ) {
        
        super.willMove(
            toWindow: newWindow
        )
        
        if newWindow == nil {
            
            releaseResources()
            
        } else {
            
            startShimmering()
        }
    }
}
