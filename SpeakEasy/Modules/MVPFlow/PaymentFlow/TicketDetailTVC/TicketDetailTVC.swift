//
//  TicketDetailTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 06/04/23.
//

import UIKit

final class TicketDetailTVC: UITableViewCell {
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var subTitleLbl: UILabel!
    @IBOutlet weak var quantityLbl: UILabel!
    @IBOutlet weak var checkInProgressBarView: UIView!
    @IBOutlet weak var checkInProgress: UIProgressView!
    @IBOutlet weak var checkInCount: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
