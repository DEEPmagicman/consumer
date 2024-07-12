//
//  EventQuestionTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 06/07/24.
//

import UIKit

final class EventQuestionTVC: UITableViewCell {
    
    @IBOutlet weak var dropDownBtn: UIButton!
    @IBOutlet weak var questionNameLbl: UILabel!
    @IBOutlet weak var textQuestionView: UITextField!
    @IBOutlet weak var checkBoxView: UIView!
    @IBOutlet weak var multiSelectView: UIView!
    @IBOutlet weak var multiSelectLbl: UILabel!
    @IBOutlet weak var checkBox: UIButton!
    @IBOutlet weak var checkBoxQuestionLbl: UILabel!
    @IBOutlet weak var questionView: UIView!
    
    var dropDown = DropDown()
    var questionType = String()
    var selectedAns = [String]()
    var options = [String]()
    var selectedIndex = Int()
    weak var delegate: DropDownDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        dropDownLayout(dropDown: dropDown)
        checkBox.setImage(CommonConstant.Icon.checkBoxEmpty, for: .normal)
        checkBox.setImage(CommonConstant.Icon.checkBoxFull, for: .selected)
        textQuestionView.addTarget(self, action: #selector(textValueChanged), for: .allEvents)
    }
    
    @objc func textValueChanged() {
        delegate?.textAns(ans: textQuestionView.text ?? "", index: selectedIndex)
    }
    
    @IBAction func onClickDropDown(_ sender: Any) {
        dropDown.dataSource = options
        dropDown.show()
    }
    
    private func dropDownLayout(dropDown: DropDown) {
        dropDown.cellHeight = 37
        dropDown.selectionBackgroundColor = .clear
        DropDown.appearance().setupCornerRadius(10)
        dropDown.textColor = .white
        dropDown.backgroundColor = .gray
        dropDown.textFont = Fonts.poppinsRegular(15)
        dropDown.tableView.bounces = false
        dropDown.anchorView = dropDownBtn
        dropDown.direction = .bottom
        dropDown.bottomOffset = CGPoint(x: 0, y: dropDownBtn.bounds.height)
        
        dropDown.width = dropDownBtn.bounds.width
        
        dropDown.cellNib = UINib(nibName: "DropdownCustomCell", bundle: nil)
        dropDown.customCellConfiguration = { [weak self] (index: Index, item: String, cell: DropDownCell) -> Void in
            guard let self = self, let cell = cell as? DropdownCustomCell else {
                return
            }
            if selectedAns.contains(options[index]) {
                cell.checkBoxBtn.isSelected = true
            } else {
                cell.checkBoxBtn.isSelected = false
            }
        }
        
        dropDown.selectionAction = { [weak self] (index, item) in
            guard let self = self else { return }
            if questionType == "SINGLE_SELECT" {
                selectedAns.removeAll()
            }
            if selectedAns.contains(item) {
                if let removeAtIndex = selectedAns.firstIndex(of: item) {
                    self.selectedAns.remove(at: removeAtIndex )
                }
            } else {
                self.selectedAns.append(item)
            }
            let joinedString = self.selectedAns.joined(separator: ", ")
            self.multiSelectLbl.text = joinedString
            if questionType == "SINGLE_SELECT" {
                self.delegate?.textAns(ans: selectedAns.first ?? "", index: selectedIndex)
                dropDown.hide()
            } else {
                self.delegate?.multipleAns(ans: selectedAns, index: selectedIndex)
                dropDown.reloadAllComponents()
            }
        }
    }
    
    @IBAction func onClickCheckBox(_ sender: Any) {
        checkBox.isSelected = !checkBox.isSelected
        delegate?.boolAns(ans: checkBox.isSelected, index: selectedIndex)
    }
}
