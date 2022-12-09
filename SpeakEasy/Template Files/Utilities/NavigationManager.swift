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
    
    func startScreenViewController(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(StartScreenViewController.self)) as! StartScreenViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func enterPhoneNumVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(EnterPhoneNumberViewController.self)) as! EnterPhoneNumberViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func enterVerificationCodeVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(VerificationCodeViewController.self)) as! VerificationCodeViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func enterNameVc(_ sender: UIViewController) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(EnterNameViewController.self)) as! EnterNameViewController
        sender.navigationController?.pushViewController(vc, animated: true)
    }
    
    func presentConfirmPopUp(_ sender: UIViewController,text1: String, text2: String, text3: String) {
        let vc = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.shared.getIdentifier(ConfirmPopUpViewController.self)) as! ConfirmPopUpViewController
        vc.modalPresentationStyle = .overCurrentContext
        vc.confirmPopUpDelegate = sender as? ConfirmPopUpDelegate
        vc.confirmInfoText = text1
        vc.infoDetailtext = text2
        vc.infoNoteText = text3
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
}


