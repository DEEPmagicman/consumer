//
//  weekDaysView.swift
//  Cavalli
//
//  Created by Usman Bin Rehan on 4/9/18.
//  Copyright © 2018 Ingic. All rights reserved.
//

import UIKit

class WeekDays: UIView {

    class func instanceFromNib() -> UIView{
        return UINib(nibName: "WeekDays", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
}
