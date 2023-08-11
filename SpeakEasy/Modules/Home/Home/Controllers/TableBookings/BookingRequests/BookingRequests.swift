//
//  BookingRequests.swift
//  SpeakEasy-Consumer
//
//  Created by M.Usman Bin Rehan on 06/09/2022.
//

import UIKit

class BookingRequests: BaseController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setData()
    }
    @IBOutlet weak var imgBrandLogo: UIImageView!
    @IBAction func onBtnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true
        )
    }
    
    @IBAction func onBtnBottleMenu(_ sender: UIButtonDeviceClass) {
        Utility.main.topViewController()?.navigationController?.pushViewController(BottleMenu(), animated: true)
    }
    @IBAction func onBtnProceedToInvites(_ sender: UIButtonDeviceClass) {
        Utility.main.topViewController()?.navigationController?.pushViewController(InviteFriends(), animated: true)
    }
    
    @IBAction func onTFSpend(_ sender: UITextFieldDeviceClass) {
        let inputText = (sender.text ?? "").replacingLastOccurrenceOfString(Constants.currency, with: "")
        sender.text = "\(Constants.currency)\(inputText)"

    }
    private func setData(){
        self.imgBrandLogo.image = VenueDetails.hotVenuesData?.imgBrandLogo
    }
}
extension BookingRequests: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
            let allowedCharacterSet = CharacterSet.init(charactersIn: "0123456789")
            let inputText = (textField.text ?? "").replacingLastOccurrenceOfString(Constants.currency, with: "")
            
        if !(inputText+string).validateDouble {
                return false
            }
            
            let textCharacterSet = CharacterSet.init(charactersIn: inputText + string)
            if !allowedCharacterSet.isSuperset(of: textCharacterSet) {
                return false
            }
        return true
    }
}
