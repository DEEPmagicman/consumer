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
    var isFromLogin = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        otpFieldView.delegate = self
        setOtpView()
        
        self.continueBtn.isUserInteractionEnabled = false
        self.continueBtn.alpha = 0.5

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
        if isFromLogin {
            
        } else {
            if otpText == ""{
                showAlert(with: "", message: "enter Otp")
            }else{
//                OtpVerification()
                Navigate.to.welcomeVc(self)
            }
        }

    }
    
    @IBAction func onClickDidNotGetCode(_ sender: Any) {
        
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
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
//            OtpVerification()
        }
        return true
    }
    
}
