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
}

final class SetProfilePictureViewController: UIViewController {

    @IBOutlet weak var profileView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var cameraBtn: UIButton!
    
    var onBoardingDelegate = OnBoardingPresenter()
    var imgUrl = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let gesture = UITapGestureRecognizer(target: self, action: #selector(onClickAddPhoto))
        self.profileView.addGestureRecognizer(gesture)
        
        self.imageView.cornerRadius = 75
        self.continueBtn.isUserInteractionEnabled = false
        self.continueBtn.alpha = 0.5
    }

    @IBAction func onClickContinue(_ sender: Any) {
        self.onBoardingDelegate.uploadPhotoApi(image: imageView.image ?? UIImage()) { imgUrl ,isSuccess in
            if isSuccess {
                self.imgUrl = imgUrl
                let imgDetail = ImageDetail(key:"imgUrl",name:"\(UserDefault.shared.user?.phone ?? "")", description:"profile picture")
                self.onBoardingDelegate.editUserProfileApi(image: imgDetail) { isSuccess in
                    if isSuccess {
                        UserDefault.shared.user?.image = imgUrl
                        Navigate.to.notificationPermissionVc(self)
                        Loader.hide()
                    } else {
                        Alert.showAlertSheet(style: .alert, title: "image not update", message: "")
                        Loader.hide()
                    }
                }
            } else {
                Alert.showAlertSheet(style: .alert, title: "image not upload", message: "")
                Loader.hide()
            }
            
        }
    }
    
    @IBAction func onClickCamaraBtn(_ sender: Any) {
        onClickAddPhoto()
    }
    
    @objc func onClickAddPhoto() {
        showImagePickerControllerActionSheet()
    }
    
}

extension SetProfilePictureViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func showImagePickerControllerActionSheet() {
        let photoLibraryAction = UIAlertAction(title: "Camera Roll", style: .default) { (action) in
            self.showImagePickerController(soureType:.photoLibrary)
        }
        let instagram = UIAlertAction(title: "Connect Instagram", style: .default) { (action) in
//            Permission.openCamera(sender: self, mediaTypes: ["public.image"])
//            self.showImagePickerController(soureType:.camera)
            self.fetchInstaPhotos(self)
        }
        let cancelAction =  UIAlertAction(title: "Cancel", style: .cancel, handler: nil )
        
        Alert.showAlertSheet(style: .actionSheet, title: "Add photo", message: "", actions: [photoLibraryAction,cancelAction,instagram], completion: nil)
        
    }
    
    func fetchInstaPhotos(_ fromViewController: UIViewController) {
        
        if !Connectivity.isConnectedToInternet {
            Alert.showAlertSheet(style: .alert, title: Constant.String.internetNotConnect, message: "")
            return
        }
         let instaToken = UserDefault.shared.user?.instagramTokan
        if instaToken != "" && instaToken != nil {
            Navigate.to.selectPhotoVc(self)
        } else {
            Navigate.to.instagramWebView(self)
        }
    }
    
    func showImagePickerController(soureType:UIImagePickerController.SourceType){
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        imagePickerController.sourceType = soureType
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            imageView.image = editedImage
            self.cameraBtn.isHidden = true
            self.continueBtn.isUserInteractionEnabled = true
            self.continueBtn.alpha = 1
            
        } else if let orignalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = orignalImage
            self.cameraBtn.isHidden = true
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
        self.cameraBtn.isHidden = true
        self.continueBtn.isUserInteractionEnabled = true
        self.continueBtn.alpha = 1
    }
}
