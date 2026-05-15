//
//  DateSelectionCVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 24/12/25.
//

import UIKit

final class DateSelectionCVC: UICollectionViewCell {

    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var dateLbl: UILabel!

    func configure(
        with date: String,
        isSelected: Bool
    ) {

        dateLbl.text = date

        UIView.animate(withDuration: 0.2) {

            self.bgView.backgroundColor = isSelected
            ? .white
            : UIColor.white.withAlphaComponent(0.09)

            self.dateLbl.textColor = isSelected
            ? .black
            : .white
        }
    }
}
