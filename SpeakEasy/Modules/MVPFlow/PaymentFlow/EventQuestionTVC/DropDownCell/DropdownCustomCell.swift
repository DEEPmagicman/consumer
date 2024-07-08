//
//  DropdownCustomCell.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 06/07/24.
//

import UIKit
//import DropDown

final class DropdownCustomCell: DropDownCell {
    
    @IBOutlet weak var checkBoxBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        checkBoxBtn.setImage(CommonConstant.Icon.checkBoxEmpty, for: .normal)
        checkBoxBtn.setImage(CommonConstant.Icon.checkBoxFull, for: .selected)
    }
}
