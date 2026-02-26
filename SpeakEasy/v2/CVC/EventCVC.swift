//
//  EventCVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 23/12/25.
//

import UIKit

final class EventCVC: UICollectionViewCell {
    @IBOutlet weak var shimmerView: ShimmerView!
    @IBOutlet weak var eventTitleLbl: UILabel!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var eventTimeLbl: UILabel!
    @IBOutlet weak var bgImg: UIImageView!
    @IBOutlet weak var bgImage: UIImageView!
    
    
    func setupData(event: Event) {
        bgImg.sd_setImage(with: URL(string: (event.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
        bgImage.sd_setImage(with: URL(string: (event.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
        eventTitleLbl.text = event.title.uppercased()
        
        if let customText = event.openTimeCustomText,
           !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            
            eventTimeLbl.text = customText
            
        } else {
            
            let timezone =  ""
            
            let dateText = event.startDateTime.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .EEEMMMD,
                customTimeZone: timezone
            )
            
            let startTime = event.startDateTime.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .hmma,
                customTimeZone: timezone
            )
            
            let endTime = event.endDateTime?.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .hmma,
                customTimeZone: timezone
            ) ?? "LATE"
            
            if !dateText.isEmpty && !startTime.isEmpty {
                eventTimeLbl.text = "\(dateText) at \(startTime) - \(endTime)"
            } else {
                eventTimeLbl.text = ""
            }
        }
        
        
    }
    
}
