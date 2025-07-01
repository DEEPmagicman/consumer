//
//  BarTabConfirmationVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 27/06/25.
//

import UIKit

final class BarTabConfirmationVC: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var qrImage: UIImageView!
    @IBOutlet weak var ticketCodeView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(qrImageTapped))
        containerView.addGestureRecognizer(tapGesture)
    }
    
    @objc func qrImageTapped() {
        containerView.isUserInteractionEnabled = false
        flipView()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.flipView()
            self.containerView.isUserInteractionEnabled = true
        }
    }
    
    private func flipView() {
        UIView.transition(with: containerView, duration: 1, options: .transitionFlipFromRight, animations: {[weak self] in
            guard let self = self else { return }
            self.ticketCodeView.isHidden = !self.ticketCodeView.isHidden
            self.qrImage.isHidden = !self.qrImage.isHidden
        })
    }
}
