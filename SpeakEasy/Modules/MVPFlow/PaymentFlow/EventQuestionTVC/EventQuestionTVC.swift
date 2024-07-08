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
    
    private var dropDown = DropDown()
    
    var selectedAns = [String]()
    var options = ["!", "2", "3"]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        dropDownLayout(dropDown: dropDown)
    }
    
    @IBAction func onClickDropDown(_ sender: Any) {
        dropDown.show()
    }
    
    private func dropDownLayout(dropDown: DropDown) {
        dropDown.cellHeight = 37
        dropDown.selectionBackgroundColor = .clear
        DropDown.appearance().setupCornerRadius(10)
        dropDown.textColor = .white
        dropDown.backgroundColor = .gray
        dropDown.textFont = Fonts.poppinsRegular(15)
        
        dropDown.anchorView = dropDownBtn
        dropDown.direction = .bottom
        dropDown.bottomOffset = CGPoint(x: 0, y: dropDownBtn.bounds.height)
        
        dropDown.dataSource = options
        dropDown.width = dropDownBtn.bounds.width
        
        dropDown.cellNib = UINib(nibName: "DropdownCustomCell", bundle: nil)
        dropDown.customCellConfiguration = { [weak self] (index: Index, item: String, cell: DropDownCell) -> Void in
            guard let self = self, let cell = cell as? DropdownCustomCell else { 
                print("--return")
                return }
            if selectedAns.contains(options[index]) {
                cell.checkBoxBtn.isSelected = true
            } else {
                cell.checkBoxBtn.isSelected = false
            }
        }
        
        dropDown.selectionAction = { [weak self] (index, item) in
            guard let self = self else { return }
            
            if selectedAns.contains(item) {
                if let removeAtIndex = selectedAns.firstIndex(of: item) {
                    self.selectedAns.remove(at: removeAtIndex )
                }
            } else {
                self.selectedAns.append(item)
            }
            dropDown.reloadAllComponents()
        }
    }
}
