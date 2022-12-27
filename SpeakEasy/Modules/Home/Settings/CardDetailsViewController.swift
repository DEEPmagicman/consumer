//
//  CardDetailsViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 27/12/22.
//

import UIKit

class CardDetailsViewController: UIViewController {

    @IBOutlet weak var defaultBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        defaultBtn.setImage(Constant.Icon.defaultIcon, for: .normal)
        defaultBtn.setImage(Constant.Icon.check, for: .selected)
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction func onClickDelete(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction func onClickDefault(_ sender: UIButton) {
        defaultBtn.isSelected.toggle()
    }
    
}
