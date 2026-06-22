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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        connectOverlayButtons(in: contentView)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onTap = nil
        webSiteTitleLbl.text = nil
        webSiteDiscriptionLbl.text = nil
        linkImageView.image = nil
    }

    func configure(
        with item: AdditionalButton,
        tintColor: UIColor
    ) {
        webSiteTitleLbl.text = item.title
        webSiteDiscriptionLbl.text = readableLink(from: item.link)
        webSiteDiscriptionLbl.isHidden =
        item.link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

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

    private func readableLink(from link: String) -> String {
        let trimmed = link.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let url = URL(string: normalizedLink(trimmed)),
              let host = url.host,
              !host.isEmpty else {
            return trimmed
        }

        return host.replacingOccurrences(of: "www.", with: "")
    }

    private func normalizedLink(_ link: String) -> String {
        guard !link.isEmpty else { return link }

        if link.lowercased().hasPrefix("http://") ||
            link.lowercased().hasPrefix("https://") {
            return link
        }

        return "https://\(link)"
    }

    @objc private func handleTap() {
        onTap?()
    }
}
