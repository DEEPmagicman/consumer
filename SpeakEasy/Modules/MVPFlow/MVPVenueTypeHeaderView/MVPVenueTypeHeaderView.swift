//
//  MVPVenueTypeHeaderView.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 27/02/23.
//

import UIKit

class MVPVenueTypeHeaderView: UIView {
    
    @IBOutlet weak var openCloseLbl: UILabel!
    @IBOutlet weak var detailLbl: UILabel!
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "MVPVenueTypeHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }

}
