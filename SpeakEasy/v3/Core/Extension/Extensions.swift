//
//  File.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 09/06/26.
//

import UIKit

extension UIViewController {

    func presentPremium(
        _ viewController: UIViewController
    ) {

        viewController.modalPresentationStyle = .overFullScreen

        let transition = CATransition()
        transition.duration = 0.42
        transition.type = .moveIn
        transition.subtype = .fromTop
        transition.timingFunction = CAMediaTimingFunction(
            name: .easeInEaseOut
        )

        view.window?.layer.add(
            transition,
            forKey: kCATransition
        )

        present(
            viewController,
            animated: false
        )
    }

    func dismissPremium() {

        let transition = CATransition()
        transition.duration = 0.35
        transition.type = .reveal
        transition.subtype = .fromBottom
        transition.timingFunction = CAMediaTimingFunction(
            name: .easeInEaseOut
        )

        view.window?.layer.add(
            transition,
            forKey: kCATransition
        )

        dismiss(animated: false)
    }
}
