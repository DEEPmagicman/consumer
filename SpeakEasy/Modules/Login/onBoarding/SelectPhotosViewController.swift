//
//  SelectPhotosViewController.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 02/01/23.
//

import UIKit

protocol InstagramPhotos {
    func getInstaImages(media:[InstagramMedia], isLastPage: Bool)
}

class SelectPhotosViewController: UIViewController {
    
    var instaPhoto = [InstagramMedia]()

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    

}

extension SelectPhotosViewController: InstagramPhotos {
    func getInstaImages(media: [InstagramMedia], isLastPage: Bool) {
        self.instaPhoto = media
    }
    
}

