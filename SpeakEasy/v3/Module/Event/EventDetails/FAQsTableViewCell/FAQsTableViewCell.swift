//
//  FAQsTableViewCell.swift
//  eventDeatilModule
//
//  Created by MAC on 06/02/26.
//

import UIKit

class FAQsTableViewCell: UITableViewCell {

    @IBOutlet weak var questionLbl: UILabel!
    @IBOutlet weak var dropDowenBtn: UIImageView!
    @IBOutlet weak var ansLbl: UILabel!
    @IBOutlet weak var ansView: UIView!
    @IBOutlet weak var ansLblTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var ansLblBottomConstraint: NSLayoutConstraint!

    var onToggle: (() -> Void)?
    private let compactAnswerTopPadding: CGFloat = 8
    private let compactAnswerBottomPadding: CGFloat = 0

    override func awakeFromNib() {
        super.awakeFromNib()

        ansLbl.numberOfLines = 0
        ansView.isHidden = true
        dropDowenBtn.image = UIImage(named: "arrowTopIcon")?.withRenderingMode(.alwaysTemplate)
        dropDowenBtn.tintColor = .white
        dropDowenBtn.contentMode = .scaleAspectFit
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        setAnswerPadding(top: compactAnswerTopPadding, bottom: compactAnswerBottomPadding)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onToggle = nil
        dropDowenBtn.transform = CGAffineTransform(rotationAngle: .pi)
    }

    func configure(
        title: String,
        content: String,
        isExpanded: Bool,
        answerBottomPadding: CGFloat? = nil
    ) {
        questionLbl.text = title
        ansLbl.text = content

        ansLbl.isHidden = !isExpanded
        ansView.isHidden = !isExpanded
        setAnswerPadding(
            top: compactAnswerTopPadding,
            bottom: answerBottomPadding ?? compactAnswerBottomPadding
        )

        dropDowenBtn.transform = isExpanded
            ? .identity
            : CGAffineTransform(rotationAngle: .pi)
    }

    func setAnswerPadding(top: CGFloat, bottom: CGFloat) {
        ansLblTopConstraint.constant = top
        ansLblBottomConstraint.constant = bottom
    }

    @IBAction func onClickQuestionView(_ sender: Any) {
        onToggle?()
    }
}
