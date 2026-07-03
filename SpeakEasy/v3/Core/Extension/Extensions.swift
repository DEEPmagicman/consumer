//
//  File.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 09/06/26.
//

import UIKit

enum LoginRequiredCoordinator {

    static var isAuthenticated: Bool {
        UserDefault.shared.user != nil
    }

    static func presentLogin(
        from presenter: UIViewController,
        onSuccess: (() -> Void)? = nil
    ) {
        Navigate.to.openPhoneLoginPopup(presenter) {
            onSuccess?()
        }
    }

    static func perform(
        from presenter: UIViewController,
        action: @escaping () -> Void
    ) {
        guard isAuthenticated else {
            presentLogin(
                from: presenter,
                onSuccess: action
            )
            return
        }

        action()
    }
}

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
