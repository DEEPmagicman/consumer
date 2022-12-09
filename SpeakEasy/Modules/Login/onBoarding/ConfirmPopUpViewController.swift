//
//  ConfirmPopUpViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 08/12/22.
//

protocol ConfirmPopUpDelegate {
    func confirmDetail()
}

import UIKit

class ConfirmPopUpViewController: UIViewController {

    @IBOutlet weak var confirmInFoLbl: UILabel!
    @IBOutlet weak var infoDetailLbl: UILabel!
    @IBOutlet weak var infoNoteLbl: UILabel!
    
    var confirmInfoText = ""
    var infoDetailtext = ""
    var infoNoteText = ""
    
    var confirmPopUpDelegate: ConfirmPopUpDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.confirmInFoLbl.text = confirmInfoText
        self.infoDetailLbl.text = infoDetailtext
        self.infoNoteLbl.text = infoNoteText
        view.backgroundColor = UIColor(white:0, alpha: 0.7)
    
    }
    
    @IBAction func onClickEdit(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onClickConfirm(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        self.confirmPopUpDelegate?.confirmDetail()
    }
    

}
