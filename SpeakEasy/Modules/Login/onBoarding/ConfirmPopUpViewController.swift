//
//  ConfirmPopUpViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 08/12/22.
//

protocol ConfirmPopUpDelegate {
    func confirmDetail()
    func cancelDetail()
}

import UIKit

class ConfirmPopUpViewController: UIViewController {

    @IBOutlet weak var confirmInFoLbl: UILabel!
    @IBOutlet weak var infoDetailLbl: UILabel!
    @IBOutlet weak var infoNoteLbl: UILabel!
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var confirmBtn: UIButton!
    
    var confirmInfoText = ""
    var infoDetailtext = ""
    var infoNoteText = ""
    var isPrivetOrPublic = false
    
    var confirmPopUpDelegate: ConfirmPopUpDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.confirmInFoLbl.text = confirmInfoText
        self.infoDetailLbl.text = infoDetailtext
        self.infoNoteLbl.text = infoNoteText
        view.backgroundColor = UIColor(white:0, alpha: 0.7)
        if isPrivetOrPublic {
            self.editBtn.setTitle("No", for: .normal)
            self.confirmBtn.setTitle("Yes", for: .normal)
        }
    
    }
    
    @IBAction func onClickEdit(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        self.confirmPopUpDelegate?.cancelDetail()
    }
    
    @IBAction func onClickConfirm(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        self.confirmPopUpDelegate?.confirmDetail()
    }
    

}
