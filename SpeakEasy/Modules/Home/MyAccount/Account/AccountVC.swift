//
//  AccountVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 07/04/23.
//

import UIKit

final class AccountVC: UIViewController {

    @IBOutlet private weak var profileImg: UIImageView!
    @IBOutlet private weak var nameLbl: UILabel!
    @IBOutlet private weak var listTableView: UITableView!
    @IBOutlet private weak var listHeight: NSLayoutConstraint!
    @IBOutlet private weak var confirmEmailLbl: UILabel!

    private var listHeightObservation: NSKeyValueObservation?
    private var onBoardingPresenter = OnBoardingPresenter()

    override func viewDidLoad() {
        super.viewDidLoad()
        displayData()
        let gesture = UITapGestureRecognizer(target: self, action: #selector(onClickAddPhoto))
        profileImg.isUserInteractionEnabled = true
        profileImg.addGestureRecognizer(gesture)
        listTableView.register(UINib(nibName: "TitleHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "TitleHeader")
        listTableView.register(UINib(nibName: "DetailTVC", bundle: nil), forCellReuseIdentifier: "DetailTVC")
        listHeightObservation = listTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.listHeight.constant = self.listTableView.contentSize.height
            self.listTableView.layoutIfNeeded()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(onClickConfirmEmail))
        confirmEmailLbl.isUserInteractionEnabled = true
        confirmEmailLbl.addGestureRecognizer(tap)
        listTableView.setupPadding()
        listTableView.groupStyleSpacing()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        displayData()
    }
    
    private func displayData() {
        profileImg.sd_setImage(with: URL(string: UserDefault.shared.user?.image.key ?? ""), placeholderImage: Constant.Icon.uploadImage) { [weak self] _, err, _, _ in
            self?.profileImg.borderWidth = err == nil ? 2 : 0
        }
        nameLbl.text = "\(UserDefault.shared.user?.firstName ?? "") \(UserDefault.shared.user?.lastName ?? "")"
    }
    
    @objc private func onClickAddPhoto() {
        Navigate.to.showImagePickerController(self, sourceType: .photoLibrary)
    }
    
    @objc private func onClickConfirmEmail() {
        Navigate.to.presentCommentDoneBottomSheet(self)
    }
    
    private func uploadProfileImg() {
        onBoardingPresenter.uploadPhotoApi(image: profileImg.image ?? UIImage()) { [weak self] imgUrl ,isSuccess in
            guard let self = self else {
                Loader.hide()
                return
            }
            if isSuccess {
                let imgDetail = ImageDetail(key: imgUrl, name:"\(UserDefault.shared.user?.phone ?? "")", description: "profile picture")
                self.onBoardingPresenter.editUserProfileApi(image: imgDetail) { isSuccess, errorMsg  in
                    if isSuccess {
                        UserDefault.shared.user?.image = imgDetail
                        Loader.hide()
                    } else {
                        if errorMsg != nil {
                            Alert.showAlertSheet(style: .alert, title: errorMsg, message: "")
                        } else {
                            Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                        }
                        Loader.hide()
                    }
                }
            } else {
                Alert.showAlertSheet(style: .alert, title: "image not upload", message: "")
                Loader.hide()
            }
        }
    }
    
    @IBAction func onClickShare(_ sender: Any) {
        let msgText = """
 Download Speakeasy on the Apple App Store to stay updated on covers and wait times at your favorite venues.

 Link to App: https://apps.apple.com/us/app/speakeasy-go/id1642351956
 """
         Utility.main.shareSocialWith(text: msgText)
    }

    @IBAction func onBtnSetting(_ sender: UIButton) {
        Navigate.to.settingsVc(self)
    }
}

extension AccountVC: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        3
    }
            
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailTVC", for: indexPath) as! DetailTVC
        cell.priceLbl.text = "TAO Nightclub, Chicago"
        cell.priceLbl.textColor = Constant.Color.codea1Color
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        72
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "TitleHeader") as? TitleHeader
        if section == 0 {
            header?.titleLbl.text = "Your Tickets"
        } else {
            header?.titleLbl.text = "Recommended"
        }
        return header
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            // TODO: navigate with actual data
            Navigate.to.QRCode(self, venueName: "LIQR Box Chicago", bookingId: "hello", venueAttachment: "prod/p-1678166121050-0hkR.png", venueLogo: "prod/l-1678106876023-Z3iH.png", selectedTickets: [])
        case 1:
            // TODO: navigate to recommended event
            break
        default:
            break
        }
    }
}

extension AccountVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            profileImg.image = editedImage
            
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            profileImg.image = originalImage
        }
        picker.dismiss(animated: true, completion: nil)
        uploadProfileImg()
    }
}

extension AccountVC: QRCodeVCNavigationDelegate {
    func navigateToEventDetail(eventId: String) {
        Navigate.to.eventDetail(self, eventId: eventId, venueDetail: nil, event: nil)
    }
}
