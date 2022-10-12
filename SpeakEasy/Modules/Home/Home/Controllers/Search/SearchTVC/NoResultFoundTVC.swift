//
//  NoResultFoundTVC.swift
//  SpeakEasy-Consumer
//
//  Created by M.Usman Bin Rehan on 06/09/2022.
//

import UIKit

class NoResultFoundTVC: UITableViewCell {

    @IBOutlet weak var lblNoResult: UILabelDeviceClass!
  
    func setData(hasVenues: Bool, hasEvents: Bool, searchedFor: String) {
        if !hasVenues && !hasEvents {
            self.lblNoResult.text = "\(Strings.NO_RESULT_MATCHING.text)\n\"\(searchedFor)\""
        }
        else {
            if !hasVenues {
                self.lblNoResult.text = "\(Strings.NO_VENUE_RESULTS_MATCHING.text)\n\"\(searchedFor)\""
            }
            if !hasEvents {
                self.lblNoResult.text = "\(Strings.NO_EVENT_RESULTS_MATCHING.text)\n\"\(searchedFor)\""
            }
        }
    }
}
