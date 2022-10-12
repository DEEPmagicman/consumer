//
//  ImportantDatesTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 29/08/2022.
//

import UIKit
import DropDown

class ImportantDatesTVC: UITableViewCell {

    @IBOutlet weak var lblTitle: UILabelDeviceClass!
    @IBOutlet weak var imgUser: UIImageView!
    @IBOutlet weak var lblMonth: UILabelDeviceClass!
    @IBOutlet weak var lblDay: UILabelDeviceClass!
    @IBOutlet weak var btnMonth: UIButton!
    @IBOutlet weak var btnDay: UIButton!
    @IBOutlet weak var imgDelete: UIImageView!
    
    let monthDropDown = DropDown()
    let dayDropDown = DropDown()
    
    func setData(data: ImportantDates) {
        
        self.lblTitle.text = data.title
        self.lblMonth.text = data.month
        self.lblDay.text = data.day
        self.imgUser.image = UIImage(named: data.leftImage)
        self.imgDelete.image = UIImage(named: data.rightImage ?? "")

        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func onBtnMonth(_ sender: UIButton) {
        self.setMonthDropDown(show: true)
    }
    
    @IBAction func onBtnDay(_ sender: UIButton) {
        self.setDayDropDown(show: true)
    }
}

//MARK: - Drop Down
extension ImportantDatesTVC {
    private func setMonthDropDown(show: Bool) {
        self.monthDropDown.dataSource = ["January","February","March","April","May","June","July","August","September","October","November","December"]
        self.monthDropDown.anchorView = self.btnMonth
        self.monthDropDown.bottomOffset = CGPoint(x: 0, y:(self.monthDropDown.anchorView?.plainView.bounds.height ?? 0.0))
        self.monthDropDown.cellHeight = self.btnMonth.frame.height-10.0
        self.monthDropDown.backgroundColor = Global.APP_COLOR
        self.monthDropDown.textColor = .white
        self.monthDropDown.textFont = UIFont(name: "Poppins-SemiBold", size: 13.0) ?? UIFont.systemFont(ofSize:13.0)
        self.monthDropDown.selectionBackgroundColor = Global.APP_COLOR_GREY
        self.monthDropDown.width = self.btnMonth.frame.width
        self.monthDropDown.dimmedBackgroundColor = UIColor(displayP3Red: 0/255, green: 0/255, blue: 0/255, alpha: 0.25)
        self.monthDropDown.show()
        self.monthDropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            self.lblMonth.text = item
        }
    }
    
    private func setDayDropDown(show: Bool) {
        self.dayDropDown.dataSource = ["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30"]
        self.dayDropDown.anchorView = self.btnDay
        self.dayDropDown.bottomOffset = CGPoint(x: 0, y:(self.dayDropDown.anchorView?.plainView.bounds.height ?? 0.0))
        self.dayDropDown.cellHeight = self.btnDay.frame.height-10.0
        self.dayDropDown.backgroundColor = Global.APP_COLOR
        self.dayDropDown.textColor = .white
        self.dayDropDown.textFont = UIFont(name: "Poppins-SemiBold", size: 13.0) ?? UIFont.systemFont(ofSize:13.0)
        self.dayDropDown.selectionBackgroundColor = Global.APP_COLOR_GREY
        self.dayDropDown.width = self.btnDay.frame.width
        self.dayDropDown.dimmedBackgroundColor = UIColor(displayP3Red: 0/255, green: 0/255, blue: 0/255, alpha: 0.25)
        self.dayDropDown.show()
        self.dayDropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            self.lblDay.text = item
        }
    }

}
