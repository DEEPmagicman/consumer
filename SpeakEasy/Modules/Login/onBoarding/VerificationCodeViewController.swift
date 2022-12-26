//
//  VerificationCodeViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 07/12/22.
//

import UIKit
import OTPFieldView
import SwiftUI

final class VerificationCodeViewController: UIViewController {

    @IBOutlet weak var phoneNumLbl: UILabel!
    @IBOutlet weak var otpFieldView: OTPFieldView!
    @IBOutlet weak var continueBtn: UIButton!
    
    var otpText = ""
    var currectOtp = ""
    var otpRef = ""
    var isFromLogin = false
    private var onBoardingDelegate = OnBoardingPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        otpFieldView.delegate = self
        setOtpView()
        
        self.continueBtn.isUserInteractionEnabled = false
        self.continueBtn.alpha = 0.5
        print("*-*\(currectOtp)")

    }
    
    func setOtpView() {
        self.otpFieldView.fieldsCount = 6
        self.otpFieldView.fieldBorderWidth = 1
        self.otpFieldView.defaultBorderColor = .white
        self.otpFieldView.cursorColor = Constant.Color.primaryColor
        self.otpFieldView.filledBorderColor = Constant.Color.primaryColor
        self.otpFieldView.displayType = .underlinedBottom
        self.otpFieldView.fieldSize = 40
        self.otpFieldView.separatorSpace = 8
        self.otpFieldView.shouldAllowIntermediateEditing = false
        self.otpFieldView.initializeUI()
    }

    @IBAction func onClickEdit(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        if otpText == ""{
                showAlert(with: "", message: "Please Enter Otp")
        } else {
            otpVerification()
        }

    }
    
    @IBAction func onClickDidNotGetCode(_ sender: Any) {
        if isFromLogin {
            self.onBoardingDelegate.resendOtpApi(otpref: self.otpRef) { otp, otpRef, isSuccess in
                if isSuccess {
                    self.otpRef = otpRef
                    self.currectOtp = otp
                    print("*-*\(self.currectOtp)")
                } else {
                    Alert.showAlertSheet(style: .alert, title: "Otp not send", message: "")
                }
                Loader.hide()
            }
        } else {
            
        }
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    private func otpVerification() {
        if isFromLogin {
            self.onBoardingDelegate.otpVerifyApi(otp: Int(otpText) ?? 0, otpRef: self.otpRef) { isSuccess in
                if isSuccess {
//                    if self.isFromLogin {
                        let user = UserModel()
                        AppStateManager.sharedInstance.loginUser(user: user)
//                    } else {
//                        Navigate.to.welcomeVc(self)
//                    }
                    Loader.hide()
                } else {
                    Alert.showAlertSheet(style: .alert, title: "invalid otp", message: "")
                    Loader.hide()
                }
            }
        } else {
            //signUp
        }
      
    }
}

extension VerificationCodeViewController : OTPFieldViewDelegate{
    func shouldBecomeFirstResponderForOTP(otpTextFieldIndex index: Int) -> Bool {
        self.continueBtn.isUserInteractionEnabled = false
        self.continueBtn.alpha = 0.5
        return true
    }
    
    func enteredOTP(otp: String) {
            otpText = otp
        self.continueBtn.isUserInteractionEnabled = true
        self.continueBtn.alpha = 1.0
    }
    
    func hasEnteredAllOTP(hasEnteredAll: Bool) -> Bool {
        if hasEnteredAll {
            otpVerification()
        }
        return true
    }
    
}
