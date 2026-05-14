//
//  LocationUpdatePopupViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 14/05/26.
//

import Foundation
import UIKit

final class LocationUpdatePopupViewController: UIViewController {

    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = .black.withAlphaComponent(0.6)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let popup = LocationUpdatePopupView()

    var titleText: String = ""
    var subtitleText: String = ""
    var confirmTitle: String = "Confirm"
    var onConfirm: (() -> Void)?

    static func show(
        from presenter: UIViewController,
        title: String,
        subtitle: String,
        confirmTitle: String = "Confirm",
        onConfirm: @escaping () -> Void
    ) {
        let vc = LocationUpdatePopupViewController()
        vc.titleText    = title
        vc.subtitleText = subtitle
        vc.confirmTitle = confirmTitle
        vc.onConfirm    = onConfirm
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle   = .crossDissolve
        presenter.present(vc, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        view.addSubview(dimView)
        view.addSubview(popup)

        NSLayoutConstraint.activate([
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            popup.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            popup.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            popup.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        dimView.addGestureRecognizer(tap)

        popup.configure(
            title: titleText,
            subtitle: subtitleText,
            confirmTitle: confirmTitle
        ) { [weak self] in
            self?.dismiss(animated: true) { self?.onConfirm?() }
        }
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
}
