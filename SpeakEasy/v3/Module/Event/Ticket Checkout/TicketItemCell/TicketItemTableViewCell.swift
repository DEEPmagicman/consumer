//
//  TicketItemTableViewCell.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 13/02/26.
//

import UIKit

class TicketItemTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var amountLbl: UILabel!
    @IBOutlet weak var titleTopConstraint: NSLayoutConstraint!

    private let infoButton = UIButton(type: .system)
    private var infoButtonWidthConstraint: NSLayoutConstraint?
    private var infoText = ""

    override func awakeFromNib() {
        super.awakeFromNib()
        setupInfoButton()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        configure(title: "", amount: "", infoText: nil)
    }

    func configure(title: String, amount: String, infoText: String? = nil) {
        titleLbl.text = title
        amountLbl.text = amount

        self.infoText = infoText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let hasInfo = !self.infoText.isEmpty
        infoButton.isHidden = !hasInfo
        infoButtonWidthConstraint?.constant = hasInfo ? 18 : 0
    }

    private func setupInfoButton() {
        guard let container = titleLbl.superview else { return }

        titleLbl.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        infoButton.setImage(UIImage(systemName: "info.circle"), for: .normal)
        infoButton.tintColor = UIColor.white.withAlphaComponent(0.85)
        infoButton.isHidden = true
        infoButton.translatesAutoresizingMaskIntoConstraints = false
        infoButton.addTarget(self, action: #selector(onInfoTap), for: .touchUpInside)
        container.addSubview(infoButton)

        let width = infoButton.widthAnchor.constraint(equalToConstant: 0)
        infoButtonWidthConstraint = width

        NSLayoutConstraint.activate([
            infoButton.leadingAnchor.constraint(equalTo: titleLbl.trailingAnchor, constant: 6),
            infoButton.centerYAnchor.constraint(equalTo: titleLbl.centerYAnchor),
            width,
            infoButton.heightAnchor.constraint(equalToConstant: 18),
            infoButton.trailingAnchor.constraint(lessThanOrEqualTo: amountLbl.leadingAnchor, constant: -8)
        ])
    }

    @objc private func onInfoTap() {
        guard !infoText.isEmpty else { return }
        Alert.showToast(infoText)
    }
    
}
