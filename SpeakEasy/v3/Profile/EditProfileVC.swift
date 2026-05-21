//
//  EditProfileVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 19/05/26.
//


import UIKit
import SDWebImage

final class EditProfileVC: UIViewController {
    
    private let backBtn = AppIconButton()
    private let titleLabel = UILabel()
    
    private let avatarContainer = UIView()
    private let imageView = UIImageView()
    private let firstNameLetter = UILabel()
    private let addPhotoBtn = UIButton(type: .system)
    
    private let firstNameView = FloatingInputView(title: "First name")
    private let lastNameView = FloatingInputView(title: "Last name")
    private let dobView = FloatingInputView(title: "Date of birth")
    
    private var firstNameTF: UITextField { firstNameView.textField }
    private var lastNameTF: UITextField { lastNameView.textField }
    private var dobTF: UITextField { dobView.textField }
    
    private let genderControl = UIControl()
    private let genderTitleLabel = UILabel()
    private let genderValueLabel = UILabel()
    private let genderArrow = UIImageView()
    
    private var genderValueLabelBottomConstraint: NSLayoutConstraint?
    private var genderValueLabelCenterYConstraint: NSLayoutConstraint?
    
    private let saveBtn = PrimaryButton()
    
    private let presenter = OnBoardingPresenter()
    private var gender = "MALE"
    
    private var selectedProfileImage: UIImage?
    private var didChangeProfileImage = false
    
    private var originalFirstName = ""
    private var originalLastName = ""
    private var originalDOB = ""
    private var originalGender = ""
    private var originalImageUrl = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardDismiss()
        loadUserData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.applyScreenBgGradient()
        avatarContainer.layer.cornerRadius = avatarContainer.bounds.height / 2
        imageView.layer.cornerRadius = imageView.bounds.height / 2
        addPhotoBtn.layer.cornerRadius = addPhotoBtn.bounds.height / 2
    }
    
    private func setupUI() {
        setupNav()
        setupAvatar()
        setupFields()
        setupSaveButton()
        setupConstraints()
    }
    
    private func setupNav() {
        backBtn.iconTypeValue = AppIconType.leftSideBack.rawValue
        backBtn.iconSize = 20
        backBtn.buttonSize = 40
        backBtn.iconTintColor = .white
        backBtn.addTarget(self, action: #selector(onClickBack), for: .touchUpInside)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backBtn)
        
        titleLabel.text = "Edit profile"
        titleLabel.textColor = AppColor.primaryWhiteColor
        titleLabel.font = Constant.Font.geistMedium(size: 22)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
    }
    
    private func setupAvatar() {
        avatarContainer.backgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.08)
        avatarContainer.clipsToBounds = true
        avatarContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(avatarContainer)

        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(onClickAddPhoto))
        avatarContainer.addGestureRecognizer(avatarTap)
        avatarContainer.isUserInteractionEnabled = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addSubview(imageView)
        
        firstNameLetter.textColor = .white
        firstNameLetter.font = Constant.Font.geistMedium(size: 40)
        firstNameLetter.textAlignment = .center
        firstNameLetter.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addSubview(firstNameLetter)
        
        addPhotoBtn.setImage(UIImage(systemName: "plus"), for: .normal)
        addPhotoBtn.tintColor = .white
        addPhotoBtn.backgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.12)
        addPhotoBtn.translatesAutoresizingMaskIntoConstraints = false
        addPhotoBtn.addTarget(self, action: #selector(onClickAddPhoto), for: .touchUpInside)

        let addPhotoBtnBgView = LiquidGlassBackgroundView()
        addPhotoBtnBgView.borderWidth = 0.5
        addPhotoBtnBgView.overrideBackgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.12)
        addPhotoBtn.addSubview(addPhotoBtnBgView)
        view.addSubview(addPhotoBtn)
    }
    
    private func setupFields() {
        view.addSubview(firstNameView)
        view.addSubview(lastNameView)
        view.addSubview(dobView)

        dobTF.inputView = UIView()
        dobTF.tintColor = .clear
        dobView.addTarget(self, action: #selector(onClickDOB), for: .touchUpInside)
        
        firstNameTF.addTarget(self, action: #selector(profileFieldDidChange), for: .editingChanged)
        lastNameTF.addTarget(self, action: #selector(profileFieldDidChange), for: .editingChanged)
        dobTF.addTarget(self, action: #selector(profileFieldDidChange), for: .editingChanged)

        setupGenderView()
    }
    
    private func setupTextField(_ textField: UITextField, placeholder: String) {
        textField.backgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.05)
        textField.textColor = AppColor.primaryWhiteColor
        textField.font = Constant.Font.geistRegular(size: 18)
        textField.layer.cornerRadius = 16
        textField.layer.cornerCurve = .continuous
        textField.clipsToBounds = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: AppColor.primaryWhiteColor.withAlphaComponent(0.35)]
        )
        
        let left = UIView(frame: CGRect(x: 0, y: 0, width: 26, height: 1))
        textField.leftView = left
        textField.leftViewMode = .always
        
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        view.addSubview(textField)
    }
    
    private func setupGenderView() {
        genderControl.backgroundColor =  AppColor.primaryWhiteColor.withAlphaComponent(0.05)
        genderControl.layer.cornerRadius = 16
        genderControl.layer.cornerCurve = .continuous
        genderControl.clipsToBounds = true
        genderControl.addTarget(self, action: #selector(onClickGender), for: .touchUpInside)
        genderControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(genderControl)
        
        genderTitleLabel.text = "Gender"
        genderTitleLabel.textColor = AppColor.primaryWhiteColor.withAlphaComponent(0.35)
        genderTitleLabel.font = Constant.Font.geistRegular(size: 16)
        genderTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        genderControl.addSubview(genderTitleLabel)
        
        genderValueLabel.textColor = AppColor.primaryWhiteColor
        genderValueLabel.font = Constant.Font.geistRegular(size: 18)
        genderValueLabel.translatesAutoresizingMaskIntoConstraints = false
        genderControl.addSubview(genderValueLabel)
        
        genderArrow.image = UIImage(systemName: "chevron.down")
        genderArrow.tintColor = AppColor.primaryWhiteColor.withAlphaComponent(0.35)
        genderArrow.translatesAutoresizingMaskIntoConstraints = false
        genderControl.addSubview(genderArrow)
        
        genderValueLabelBottomConstraint = genderValueLabel.bottomAnchor.constraint(
            equalTo: genderControl.bottomAnchor,
            constant: -16
        )

        genderValueLabelCenterYConstraint = genderValueLabel.centerYAnchor.constraint(
            equalTo: genderControl.centerYAnchor
        )
        
        NSLayoutConstraint.activate([
            genderTitleLabel.leadingAnchor.constraint(equalTo: genderControl.leadingAnchor, constant: 26),
            genderTitleLabel.topAnchor.constraint(equalTo: genderControl.topAnchor, constant: 14),
            
            genderValueLabel.leadingAnchor.constraint(equalTo: genderTitleLabel.leadingAnchor),
            genderValueLabelBottomConstraint!,
            
            genderArrow.trailingAnchor.constraint(equalTo: genderControl.trailingAnchor, constant: -20),
            genderArrow.centerYAnchor.constraint(equalTo: genderControl.centerYAnchor)
        ])
    }
    
    private func setupSaveButton() {
        saveBtn.configure(title: "Save changes", fontSize: 18, cornerRadius: 16)
        saveBtn.addTarget(self, action: #selector(onClickSave), for: .touchUpInside)
        view.addSubview(saveBtn)

        updateSaveButtonState()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            backBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backBtn.widthAnchor.constraint(equalToConstant: 40),
            backBtn.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            avatarContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 52),
            avatarContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarContainer.widthAnchor.constraint(equalToConstant: 100),
            avatarContainer.heightAnchor.constraint(equalToConstant: 100),
            
            imageView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor),
            
            firstNameLetter.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            firstNameLetter.centerYAnchor.constraint(equalTo: avatarContainer.centerYAnchor),
            
            addPhotoBtn.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor, constant: 4),
            addPhotoBtn.topAnchor.constraint(equalTo: avatarContainer.topAnchor, constant: -4),
            addPhotoBtn.widthAnchor.constraint(equalToConstant: 32),
            addPhotoBtn.heightAnchor.constraint(equalToConstant: 32),
            
            firstNameView.topAnchor.constraint(equalTo: avatarContainer.bottomAnchor, constant: 40),
            firstNameView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            firstNameView.heightAnchor.constraint(equalToConstant: 80),
            
            lastNameView.leadingAnchor.constraint(equalTo: firstNameView.trailingAnchor, constant: 8),
            lastNameView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            lastNameView.topAnchor.constraint(equalTo: firstNameView.topAnchor),
            lastNameView.widthAnchor.constraint(equalTo: firstNameView.widthAnchor),
            lastNameView.heightAnchor.constraint(equalTo: firstNameView.heightAnchor),
            
            genderControl.topAnchor.constraint(equalTo: firstNameView.bottomAnchor, constant: 8),
            genderControl.leadingAnchor.constraint(equalTo: firstNameView.leadingAnchor),
            genderControl.trailingAnchor.constraint(equalTo: lastNameView.trailingAnchor),
            genderControl.heightAnchor.constraint(equalToConstant: 80),
            
            dobView.topAnchor.constraint(equalTo: genderControl.bottomAnchor, constant: 8),
            dobView.leadingAnchor.constraint(equalTo: genderControl.leadingAnchor),
            dobView.trailingAnchor.constraint(equalTo: genderControl.trailingAnchor),
            dobView.heightAnchor.constraint(equalToConstant: 80),
            
            saveBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            saveBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            saveBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -28),
            saveBtn.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func onClickAddPhoto() {
        view.endEditing(true)

        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    private func loadUserData() {
        let user = UserDefault.shared.user

        firstNameView.text = user?.firstName
        lastNameView.text = user?.lastName

        if let dob = user?.dateOfBirth,
           !dob.isEmpty,
           dob != "No date Found" {

            let formattedDOB = dob.convertDateFormat(
                from: .YYYYMMDD,
                to: .MMDDYYYY,
                isUTC: false
            )

            dobView.text = formattedDOB == "No date Found" ? nil : formattedDOB
        } else {
            dobView.text = nil
        }

        let userGender = user?.gender.capitalized ?? ""

        if userGender.isEmpty || userGender == "Unassigned" {
            gender = ""
            setGenderEmpty()
        } else {
            gender = userGender.uppercased()
            setGenderSelected(userGender)
        }

        let imageUrl = user?.image.key ?? ""
        let firstLetter = user?.firstName.first ?? "P"

        if !imageUrl.isEmpty {
            imageView.isHidden = false
            firstNameLetter.isHidden = true
            imageView.sd_setImage(
                with: URL(string: imageUrl),
                placeholderImage: UIImage(resource: .profileBgPlaceholder)
            )
        } else {
            imageView.isHidden = false
            imageView.image = UIImage(resource: .profileBg)
            firstNameLetter.isHidden = false
            firstNameLetter.text = String(firstLetter).uppercased()
        }
        
        originalFirstName = firstNameTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        originalLastName = lastNameTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        originalDOB = dobTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        originalGender = gender
        originalImageUrl = UserDefault.shared.user?.image.key ?? ""

        didChangeProfileImage = false
        updateSaveButtonState()
    }
    
    private func setGenderEmpty() {
        genderTitleLabel.isHidden = true
        genderValueLabel.text = "Select gender"
        genderValueLabel.textColor = AppColor.primaryWhiteColor.withAlphaComponent(0.35)

        genderValueLabelBottomConstraint?.isActive = false
        genderValueLabelCenterYConstraint?.isActive = true
    }

    private func setGenderSelected(_ value: String) {
        genderTitleLabel.isHidden = false
        genderValueLabel.text = value.capitalized
        genderValueLabel.textColor = AppColor.primaryWhiteColor

        genderValueLabelCenterYConstraint?.isActive = false
        genderValueLabelBottomConstraint?.isActive = true
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        textField.layer.borderWidth = 0
        textField.layer.borderColor = UIColor.clear.cgColor
    }
    
    @objc private func onClickBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func onClickDOB() {
        view.endEditing(true)
        Navigate.to.presentDateSelectionBottomSheet(
            self,
            date: self.dobTF.text?.toDate(withFormat: .MMDDYYYY, isUTC: false)
        )
    }
    
    @objc private func onClickGender() {
        view.endEditing(true)
        let vc = GenderSelectionBottomSheetVC(selectedGender: gender)
        vc.delegate = self
        present(vc, animated: false)
    }
    
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func profileFieldDidChange() {
        clearValidationUI()
        updateSaveButtonState()
    }

    private func updateSaveButtonState() {
        let currentFirstName = firstNameTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let currentLastName = lastNameTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let currentDOB = dobTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let hasChanges =
            currentFirstName != originalFirstName ||
            currentLastName != originalLastName ||
            currentDOB != originalDOB ||
            gender != originalGender ||
            didChangeProfileImage

        saveBtn.isUserInteractionEnabled = hasChanges

        UIView.animate(withDuration: 0.2) {
            self.saveBtn.alpha = hasChanges ? 1.0 : 0.45
        }
    }
    
    @objc private func endEditing() {
        view.endEditing(true)
    }
    
    @objc private func onClickSave() {
        view.endEditing(true)
        guard validate() else { return }

        if didChangeProfileImage, let image = selectedProfileImage {
            uploadProfileAndSave(image: image)
        } else {
            saveProfile(imageDetail: nil)
        }
    }
    
    private func uploadProfileAndSave(image: UIImage) {
        saveBtn.startLoading()
        view.isUserInteractionEnabled = false

        presenter.uploadPhotoApi(image: image) { [weak self] imgUrl, isSuccess in
            guard let self else { return }

            if isSuccess {
                let imgDetail = ImageDetail(
                    key: imgUrl,
                    name: "\(UserDefault.shared.user?.phone ?? "")",
                    description: "profile picture"
                )

                self.saveProfile(imageDetail: imgDetail)
            } else {
                self.saveBtn.stopLoading()
                self.view.isUserInteractionEnabled = true

                Alert.showAlertSheet(
                    style: .alert,
                    title: "Image not uploaded",
                    message: ""
                )
            }
        }
    }

    private func saveProfile(imageDetail: ImageDetail?) {
        var date = dobTF.text?.convertDateFormat(from: .MMDDYYYY, to: .YYYYMMDD, isUTC: false) ?? ""
        if date == "No date Found" { date = "" }

        if !didChangeProfileImage {
            saveBtn.startLoading()
            view.isUserInteractionEnabled = false
        }

        let completion: (Bool, String?) -> Void = { [weak self] isSuccess, errorMsg in
            guard let self else { return }

            self.saveBtn.stopLoading()
            self.view.isUserInteractionEnabled = true

            if isSuccess {
                UserDefault.shared.user?.firstName = self.firstNameTF.text ?? ""
                UserDefault.shared.user?.lastName = self.lastNameTF.text ?? ""
                UserDefault.shared.user?.dateOfBirth = date
                UserDefault.shared.user?.gender = self.gender

                if let imageDetail {
                    UserDefault.shared.user?.image = imageDetail
                }

                if UserDefault.shared.user?.email != nil && UserDefault.shared.user?.email != "" {
                    UserDefault.shared.user?.isProfileCompleted = true
                }

                ProfileUpdateNotifier.post(
                    firstName: self.firstNameTF.text ?? "",
                    lastName: self.lastNameTF.text ?? "",
                    imageUrl: UserDefault.shared.user?.image.key
                )
                
                self.navigationController?.popViewController(animated: true)
            } else {
                Alert.showAlertSheet(
                    style: .alert,
                    title: errorMsg ?? Constant.String.somethingWrong,
                    message: ""
                )
            }
        }

        if let imageDetail {
            presenter.editUserProfileApi(
                fName: firstNameTF.text ?? "",
                lName: lastNameTF.text ?? "",
                nickName: "",
                dob: date,
                gender: gender,
                image: imageDetail,
                completion: completion
            )
        } else {
            presenter.editUserProfileApi(
                fName: firstNameTF.text ?? "",
                lName: lastNameTF.text ?? "",
                nickName: "",
                dob: date,
                gender: gender,
                completion: completion
            )
        }
    }
        
    private func validate() -> Bool {
        clearValidationUI()
        
        let firstName = firstNameTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lastName = lastNameTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let dob = dobTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if firstName.isEmpty {
            firstNameView.showError()
            Alert.showAlertSheet(style: .alert, title: "Please enter first name.", message: "")
            return false
        }
        
        if lastName.isEmpty {
            lastNameView.showError()
            Alert.showAlertSheet(style: .alert, title: "Please enter last name.", message: "")
            return false
        }
        
        if gender.isEmpty {
            genderControl.layer.borderWidth = 1
            genderControl.layer.borderColor = UIColor.systemRed.cgColor
            genderControl.shake()
            Alert.showAlertSheet(style: .alert, title: "Please select gender.", message: "")
            return false
        }
        
        if dob.isEmpty {
            dobView.showError()
            Alert.showAlertSheet(style: .alert, title: "Please select date of birth.", message: "")
            return false
        }
        
        return true
    }

    private func clearValidationUI() {
        firstNameView.clearError()
        lastNameView.clearError()
        dobView.clearError()
        
        genderControl.layer.borderWidth = 0
        genderControl.layer.borderColor = UIColor.clear.cgColor
    }

    private func showFieldError(_ textField: UITextField, message: String) {
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemRed.cgColor
        textField.shake()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Alert.showAlertSheet(style: .alert, title: message, message: "")
    }

    private func showGenderError(message: String) {
        genderControl.layer.borderWidth = 1
        genderControl.layer.borderColor = UIColor.systemRed.cgColor
        genderControl.shake()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Alert.showAlertSheet(style: .alert, title: message, message: "")
    }
}

extension EditProfileVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let image =
            info[.editedImage] as? UIImage ??
            info[.originalImage] as? UIImage

        if let image {
            selectedProfileImage = image
            didChangeProfileImage = true

            imageView.isHidden = false
            firstNameLetter.isHidden = true
            imageView.image = image
            updateSaveButtonState()
        }

        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension EditProfileVC: GenderSelectionBottomSheetDelegate {
    func genderSelectionBottomSheet(_ vc: GenderSelectionBottomSheetVC, didSelect gender: String) {
        self.gender = gender.uppercased()
        setGenderSelected(gender)
        clearValidationUI()
        updateSaveButtonState()
    }
}

extension EditProfileVC: DateSelectionDelegate {
    func selectedDate(date: Date) {
        dobTF.text = date.string(format: .MMDDYYYY, isUTC: false)
        dobView.text = dobTF.text
        clearValidationUI()
        updateSaveButtonState()
    }
}
