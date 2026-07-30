//
//  ProfileInfoVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 13/05/26.
//

import UIKit

final class ProfileInfoVC: UIViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private var backBtn = AppIconButton()
    private var titleLabel = UILabel()
    private var subtitleLabel = UILabel()

    private let firstNameTF = UITextField()
    private let lastNameTF = UITextField()
    private let emailTF = UITextField()
    private let dobTF = UITextField()

    private let genderControl = UIControl()
    private let genderLabel = UILabel()
    private let genderArrow = UIImageView()

    private let continueBtn = PrimaryButton()

    private let profileService = ProfileService()
    private var gender = "MALE"

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardDismiss()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.applyScreenBgGradient()
    }

    private func setupUI() {
        scrollView.keyboardDismissMode = .interactive
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        setupBackButton()
        setupHeader()
        setupFields()
        setupGenderView()
        setupContinueButton()
        setupConstraints()
    }

    private func setupBackButton() {
        backBtn.iconTypeValue = AppIconType.leftSideBack.rawValue
        backBtn.iconSize = 22
        backBtn.buttonSize = 50
        backBtn.iconTintColor = .white
        backBtn.addTarget(self, action: #selector(onClickBack), for: .touchUpInside)
        view.addSubview(backBtn)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupHeader() {
        titleLabel = Utility.main.makeLabel("Additional info", size: 32, textAlignment: .left)
        subtitleLabel = Utility.main.makeLabel("Enter your first, last name and email address\nto continue to ticket purchase", textAlignment: .left, font: Constant.Font.geistRegular(size: 13))
        subtitleLabel.textColor = AuthTheme.subtitleGrayColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
    }

    private func setupFields() {
        setupTextField(firstNameTF, placeholder: "First name")
        setupTextField(lastNameTF, placeholder: "Last name")
        setupTextField(emailTF, placeholder: "Email address")
        setupTextField(dobTF, placeholder: "Date of Birth")
        
        dobTF.inputView = UIView()
        dobTF.tintColor = .clear

        let dobTap = UITapGestureRecognizer(target: self, action: #selector(onClickDOB))
        dobTF.addGestureRecognizer(dobTap)
        dobTF.isUserInteractionEnabled = true

        emailTF.keyboardType = .emailAddress
        emailTF.autocapitalizationType = .none
    }

    private func setupTextField(_ textField: UITextField, placeholder: String) {
        textField.backgroundColor = AuthTheme.fieldBackground
        textField.textColor = AppColor.primaryWhiteColor
        textField.tintColor = AppColor.primaryWhiteColor
        textField.font = Constant.Font.geistRegular(size: 16)
        textField.layer.cornerRadius = 14
        textField.layer.cornerCurve = .continuous
        textField.clipsToBounds = true
        textField.translatesAutoresizingMaskIntoConstraints = false

        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: AppColor.primaryWhiteColor.withAlphaComponent(0.32),
                .font: Constant.Font.geistRegular(size: 16)
            ]
        )

        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 1))
        textField.leftView = leftView
        textField.leftViewMode = .always

        contentView.addSubview(textField)
    }

    private func setupGenderView() {
        genderControl.backgroundColor = AuthTheme.fieldBackground
        genderControl.layer.cornerRadius = 14
        genderControl.layer.cornerCurve = .continuous
        genderControl.clipsToBounds = true
        genderControl.addTarget(self, action: #selector(onClickGender), for: .touchUpInside)
        genderControl.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(genderControl)

        genderLabel.text = "Select Gender"
        genderLabel.textColor = AppColor.primaryWhiteColor
        genderLabel.font = Constant.Font.geistRegular(size: 16)
        genderLabel.translatesAutoresizingMaskIntoConstraints = false
        genderControl.addSubview(genderLabel)

        genderArrow.transform = CGAffineTransform(rotationAngle: .pi)
        genderArrow.image = UIImage(systemName: "triangle.fill")
        genderArrow.tintColor = AppColor.primaryWhiteColor.withAlphaComponent(0.72)
        genderArrow.contentMode = .scaleAspectFit
        genderArrow.translatesAutoresizingMaskIntoConstraints = false
        genderControl.addSubview(genderArrow)

        NSLayoutConstraint.activate([
            genderLabel.leadingAnchor.constraint(equalTo: genderControl.leadingAnchor, constant: 20),
            genderLabel.centerYAnchor.constraint(equalTo: genderControl.centerYAnchor),

            genderArrow.trailingAnchor.constraint(equalTo: genderControl.trailingAnchor, constant: -20),
            genderArrow.centerYAnchor.constraint(equalTo: genderControl.centerYAnchor),
            genderArrow.widthAnchor.constraint(equalToConstant: 10),
            genderArrow.heightAnchor.constraint(equalToConstant: 10)
        ])
    }

    private func setupContinueButton() {
        continueBtn.configure(title: "Continue", fontSize: 18, cornerRadius: 14)
        continueBtn.addTarget(
            self,
            action: #selector(onClickSave),
            for: .touchUpInside
        )
        
        contentView.addSubview(continueBtn)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: backBtn.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            backBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26),
            backBtn.widthAnchor.constraint(equalToConstant: 52),
            backBtn.heightAnchor.constraint(equalToConstant: 52),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 26),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            firstNameTF.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            firstNameTF.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            firstNameTF.heightAnchor.constraint(equalToConstant: 52),

            lastNameTF.leadingAnchor.constraint(equalTo: firstNameTF.trailingAnchor, constant: 8),
            lastNameTF.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            lastNameTF.topAnchor.constraint(equalTo: firstNameTF.topAnchor),
            lastNameTF.widthAnchor.constraint(equalTo: firstNameTF.widthAnchor),
            lastNameTF.heightAnchor.constraint(equalTo: firstNameTF.heightAnchor),

            emailTF.topAnchor.constraint(equalTo: firstNameTF.bottomAnchor, constant: 8),
            emailTF.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            emailTF.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            emailTF.heightAnchor.constraint(equalToConstant: 52),

            dobTF.topAnchor.constraint(equalTo: emailTF.bottomAnchor, constant: 8),
            dobTF.leadingAnchor.constraint(equalTo: emailTF.leadingAnchor),
            dobTF.trailingAnchor.constraint(equalTo: emailTF.trailingAnchor),
            dobTF.heightAnchor.constraint(equalToConstant: 52),

            genderControl.topAnchor.constraint(equalTo: dobTF.bottomAnchor, constant: 8),
            genderControl.leadingAnchor.constraint(equalTo: emailTF.leadingAnchor),
            genderControl.trailingAnchor.constraint(equalTo: emailTF.trailingAnchor),
            genderControl.heightAnchor.constraint(equalToConstant: 52),

            continueBtn.topAnchor.constraint(equalTo: genderControl.bottomAnchor, constant: 10),
            continueBtn.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            continueBtn.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            continueBtn.heightAnchor.constraint(equalToConstant: 52),
            continueBtn.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -28)
        ])
    }

    private func loadUserData() {
        firstNameTF.text = UserDefault.shared.user?.firstName
        lastNameTF.text = UserDefault.shared.user?.lastName
        emailTF.text = UserDefault.shared.user?.email

        if let dob = UserDefault.shared.user?.dateOfBirth, !dob.isEmpty {
            dobTF.text = dob.convertDateFormat(from: .YYYYMMDD, to: .MMDDYYYY, isUTC: false)
        } else {
            dobTF.text = nil
        }

        let userGender = UserDefault.shared.user?.gender.capitalized ?? ""

        if userGender.isEmpty || userGender == "Unassigned" {
            gender = "MALE"
            genderLabel.text = "Select Gender"
        } else {
            gender = userGender.uppercased()
            genderLabel.text = userGender
        }
    }

    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func endEditing() {
        view.endEditing(true)
    }

    @objc private func onClickBack() {
        Navigate.to.back(self)
    }

    @objc private func onClickDOB() {
        view.endEditing(true)

        let vc = DateOfBirthSelectionVC(
            date: dobTF.text?.toDate(withFormat: .MMDDYYYY, isUTC: false)
        )
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func onClickGender() {
        view.endEditing(true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            let vc = GenderSelectionBottomSheetVC(selectedGender: self.gender)
            vc.delegate = self
            self.present(vc, animated: false)
        }
    }
    
    @objc private func onClickSave() {
        view.endEditing(true)
        
        guard validateForm() else { return }
        
        var date = dobTF.text?.convertDateFormat(from: .MMDDYYYY, to: .YYYYMMDD, isUTC: false) ?? ""
        if date == "No date Found" { date = "" }
        
        continueBtn.startLoading()
        
        profileService.updateProfile(
            firstName: firstNameTF.text ?? "",
            lastName: lastNameTF.text ?? "",
            nickName: "",
            email: self.emailTF.text ?? "",
            dob: date,
            gender: gender,
            isProfileCompleted: true
        ) { [weak self] isSuccess, errorMsg in
            guard let self else { return }

            self.continueBtn.stopLoading()

            if isSuccess {
                UserDefault.shared.user?.firstName = self.firstNameTF.text ?? ""
                UserDefault.shared.user?.lastName = self.lastNameTF.text ?? ""
                UserDefault.shared.user?.dateOfBirth = date
                UserDefault.shared.user?.gender = self.gender
                UserDefault.shared.user?.isProfileCompleted = true
                UserDefault.shared.user?.email = self.emailTF.text ?? ""
                Navigate.to.notificationPermissionVC(self)
            } else {
                Alert.showAlertSheet(
                    style: .alert,
                    title: errorMsg ?? Constant.String.somethingWrong,
                    message: ""
                )
            }
        }
    }
}

extension ProfileInfoVC: GenderSelectionBottomSheetDelegate {
    func genderSelectionBottomSheet(_ vc: GenderSelectionBottomSheetVC, didSelect gender: String) {
        self.gender = gender.uppercased()
        self.genderLabel.text = gender.capitalized
    }
}

extension ProfileInfoVC: DateSelectionDelegate {
    func selectedDate(date: Date) {
        dobTF.text = date.string(format: .MMDDYYYY, isUTC: false)
    }
}

extension ProfileInfoVC {
    
    private func validateForm() -> Bool {
        let firstName = firstNameTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lastName = lastNameTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email = emailTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let dob = dobTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isGenderSelected = genderLabel.text != "Select Gender"
        
        clearValidationUI()
        
        if firstName.isEmpty {
            showFieldError(firstNameTF, message: "Please enter your first name.")
            return false
        }
        
        if lastName.isEmpty {
            showFieldError(lastNameTF, message: "Please enter your last name.")
            return false
        }
        
        if email.isEmpty {
            showFieldError(emailTF, message: "Please enter your email address.")
            return false
        }
        
        if !isValidEmail(email) {
            showFieldError(emailTF, message: "Please enter a valid email address.")
            return false
        }
        
        if dob.isEmpty {
            showFieldError(dobTF, message: "Please select your date of birth.")
            return false
        }
        
        if !isGenderSelected {
            showGenderError(message: "Please select your gender.")
            return false
        }
        
        return true
    }
    
    private func clearValidationUI() {
        [firstNameTF, lastNameTF, emailTF, dobTF].forEach {
            $0.layer.borderWidth = 0
            $0.layer.borderColor = UIColor.clear.cgColor
        }
        
        genderControl.layer.borderWidth = 0
        genderControl.layer.borderColor = UIColor.clear.cgColor
    }
    
    private func showFieldError(_ textField: UITextField, message: String) {
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemRed.cgColor
        
        AppHaptic.error()
        
        textField.shake()
        scrollToView(textField)
        
        Alert.showAlertSheet(
            style: .alert,
            title: message,
            message: ""
        )
    }
    
    private func showGenderError(message: String) {
        genderControl.layer.borderWidth = 1
        genderControl.layer.borderColor = UIColor.systemRed.cgColor
        
        AppHaptic.error()
        
        genderControl.shake()
        scrollToView(genderControl)
        
        Alert.showAlertSheet(
            style: .alert,
            title: message,
            message: ""
        )
    }
    
    private func scrollToView(_ targetView: UIView) {
        let rect = targetView.convert(targetView.bounds, to: scrollView)
        scrollView.scrollRectToVisible(
            rect.insetBy(dx: 0, dy: -24),
            animated: true
        )
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
}

extension UIView {
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.values = [-8, 8, -6, 6, -3, 3, 0]
        animation.duration = 0.32
        layer.add(animation, forKey: "shake")
    }
}
