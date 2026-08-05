//
//  AdditionalButtonsTableViewCell.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 25/05/26.
//

import UIKit

class AdditionalButtonsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var webSiteTitleLbl: UILabel!
    @IBOutlet weak var webSiteDiscriptionLbl: UILabel!
    @IBOutlet weak var linkImageView: UIImageView!
    var onTap: (() -> Void)?

    private var cardView: UIView? {
        contentView.subviews.first?.subviews.first
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        connectOverlayButtons(in: contentView)
        webSiteDiscriptionLbl.isHidden = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onTap = nil
        webSiteTitleLbl.text = nil
        webSiteDiscriptionLbl.text = nil
        webSiteDiscriptionLbl.isHidden = true
        linkImageView.image = nil
    }

    func configure(
        with item: AdditionalButton,
        tintColor: UIColor
    ) {
        webSiteTitleLbl.text = item.title
        
        if let disc = item.name, !disc.isEmpty {
            webSiteDiscriptionLbl.text = disc
            webSiteDiscriptionLbl.isHidden = false
        } else {
            webSiteDiscriptionLbl.text = nil
            webSiteDiscriptionLbl.isHidden = true
        }
     
        cardView?.layer.borderWidth = 1
        cardView?.layer.borderColor = tintColor.cgColor

        let icon =
        UIImage(named: "ic-webLink") ??
        UIImage(named: "ic_link") ??
        UIImage(systemName: "link")

        linkImageView.image = icon?.withRenderingMode(.alwaysTemplate)
        linkImageView.tintColor = tintColor
        linkImageView.isHidden = icon == nil
    }

    private func connectOverlayButtons(in view: UIView) {
        for subview in view.subviews {
            if let button = subview as? UIButton {
                button.addTarget(
                    self,
                    action: #selector(handleTap),
                    for: .touchUpInside
                )
                button.isUserInteractionEnabled = true
            }

            connectOverlayButtons(in: subview)
        }
    }

    @objc private func handleTap() {
        onTap?()
    }
}
