//
//  UIImage+Extension.swift
//  Quick Delivery
//
//  Created by Mac Book on 15/08/2020.
//  Copyright © 2020 Quick Delivery. All rights reserved.
//

import UIKit
import SDWebImage

extension UIImageView {
    func setProfileImage(filePath: String){
        let imageURL = "\(Constants.BaseS3URL)\(filePath)"
        self.sd_setImage(with: URL(string: imageURL), placeholderImage: UIImage(named: Strings.PROFILE_PLACE_HOLDER.text), options: .highPriority)
    }
    func setGalleryImage(filePath: String){
        let imageURL = "\(Constants.BaseS3URL)\(filePath)"
        self.sd_setImage(with: URL(string: imageURL), placeholderImage: UIImage(named: Strings.IMAGE_PLACE_HOLDER.text), options: .highPriority)
    }
    func setNotificationImage(filePath: String, status: Bool){
        var imageURL = ""
        var placeHolder = "Logo"
        
        switch status{
        case true:
            placeHolder = Strings.SUCCESS.text
        case false:
            imageURL = filePath
        }
        
        if imageURL.isEmpty {
            self.image = UIImage(named: placeHolder)
        }
        else{
            self.sd_setImage(with: URL(string: imageURL), placeholderImage: UIImage(named: placeHolder))
        }
    }
}
