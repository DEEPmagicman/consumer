//
//  CostSplitSelectionTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 9/12/22.
//

import UIKit

class CostSplitSelectionTVC: UITableViewCell {
    
    var didTapCodeSplitOptions: ((Int)->Void)?
    
    @IBOutlet weak var imgItsOnMe: UIImageView!
    @IBOutlet weak var imgSplitEquality: UIImageView!
    @IBOutlet weak var imgCustomSplit: UIImageView!
    
    @IBAction func onBtnCostSplitOtion(_ sender: UIButton) {
        self.setData(tag: sender.tag)
        self.didTapCodeSplitOptions?(sender.tag)
    }
    
    public func setData(tag: Int){
        switch tag {
        case 1:
            imgItsOnMe.image = UIImage(named: "check")
            imgSplitEquality.image = UIImage(named: "uncheck")
            imgCustomSplit.image = UIImage(named: "uncheck")
        case 2:
            imgItsOnMe.image = UIImage(named: "uncheck")
            imgSplitEquality.image = UIImage(named: "check")
            imgCustomSplit.image = UIImage(named: "uncheck")
        default:
            imgItsOnMe.image = UIImage(named: "uncheck")
            imgSplitEquality.image = UIImage(named: "uncheck")
            imgCustomSplit.image = UIImage(named: "check")
        }
    }
}
