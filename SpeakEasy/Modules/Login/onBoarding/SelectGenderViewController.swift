//
//  SelectGenderViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 16/12/22.
//

import UIKit
// TODO: check if being used anywhere or remove
final class SelectGenderViewController: UIViewController {

    @IBOutlet weak var manSelectionView: UIView!
    @IBOutlet weak var womenSelectionView: UIView!
    @IBOutlet weak var otherSelectionView: UIView!
    @IBOutlet weak var manRedioBtn: UIButton!
    @IBOutlet weak var womenRedioBtn: UIButton!
    @IBOutlet weak var otherRedioBtn: UIButton!
    @IBOutlet weak var continueBtn: UIButton!
    
    private var onBoardingDelegate = OnBoardingPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(onClickManView))
        manSelectionView.addGestureRecognizer(gesture)
        let gesture2 = UITapGestureRecognizer(target: self, action: #selector(onClickWomanView))
        womenSelectionView.addGestureRecognizer(gesture2)
        let gesture3 = UITapGestureRecognizer(target: self, action: #selector(onClickOtherView))
        otherSelectionView.addGestureRecognizer(gesture3)
        manSelectionView.tag = 0
        womenSelectionView.tag = 0
        otherSelectionView.tag = 0
        
        continueBtn.isUserInteractionEnabled = false
        continueBtn.alpha = 0.5
        switch UserDefault.shared.user?.gender.capitalized {
        case "Male":
            onClickManView()
        case "Female":
            onClickWomanView()
        case "Other":
            onClickOtherView()
        default:
            break
        }
    }
    
    @objc private func onClickManView() {
        manRedioBtn.setImage(Constant.Icon.radioClick, for: .normal)
        womenRedioBtn.setImage(Constant.Icon.radioIcon, for: .normal)
        otherRedioBtn.setImage(Constant.Icon.radioIcon, for: .normal)
        continueBtn.isUserInteractionEnabled = true
        continueBtn.alpha = 1
        UserDefault.shared.user?.gender = "MALE"
    }
    
    @objc private func onClickWomanView() {
        womenRedioBtn.setImage(Constant.Icon.radioClick, for: .normal)
        manRedioBtn.setImage(Constant.Icon.radioIcon, for: .normal)
        otherRedioBtn.setImage(Constant.Icon.radioIcon, for: .normal)
        continueBtn.isUserInteractionEnabled = true
        continueBtn.alpha = 1
        UserDefault.shared.user?.gender = "FEMALE"
    }
    
    @objc private func onClickOtherView() {
        manRedioBtn.setImage(Constant.Icon.radioIcon, for: .normal)
        womenRedioBtn.setImage(Constant.Icon.radioIcon, for: .normal)
        otherRedioBtn.setImage(Constant.Icon.radioClick, for: .normal)
        continueBtn.isUserInteractionEnabled = true
        continueBtn.alpha = 1
        UserDefault.shared.user?.gender = "OTHER"
    }
    
    @IBAction private func onClickManBtn(_ sender: Any) {
        onClickManView()
    }
    
    @IBAction private func onClickWomanBtn(_ sender: Any) {
        onClickWomanView()
    }
    
    @IBAction private func onClickOtherBtn(_ sender: Any) {
        onClickOtherView()
    }

    @IBAction private func onClickContinue(_ sender: Any) {
        self.onBoardingDelegate.editUserProfileApi(gender: UserDefault.shared.user?.gender) { [weak self] isSuccess,errorMsg  in
            guard let self = self else {
                Loader.hide()
                return
            }
            if isSuccess {
                Navigate.to.SetProfilePicVc(self)
            } else {
                if errorMsg != nil {
                    Alert.showAlertSheet(style: .alert, title: errorMsg, message: "")
                } else {
                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                }
            }
            Loader.hide()
        }
    }
}
