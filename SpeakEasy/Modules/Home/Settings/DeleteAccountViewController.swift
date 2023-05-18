//
//  DeleteAccountViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 26/12/22.
//

import UIKit

final class DeleteAccountViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction private func onClickContactUs(_ sender: Any) {
        guard let url = URL(string: APIBuilder.supportURL) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    @IBAction private func onClickDelete(_ sender: Any) {
        let okAction = UIAlertAction(title: "Yes", style: UIAlertAction.Style.destructive) {
            UIAlertAction in
            self.deleteAccount()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
            _ in
        }
        Alert.showAlertSheet(style: .alert, title: "", message: "Are you sure you want to delete your account? Your information will be lost forever.", actions: [okAction, cancelAction])
    }
    
    private func deleteAccount() {
        Loader.show()
        OnBoardingPresenter.deleteUser { isSuccess, errorMsg in
            Loader.hide()
            if isSuccess {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    UserDefault.shared.emptyData()
                    AppDelegate.shared.changeRootViewController()
                }
            } else {
                Alert.showAlertSheet(style: .alert, title: errorMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
    }
}
