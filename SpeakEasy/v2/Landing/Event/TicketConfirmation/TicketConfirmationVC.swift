//
//  TicketConfirmationVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 09/02/26.
//

import UIKit

class TicketConfirmationVC: UIViewController {
    
    
    @IBOutlet weak var venueLogoImg: UIImageView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var venueName2: UILabel!
    @IBOutlet weak var dateandtimeLbl: UILabel!
    @IBOutlet weak var eventTitleLbl: UILabel!
    @IBOutlet weak var noteView: UILabel!
    @IBOutlet weak var eventImgView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func onClickViewtTicket(_ sender: Any) {
        
    }
    
    
    @IBAction func onClickCloseBtn(_ sender: Any) {
        self.dismiss(animated: false)
    }
    
}
