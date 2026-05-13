//
//  AuthOTPInputViewDelegate.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 12/05/26.
//

import UIKit
import OTPFieldView
import MHLoadingButton

protocol AuthOTPInputViewDelegate: AnyObject {
    func authOTPInputViewDidTapContinue(_ view: AuthOTPInputView, otp: String)
    func authOTPInputViewDidTapBack(_ view: AuthOTPInputView)
    func authOTPInputViewDidTapResend(_ view: AuthOTPInputView)
}

final class AuthOTPInputView: UIView {

    weak var delegate: AuthOTPInputViewDelegate?

    let continueBtn = LoadingButton()
    let resendBtn = ClearHighlightLoadingButton()

    private let phoneNumLbl = UILabel()
    private let otpFieldView = OTPFieldView()
    private let timerLbl = UILabel()
    private let backBtn = LoadingButton()

    private var otpText = ""
    private var otpSize = 58.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setOtpView()
        setButton(continueBtn, enabled: false)
        setResendEnabled(false)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setOtpView()
        setButton(continueBtn, enabled: false)
        setResendEnabled(false)
    }

    func configure(phone: String, countryCode: String) {
        phoneNumLbl.text = "Enter the 6 digits code sent to \(countryCode)...\(phone.suffix(2))"
    }

    func updateTimer(_ text: String) {
        timerLbl.text = text
    }

    func setResendEnabled(_ enabled: Bool) {
        resendBtn.isUserInteractionEnabled = enabled
        resendBtn.alpha = enabled ? 1.0 : 0.5
    }

    func resetOTP() {
        otpText = ""
        setButton(continueBtn, enabled: false)
        otpFieldView.initializeUI()
        setOtpView()
    }

    private func setupUI() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        otpSize = min(58, floor(((UIScreen.main.bounds.width - 32 - 36) - (7 * 5)) / 6))
        let titleLabel = Utility.main.makeLabel("Verification code", size: 22)

        phoneNumLbl.textColor = AuthTheme.subtitle
        phoneNumLbl.font = Constant.Font.geistRegular(size: 13)
        phoneNumLbl.textAlignment = .center
        phoneNumLbl.numberOfLines = 0

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(phoneNumLbl)
        stack.addArrangedSubview(makeSpacer(16))

//        let otpSize = min(58, floor(((UIScreen.main.bounds.width - 32 - 36) - (7 * 5)) / 6))
        otpFieldView.translatesAutoresizingMaskIntoConstraints = false
        otpFieldView.heightAnchor.constraint(equalToConstant: otpSize + 10).isActive = true
        stack.addArrangedSubview(otpFieldView)

        resendBtn.setTitle("Resend code", for: .normal)
        resendBtn.setTitleColor(AuthTheme.link, for: .normal)
        resendBtn.titleLabel?.font = Constant.Font.geistRegular(size: 14)
        resendBtn.bgColor = .clear
        resendBtn.backgroundColor = .clear
        resendBtn.indicator = MaterialLoadingIndicator(color: AuthTheme.link)
        resendBtn.addTarget(self, action: #selector(onClickResend), for: .touchUpInside)
        resendBtn.heightAnchor.constraint(equalToConstant: 32).isActive = true
        stack.addArrangedSubview(resendBtn)

        timerLbl.textColor = AuthTheme.subtitle
        timerLbl.font = Constant.Font.geistRegular(size: 12)
        timerLbl.textAlignment = .center
        stack.addArrangedSubview(timerLbl)

        stylePrimaryButton(continueBtn, title: "Continue")
        continueBtn.addTarget(self, action: #selector(onClickContinue), for: .touchUpInside)
        stack.addArrangedSubview(continueBtn)

        backBtn.setTitle("Back", for: .normal)
        backBtn.setTitleColor(AuthTheme.title, for: .normal)
        backBtn.titleLabel?.font = Constant.Font.geistSemiBold(size: 16)
        backBtn.bgColor = AppColor.primaryBlackColor.withAlphaComponent(0.10)
        backBtn.layer.cornerRadius = 16
        backBtn.layer.borderWidth = 1
        backBtn.clipsToBounds = true
        backBtn.layer.borderColor = AuthTheme.border.cgColor
        backBtn.addTarget(self, action: #selector(onClickBack), for: .touchUpInside)
        backBtn.heightAnchor.constraint(equalToConstant: 54).isActive = true
        stack.addArrangedSubview(backBtn)
    }

    private func setOtpView() {
        otpFieldView.delegate = self
        otpFieldView.fieldsCount = 6
        otpFieldView.fieldBorderWidth = 0
        otpFieldView.defaultBackgroundColor = AuthTheme.fieldBackground
        otpFieldView.filledBackgroundColor = AuthTheme.fieldBackground
        otpFieldView.defaultBorderColor = .clear
        otpFieldView.filledBorderColor = .clear
        otpFieldView.cursorColor = AuthTheme.link
        otpFieldView.displayType = .roundedCorner
        otpFieldView.shouldAllowIntermediateEditing = false

//        let availableWidth = UIScreen.main.bounds.width - 32 - 36
        let spacing: CGFloat = 7
//        let calculatedSize = floor((CGFloat(availableWidth) - spacing * 5) / 6)

        otpFieldView.fieldSize = min(58, otpSize)
        otpFieldView.separatorSpace = spacing
        otpFieldView.initializeUI()
        print("-1-1-1\(self.otpFieldView.subviews.count)")
        
        DispatchQueue.main.async {
            self.otpFieldView.subviews.forEach { view in
                print("-1-1-1-1-1- \(self.otpFieldView.subviews.count)")
                guard let textField = view as? UITextField else { return }
                textField.textColor = AuthTheme.title
                textField.font = Constant.Font.geistRegular(size: 26)
                textField.backgroundColor = AuthTheme.fieldBackground
                textField.layer.cornerRadius = 12
                textField.layer.cornerCurve = .continuous
                textField.clipsToBounds = true
                textField.keyboardType = .numberPad
                textField.textAlignment = .center
            }
        }
    }
    
    @objc private func onClickContinue() {
        delegate?.authOTPInputViewDidTapContinue(self, otp: otpText)
    }

    @objc private func onClickBack() {
        delegate?.authOTPInputViewDidTapBack(self)
    }

    @objc private func onClickResend() {
        delegate?.authOTPInputViewDidTapResend(self)
    }

    private func makeSpacer(_ height: CGFloat) -> UIView {
        let view = UIView()
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }

    private func stylePrimaryButton(_ button: LoadingButton, title: String) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(AppColor.primaryBlackColor, for: .normal)
        button.titleLabel?.font = Constant.Font.geistMedium(size: 17)
        button.bgColor = AuthTheme.primaryButtonBg
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        button.indicator = MaterialLoadingIndicator(color: AuthTheme.primaryButtonTitle)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }

    private func setButton(_ button: LoadingButton, enabled: Bool) {
        button.isUserInteractionEnabled = enabled
        button.bgColor = enabled ? AuthTheme.primaryButtonBg : AuthTheme.disabledButtonBg
        button.setTitleColor(enabled ? AuthTheme.primaryButtonTitle : AppColor.primaryColor, for: .normal)
    }
    
    func focusFirstField() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for view in self.otpFieldView.subviews {
                if let textField = view as? UITextField {
                    textField.becomeFirstResponder()
                    break
                }
            }
        }
    }
}

extension AuthOTPInputView: OTPFieldViewDelegate {

    func shouldBecomeFirstResponderForOTP(otpTextFieldIndex index: Int) -> Bool {
        setButton(continueBtn, enabled: false)
        return true
    }

    func enteredOTP(otp: String) {
        otpText = otp
        setButton(continueBtn, enabled: otp.count == 6)
    }

    func hasEnteredAllOTP(hasEnteredAll: Bool) -> Bool {
        if hasEnteredAll {
            delegate?.authOTPInputViewDidTapContinue(self, otp: otpText)
        }
        return true
    }
}
