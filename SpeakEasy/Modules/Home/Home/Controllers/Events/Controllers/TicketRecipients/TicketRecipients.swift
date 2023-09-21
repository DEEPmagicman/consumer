//
//  TicketRecipients.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 03/09/2022.
//

import UIKit
import DropDown

class TicketRecipients: BaseController {
    
    @IBOutlet weak var lblCode: UILabelDeviceClass!
    @IBOutlet weak var lblCountry: UILabelDeviceClass!
    @IBOutlet weak var inviteFriendsCollectionView: UICollectionView!
    @IBOutlet weak var friendsCollectionView: UICollectionView!
    @IBOutlet weak var viewMale: UIView!
    @IBOutlet weak var viewCompletePurchase: UIView!
    @IBOutlet weak var lblGeneralAdmission: UILabelDeviceClass!
    @IBOutlet weak var lblPC: UILabelDeviceClass!
    @IBOutlet weak var lblGeneralAdmissionBottom: UILabelDeviceClass!
    @IBOutlet weak var lblPCBottom: UILabelDeviceClass!
    @IBOutlet weak var tfGender: UITextFieldDeviceClass!
    @IBOutlet weak var btnGender: UIButton!
    
    var ticketRecipients: TicketRecipientsType = .MaleGeneral
    
    var arrInviteFriends = [InviteFriendsModel(name: "Paul", img: "paul")]
    
    let genderDropDown = DropDown()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerCell()
        self.setUI()
    }
    
    @IBAction func onBtnGenerealAdmission(_ sender: UIButton) {
        
        switch self.ticketRecipients {
            
        case .MaleGeneral:
            let controller = TicketRecipients()
            controller.ticketRecipients = .FemaleGeneral
            self.navigationController?.pushViewController(controller, animated: true)
        case .FemaleGeneral:
            let controller = TicketRecipients()
            controller.ticketRecipients = .CompletePurchase
            self.navigationController?.pushViewController(controller, animated: true)
        case .CompletePurchase:
            break
        }
    }
    @IBAction func onBtnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func onBtnConfirmation(_ sender: UIButtonDeviceClass) {
        self.navigationController?.pushViewController(ViewEventTickets(), animated: true)
    }
    
    @IBAction func onBtnMyTicket(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }
    
    @IBAction func onBtnCode(_ sender: UIButton) {
//        let controller = MICountryPicker()
//        controller.delegate = self
//        controller.showCallingCodes = true
//        self.present(controller, animated: true, completion: nil)
    }
    @IBAction func onBtnGender(_ sender: UIButton) {
        self.setGenderDropDown(show: true)
    }
}

//MARK:- MICountryPickerDelegate
//extension TicketRecipients: MICountryPickerDelegate{
//    func countryPicker(_ picker: MICountryPicker, didSelectCountryWithName name: String, code: String) {
//        self.dismiss(animated: true, completion: nil)
//    }
//    func countryPicker(_ picker: MICountryPicker, didSelectCountryWithName name: String, code: String, dialCode: String) {
//        self.lblCountry.text = name
//        self.lblCode.text = dialCode
//    }
//}
//MARK: - Helper Methods
extension TicketRecipients {
    private func registerCell(){
        self.inviteFriendsCollectionView.register(UINib(nibName: "InviteFriendsCVC", bundle: nil), forCellWithReuseIdentifier: "InviteFriendsCVC")
        self.friendsCollectionView.register(UINib(nibName: "FriendsCVC", bundle: nil), forCellWithReuseIdentifier: "FriendsCVC")
    }
    
    private func setUI(){
        
        switch self.ticketRecipients {
            
        case .MaleGeneral:
            self.viewMale.isHidden = false
            self.viewCompletePurchase.isHidden = true
            self.lblGeneralAdmission.text = "Male General Admission-Tier1"
            self.lblPC.text = "1pc at $70 each"
            
            self.lblGeneralAdmissionBottom.text = "Male General Admission-Tier 2"
            self.lblPCBottom.text = "2pc"
            
        case .FemaleGeneral:
            self.viewMale.isHidden = false
            self.viewCompletePurchase.isHidden = true
            
            self.lblGeneralAdmission.text = "Female General Admission-Tier2"
            self.lblPC.text = "2pc at $70 each"
            self.lblGeneralAdmissionBottom.text = "Female General Admission"
            self.lblPCBottom.text = "3pc"
            
        case .CompletePurchase:
            self.viewMale.isHidden = true
            self.viewCompletePurchase.isHidden = false
            self.lblGeneralAdmission.text = "Female General Admission"
            self.lblPC.text = "3pc at $70 each"
        }
    }
    
    private func setGenderDropDown(show: Bool) {
        self.genderDropDown.dataSource = ["Male","Female","Other"]
        self.genderDropDown.anchorView = self.btnGender
        self.genderDropDown.bottomOffset = CGPoint(x: 0, y:(self.genderDropDown.anchorView?.plainView.bounds.height ?? 0.0))
        self.genderDropDown.cellHeight = self.btnGender.frame.height-10.0
        self.genderDropDown.backgroundColor = Global.APP_COLOR
        self.genderDropDown.textColor = .white
        self.genderDropDown.textFont = UIFont(name: "Poppins-SemiBold", size: 13.0) ?? UIFont.systemFont(ofSize:13.0)
        self.genderDropDown.selectionBackgroundColor = Global.APP_COLOR_GREY
        self.genderDropDown.width = self.btnGender.frame.width
        self.genderDropDown.dimmedBackgroundColor = UIColor(displayP3Red: 0/255, green: 0/255, blue: 0/255, alpha: 0.25)
        self.genderDropDown.show()
        self.genderDropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            self.tfGender.text = item
        }
    }
}

//MARK: - UICollectionViewDataSource
extension TicketRecipients: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case inviteFriendsCollectionView:
            return self.arrInviteFriends.count
        default:
            return 3
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case inviteFriendsCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "InviteFriendsCVC", for: indexPath) as! InviteFriendsCVC
            cell.btnDelete.tag = indexPath.item
            cell.btnDelete.addTarget(nil, action: #selector(self.onBtnDelete(_:)), for: .touchUpInside)
            return cell
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FriendsCVC", for: indexPath)
            return cell
        }
    }
    
    @objc func onBtnDelete(_ sender:UIButton) {
        self.arrInviteFriends.remove(at: sender.tag)
        self.inviteFriendsCollectionView.reloadData()
    }
}
//MARK: - UICollectionViewDelegateFlowLayout
extension TicketRecipients: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        switch collectionView {
        case inviteFriendsCollectionView:
            let width = collectionView.frame.width/5
            let height = 110.0
            let size = CGSize(width: width, height: height)
            return size
        default:
            let width = collectionView.frame.width/3
            let height = width
            let size = CGSize(width: width, height: height)
            return size
        }
    }
}
