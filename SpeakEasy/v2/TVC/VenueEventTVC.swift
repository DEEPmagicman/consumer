//
//  VenueEventTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 19/03/26.
//

import UIKit

enum ScreenType {
    case `default`
    case premiumExperience
}

final class VenueEventTVC: UITableViewCell {
    
    @IBOutlet weak var eventImg: UIImageView!
    @IBOutlet weak var bottomLbl: UILabel!
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var eventTitleLbl: UILabel!
    @IBOutlet weak var tablePriceView: UIView!
    
    var screenType: ScreenType = .default
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        eventImg.contentMode = .scaleAspectFill
        eventImg.clipsToBounds = true
        eventImg.layer.cornerRadius = 10
      
    }
    
    func setScreenType(screenType: ScreenType = .default) {
        tablePriceView.isHidden = (screenType == .default)
    }
    
    func configure(with event: Event) {
        eventTitleLbl.text = event.title
        
        dateLbl.text = formatDateRange(
            start: event.startDateTime,
            end: event.endDateTime ?? ""
        )
        
        bottomLbl.text = event.venue?.name ?? "Unknown Venue"
        
        eventImg.sd_setImage(
            with: URL(string: (event.flyer?.key ?? "").imageURL),
            placeholderImage: Constant.Icon.uploadImage
        )
      
        
        eventImg.hero.id = "event.image.\(event.id)"
        eventTitleLbl.hero.id = "event.title.\(event.id)"
    }
}

private func formatDateRange(start: String, end: String) -> String {
    
    let inputFormatter = DateFormatter()
    inputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    
    let outputFormatter = DateFormatter()
    outputFormatter.dateFormat = "dd MMM, hh:mm a"
    
    guard let startDate = inputFormatter.date(from: start),
          let endDate = inputFormatter.date(from: end) else {
        return ""
    }
    
    let startStr = outputFormatter.string(from: startDate)
    let endStr = outputFormatter.string(from: endDate)
    
    return "\(startStr) - \(endStr)"
}
