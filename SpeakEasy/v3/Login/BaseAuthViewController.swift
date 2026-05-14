//
//  BaseAuthViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 12/05/26.
//

import UIKit
import MHLoadingButton

class BaseAuthViewController: UIViewController {
    
    let cardView = GradientBorderCardView()
    let contentStack = UIStackView()
    
    private let screenGradient = CAGradientLayer()
    private var cardCenterYConstraint: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupCard()
        observeKeyboard()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        screenGradient.frame = view.bounds
        setupBackground()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupBackground() {
        view.applyScreenBgGradient()
    }
    
    private func setupCard() {
        cardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardView)
        
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 10
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(contentStack)
        
        cardCenterYConstraint = nil
        
        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            contentStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 30),
            contentStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
            contentStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),
            contentStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -30)
        ])
        
        animateBottomCardIn()
    }
    
    private func animateBottomCardIn() {
        cardView.alpha = 0
        cardView.transform = CGAffineTransform(translationX: 0, y: 80)
        
        UIView.animate(
            withDuration: 0.46,
            delay: 0,
            usingSpringWithDamping: 0.86,
            initialSpringVelocity: 0.7,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            self.cardView.alpha = 1
            self.cardView.transform = .identity
        }
    }
    
    private func observeKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }
        
        let keyboardHeight = frame.height
        cardView.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight + 20)
        
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        UIView.animate(withDuration: 0.25) {
            self.cardView.transform = .identity
        }
    }
}
