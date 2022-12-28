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
    @IBOutlet weak var bgImg: UIImageView!
    
    var otpText = ""
    var currectOtp = ""
    var otpRef = ""
    var phoneNum = ""
    var isFromLogin = false
    private var onBoardingDelegate = OnBoardingPresenter()
    var isFromSettings = false
    var isForEmail = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        otpFieldView.delegate = self
        setOtpView()
        
        self.continueBtn.isUserInteractionEnabled = false
        self.continueBtn.alpha = 0.5
        print("*-*\(currectOtp)")

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isFromSettings {
            bgImg.isHidden = true
        } else {
            bgImg.isHidden = false
        }
            phoneNumLbl.text = phoneNum
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
            self.onBoardingDelegate.loginResendOtpApi(otpref: self.otpRef) { otp, otpRef, isSuccess in
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
            if isFromSettings {
                if isForEmail {
                    
                } else {
                    
                }
            } else {
                self.onBoardingDelegate.signUpResendOtpApi(otpref: self.otpRef) { otp, otpRef, isSuccess in
                    if isSuccess {
                        self.otpRef = otpRef
                        self.currectOtp = otp
                        print("*-*\(self.currectOtp)")
                    } else {
                        Alert.showAlertSheet(style: .alert, title: "Otp not send", message: "")
                    }
                    Loader.hide()
                }

            }
        }
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    private func otpVerification() {
        if isFromLogin {
            self.onBoardingDelegate.loginOtpVerifyApi(otp: Int(otpText) ?? 0, otpRef: self.otpRef) { isSuccess in
                if isSuccess {
                        let user = UserModel()
                        AppStateManager.sharedInstance.loginUser(user: user)
                    Loader.hide()
                } else {
                    Alert.showAlertSheet(style: .alert, title: "invalid otp", message: "")
                    Loader.hide()
                }
            }
            print("*-*login")
        } else {
            if isFromSettings {
                if isForEmail {
                    print("*-*email")
                } else {
                    if let pInfoVC = navigationController?.viewControllers.first(where: { ($0 as? PersonalInformationViewController) != nil}) {
                          self.navigationController?.popToViewController(pInfoVC, animated: false)
                        }
                    print("*-*settingPhone")
                }
               
            } else {
                self.onBoardingDelegate.signUpOtpVerifyApi(otp: Int(otpText) ?? 0, otpRef: self.otpRef) { isSuccess in
                    if isSuccess {
                            Navigate.to.welcomeVc(self)
                        Loader.hide()
                    } else {
                        Alert.showAlertSheet(style: .alert, title: "invalid otp", message: "")
                        Loader.hide()
                    }
                }
               print("*-*signup")
            }
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
