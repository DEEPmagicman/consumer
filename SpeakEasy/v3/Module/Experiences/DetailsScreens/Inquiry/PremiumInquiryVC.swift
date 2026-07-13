//
//  PremiumInquiryVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 18/06/26.
//

import UIKit

final class PremiumInquiryVC: UIViewController {

    // MARK: - Views

    private let scrollView = UIScrollView()

    private let contentView = UIView()

    private let shimmerView = PremiumInquiryShimmerView()

    private let cardView = PremiumInquiryCardView()

    private let successView = PremiumInquirySuccessView()
    // MARK: - Data

    var event: Event?

    var seatingAreas: [SeatingArea] = [] {
        didSet {
            configureDefaultValues()
        }
    }

    // MARK: - State

    private var isLoading = true

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()

        showLoading()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in

            self?.hideLoading()
        }
    }
}

// MARK: - UI

private extension PremiumInquiryVC {

    func setupUI() {

        view.backgroundColor = .clear

        setupScrollView()

        setupShimmer()

        setupCard()

        setupConstraints()
        
        setupSuccessView()
    }

    func setupScrollView() {

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.keyboardDismissMode = .interactive
        scrollView.showsVerticalScrollIndicator = false

        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .clear

        scrollView.addSubview(contentView)
    }

    func setupShimmer() {

        shimmerView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(shimmerView)
    }

    func setupCard() {

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.isHidden = true

        cardView.onRequestSuccess = { [weak self] in

            self?.showSuccess()
        }
        
        contentView.addSubview(cardView)
    }
}

// MARK: - Constraints

private extension PremiumInquiryVC {

    func setupConstraints() {

        NSLayoutConstraint.activate([

            // Scroll

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Content

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            // Shimmer

            shimmerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            shimmerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            shimmerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // Card

            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}

// MARK: - Loading

private extension PremiumInquiryVC {

    func showLoading() {

        isLoading = true

        shimmerView.isHidden = false

        cardView.isHidden = true
    }

    func hideLoading() {

        isLoading = false

        shimmerView.isHidden = true

        cardView.isHidden = false

        configureDefaultValues()
    }
}

// MARK: - Configure

private extension PremiumInquiryVC {

    func configureDefaultValues() {

        guard !isLoading else { return }

        cardView.event = event

        cardView.seatingAreas = seatingAreas

        cardView.configure()
    }
}

private extension PremiumInquiryVC {

    func setupSuccessView() {

        successView.translatesAutoresizingMaskIntoConstraints = false
        successView.isHidden = true

        contentView.addSubview(successView)

        NSLayoutConstraint.activate([

            successView.topAnchor.constraint(equalTo: contentView.topAnchor),

            successView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),

            successView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            successView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}

private extension PremiumInquiryVC {

    func showSuccess() {

        UIView.transition(
            with: contentView,
            duration: 0.25,
            options: .transitionCrossDissolve
        ) {

            self.cardView.isHidden = true

            self.successView.isHidden = false
        }
    }
}
