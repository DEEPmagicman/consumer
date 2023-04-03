//
//  SelectGenderViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 16/12/22.
//

import UIKit

final class SelectGenderViewController: UIViewController {

    @IBOutlet weak var manSelectionView: UIView!
    @IBOutlet weak var womenSelectionView: UIView!
    @IBOutlet weak var otherSelectionView: UIView!
    @IBOutlet weak var manRedioBtn: UIButton!
    @IBOutlet weak var womenRedioBtn: UIButton!
    @IBOutlet weak var otherRedioBtn: UIButton!
    @IBOutlet weak var continueBtn: UIButton!
    
    var onBoardingDelegate = OnBoardingPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(onClickManView))
        self.manSelectionView.addGestureRecognizer(gesture)
        let gesture2 = UITapGestureRecognizer(target: self, action: #selector(onClickWomanView))
        self.womenSelectionView.addGestureRecognizer(gesture2)
        let gesture3 = UITapGestureRecognizer(target: self, action: #selector(onClickOtherView))
        self.otherSelectionView.addGestureRecognizer(gesture3)
        self.manSelectionView.tag = 0
        self.womenSelectionView.tag = 0
        self.otherSelectionView.tag = 0
        
        self.continueBtn.isUserInteractionEnabled = false
        self.continueBtn.alpha = 0.5

    }
    
    @objc func onClickManView() {
        self.manRedioBtn.setImage(Constant.Icon.radioClick, for: .normal)
        self.womenRedioBtn.setImage(Constant.Icon.radioIcon, for: .normal)
        self.otherRedioBtn.setImage(Constant.Icon.radioIcon, for: .normal)
        self.continueBtn.isUserInteractionEnabled = true
        self.continueBtn.alpha = 1
        UserDefault.shared.user?.gender = "MALE"
    }
    
    @objc func onClickWomanView() {
            self.womenRedioBtn.setImage(Constant.Icon.radioClick, for: .normal)
        self.manRedioBtn.setImage(Constant.Icon.radioIcon, for: .normal)
        self.otherRedioBtn.setImage(Constant.Icon.radioIcon, for: .normal)
        self.continueBtn.isUserInteractionEnabled = true
        self.continueBtn.alpha = 1
        UserDefault.shared.user?.gender = "FEMALE"
    }
    
    @objc func onClickOtherView() {
        self.manRedioBtn.setImage(Constant.Icon.radioIcon, for: .normal)
        self.womenRedioBtn.setImage(Constant.Icon.radioIcon, for: .normal)
        self.otherRedioBtn.setImage(Constant.Icon.radioClick, for: .normal)
        self.continueBtn.isUserInteractionEnabled = true
        self.continueBtn.alpha = 1
        UserDefault.shared.user?.gender = "OTHER"
    }
    
    @IBAction func onClickManBtn(_ sender: Any) {
        onClickManView()
    }
    
    @IBAction func onClickWomanBtn(_ sender: Any) {
        onClickWomanView()
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        self.onBoardingDelegate.editUserProfileApi(gender: UserDefault.shared.user?.gender) { isSuccess,errorMsg  in
            if isSuccess {
                Navigate.to.connectAccountVc(self)
//                Navigate.to.SetProfilePicVc(self)
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
