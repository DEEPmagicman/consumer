//
//  CheckInBottomSheet.swift
//  SpeakEasy-Consumer
//
//  Created by Mac on 02/04/24.
//

import UIKit

final class CheckInBottomSheet: UIViewController {
    
    @IBOutlet weak var checkInBtn: UIButton!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    
    var ticketId = [String]()
    var bookingId = String()
    weak var delegate: DateSelectionDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loader.startAnimating()
        loader.isHidden = true
    }
    
    @IBAction func onClickCheckIn(_ sender: Any) {
        loader.isHidden = false
        checkInBtn.isHidden = true
        EventPresenter.eventTicketCheckIn(bookingId: bookingId, ticketIds: ticketId) { isSuccess, errMsg, checkInData in
            if isSuccess {
                self.delegate?.checkInStatusChange(checkInData: checkInData ?? [])
                self.dismiss(animated: true)
            } else {
                if errMsg != nil {
                    Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
                } else {
                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                }
            }
        }
    }
    
    @IBAction func onClickCancel(_ sender: Any) {
        self.dismiss(animated: true)
    }
}
