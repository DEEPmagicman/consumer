//
//  LegacySwitchControl.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 22/05/26.
//

import UIKit

final class LegacySwitchControl: UIControl {

    private let trackView = UIView()
    private let thumbView = UIView()

    private var thumbLeadingConstraint: NSLayoutConstraint!

    var isOn: Bool = false {
        didSet {
            updateState(animated: true)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = true

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 50),
            heightAnchor.constraint(equalToConstant: 30)
        ])

        trackView.isUserInteractionEnabled = false
        trackView.layer.cornerRadius = 15
        trackView.layer.cornerCurve = .continuous
        trackView.clipsToBounds = true
        trackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(trackView)

        thumbView.isUserInteractionEnabled = false
        thumbView.layer.cornerRadius = 12
        thumbView.layer.cornerCurve = .continuous
        thumbView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(thumbView)

        thumbLeadingConstraint = thumbView.leadingAnchor.constraint(
            equalTo: leadingAnchor,
            constant: 3
        )

        NSLayoutConstraint.activate([
            trackView.topAnchor.constraint(equalTo: topAnchor),
            trackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            trackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            thumbView.widthAnchor.constraint(equalToConstant: 24),
            thumbView.heightAnchor.constraint(equalToConstant: 24),
            thumbView.centerYAnchor.constraint(equalTo: centerYAnchor),
            thumbLeadingConstraint
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        addGestureRecognizer(tap)

        updateState(animated: false)
    }

    @objc private func onTap() {
        isOn.toggle()
        AppHaptic.selectionChanged()
        sendActions(for: .valueChanged)
    }

    private func updateState(animated: Bool) {
        thumbLeadingConstraint.constant = isOn ? 23 : 3

        let changes = {
            self.trackView.backgroundColor = self.isOn
                ? AppColor.primaryWhiteColor
                : AppColor.primaryWhiteColor.withAlphaComponent(0.25)

            self.thumbView.backgroundColor = self.isOn
                ? AppColor.primaryColor
                : AppColor.primaryWhiteColor

            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(
                withDuration: 0.22,
                delay: 0,
                usingSpringWithDamping: 0.82,
                initialSpringVelocity: 0.5,
                options: [.curveEaseOut, .allowUserInteraction],
                animations: changes
            )
        } else {
            changes()
        }
    }
}
