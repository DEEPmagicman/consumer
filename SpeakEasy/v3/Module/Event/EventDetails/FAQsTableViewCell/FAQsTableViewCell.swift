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

    var onToggle: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        ansLbl.numberOfLines = 0
        ansView.isHidden = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onToggle = nil
    }

    func configure(title: String, content: String, isExpanded: Bool) {
        questionLbl.text = title
        ansLbl.text = content

        ansLbl.isHidden = !isExpanded
        ansView.isHidden = !isExpanded

        dropDowenBtn.transform = isExpanded
            ? CGAffineTransform(rotationAngle: .pi/2)
            : .identity
    }

    @IBAction func onClickQuestionView(_ sender: Any) {
        onToggle?()
    }
}
