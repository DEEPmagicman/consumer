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
    @IBOutlet private weak var zeroCaseView: UIView!

    private var onBoardingPresenter = OnBoardingPresenter()
    private var bookings = [Booking]()
    private var recommended = [Event]()

    override func viewDidLoad() {
        super.viewDidLoad()
        displayData()
        let gesture = UITapGestureRecognizer(target: self, action: #selector(onClickAddPhoto))
        profileImg.isUserInteractionEnabled = true
        profileImg.addGestureRecognizer(gesture)
        listTableView.register(UINib(nibName: "TitleHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "TitleHeader")
        listTableView.register(UINib(nibName: "DetailTVC", bundle: nil), forCellReuseIdentifier: "DetailTVC")
        listTableView.contentInset = UIEdgeInsets(top: 60, left: 0, bottom: 0, right: 0)
        listTableView.setupPadding()
        listTableView.groupStyleSpacing()
        listTableView.tableHeaderView?.frame.size.height = 81
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getTickets()
        getRecommended()
        displayData()
    }
    
    private func displayData() {
        profileImg.sd_setImage(with: URL(string: UserDefault.shared.user?.image.key ?? ""), placeholderImage: Constant.Icon.uploadImage) { [weak self] _, err, _, _ in
            self?.profileImg.borderWidth = err == nil ? 2 : 0
        }
        nameLbl.text = "\(UserDefault.shared.user?.firstName ?? "") \(UserDefault.shared.user?.lastName ?? "")"
    }
    
    private func getTickets() {
        PaymentPresenter.getUpcomingTickets { [weak self] isSuccess, errMsg, bookings in
            guard let self = self else { return }
            self.bookings = bookings
            self.listTableView.reloadData()
            self.checkZeroViewCase()
        }
    }
    
    private func getRecommended() {
        EventPresenter.getRecommendedEvents { [weak self] isSuccess, errMsg, eventList in
            guard let self = self else { return }
            self.recommended = eventList
            self.listTableView.reloadSections([1], with: .automatic)
            self.checkZeroViewCase()
        }
    }
    
    @objc private func onClickAddPhoto() {
        Navigate.to.showImagePickerController(self, sourceType: .photoLibrary)
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
    
    private func checkZeroViewCase() {
        zeroCaseView.isHidden = !(bookings.count == 0 && recommended.count == 0)
    }
    
    @IBAction func onClickShare(_ sender: Any) {
        let msgText = """
 Download Speakeasy on the Apple App Store to stay updated on covers and wait times at your favorite venues.

 Link to App: \(APIBuilder.appStoreURL)
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
        switch section {
        case 0:
            return bookings.count
        case 1:
            return recommended.count
        default:
            return 0
        }
    }
            
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailTVC", for: indexPath) as! DetailTVC
        if indexPath.section == 0 {
            if bookings[indexPath.row].eventId == nil {
                if bookings[indexPath.row].isCompedTicket == true, let inviteLink = bookings[indexPath.row].inviteLink {
                    cell.nameLbl.text = inviteLink.name
                    cell.dateLbl.text = inviteLink.date.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .EEEMMMD)
                } else {
                    cell.nameLbl.text = Constant.String.liveCoverTicket
                    cell.dateLbl.text = bookings[indexPath.row].createdAt.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .EEEMMMD)
                }
                cell.upcomingImage.image = Constant.Icon.liveCover
            } else {
                cell.nameLbl.text = bookings[indexPath.row].event?.title ?? "Untitle Event"
                cell.dateLbl.text = bookings[indexPath.row].event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .EEEMMMD, useDayLightSavingTime: true, customTimeZone: bookings[indexPath.row].venueObject?.useTimezone ?? "")
                cell.upcomingImage.sd_setImage(with: URL(string: (bookings[indexPath.row].event?.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
            }
            cell.priceLbl.text = "\(bookings[indexPath.row].venueObject?.name ?? ""), \(bookings[indexPath.row].venueObject?.city ?? "")"
        } else {
            cell.upcomingImage.sd_setImage(with: URL(string: (recommended[indexPath.row].flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
            cell.nameLbl.text = recommended[indexPath.row].title
            cell.dateLbl.text = recommended[indexPath.row].startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .EEEMMMD, useDayLightSavingTime: true, customTimeZone: recommended[indexPath.row].venue?.useTimezone ?? "")
            cell.priceLbl.text = ""
        }
        cell.priceLbl.textColor = Constant.Color.codea1Color
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return bookings.count > 0 ? 72 : 0
        case 1:
            return recommended.count > 0 ? 72 : 0
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "TitleHeader") as? TitleHeader
        if section == 0 {
            header?.titleLbl.text = "Your Tickets"
        } else {
            header?.titleLbl.text = "Recommended"
        }
        header?.tintColor = .black
        return header
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            Navigate.to.QRCode(self, booking: bookings[indexPath.row], bookingId: bookings[indexPath.row].id, type: bookings[indexPath.row].eventId == nil ? .appClip : .singleTickedEvent)
        case 1:
            Navigate.to.eventDetail(self, eventId: recommended[indexPath.row].id, venueDetail: nil, event: nil)
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
    func navigateToEventDetail(eventId: String, venueDetail: ClipVenue?, event: Event?) {
        Navigate.to.eventDetail(self, eventId: eventId, venueDetail: venueDetail, event: event)
    }
}
