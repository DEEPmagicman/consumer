//
//  DateSelectionCVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 24/12/25.
//

import UIKit

final class DateSelectionCVC: UICollectionViewCell {

    enum CellType {
        case date
        case filter
    }

    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottemConstraint: NSLayoutConstraint!
    

    func configure(
        with date: String,
        isSelected: Bool,
        cellType: CellType = .date
    ) {
        dateLbl.text = date

        switch cellType {
        case .date:
            leadingConstraint.constant = 30
            trailingConstraint.constant = 30
            topConstraint.constant = 6
            bottemConstraint.constant = 6
            dateLbl.font = Constant.Font.geistRegular(size: 12)

        case .filter:
            leadingConstraint.constant = 18
            trailingConstraint.constant = 18
            topConstraint.constant = 10
            bottemConstraint.constant = 10
            dateLbl.font = Constant.Font.geistRegular(size: 14)
        }

        UIView.animate(withDuration: 0.2) {

            self.bgView.backgroundColor = isSelected
                ? .white
                : UIColor.white.withAlphaComponent(0.09)

            self.dateLbl.textColor = isSelected
                ? .black
                : .white

            // Border only for filter type when not selected
            if cellType == .filter && !isSelected {
                self.bgView.layer.borderWidth = 1
                self.bgView.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
            } else {
                self.bgView.layer.borderWidth = 0
                self.bgView.layer.borderColor = UIColor.clear.cgColor
            }
        }
    }
}
