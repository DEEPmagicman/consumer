//
//  SetProfilePictureViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 09/12/22.
//

import UIKit
import SwiftUI
import SDWebImage

protocol SelectedInstaImgDelegate: AnyObject {
    func selectedImg(image: String)
    func loginAgain()
}

final class SetProfilePictureViewController: UIViewController {

    @IBOutlet weak var profileView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var continueBtn: UIButton!
    
    private var presenter = OnBoardingPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let gesture = UITapGestureRecognizer(target: self, action: #selector(onClickAddPhoto))
        profileView.addGestureRecognizer(gesture)
        
        imageView.cornerRadius = 75
        if (UserDefault.shared.user?.image.key ?? "") != "", let url = URL(string: UserDefault.shared.user?.image.key ?? "") {
            imageView.sd_setImage(with: url, placeholderImage: Constant.Icon.uploadImage)
            continueBtn.isUserInteractionEnabled = true
            continueBtn.alpha = 1
        } else {
            continueBtn.isUserInteractionEnabled = false
            continueBtn.alpha = 0.5
        }
    }

    @IBAction private func onClickContinue(_ sender: Any) {
        presenter.uploadPhotoApi(image: imageView.image ?? UIImage()) { [weak self] imgUrl ,isSuccess in
            guard let self = self else {
                Loader.hide()
                return
            }
            if isSuccess {
                let imgDetail = ImageDetail(key: imgUrl, name:"\(UserDefault.shared.user?.phone ?? "")", description: "profile picture")
                self.presenter.editUserProfileApi(image: imgDetail) { [weak self] isSuccess, errorMsg  in
                    guard let self = self else {
                        Loader.hide()
                        return
                    }
                    if isSuccess {
                        UserDefault.shared.user?.image = imgDetail
                        Navigate.to.notificationPermissionVc(self)
                        Loader.hide()
                    } else {
                        if errorMsg != nil {
                            Alert.showAlertSheet(style: .alert, title: errorMsg, message: "")
                        } else {
                            Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                        }
                        Loader.hide()
                    }
                }
            } else {
                Alert.showAlertSheet(style: .alert, title: "image not upload", message: "")
                Loader.hide()
            }
        }
    }
    
    @IBAction private func onClickSkipForNow(_ sender: Any) {
        Navigate.to.notificationPermissionVc(self)
    }
    
    @objc private func onClickAddPhoto() {
        Navigate.to.showImagePickerController(self, sourceType: .photoLibrary)
        // MARK: hide showImagePickerControllerActionSheet for now
//        showImagePickerControllerActionSheet()
    }
}

extension SetProfilePictureViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func showImagePickerControllerActionSheet() {
        let photoLibraryAction = UIAlertAction(title: "Camera Roll", style: .default) { (action) in
            Navigate.to.showImagePickerController(self, sourceType: .photoLibrary)
        }
        // MARK: comment out Instagram flow for now
//        let instagram = UIAlertAction(title: "Connect Instagram", style: .default) { (action) in
////            Permission.openCamera(sender: self, mediaTypes: ["public.image"])
////            self.showImagePickerController(soureType:.camera)
//            self.fetchInstaPhotos(self)
//        }
        let cancelAction =  UIAlertAction(title: "Cancel", style: .cancel, handler: nil )
        
        Alert.showAlertSheet(style: .actionSheet, title: "Add photo", message: "", actions: [photoLibraryAction, cancelAction], completion: nil)
    }
    
    func fetchInstaPhotos(_ fromViewController: UIViewController) {
        if !Connectivity.isConnectedToInternet {
            Alert.showAlertSheet(style: .alert, title: Constant.String.internetNotConnect, message: "")
            return
        }
        let instaToken = UserDefault.shared.user?.instagramToken
        if instaToken != "" && instaToken != nil {
            Navigate.to.selectPhotoVc(self)
        } else {
            Navigate.to.instagramWebView(self)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            imageView.image = editedImage
            self.continueBtn.isUserInteractionEnabled = true
            self.continueBtn.alpha = 1
            
        } else if let orignalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = orignalImage
            self.continueBtn.isUserInteractionEnabled = true
            self.continueBtn.alpha = 1
        }
        picker.dismiss(animated: true, completion: nil)
    }
}

extension SetProfilePictureViewController: InstagramConnectedDelegate {
    func instaConnect() {
        Navigate.to.selectPhotoVc(self)
    }
}

extension SetProfilePictureViewController: SelectedInstaImgDelegate {
    func selectedImg(image: String) {
        imageView.sd_setImage(with: URL( string: image), completed: nil)
        continueBtn.isUserInteractionEnabled = true
        continueBtn.alpha = 1
    }
    
    func loginAgain() {
        DispatchQueue.main.async {
            Navigate.to.instagramWebView(self)
        }
    }
}
