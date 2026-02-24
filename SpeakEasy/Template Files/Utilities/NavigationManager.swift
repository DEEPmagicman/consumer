//
//  NavigationManager.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 07/12/22.
//

import UIKit
import NBBottomSheet
import GSImageViewerController

enum NavigationDestination {
    case appLaunch
    case venue
    case event
    case inviteLink
    case booking
    case addOns
}

final class Navigate {
    
   static let to = Navigate()
    
    private init() { }
    
    func showImagePickerController(_ sender: UIViewController, sourceType: UIImagePickerController.SourceType) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = sender as? UIImagePickerControllerDelegate & UINavigationControllerDelegate
        imagePickerController.allowsEditing = true
        imagePickerController.sourceType = sourceType
        sender.present(imagePickerController, animated: true, completion: nil)
    }
    
    func back(_ sender: UIViewController) {
        sender.navigationController?.popViewController(animated: true)
    }
    
    func enterPhoneNumVc(_ sender: UIViewController, isFromLogin: Bool = false, isFromSettings: Bool = false) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateVC(EnterPhoneNumberViewController.self)
        vc.isFromLogin = isFromLogin
        vc.isFromSettings = isFromSettings
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func enterVerificationCodeVc(_ sender: UIViewController, isFromLogin: Bool = false, isFromSettings: Bool = false, isForEmail: Bool = false, otp: String? = "", otpRef: String? = "", phoneNum: String, countryCode: String) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateVC(VerificationCodeViewController.self)
        vc.isFromLogin = isFromLogin
        vc.currectOtp = otp ?? ""
        vc.otpRef = otpRef ?? ""
        vc.isFromSettings = isFromSettings
        vc.isForEmail = isForEmail
        vc.phoneNum = phoneNum
        vc.countryCode = countryCode
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func enterNameVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateVC(EnterNameViewController.self)
        sender.navigationController?.pushViewController(vc, animated: true)
        if let indexOfOTPVC = sender.navigationController?.viewControllers.firstIndex(where: { $0.isKind(of: VerificationCodeViewController.self) }) {
            sender.navigationController?.viewControllers.remove(at: indexOfOTPVC)
        }
    }
    
    func presentConfirmPopUp(_ sender: UIViewController,text1: String, text2: String, text3: String, isYesOrNoBtn: Bool = false) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateVC(ConfirmPopUpViewController.self)
        vc.modalPresentationStyle = .overCurrentContext
        vc.confirmPopUpDelegate = sender as? ConfirmPopUpDelegate
        vc.confirmInfoText = text1
        vc.infoDetailtext = text2
        vc.infoNoteText = text3
        vc.isPrivetOrPublic = isYesOrNoBtn
        sender.navigationController?.present(vc, animated: true, completion: nil)
    }
    
    func presentDateSelectionBottomSheet(_ sender: UIViewController, date: Date? = nil) {
        var configuration: NBBottomSheetConfiguration
        configuration = NBBottomSheetConfiguration(sheetSize: .fixed(310))
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateVC(DateSelectionBottomSheet.self)
        vc.delegate = sender as? DateSelectionDelegate
        vc.date = date
        let bottomSheetController = NBBottomSheetController(configuration: configuration)
        bottomSheetController.present(vc, on: sender)
    }
    
    func presentCheckInBottomSheet(_ sender: UIViewController, ticketId: [String], bookingId: String) {
        var configuration: NBBottomSheetConfiguration
        configuration = NBBottomSheetConfiguration(sheetSize: .fixed(500))
        let vc = StoryboardAndXibManager.StoryBoard.payment.instantiateVC(CheckInBottomSheet.self)
        let bottomSheetController = NBBottomSheetController(configuration: configuration)
        vc.delegate = sender as? DateSelectionDelegate
        vc.bookingId = bookingId
        vc.ticketId = ticketId
        bottomSheetController.present(vc, on: sender)
    }
    
    func connectAccountVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateVC(ConnectAccountViewController.self)
        sender.navigationController?.pushViewController(vc, animated: true)
        if let indexOfOTPVC = sender.navigationController?.viewControllers.firstIndex(where: { $0.isKind(of: VerificationCodeViewController.self) }) {
            sender.navigationController?.viewControllers.remove(at: indexOfOTPVC)
        }
    }
    
    func SetProfilePicVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateVC(SetProfilePictureViewController.self)
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func notificationPermissionVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateVC(NotificationPermissionViewController.self)
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func setLocationVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateVC(SetLocationViewController.self)
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func selectCityVc(_ sender: UIViewController, userLocationCity: String = "") {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateVC(SelectCityViewController.self)
        vc.userLocationCity = userLocationCity
        if sender.navigationController?.viewControllers.last is SelectCityViewController { return }
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func signInOptionVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.login.instantiateVC(SignInOptionViewController.self)
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func MVPVenueDetailViewController(_ sender: UIViewController, venueId: String, venueUniqueId: String, venueTimeZone: String) {
        let vc = StoryboardAndXibManager.StoryBoard.home.instantiateVC(MVPVenueDetailVc.self)
        vc.venueId = venueId
        vc.venueUniqueId = venueUniqueId
        vc.venueTimeZone = venueTimeZone
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func eventDetail(_ sender: UIViewController, eventId: String, venueDetail: ClipVenue?, event: Event?, promoteId: String = "") {
        let vc = StoryboardAndXibManager.StoryBoard.home.instantiateVC(EventDetailVC.self)
        vc.eventId = eventId
        vc.venueDetails = venueDetail
        vc.event = event
        vc.promoteId = promoteId
        vc.hidesBottomBarWhenPushed = true
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func inviteVC(_ sender: UIViewController, inviteId: String) {
        let vc = StoryboardAndXibManager.StoryBoard.home.instantiateVC(InviteLinkVC.self)
        vc.inviteId = inviteId
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func fullScreenImg(_ sender: UIViewController, imgURL: String) {
        let vc = StoryboardAndXibManager.StoryBoard.home.instantiateVC(FullScreenImgVC.self)
        vc.imgURL = imgURL
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overCurrentContext
        sender.navigationController?.present(vc, animated: true, completion: nil)
    }
    
    func presentGSImageViewerController(_ sender: UIViewController, imageView: UIImageView) {
        let image = imageView.image ?? Constant.Icon.uploadImage ?? UIImage()
        let imageInfo = GSImageInfo(image: image, imageMode: .aspectFit)
        let transitionInfo = GSTransitionInfo(fromView: imageView)
        let imageViewer = GSImageViewerController(imageInfo: imageInfo, transitionInfo: transitionInfo)
        sender.present(imageViewer, animated: true, completion: nil)
    }
    
    func checkOutVC(_ sender: UIViewController, venue: ClipVenue?, selectedCoverTickets: [CoverTicket], selectedEventTicket: [EventTicket], selectedAddOnsItem: [UpSellTicket], event: Event? = nil, totalPrice: Double, type: PaymentIntentType, promoteId: String = "", bookingType: TicketPriceType = .PAID) {
        let vc = StoryboardAndXibManager.StoryBoard.payment.instantiateVC(CheckOutVC.self)
        vc.selectedCoverTickets = selectedCoverTickets
        vc.selectedEventTicket = selectedEventTicket
        vc.selectedAddOnsItem = selectedAddOnsItem
        vc.totalPrice = totalPrice
        vc.venue = venue
        vc.type = type
        vc.event = event
        vc.promoteId = promoteId
        vc.bookingType = bookingType
        vc.updateDelegate = sender as? UpdateDetailDelegate
        vc.hidesBottomBarWhenPushed = true
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func showQRCode(_ sender: UIViewController, booking: Booking?, bookingId: String, type: PaymentIntentType) {
        let vc = StoryboardAndXibManager.StoryBoard.payment.instantiateVC(ShowQRCodeVC.self)
        vc.booking = booking
        vc.bookingId = bookingId
        vc.delegate = sender as? QRCodeVCNavigationDelegate
        vc.type = type
        if let homeVc = sender.navigationController?.viewControllers.first(where: { $0.isKind(of: MVPVenueListVc.self) }) {
            homeVc.present(vc, animated: true)
            homeVc.tabBarController?.selectedIndex = 1
            sender.navigationController?.viewControllers = [homeVc]
            if vc.delegate == nil, let tabTwo = homeVc.tabBarController?.viewControllers?.last as? UINavigationController, let accountVC = tabTwo.viewControllers.first(where: { $0 is AccountVC }) as? AccountVC {
                vc.delegate = accountVC
            }
            return
        } else if let accountVc = sender.navigationController?.viewControllers.first(where: { $0.isKind(of: AccountVC.self) }) {
            accountVc.present(vc, animated: true)
            accountVc.tabBarController?.selectedIndex = 1
            sender.navigationController?.viewControllers = [accountVc]
            vc.delegate = accountVc as? AccountVC
            return
        }
        sender.navigationController?.present(vc, animated: true)
    }
    
    func paymentDetailVC(_ sender: UIViewController, booking: Booking?) {
        let vc = StoryboardAndXibManager.StoryBoard.payment.instantiateVC(PaymentDetailVC.self)
        vc.booking = booking
        sender.present(vc, animated: true)
    }
    
    func loginMandatory(_ sender: UIViewController, guestUserLastNavigation: (NavigationDestination, String) = (.appLaunch, "")) {
        sender.tabBarController?.selectedIndex = 1
        if let vc = (sender.tabBarController?.viewControllers?.last as? UINavigationController)?.viewControllers.first(where: { $0 is MVPStartScreenVC }) as? MVPStartScreenVC {
            vc.guestUserLastNavigation = guestUserLastNavigation
        }
    }
    
    func login(forceCreateAccount: Bool = false) {
        AppDelegate.shared.guestUserLastNavigation = (.appLaunch, "")
        UserDefault.shared.emptyData()
        AppDelegate.shared.changeRootViewController(forceCreateAccount: forceCreateAccount)
    }
    
    func settingsVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.settings.instantiateVC(SettingsViewController.self)
        fullscreenPush(vc: vc)
    }
    
    func notificationVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.settings.instantiateVC(NotificationViewController.self)
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func deleteAccountVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.settings.instantiateVC(DeleteAccountViewController.self)
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func personalInformationVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.settings.instantiateVC(PersonalInformationViewController.self)
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func pastPurchasesVisitsVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.settings.instantiateVC(PastPurchasesVisitsViewController.self)
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func paymentMethodsVc(_ sender: UIViewController, selectedId: String, isEditable: Bool = false) {
        let vc = StoryboardAndXibManager.StoryBoard.settings.instantiateVC(PaymentMethodsViewController.self)
        vc.delegate = sender as? PaymentMethodVCDelegate
        vc.selectedId = selectedId
        vc.isEditable = isEditable
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func cardDetailsVc(_ sender: UIViewController, customerId: String, paymentMethod: PaymentMethod?) {
        let vc = StoryboardAndXibManager.StoryBoard.settings.instantiateVC(CardDetailsViewController.self)
        vc.customerId = customerId
        vc.paymentMethod = paymentMethod
        vc.delegate = sender as? CardDetailChangeDelegate
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func mvpCitySelection(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.home.instantiateVC(MVPCitySelectionVC.self)
        vc.citySelectionDelegate = sender as? CitySelectionDelegate
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func scanQR(_ sender: UIViewController, isAddOnsAvailable: Bool = false, bookingId: String, booking: Booking? = nil, isOnlyAddOnAvailable: Bool = false, venueId: String = "", addOnsBookingId: String, venueName: String? = "") {
        let vc = StoryboardAndXibManager.StoryBoard.payment.instantiateVC(ScanQRCodeVC.self)
        vc.isAddOnsAvailable = isAddOnsAvailable
        vc.bookingId = bookingId
        vc.booking = booking
        vc.isOnlyAddOnAvailable = isOnlyAddOnAvailable
        vc.venueId = venueId
        vc.delegate = sender as? QRCodeVCNavigationDelegate
        vc.addOnsBookingId = addOnsBookingId
        vc.venueNameText = venueName
        if let homeVc = sender.navigationController?.viewControllers.first(where: { $0.isKind(of: MVPVenueListVc.self) }) {
            homeVc.present(vc, animated: true)
            homeVc.tabBarController?.selectedIndex = 1
            sender.navigationController?.viewControllers = [homeVc]
            if vc.delegate == nil, let tabTwo = homeVc.tabBarController?.viewControllers?.last as? UINavigationController, let accountVC = tabTwo.viewControllers.first(where: { $0 is AccountVC }) as? AccountVC {
                vc.delegate = accountVC
            }
            return
        } else if let accountVc = sender.navigationController?.viewControllers.first(where: { $0.isKind(of: AccountVC.self) }) {
            accountVc.present(vc, animated: true)
            accountVc.tabBarController?.selectedIndex = 1
            sender.navigationController?.viewControllers = [accountVc]
            vc.delegate = accountVc as? AccountVC
            return
        }
        sender.navigationController?.present(vc, animated: true)
    }
    
    func upSellTicketVC(_ sender: UIViewController, upSellTicket: [UpSellTicket], hasMany: Bool, venueDetails: ClipVenue?, doormanId: String, bookingType: TicketPriceType = .PAID) {
        let vc = StoryboardAndXibManager.StoryBoard.home.instantiateVC(UpSellTicketVC.self)
        vc.upSellTicket = upSellTicket
        vc.hasMany = hasMany
        vc.venueDetails = venueDetails
        vc.doormanId = doormanId
        vc.bookingType = bookingType
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func eventFreeCheckoutVC(_ sender: UIViewController, event: Event?, selectedEventTicket: [EventTicket], venueDetails: ClipVenue?) {
        let vc = StoryboardAndXibManager.StoryBoard.payment.instantiateVC(EventCheckoutVC.self)
        vc.event = event
        vc.selectedEventTicket = selectedEventTicket
        vc.venueDetails = venueDetails
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func fullscreenPush(vc: UIViewController) {
        if  Utility.main.topViewController()?.navigationController?.navigationController == nil {
            Utility.main.topViewController()?.navigationController?.pushViewController(vc, animated: true)
        } else {
            Utility.main.topViewController()?.navigationController?.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    static func externalURL(_ url: String) {
        guard let url = URL(string: url) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func barTabCheckoutVC(_ sender: UIViewController, selectedTicket: [CoverTicket], venueDetails: ClipVenue?) {
        let vc = StoryboardAndXibManager.StoryBoard.bartab.instantiateVC(BarTabCheckoutVC.self)
        vc.selectedTicket = selectedTicket
        vc.venueDetails = venueDetails
        vc.hidesBottomBarWhenPushed = true
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func barTabQRCodeVC(_ sender: UIViewController, venue: ClipVenue?, barTabId: String) {
        let vc = StoryboardAndXibManager.StoryBoard.bartab.instantiateVC(BarTabQRCodeVC.self)
        vc.venue = venue
        vc.barTabId = barTabId
        if let homeVc = sender.navigationController?.viewControllers.first(where: { $0.isKind(of: MVPVenueListVc.self) }) {
            homeVc.present(vc, animated: true)
            homeVc.tabBarController?.selectedIndex = 1
            sender.navigationController?.viewControllers = [homeVc]
            if vc.delegate == nil, let tabTwo = homeVc.tabBarController?.viewControllers?.last as? UINavigationController, let accountVC = tabTwo.viewControllers.first(where: { $0 is AccountVC }) as? AccountVC {
                vc.delegate = accountVC
            }
            return
        } else if let accountVc = sender.navigationController?.viewControllers.first(where: { $0.isKind(of: AccountVC.self) }) {
            accountVc.present(vc, animated: true)
            accountVc.tabBarController?.selectedIndex = 1
            sender.navigationController?.viewControllers = [accountVc]
            vc.delegate = accountVc as? AccountVC
            return
        }
        sender.navigationController?.present(vc, animated: true)
//        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    func allVenueVC(_ sender: UIViewController) {
        let vc = AllVenueVC(nibName: "AllVenueVC", bundle: nil)
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func selectLocationVC(_ sender: UIViewController) {
        let vc = SelectLocationVC(nibName: "SelectLocationVC", bundle: nil)
        sender.pushVC(vc)
    }
    
    func dateRangeSelectionVC(_ sender: UIViewController) {
        let vc = DateRangeSelectionVC(nibName: "DateRangeSelectionVC", bundle: nil)
        vc.dateDelegate = sender as? SelectedDateDelegate
        sender.presentVC(vc)
    }
    
    func tables3DMapVC(_ sender: UIViewController) {
        let vc = Tables3DMapVC(nibName: "Tables3DMapVC", bundle: nil)
        sender.pushVC(vc)
    }
    
    func tableCheckOutVC(_ sender: UIViewController, event: Event) {
        let vc = TableCheckOutVC(nibName: "TableCheckOutVC", bundle: nil)
        vc.event = event
        sender.pushVC(vc)
    }
    
    func eventDetailsVC(_ sender: UIViewController, event: Event?) {
        let vc = EventDetailsVC(nibName: "EventDetailsVC", bundle: nil)
        vc.event = event
        sender.pushVC(vc)
    }
    
    func ticketSelectionVc(_ sender: UIViewController, event: Event) {
        let vc = TicketSelectionViewController(nibName: "TicketSelectionViewController", bundle: nil)
        vc.event = event
        sender.pushVC(vc)
    }
    
    func ticketCheckoutVC(_ sender: UIViewController, event: Event, selectedTickets: [EventTicket] = [], bookingId: String? = nil) {
        let vc = TicketCheckoutVC(nibName: "TicketCheckoutVC", bundle: nil)
        vc.event = event
        vc.selectedTickets = selectedTickets
        vc.bookingId = bookingId
        sender.pushVC(vc)
    }
    
    func tableSeatingVC(_ sender: UIViewController, seatingArea: SeatingArea) {
        let vc = TableSeatingViewController(
            nibName: "TableSeatingViewController",
            bundle: nil
        )
        vc.seatingArea = seatingArea
        vc.modalPresentationStyle = .overCurrentContext
        sender.present(vc, animated: false)
    }
    
    
    func tablePurchaseVC(_ sender: UIViewController) {
        let vc = TablePurchaseVC(nibName: "TablePurchaseVC", bundle: nil)
        sender.pushVC(vc)
    }
    
}
