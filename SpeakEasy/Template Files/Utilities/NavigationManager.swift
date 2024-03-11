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
    
    func confirmEmailVC(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateVC(ConfirmEmailVC.self)
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overFullScreen
        sender.navigationController?.present(vc, animated: true, completion: nil)
    }
    
//    func presentCommentDoneBottomSheet(_ sender: UIViewController) {
//        var configuration: NBBottomSheetConfiguration
//        configuration = NBBottomSheetConfiguration(sheetSize: .fixed(380))
//        let viewController = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateVC(ConfirmEmailBottomSheet.self)
//        let bottomSheetController = NBBottomSheetController(configuration: configuration)
//        bottomSheetController.present(viewController, on: sender)
//    }
    
    func presentDateSelectionBottomSheet(_ sender: UIViewController, date: Date? = nil) {
        var configuration: NBBottomSheetConfiguration
        configuration = NBBottomSheetConfiguration(sheetSize: .fixed(310))
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateVC(DateSelectionBottomSheet.self)
        vc.delegate = sender as? DateSelectionDelegate
        vc.date = date
        let bottomSheetController = NBBottomSheetController(configuration: configuration)
        bottomSheetController.present(vc, on: sender)
    }
    
    func connectAccountVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateVC(ConnectAccountViewController.self)
        sender.navigationController?.pushViewController(vc, animated: true)
        if let indexOfOTPVC = sender.navigationController?.viewControllers.firstIndex(where: { $0.isKind(of: VerificationCodeViewController.self) }) {
            sender.navigationController?.viewControllers.remove(at: indexOfOTPVC)
        }
    }
    
    func addEmailVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateVC(AddEmailViewController.self)
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func dateOfBirthVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateVC(DateOfBirthViewController.self)
        sender.navigationController?.pushViewController(vc, animated: true)
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
    
    func selectVibesVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateVC(SelectVibesViewController.self)
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func selectFavoriteDrinkVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateVC(SelectFavoriteDrinkViewController.self)
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func connectSocialMediaVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateVC(ConnectSocialMediaViewController.self)
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func signInOptionVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.login.instantiateVC(SignInOptionViewController.self)
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func loginWithEmailVc(_ sender: UIViewController, isFromSettings: Bool = false) {
        let vc = StoryboardAndXibManager.StoryBoard.login.instantiateVC(LoginWithEmailViewController.self)
        vc.isFromSettings = isFromSettings
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func enterEmailPassVc(_ sender: UIViewController, email: String) {
        let vc = StoryboardAndXibManager.StoryBoard.login.instantiateVC(EnterEmailPassViewController.self)
        vc.email = email
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func resetPasswordVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.login.instantiateVC(ResetPasswordViewController.self)
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func createPasswordVc(_ sender: UIViewController,email: String) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateVC(CreatePasswordViewController.self)
        vc.email = email
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func changePasswordVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.settings.instantiateVC(ChangePasswordViewController.self)
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func welcomeVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateVC(WelcomeViewController.self)
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func welcomeItroduceVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateVC(WelcomeItroduceViewController.self)
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func MVPVenueDetailViewController(_ sender: UIViewController, venueId: Int, venueUniqueId: String, venueTimeZone: String) {
        let vc = StoryboardAndXibManager.StoryBoard.home.instantiateVC(MVPVenueDetailVc.self)
        vc.venueId = venueId
        vc.venueUniqueId = venueUniqueId
        vc.venueTimeZone = venueTimeZone
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func selectTicket(_ sender: UIViewController, venueDetail: ClipVenue?, event: Event?, type: TicketType = .appClip) {
        let vc = StoryboardAndXibManager.StoryBoard.home.instantiateVC(SelectTicketVC.self)
        vc.venueDetails = venueDetail
        vc.event = event
        vc.type = type
        vc.hidesBottomBarWhenPushed = true
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
    
    func checkOutVC(_ sender: UIViewController, venue: ClipVenue?, selectedCoverTickets: [CoverTicket], selectedEventTicket: [EventTicket], selectedAddOnsItem: [UpSellTicket], event: Event? = nil, totalPrice: Double, type: PaymentIntentType, promoteId: String = "") {
        let vc = StoryboardAndXibManager.StoryBoard.payment.instantiateVC(CheckOutVC.self)
        vc.selectedCoverTickets = selectedCoverTickets
        vc.selectedEventTicket = selectedEventTicket
        vc.selectedAddOnsItem = selectedAddOnsItem
        vc.totalPrice = totalPrice
        vc.venue = venue
        vc.type = type
        vc.event = event
        vc.promoteId = promoteId
        vc.updateDelegate = sender as? UpdateDetailDelegate
        vc.hidesBottomBarWhenPushed = true
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func showQRCode(_ sender: UIViewController, booking: Booking?, bookingId: Int, type: PaymentIntentType) {
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
    
    func instagramWebView(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateVC(InstagramWebController.self)
        vc.instaConnectedDelegate = sender as? InstagramConnectedDelegate
        sender.navigationController?.present(vc, animated: true, completion: nil)
    }
    
    func selectPhotoVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateVC(SelectPhotosViewController.self)
        vc.selectedImgDelegate = sender as? SelectedInstaImgDelegate
        sender.navigationController?.present(vc, animated: true, completion: nil)
    }
    
    func inviteFriendPopUp(_ sender: UIViewController, invitedFrdList: [InviteFriendsModel], selectedGuest: Int) {
        let vc = InviteFriendsPopUp()
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overCurrentContext
        vc.invitedFrdDelegate = sender as? InvitedFriendDelegate
        vc.selectedFriend = invitedFrdList
        vc.guest = selectedGuest
        sender.navigationController?.present(vc, animated: true, completion: nil)
    }
    
    func editProfile(_ sender: UIViewController) {
        let vc = EditProfileVC()
        fullscreenPush(vc: vc)
    }
    
    func bookingInvite(_ sender: UIViewController, booking: BookingsDataSet?, isFromSettings: Bool = false) {
        let vc = PendingBookingAwait()
        vc.booking = booking
        vc.isFromSettings = isFromSettings
        Utility.main.topViewController()?.navigationController?.pushViewController(vc, animated: true)
    }
    
    func VIPBookingInviteNew(_ sender: UIViewController, isFree: Bool) {
        let vc = VipBookingInviteNew()
        vc.itsFree = isFree
        fullscreenPush(vc: vc)
    }
    
    func pendingBookingAwait(_ sender: UIViewController, data: BookingsDataSet?, fromBooking: Bool = false) {
        let vc = PendingBookingAwait()
        vc.booking = data
        vc.fromBookingInvite = fromBooking
        fullscreenPush(vc: vc)
    }
    
    func ticketConfirmation(_ sender: UIViewController, data: BookingsDataSet?, isFromSettings: Bool = false) {
      let data = TopEventDataSet(imgEventCover: UIImage(named: "duttonRanch"), lblPerformerName: "Dutton Ranch", lblVenueName: "Welcome to the Farm",imgBrandLogo: UIImage(named: "welcomeFarmLogo"), lblEventDate: "Friday, October 28",location: "1054 Old River Rd. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "welcomeFarmLogoLarge"), lblSongName: "Country Girl", lblSongArtist: "Luke Bryan")
        let vc = TicketConfirmation()
        vc.screenType = .FromBooking
        vc.isFromSettings = isFromSettings
        vc.topEventData = data
        fullscreenPush(vc: vc)
    }
    
    func allEvents(_ sender: UIViewController) {
        let vc = AllEvents()
        Utility.main.topViewController()?.navigationController?.pushViewController(vc, animated: true)
    }
    
    func allVenues(_ sender: UIViewController) {
        let vc = AllVenues()
        Utility.main.topViewController()?.navigationController?.pushViewController(vc, animated: true)
    }
    
    func tutorialVc(_ sender: UIViewController) {
        let vc = Tutorials()
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
//    func eventDetail(_ sender: UIViewController, eventId: String) {
//        let vc = EventBookingDetails()
//        vc.eventId = eventId
//        sender.navigationController?.pushViewController(vc, animated: true)
//    }
    
    func homeCitySelection(_ sender: UIViewController) {
        let vc = HomeCitySelectionVC()
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func mvpCitySelection(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.home.instantiateVC(MVPCitySelectionVC.self)
        vc.citySelectionDelegate = sender as? CitySelectionDelegate
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func scanQR(_ sender: UIViewController, isAddOnsAvailable: Bool = false, bookingId: Int, booking: Booking? = nil, isOnlyAddOnAvailable: Bool = false, venueId: Int = 0, addOnsBookingId: String, venueName: String? = "") {
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
    
    func upSellTicketVC(_ sender: UIViewController, upSellTicket: [UpSellTicket], hasMany: Bool, venueDetails: ClipVenue?, doormanId: String) {
        let vc = StoryboardAndXibManager.StoryBoard.home.instantiateVC(UpSellTicketVC.self)
        vc.upSellTicket = upSellTicket
        vc.hasMany = hasMany
        vc.venueDetails = venueDetails
        vc.doormanId = doormanId
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
}
