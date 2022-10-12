//
//  SearchTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 05/09/2022.
//

import UIKit


class SearchTVC: UITableViewCell {
    
    var didTapSearchButton: (()->Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    @IBAction func onBtnSearch(_ sender: Any) {
        self.didTapSearchButton?()
    }
}
