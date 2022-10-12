//
//  HeaderViewCustom.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 8/30/22.
//

import Foundation
import UIKit

class HeaderViewCustom: UIView {
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "HeaderViewCustom", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }   
}
