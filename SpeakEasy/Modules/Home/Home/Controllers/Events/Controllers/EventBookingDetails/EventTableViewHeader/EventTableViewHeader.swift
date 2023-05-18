//
//  EventTableViewHeader.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 9/1/22.
//

import UIKit
import SDWebImage

class EventTableViewHeader: UIView {
    
    @IBOutlet weak var btnDescription: UIButtonDeviceClass!
    @IBOutlet weak var btnCloseDescription: UIButtonDeviceClass!
    @IBOutlet weak var lblDescription: UILabelDeviceClass!
    
    @IBOutlet weak var imgEventCover: UIImageView!
    @IBOutlet weak var imgBrandLogo: UIImageView!
    @IBOutlet weak var lblVenueName: UILabelDeviceClass!
    @IBOutlet weak var lblLocation: UILabelDeviceClass!
    @IBOutlet weak var lblSongName: UILabelDeviceClass!
    @IBOutlet weak var lblSongArtists: UILabelDeviceClass!
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "EventTableViewHeader", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
    
    @IBAction func onBtnViewDescription(_ sender: UIButtonDeviceClass) {
        self.btnDescription.isHidden = true
        self.btnCloseDescription.isHidden = false
        UIView.animate(withDuration: 0.25, delay: 0, options: UIView.AnimationOptions.curveEaseInOut) {
            self.updatedLable()
        }
    }
    @IBAction func onBtnCloseDescription(_ sender: UIButtonDeviceClass) {
        self.btnDescription.isHidden = false
        self.btnCloseDescription.isHidden = true
        UIView.animate(withDuration: 0.25, delay: 0, options: UIView.AnimationOptions.curveEaseInOut) {
            self.updatedLable()
        }
    }
    private func updatedLable() {
        self.lblDescription.isHidden = !self.lblDescription.isHidden
        self.layoutIfNeeded()
    }
    
    func setData(data: TopEventDataSet) {
        self.imgEventCover.image = data.imgEventCover
        self.imgBrandLogo.image = data.imgBrandLogoLarge
        self.lblSongName.text = data.lblSongName ?? ""
        self.lblVenueName.text = data.lblVenueName ?? ""
        self.lblSongArtists.text = data.lblSongArtist ?? ""
        self.lblLocation.text = data.location ?? ""
    }
    
    func setDataNew(data: Event) {
        let imgUrl = "https://speakeasy-storage.s3.amazonaws.com/\(data.flyer?.key ?? "")"
//        let logoUrl = "https://speakeasy-storage.s3.amazonaws.com/\(data.venue?.logo?.key ?? "")"
        self.imgEventCover.sd_setImage(with: URL( string: imgUrl), completed: nil)
//        self.imgBrandLogo.sd_setImage(with: URL( string: logoUrl), completed: nil)
        self.lblDescription.text = data.description
//        self.lblSongName.text = data.lblSongName ?? ""
//        self.lblVenueName.text = data.venue?.name ?? ""
//        self.lblSongArtists.text = data.lblSongArtist ?? ""
//        self.lblLocation.text = data.venue?.address ?? ""
    }
}
