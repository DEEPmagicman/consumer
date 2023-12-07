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
    private var isLoading = false
    private var hasMany = false
    var skipValue = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        displayData()
        let gesture = UITapGestureRecognizer(target: self, action: #selector(onClickAddPhoto))
        profileImg.isUserInteractionEnabled = true
        profileImg.addGestureRecognizer(gesture)
        listTableView.register(UINib(nibName: "TitleHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "TitleHeader")
        listTableView.register(UINib(nibName: "PurchaseDetailsTVC", bundle: nil), forCellReuseIdentifier: "PurchaseDetailsTVC")
        listTableView.register(UINib(nibName: "FooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: "FooterView")
        listTableView.contentInset = UIEdgeInsets(top: 60, left: 0, bottom: 0, right: 0)
        listTableView.setupPadding()
        listTableView.groupStyleSpacing()
        listTableView.tableHeaderView?.frame.size.height = 81
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getUpcomingTickets()
        getRecommended()
        whoAmIAPI()
    }
    
    private func whoAmIAPI() {
        onBoardingPresenter.getCurrentUserDetail {[weak self] isSuccess in
            guard let self = self else { return }
            if isSuccess {
                self.displayData()
            }
        }
    }
    private func displayData() {
        profileImg.sd_setImage(with: URL(string: UserDefault.shared.user?.image.key ?? ""), placeholderImage: Constant.Icon.defaultProfile) { [weak self] _, err, _, _ in
            self?.profileImg.borderWidth = err == nil ? 2 : 0
        }
        nameLbl.text = "\(UserDefault.shared.user?.firstName ?? "") \(UserDefault.shared.user?.lastName ?? "")"
    }
    
    private func getUpcomingTickets() {
        PaymentPresenter.getUpcomingTicket(skip: skipValue) { [weak self] isSuccess, errMsg, bookings, hasMany in
            guard let self = self else { return }
            self.isLoading = false
            if isSuccess {
                if self.skipValue == 0 {
                    self.bookings.removeAll()
                }
                
                for booking in bookings {
                    self.bookings.append(booking)
                }
                if hasMany {
                    self.skipValue += 10
                }
                self.hasMany = hasMany
                self.bookings = bookings
                self.checkZeroViewCase()
                self.listTableView.reloadData()
            }
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

 Link to App: \(SharedURL.appStoreURL)
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        358
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "PurchaseDetailsTVC", for: indexPath) as! PurchaseDetailsTVC
        
        if indexPath.section == 0 {
            if bookings[indexPath.row].eventId == nil {
                if bookings[indexPath.row].isCompedTicket == true, let inviteLink = bookings[indexPath.row].inviteLink {
                    cell.eventNameLbl.text = inviteLink.name
                    cell.monthLbl.text = inviteLink.date.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .MMM)
                    cell.dateLbl.text = inviteLink.date.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .DD)
                } else if bookings[indexPath.row].bookingType == "TABLE_BOOKING" {
                    cell.eventNameLbl.text = Constant.String.tableReservation
                    cell.dateLbl.text = bookings[indexPath.row].floorPlanTimeSlotBooking?.first?.floorPlanTableTimeSlot.date.convertDateFormat(from: .YYYYMMDD, to: .DD)
                    cell.monthLbl.text = bookings[indexPath.row].floorPlanTimeSlotBooking?.first?.floorPlanTableTimeSlot.date.convertDateFormat(from: .YYYYMMDD, to: .MMM)
                } else {
                    cell.eventNameLbl.text = Constant.String.liveCoverTicket
                    cell.dateLbl.text = bookings[indexPath.row].createdAt.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .DD)
                    cell.monthLbl.text = bookings[indexPath.row].createdAt.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .MMM)
                }
                cell.bgImage.sd_setImage(with: URL(string: (bookings[indexPath.row].venueObject?.venueAttachment.first?.key ?? "").imageURL))
                cell.venueLogoImageView.sd_setImage(with: URL(string: (bookings[indexPath.row].venueObject?.logo?.key ?? "").imageURL))
                cell.venueLogoImageView.isHidden = false
            } else {
                cell.eventNameLbl.text = bookings[indexPath.row].event?.title ?? "Untitle Event"
                cell.dateLbl.text = bookings[indexPath.row].event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .DD, useDayLightSavingTime: true, customTimeZone: bookings[indexPath.row].venueObject?.useTimezone ?? "")
                cell.monthLbl.text = bookings[indexPath.row].event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .MMM, useDayLightSavingTime: true, customTimeZone: bookings[indexPath.row].venueObject?.useTimezone ?? "")
                cell.bgImage.sd_setImage(with: URL(string: (bookings[indexPath.row].event?.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
                cell.venueLogoImageView.isHidden = true
            }
        } else {
            cell.bgImage.sd_setImage(with: URL(string: (recommended[indexPath.row].flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
            cell.eventNameLbl.text = recommended[indexPath.row].title
            cell.dateLbl.text = recommended[indexPath.row].startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .DD, useDayLightSavingTime: true, customTimeZone: recommended[indexPath.row].venue?.useTimezone ?? "")
        }
        cell.ticketTypeImage.image = bookings[indexPath.row].bookingType == "TABLE_BOOKING" ? UIImage(named: "ic-people-logo") : UIImage(named: "ic-ticket-logo")
        cell.ticketCountLbl.text = "\(bookings[indexPath.row].bookingHasItem.count)"
        cell.cityNameLbl.text = bookings[indexPath.row].venueObject?.name
        cell.setUI()
        
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
            Navigate.to.showQRCode(self, booking: bookings[indexPath.row], bookingId: bookings[indexPath.row].id, type: bookings[indexPath.row].eventId == nil ? .appClip : .singleTickedEvent)
        case 1:
            Navigate.to.eventDetail(self, eventId: recommended[indexPath.row].id, venueDetail: nil, event: nil)
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = self.listTableView.dequeueReusableHeaderFooterView(withIdentifier: "FooterView") as? FooterView
        footer?.loader.startAnimating()
        return footer
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            if isLoading {
                return 50
            } else {
                return 0
            }
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            if indexPath.row == (bookings.count) - 1 && hasMany && isLoading == false {
                isLoading = true
                DispatchQueue.main.async {
                    self.listTableView.reloadData()
                }
                getUpcomingTickets()
            }
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
    
    func navigateToVenueDetail(venueId: String, venueUniqueId: String, venueTimeZone: String) {
        Navigate.to.MVPVenueDetailViewController(self, venueId: venueId, venueUniqueId: venueUniqueId, venueTimeZone: venueTimeZone)
    }
}
