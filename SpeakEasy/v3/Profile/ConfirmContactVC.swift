//
//  ConfirmPhoneNumberVCDelegate.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 20/05/26.
//

import UIKit

enum ConfirmContactType {
    case phone
    case email

    var subtitle: String {
        switch self {
        case .phone:
            return "Is the number correct? You’ll receive a\nverification code there"
        case .email:
            return "Is the email correct?" // "You’ll receive a\nverification code there"
        }
    }
}

protocol ConfirmContactVCDelegate: AnyObject {
    func confirmContactVCDidConfirm(_ vc: ConfirmContactVC)
    func confirmContactVCDidGoBack(_ vc: ConfirmContactVC)
}

final class ConfirmContactVC: BaseAuthViewController {

    weak var delegate: ConfirmContactVCDelegate?

    var type: ConfirmContactType = .phone
    var displayText = ""

    private let valueLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let confirmBtn = PrimaryButton()
    private let backBtn = PrimaryButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        valueLabel.text = displayText
        valueLabel.textColor = AppColor.primaryWhiteColor
        valueLabel.font = Constant.Font.geistMedium(size: 18)
        valueLabel.textAlignment = .center
        valueLabel.numberOfLines = 2

        subtitleLabel.text = type.subtitle
        subtitleLabel.textColor = AppColor.primaryWhiteColor.withAlphaComponent(0.55)
        subtitleLabel.font = Constant.Font.geistRegular(size: 13)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        confirmBtn.configure(title: "Confirm", fontSize: 18, cornerRadius: 16)
        confirmBtn.addTarget(self, action: #selector(onConfirm), for: .touchUpInside)

        backBtn.configure(title: "Go back", fontSize: 18, cornerRadius: 16)
        backBtn.backgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.10)
        backBtn.setTitleColor(AppColor.primaryWhiteColor, for: .normal)
        backBtn.addTarget(self, action: #selector(onGoBack), for: .touchUpInside)

        contentStack.addArrangedSubview(valueLabel)
        contentStack.addArrangedSubview(subtitleLabel)
        contentStack.addArrangedSubview(Utility.main.makeSpacer(18))
        contentStack.addArrangedSubview(confirmBtn)
        contentStack.addArrangedSubview(backBtn)
    }

    @objc private func onConfirm() {
        delegate?.confirmContactVCDidConfirm(self)
    }

    @objc private func onGoBack() {
        delegate?.confirmContactVCDidGoBack(self)
    }
}
