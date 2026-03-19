//
//  SignUpViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 28/02/26.
//

import UIKit

final class SignUpViewController: UIViewController {

    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var emailTextFeild: UITextField!
    @IBOutlet weak var errorLbl: UILabel!
    @IBOutlet weak var textFeildView: UIView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var hintLbl: UILabel!
    @IBOutlet weak var nextBtn: UIButton!

    private enum Step: Int, CaseIterable {
        case email = 0
        case dob = 1
        case gender = 2
    }

    private var step: Step = .email {
        didSet { configureForCurrentStep() }
    }
    
    private var enteredEmail: String?
    private var selectedDOB: Date?
    private var selectedGender: String?

    private let genders = ["Female", "Male", "Non-binary", "Prefer not to say"]

    private lazy var dobPicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.preferredDatePickerStyle = .wheels
        picker.datePickerMode = .date
        picker.maximumDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) // basic safety
        picker.addTarget(self, action: #selector(didChangeDOB), for: .valueChanged)
        return picker
    }()

    private lazy var genderPicker: UIPickerView = {
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        return picker
    }()

    private lazy var accessoryToolbar: UIToolbar = {
        let tb = UIToolbar()
        tb.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneTapped))
        tb.items = [flex, done]
        return tb
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupTextField()
        configureForCurrentStep()
    }

    private func setupUI() {
        errorLbl.isHidden = true

        textFeildView.layer.cornerRadius = 10
        textFeildView.layer.borderWidth = 1
        textFeildView.layer.borderColor = UIColor(white: 1.0, alpha: 0.35).cgColor

        nextBtn.layer.cornerRadius = nextBtn.bounds.height / 2
        nextBtn.clipsToBounds = true
    }

    private func setupTextField() {
        emailTextFeild.delegate = self
        emailTextFeild.inputAccessoryView = accessoryToolbar
        emailTextFeild.autocorrectionType = .no
        emailTextFeild.spellCheckingType = .no
    }

    private func configureForCurrentStep() {
        hideError()

        switch step {
        case .email:
            titleLbl.text = "What’s your email?"
            hintLbl.text = "Enter a valid email address"
            emailTextFeild.placeholder = "Email"
            emailTextFeild.text = enteredEmail ?? ""
            emailTextFeild.keyboardType = .emailAddress
            emailTextFeild.textContentType = .emailAddress
            emailTextFeild.inputView = nil
            emailTextFeild.reloadInputViews()
            emailTextFeild.becomeFirstResponder()

            backBtn.isHidden = true
            nextBtn.setTitle("Next", for: .normal)

        case .dob:
            titleLbl.text = "What’s your date of birth?"
            hintLbl.text = "You need to be 18 years or older"
            emailTextFeild.placeholder = "Select date"
            emailTextFeild.keyboardType = .default
            emailTextFeild.textContentType = .none
            emailTextFeild.inputView = dobPicker
            emailTextFeild.reloadInputViews()

            if let selectedDOB {
                emailTextFeild.text = formatDOB(selectedDOB)
                dobPicker.date = selectedDOB
            } else {
                let date = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
                selectedDOB = date
                dobPicker.date = date
                emailTextFeild.text = formatDOB(date)
            }

            emailTextFeild.becomeFirstResponder()

            backBtn.isHidden = false
            nextBtn.setTitle("Next", for: .normal)

        case .gender:
            titleLbl.text = "What’s your gender?"
            hintLbl.text = ""
            emailTextFeild.placeholder = "Select gender"
            emailTextFeild.keyboardType = .default
            emailTextFeild.textContentType = .none
            emailTextFeild.inputView = genderPicker
            emailTextFeild.reloadInputViews()

            if let selectedGender,
               let idx = genders.firstIndex(of: selectedGender) {
                genderPicker.selectRow(idx, inComponent: 0, animated: false)
                emailTextFeild.text = selectedGender
            } else {
                selectedGender = genders.first
                genderPicker.selectRow(0, inComponent: 0, animated: false)
                emailTextFeild.text = selectedGender
            }

            emailTextFeild.becomeFirstResponder()

            backBtn.isHidden = false
            nextBtn.setTitle("Next", for: .normal)
        }
    }

    private func validateCurrentStep() -> Bool {
        hideError()

        switch step {
        case .email:
            let email = (emailTextFeild.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if email.isEmpty {
                showError("Please enter your email.")
                return false
            }
            if !isValidEmail(email) {
                showError("This email is invalid. Follow this format: jane@example.com")
                return false
            }
            enteredEmail = email
            return true

        case .dob:
            let dob = selectedDOB ?? dobPicker.date
            selectedDOB = dob

            if !is18Plus(dob) {
                showError("You need to be 18 years or older.")
                return false
            }
            emailTextFeild.text = formatDOB(dob)
            return true

        case .gender:
            let gen = (emailTextFeild.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if gen.isEmpty {
                showError("Please select a gender.")
                return false
            }
            selectedGender = gen
            return true
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    private func is18Plus(_ dob: Date) -> Bool {
        let cal = Calendar.current
        guard let eighteenYearsAgo = cal.date(byAdding: .year, value: -18, to: Date()) else { return false }
        return dob <= eighteenYearsAgo
    }

    private func formatDOB(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMMM d, yyyy"
        return df.string(from: date)
    }

    private func showError(_ msg: String) {
        errorLbl.text = msg
        errorLbl.isHidden = false
        textFeildView.layer.borderColor = UIColor.red.withAlphaComponent(0.8).cgColor
    }

    private func hideError() {
        errorLbl.isHidden = true
        textFeildView.layer.borderColor = UIColor(white: 1.0, alpha: 0.35).cgColor
    }

    @IBAction func onClickbackBtn(_ sender: Any) {
        hideError()
        switch step {
        case .email:
            break
        case .dob:
            step = .email
        case .gender:
            step = .dob
        }
    }

    @IBAction func onClickNextBtn(_ sender: Any) {
        guard validateCurrentStep() else { return }

        switch step {
        case .email:
            step = .dob
        case .dob:
            step = .gender
        case .gender:
            Navigate.to.signUpDetailsViewControllerVc(self)
        }
    }

    @objc private func didChangeDOB() {
        selectedDOB = dobPicker.date
        emailTextFeild.text = formatDOB(dobPicker.date)
        hideError()
    }

    @objc private func doneTapped() {
        view.endEditing(true)
    }
}

extension SignUpViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if step == .email {
            onClickNextBtn(nextBtn as Any)
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}

extension SignUpViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        genders.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        genders[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let gen = genders[row]
        selectedGender = gen
        emailTextFeild.text = gen
        hideError()
    }
}
