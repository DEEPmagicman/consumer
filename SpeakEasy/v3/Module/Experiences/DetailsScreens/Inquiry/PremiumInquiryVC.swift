//
//  PremiumInquiryVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 18/06/26.
//

import UIKit

final class PremiumInquiryVC: UIViewController {

    // MARK: Views

    private let scrollView = UIScrollView()

    private let contentView = UIView()
    
    var event: Event?

    var seatingAreas: [SeatingArea] = [] {

        didSet {

//            reloadUI()
        }
    }

    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
}

private extension PremiumInquiryVC {

    func setupUI() {

        view.backgroundColor = .clear

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false

        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .clear

        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),

            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            contentView.heightAnchor.constraint(
                greaterThanOrEqualTo: scrollView.heightAnchor
            )
        ])
    }
}
