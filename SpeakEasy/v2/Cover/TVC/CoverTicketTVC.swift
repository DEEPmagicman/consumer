//
//  CoverTicketTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 20/03/26.
//

import UIKit

final class CoverTicketTVC: UITableViewCell {

    @IBOutlet weak var minusBtnView: UIView!
    @IBOutlet weak var ticketCountView: UIView!
    @IBOutlet weak var plusBtnView: UIView!
    @IBOutlet weak var minusBtn: UIButton!
    @IBOutlet weak var ticketCount: UILabel!
    @IBOutlet weak var plusBtn: UIButton!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var descLbl: UILabel!
    @IBOutlet weak var priceLbl: UILabel!
    @IBOutlet weak var extraFeesLbl: UILabel!
    @IBOutlet weak var viewMoreBtnView: UIView!
    @IBOutlet weak var viewMoreBtn: UIButton!

    private let collapsedLines = 2
    private var isExpanded = false

    var onDescriptionToggle: (() -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()
        isExpanded = false
        descLbl.text = nil
        descLbl.numberOfLines = collapsedLines
        viewMoreBtnView.isHidden = true
        viewMoreBtn.setTitle("View More", for: .normal)
        onDescriptionToggle = nil
    }

    func configure(description: String?, isExpanded: Bool) {
        self.isExpanded = isExpanded

        let text = description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !text.isEmpty else {
            descLbl.isHidden = true
            viewMoreBtnView.isHidden = true
            return
        }

        descLbl.isHidden = false
        descLbl.text = text
        descLbl.numberOfLines = isExpanded ? 0 : collapsedLines
        viewMoreBtn.setTitle(isExpanded ? "View Less" : "View More", for: .normal)

        checkIfNeedsExpansion()
    }

    private func checkIfNeedsExpansion() {
        layoutIfNeeded()

        let fullHeight = descLbl.sizeThatFits(
            CGSize(width: descLbl.frame.width,
                   height: CGFloat.greatestFiniteMagnitude)
        ).height

        let collapsedHeight = descLbl.font.lineHeight * CGFloat(collapsedLines)

        if fullHeight > collapsedHeight {
            viewMoreBtnView.isHidden = false
        } else {
            viewMoreBtnView.isHidden = true
            descLbl.numberOfLines = 0
        }
    }

    @IBAction func onClickViewMoreBtn(_ sender: Any) {
        isExpanded.toggle()

        descLbl.numberOfLines = isExpanded ? 0 : collapsedLines
        viewMoreBtn.setTitle(isExpanded ? "View Less" : "View More", for: .normal)

        onDescriptionToggle?()
    }
    
}
