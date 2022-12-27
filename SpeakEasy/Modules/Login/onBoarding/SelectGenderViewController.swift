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
    @IBOutlet weak var manRedioBtn: UIButton!
    @IBOutlet weak var womenRedioBtn: UIButton!
    @IBOutlet weak var continueBtn: UIButton!
    
    var onBoardingDelegate = OnBoardingPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(onClickManView))
        self.manSelectionView.addGestureRecognizer(gesture)
        let gesture2 = UITapGestureRecognizer(target: self, action: #selector(onClickWomanView))
        self.womenSelectionView.addGestureRecognizer(gesture2)
        self.manSelectionView.tag = 0
        self.womenSelectionView.tag = 0
        
        self.continueBtn.isUserInteractionEnabled = false
        self.continueBtn.alpha = 0.5

    }
    
    @objc func onClickManView() {
            self.manRedioBtn.setImage(Constant.Icon.radioClick, for: .normal)
          self.womenRedioBtn.setImage(Constant.Icon.radioIcon, for: .normal)
        self.continueBtn.isUserInteractionEnabled = true
        self.continueBtn.alpha = 1
        UserDefault.shared.user?.gender = "MALE"
    }
    
    @objc func onClickWomanView() {
            self.womenRedioBtn.setImage(Constant.Icon.radioClick, for: .normal)
        self.manRedioBtn.setImage(Constant.Icon.radioIcon, for: .normal)
        self.continueBtn.isUserInteractionEnabled = true
        self.continueBtn.alpha = 1
        UserDefault.shared.user?.gender = "FEMALE"
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        self.onBoardingDelegate.editUserProfileApi(gender: UserDefault.shared.user?.gender) { isSuccess in
            if isSuccess {
                Navigate.to.SetProfilePicVc(self)
            } else {
                Alert.showAlertSheet(style: .alert, title: "Gender Not update", message: "")
            }
            Loader.hide()
        }
    }

}
