//
//  NavigationManager.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 07/12/22.
//

import Foundation
import UIKit

class Navigate {
    
   static let to = Navigate()
    
    private init() {
    
    }
    
    func back(_ sender: UIViewController) {
        sender.navigationController?.popViewController(animated: true)
    }
    
    func startScreenViewController(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(StartScreenViewController.self)) as! StartScreenViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func enterPhoneNumVc(_ sender: UIViewController, isFromLogin: Bool = false, isFromSettings: Bool = false) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(EnterPhoneNumberViewController.self)) as! EnterPhoneNumberViewController
        vc.isFromLogin = isFromLogin
        vc.isFromSettings = isFromSettings
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func enterVerificationCodeVc(_ sender: UIViewController, isFromLogin: Bool = false, isFromSettings: Bool = false, isForEmail: Bool = false, otp: String? = "", otpRef: String? = "",phoneNum: String) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(VerificationCodeViewController.self)) as! VerificationCodeViewController
        vc.isFromLogin = isFromLogin
        vc.currectOtp = otp ?? ""
        vc.otpRef = otpRef ?? ""
        vc.isFromSettings = isFromSettings
        vc.isForEmail = isForEmail
        vc.phoneNum = phoneNum
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func enterNameVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(EnterNameViewController.self)) as! EnterNameViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func presentConfirmPopUp(_ sender: UIViewController,text1: String, text2: String, text3: String, isYesOrNoBtn: Bool = false) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(ConfirmPopUpViewController.self)) as! ConfirmPopUpViewController
        vc.modalPresentationStyle = .overCurrentContext
        vc.confirmPopUpDelegate = sender as? ConfirmPopUpDelegate
        vc.confirmInfoText = text1
        vc.infoDetailtext = text2
        vc.infoNoteText = text3
        vc.isPrivetOrPublic = isYesOrNoBtn
        sender.navigationController?.present(vc, animated: true, completion: nil)
    }
    
    func connectAccountVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(ConnectAccountViewController.self)) as! ConnectAccountViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func addEmailVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(AddEmailViewController.self)) as! AddEmailViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func dateOfBirthVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(DateOfBirthViewController.self)) as! DateOfBirthViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func SetProfilePicVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(SetProfilePictureViewController.self)) as! SetProfilePictureViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func notificationPermissionVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(NotificationPermissionViewController.self)) as! NotificationPermissionViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func setLocationVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(SetLocationViewController.self)) as! SetLocationViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func selectCityVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(SelectCityViewController.self)) as! SelectCityViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func selectVibesVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(SelectVibesViewController.self)) as! SelectVibesViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func selectFavoriteDrinkVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(SelectFavoriteDrinkViewController.self)) as! SelectFavoriteDrinkViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func connectSocialMediaVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(ConnectSocialMediaViewController.self)) as! ConnectSocialMediaViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func signInOptionVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.login2.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(SignInOptionViewController.self)) as! SignInOptionViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func loginWithPhoneNumberVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.login2.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(LoginWithPhoneViewController.self)) as! LoginWithPhoneViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func loginWithEmailVc(_ sender: UIViewController, isFromSettings: Bool = false) {
        let vc = StoryboardAndXibManager.StoryBoard.login2.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(LoginWithEmailViewController.self)) as! LoginWithEmailViewController
        vc.isFromSettings = isFromSettings
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func enterEmailPassVc(_ sender: UIViewController, email: String) {
        let vc = StoryboardAndXibManager.StoryBoard.login2.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(EnterEmailPassViewController.self)) as! EnterEmailPassViewController
        vc.email = email
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func resetPasswordVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.login2.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(ResetPasswordViewController.self)) as! ResetPasswordViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func createPasswordVc(_ sender: UIViewController,email: String) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(CreatePasswordViewController.self)) as! CreatePasswordViewController
        vc.email = email
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func selectGenderVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(SelectGenderViewController.self)) as! SelectGenderViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func welcomeVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(WelcomeViewController.self)) as! WelcomeViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func welcomeItroduceVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(WelcomeItroduceViewController.self)) as! WelcomeItroduceViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func settingsVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.settings.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(SettingsViewController.self)) as! SettingsViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func notificationVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.settings.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(NotificationViewController.self)) as! NotificationViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func deleteAccountVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.settings.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(DeleteAccountViewController.self)) as! DeleteAccountViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func personalInformationVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.settings.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(PersonalInformationViewController.self)) as! PersonalInformationViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func pastPurchasesVisitsVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.settings.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(PastPurchasesVisitsViewController.self)) as! PastPurchasesVisitsViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func paymentMethodsVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.settings.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(PaymentMethodsViewController.self)) as! PaymentMethodsViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func addPaymentMethodsVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.settings.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(AddPaymentMethodsViewController.self)) as! AddPaymentMethodsViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func addCardInfoVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.settings.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(AddCardInfoViewController.self)) as! AddCardInfoViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func cardDetailsVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.settings.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(CardDetailsViewController.self)) as! CardDetailsViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func instagramWebView(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(InstagramWebController.self)) as! InstagramWebController
        sender.navigationController?.present(vc, animated: true, completion: nil)
    }
}
