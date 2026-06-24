//
//  PremiumTextView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 19/06/26.
//

import UIKit

final class PremiumTextView: UIView, UITextViewDelegate {

    private let cardView = GradientBorderCardView()

    let textView = UITextView()

    private let placeholderLabel = UILabel()

    var placeholder = "" {
        didSet {
            placeholderLabel.text = placeholder
        }
    }

    var text: String {
        get { textView.text }
        set {
            textView.text = newValue
            placeholderLabel.isHidden = !newValue.isEmpty
        }
    }
    
    var viewCornerRadius: CGFloat = 14 {
        didSet {
            cardView.glassCornerRadius = viewCornerRadius
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        cardView.glassCornerRadius = viewCornerRadius
    }

    private func setupUI() {

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.fillColor = UIColor.white.withAlphaComponent(0.05).cgColor
        cardView.showsBlur = true
        cardView.blurAlpha = 0.55
        cardView.thinBorder = true
        addSubview(cardView)

        textView.delegate = self
        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.font = Constant.Font.geistRegular(size: 15)
        textView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(textView)

        placeholderLabel.font = Constant.Font.geistRegular(size: 15)
        placeholderLabel.textColor = UIColor.white.withAlphaComponent(0.45)
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(placeholderLabel)

        NSLayoutConstraint.activate([

            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),

            textView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            textView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            textView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            textView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),

            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 6),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 5)
        ])
    }

    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}
