//
//  SetProfilePictureViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 09/12/22.
//

import UIKit
import SwiftUI

final class SetProfilePictureViewController: UIViewController {

    @IBOutlet weak var profileView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var cameraBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let gesture = UITapGestureRecognizer(target: self, action: #selector(onClickAddPhoto))
        self.profileView.addGestureRecognizer(gesture)
        
        self.imageView.cornerRadius = 75
    }

    @IBAction func onClickContinue(_ sender: Any) {
        Navigate.to.notificationPermissionVc(self)
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
        }
        let cancelAction =  UIAlertAction(title: "Cancel", style: .cancel, handler: nil )
        
        Alert.showAlertSheet(style: .actionSheet, title: "Add photo", message: "", actions: [photoLibraryAction,cancelAction,instagram], completion: nil)
        
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
            
        } else if let orignalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = orignalImage
            self.cameraBtn.isHidden = true
        }
        picker.dismiss(animated: true, completion: nil)
    }
}
